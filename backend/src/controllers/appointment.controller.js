const { pool } = require('../config/db');
const { generateBookingCode, generateQrData } = require('../utils/code_generator');

// 1. Đặt lịch khám bệnh linh hoạt và an toàn (Transaction chống race condition, tự xử lý thiếu profile/schedule)
async function createAppointment(req, res, next) {
  const userId = req.user.id;
  const {
    profile_id,
    doctor_id,
    schedule_id,
    work_date,
    appointment_date,
    time_slot,
    exam_type = 'Dịch vụ',
    symptoms
  } = req.body;

  console.log(`[Appointment] Nhận yêu cầu đặt lịch từ User #${userId}:`, {
    profile_id,
    doctor_id,
    schedule_id,
    work_date: work_date || appointment_date,
    time_slot,
    exam_type
  });

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // 1.1 XỬ LÝ HỒ SƠ NGƯỜI KHÁM (profile_id) LINH HOẠT
    let targetProfileId = profile_id ? parseInt(profile_id, 10) : null;
    let patientProfile = null;

    if (targetProfileId) {
      const [profiles] = await conn.query(
        'SELECT id, full_name, phone FROM patient_profiles WHERE id = ? AND user_id = ?',
        [targetProfileId, userId]
      );
      if (profiles.length > 0) {
        patientProfile = profiles[0];
      }
    }

    // Nếu profile_id không hợp lệ hoặc chưa truyền, tìm xem user này đã có profile nào chưa
    if (!patientProfile) {
      const [existingProfiles] = await conn.query(
        'SELECT id, full_name, phone FROM patient_profiles WHERE user_id = ? ORDER BY id ASC LIMIT 1',
        [userId]
      );
      if (existingProfiles.length > 0) {
        patientProfile = existingProfiles[0];
        targetProfileId = patientProfile.id;
        console.log(`[Appointment] Tự động chọn hồ sơ có sẵn #${targetProfileId} (${patientProfile.full_name}) cho user #${userId}`);
      }
    }

    // Nếu user chưa từng có bất kỳ hồ sơ nào trong patient_profiles, tự động tạo hồ sơ "Bản thân" từ bảng users
    if (!patientProfile) {
      const [users] = await conn.query('SELECT full_name, phone FROM users WHERE id = ?', [userId]);
      const defaultName = (users.length > 0 && users[0].full_name) ? users[0].full_name : 'Bệnh nhân';
      const defaultPhone = (users.length > 0 && users[0].phone) ? users[0].phone : null;

      const [newProfileResult] = await conn.query(
        `INSERT INTO patient_profiles (user_id, full_name, dob, gender, phone, relationship)
         VALUES (?, ?, '1995-01-01', 'Nam', ?, 'Bản thân')`,
        [userId, defaultName, defaultPhone]
      );
      targetProfileId = newProfileResult.insertId;
      patientProfile = {
        id: targetProfileId,
        full_name: defaultName,
        phone: defaultPhone
      };
      console.log(`[Appointment] Đã tự động tạo hồ sơ mặc định Bản thân #${targetProfileId} cho user #${userId}`);
    }

    // 1.2 XỬ LÝ BÁC SĨ (doctor_id)
    let targetDoctorId = doctor_id ? parseInt(doctor_id, 10) : null;

    // Nếu không truyền doctor_id nhưng có schedule_id, lấy doctor_id từ schedule_id
    if (!targetDoctorId && schedule_id) {
      const [schedDoctor] = await conn.query('SELECT doctor_id FROM doctor_schedules WHERE id = ?', [schedule_id]);
      if (schedDoctor.length > 0) {
        targetDoctorId = schedDoctor[0].doctor_id;
      }
    }

    // Nếu vẫn chưa có doctor_id, lấy bác sĩ đầu tiên trong CSDL
    if (!targetDoctorId) {
      const [defaultDocs] = await conn.query('SELECT id FROM doctors ORDER BY id ASC LIMIT 1');
      if (defaultDocs.length > 0) {
        targetDoctorId = defaultDocs[0].id;
      } else {
        await conn.rollback();
        return res.status(404).json({
          success: false,
          message: 'Hệ thống chưa có bác sĩ nào trong cơ sở dữ liệu.'
        });
      }
    }

    // 1.3 XỬ LÝ KHUNG GIỜ (schedule_id) LINH HOẠT - CHỐNG LỖI FOREIGN KEY
    let targetScheduleId = schedule_id ? parseInt(schedule_id, 10) : null;
    let schedule = null;
    const dateToUse = work_date || appointment_date || new Date().toISOString().split('T')[0];
    const slotToUse = time_slot || '08:30 - 09:00';

    // Thử tìm theo schedule_id truyền lên
    if (targetScheduleId && targetScheduleId > 0) {
      const [rows] = await conn.query(
        `SELECT ds.id, ds.doctor_id, ds.work_date, ds.time_slot, ds.max_patients, ds.booked_count, ds.status,
                d.full_name AS doctor_name, d.degree, d.room_number,
                s.name AS specialty_name, s.room_location, s.base_price
         FROM doctor_schedules ds
         JOIN doctors d ON ds.doctor_id = d.id
         JOIN specialties s ON d.specialty_id = s.id
         WHERE ds.id = ?
         FOR UPDATE`,
        [targetScheduleId]
      );
      if (rows.length > 0) {
        schedule = rows[0];
      }
    }

    // Nếu không tìm thấy bằng schedule_id, tìm theo (doctor_id, work_date, time_slot)
    if (!schedule) {
      const [matchedSlots] = await conn.query(
        `SELECT ds.id, ds.doctor_id, ds.work_date, ds.time_slot, ds.max_patients, ds.booked_count, ds.status,
                d.full_name AS doctor_name, d.degree, d.room_number,
                s.name AS specialty_name, s.room_location, s.base_price
         FROM doctor_schedules ds
         JOIN doctors d ON ds.doctor_id = d.id
         JOIN specialties s ON d.specialty_id = s.id
         WHERE ds.doctor_id = ? AND ds.work_date = ? AND ds.time_slot = ?
         FOR UPDATE`,
        [targetDoctorId, dateToUse, slotToUse]
      );

      if (matchedSlots.length > 0) {
        schedule = matchedSlots[0];
        targetScheduleId = schedule.id;
      } else {
        // Chưa có khung giờ này trong DB -> Tự động TẠO MỚI khung giờ để không bao giờ bị lỗi khóa ngoại!
        const [insertSlot] = await conn.query(
          `INSERT INTO doctor_schedules (doctor_id, work_date, time_slot, max_patients, booked_count, status)
           VALUES (?, ?, ?, 5, 0, 'available')`,
          [targetDoctorId, dateToUse, slotToUse]
        );
        targetScheduleId = insertSlot.insertId;

        const [createdSlotRows] = await conn.query(
          `SELECT ds.id, ds.doctor_id, ds.work_date, ds.time_slot, ds.max_patients, ds.booked_count, ds.status,
                  d.full_name AS doctor_name, d.degree, d.room_number,
                  s.name AS specialty_name, s.room_location, s.base_price
           FROM doctor_schedules ds
           JOIN doctors d ON ds.doctor_id = d.id
           JOIN specialties s ON d.specialty_id = s.id
           WHERE ds.id = ?
           FOR UPDATE`,
          [targetScheduleId]
        );
        schedule = createdSlotRows[0];
        console.log(`[Appointment] Đã tự động tạo khung giờ mới #${targetScheduleId} (${dateToUse} ${slotToUse}) cho BS #${targetDoctorId}`);
      }
    }

    // Kiểm tra tính khả dụng của khung giờ
    if (schedule.status === 'cancelled') {
      await conn.rollback();
      return res.status(400).json({
        success: false,
        message: 'Khung giờ khám này hiện đang tạm ngưng tiếp nhận bệnh nhân.'
      });
    }

    if (schedule.booked_count >= schedule.max_patients) {
      await conn.rollback();
      return res.status(400).json({
        success: false,
        message: `Khung giờ ${schedule.time_slot} ngày ${schedule.work_date} đã đủ số lượng bệnh nhân tối đa (${schedule.max_patients}/${schedule.max_patients}). Vui lòng chọn khung giờ khác.`
      });
    }

    // 1.4 Chống đặt trùng lịch: Cùng một người không đặt 2 lần cùng một khung giờ
    const [existingBookings] = await conn.query(
      `SELECT id, booking_code FROM appointments
       WHERE profile_id = ? AND schedule_id = ? AND status IN ('pending', 'confirmed')`,
      [targetProfileId, targetScheduleId]
    );

    if (existingBookings.length > 0) {
      await conn.rollback();
      return res.status(400).json({
        success: false,
        message: `Bệnh nhân ${patientProfile.full_name} đã có lịch hẹn cho khung giờ này (Mã: ${existingBookings[0].booking_code}).`
      });
    }

    // 1.5 Sinh STT, Mã phiếu khám và Mã QR
    const queueNumber = (schedule.booked_count || 0) + 1;
    const bookingCode = generateBookingCode(queueNumber);
    const doctorDisplay = schedule.doctor_name
      ? (schedule.degree && !schedule.doctor_name.startsWith(schedule.degree) ? `${schedule.degree} ${schedule.doctor_name}` : schedule.doctor_name)
      : 'Bác sĩ chuyên khoa';

    const qrData = generateQrData({
      bookingCode,
      patientName: patientProfile.full_name,
      doctorName: doctorDisplay,
      specialtyName: schedule.specialty_name || 'Khám tổng quát',
      workDate: schedule.work_date,
      timeSlot: schedule.time_slot,
      queueNumber
    });

    // Chuẩn hóa exam_type theo ENUM('BHYT', 'Dịch vụ')
    const normalizedExamType = (exam_type && exam_type.toString().toUpperCase().includes('BHYT')) ? 'BHYT' : 'Dịch vụ';

    // 1.6 Tăng booked_count trong doctor_schedules
    const nextBookedCount = (schedule.booked_count || 0) + 1;
    const nextStatus = nextBookedCount >= schedule.max_patients ? 'full' : 'available';

    await conn.query(
      'UPDATE doctor_schedules SET booked_count = ?, status = ? WHERE id = ?',
      [nextBookedCount, nextStatus, targetScheduleId]
    );

    // 1.7 Tăng patient_count cho bác sĩ
    await conn.query(
      'UPDATE doctors SET patient_count = patient_count + 1 WHERE id = ?',
      [targetDoctorId]
    );

    // 1.8 Tạo phiếu khám trong bảng appointments (khớp 100% tên cột CSDL)
    const [appointmentResult] = await conn.query(
      `INSERT INTO appointments
       (booking_code, user_id, profile_id, doctor_id, schedule_id, queue_number, qr_data, exam_type, symptoms, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'confirmed')`,
      [
        bookingCode,
        userId,
        targetProfileId,
        targetDoctorId,
        targetScheduleId,
        queueNumber,
        qrData,
        normalizedExamType,
        (symptoms && typeof symptoms === 'string' && symptoms.trim().length > 0) ? symptoms.trim() : null
      ]
    );

    await conn.commit();
    console.log(`[Appointment] Đặt khám THÀNH CÔNG! Mã: ${bookingCode}, ID: ${appointmentResult.insertId}`);

    // 1.9 Lấy lại chi tiết phiếu khám đầy đủ thông tin để trả về Client
    const [createdAppointment] = await pool.query(
      `SELECT a.*,
              p.full_name AS patient_name, p.dob AS patient_dob, p.gender AS patient_gender, p.bhyt_code,
              d.full_name AS doctor_name, d.degree, d.avatar_url AS doctor_avatar, d.hospital_name, d.room_number,
              s.name AS specialty_name, s.room_location, s.base_price,
              ds.work_date, ds.time_slot
       FROM appointments a
       JOIN patient_profiles p ON a.profile_id = p.id
       JOIN doctors d ON a.doctor_id = d.id
       JOIN specialties s ON d.specialty_id = s.id
       JOIN doctor_schedules ds ON a.schedule_id = ds.id
       WHERE a.id = ?`,
      [appointmentResult.insertId]
    );

    return res.status(201).json({
      success: true,
      message: 'Đặt lịch khám bệnh thành công!',
      data: createdAppointment[0]
    });
  } catch (error) {
    await conn.rollback();
    console.error('[Appointment Error] Đặt lịch khám thất bại:', error);
    next(error);
  } finally {
    conn.release();
  }
}

// 2. Lấy danh sách phiếu khám của người dùng
async function getAppointments(req, res, next) {
  try {
    const userId = req.user.id;
    const { status, profile_id } = req.query;

    let query = `
      SELECT a.*,
             p.full_name AS patient_name, p.gender AS patient_gender, p.relationship,
             d.full_name AS doctor_name, d.degree, d.avatar_url AS doctor_avatar, d.room_number,
             s.name AS specialty_name, s.room_location, s.base_price,
             ds.work_date, ds.time_slot
      FROM appointments a
      JOIN patient_profiles p ON a.profile_id = p.id
      JOIN doctors d ON a.doctor_id = d.id
      JOIN specialties s ON d.specialty_id = s.id
      JOIN doctor_schedules ds ON a.schedule_id = ds.id
      WHERE a.user_id = ?
    `;
    const params = [userId];

    if (status) {
      query += ` AND a.status = ?`;
      params.push(status);
    }

    if (profile_id) {
      query += ` AND a.profile_id = ?`;
      params.push(profile_id);
    }

    query += ` ORDER BY ds.work_date DESC, ds.time_slot DESC, a.id DESC`;

    const [appointments] = await pool.query(query, params);

    return res.status(200).json({
      success: true,
      count: appointments.length,
      data: appointments
    });
  } catch (error) {
    next(error);
  }
}

// 3. Lấy chi tiết một phiếu khám theo ID hoặc theo mã booking_code
async function getAppointmentById(req, res, next) {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const [appointments] = await pool.query(
      `SELECT a.*,
              p.full_name AS patient_name, p.dob AS patient_dob, p.gender AS patient_gender, p.cccd, p.bhyt_code, p.phone AS patient_phone, p.allergies,
              d.full_name AS doctor_name, d.degree, d.avatar_url AS doctor_avatar, d.hospital_name, d.room_number,
              s.name AS specialty_name, s.room_location, s.base_price,
              ds.work_date, ds.time_slot
       FROM appointments a
       JOIN patient_profiles p ON a.profile_id = p.id
       JOIN doctors d ON a.doctor_id = d.id
       JOIN specialties s ON d.specialty_id = s.id
       JOIN doctor_schedules ds ON a.schedule_id = ds.id
       WHERE (a.id = ? OR a.booking_code = ?) AND a.user_id = ?
       LIMIT 1`,
      [id, id, userId]
    );

    if (appointments.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu khám hoặc bạn không có quyền truy cập.'
      });
    }

    return res.status(200).json({
      success: true,
      data: appointments[0]
    });
  } catch (error) {
    next(error);
  }
}

// 4. Hủy lịch khám bệnh (Giảm booked_count và mở lại slot nếu cần)
async function cancelAppointment(req, res, next) {
  const userId = req.user.id;
  const { id } = req.params;
  const { reason = 'Người dùng tự hủy lịch' } = req.body;

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [appointments] = await conn.query(
      `SELECT a.*, ds.booked_count, ds.max_patients
       FROM appointments a
       JOIN doctor_schedules ds ON a.schedule_id = ds.id
       WHERE a.id = ? AND a.user_id = ?
       FOR UPDATE`,
      [id, userId]
    );

    if (appointments.length === 0) {
      await conn.rollback();
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu khám.'
      });
    }

    const appointment = appointments[0];

    if (appointment.status === 'cancelled') {
      await conn.rollback();
      return res.status(400).json({
        success: false,
        message: 'Phiếu khám này đã được hủy trước đó.'
      });
    }

    if (appointment.status === 'completed') {
      await conn.rollback();
      return res.status(400).json({
        success: false,
        message: 'Không thể hủy phiếu khám đã hoàn thành.'
      });
    }

    // Cập nhật trạng thái phiếu khám thành 'cancelled'
    await conn.query(
      `UPDATE appointments
       SET status = 'cancelled', cancelled_reason = ?
       WHERE id = ?`,
      [reason, id]
    );

    // Giảm booked_count trong doctor_schedules và chuyển trạng thái về 'available'
    const updatedBookedCount = Math.max(0, appointment.booked_count - 1);
    await conn.query(
      `UPDATE doctor_schedules
       SET booked_count = ?, status = 'available'
       WHERE id = ?`,
      [updatedBookedCount, appointment.schedule_id]
    );

    await conn.commit();

    return res.status(200).json({
      success: true,
      message: 'Hủy lịch khám thành công.'
    });
  } catch (error) {
    await conn.rollback();
    next(error);
  } finally {
    conn.release();
  }
}

module.exports = {
  createAppointment,
  getAppointments,
  getAppointmentById,
  cancelAppointment
};
