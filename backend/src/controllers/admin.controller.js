const { pool } = require('../config/db');

// 1. Thống kê tổng quan hệ thống MEDBOOK
async function getAdminStats(req, res, next) {
  try {
    const today = new Date().toISOString().split('T')[0];

    // Thống kê tổng quan
    const [[{ total_patients }]] = await pool.query('SELECT COUNT(*) AS total_patients FROM patient_profiles');
    const [[{ total_users }]] = await pool.query('SELECT COUNT(*) AS total_users FROM users WHERE role = "patient"');
    const [[{ total_doctors }]] = await pool.query('SELECT COUNT(*) AS total_doctors FROM doctors');
    const [[{ total_appointments }]] = await pool.query('SELECT COUNT(*) AS total_appointments FROM appointments');

    // Thống kê ca khám hôm nay
    const [[{ today_appointments }]] = await pool.query(
      `SELECT COUNT(*) AS today_appointments
       FROM appointments a
       JOIN doctor_schedules ds ON a.schedule_id = ds.id
       WHERE ds.work_date = ?`,
      [today]
    );

    // Thống kê phiếu khám theo từng trạng thái
    const [statusRows] = await pool.query(
      `SELECT status, COUNT(*) AS count
       FROM appointments
       GROUP BY status`
    );

    const statusCounts = {
      pending: 0,
      confirmed: 0,
      completed: 0,
      cancelled: 0
    };
    statusRows.forEach(row => {
      if (statusCounts.hasOwnProperty(row.status)) {
        statusCounts[row.status] = row.count;
      }
    });

    // Thống kê lưu lượng bệnh nhân theo từng Chuyên khoa
    const [specialtyStats] = await pool.query(
      `SELECT s.id, s.name, s.code, s.room_location, s.base_price,
              COUNT(DISTINCT d.id) AS doctor_count,
              COUNT(a.id) AS appointment_count
       FROM specialties s
       LEFT JOIN doctors d ON s.id = d.specialty_id
       LEFT JOIN appointments a ON d.id = a.doctor_id
       GROUP BY s.id, s.name, s.code, s.room_location, s.base_price
       ORDER BY appointment_count DESC, s.id ASC`
    );

    // Danh sách 6 ca đặt khám gần nhất
    const [recentAppointments] = await pool.query(
      `SELECT a.id, a.booking_code, a.queue_number, a.status, a.exam_type, a.created_at,
              p.full_name AS patient_name, p.phone AS patient_phone,
              d.full_name AS doctor_name, d.degree,
              s.name AS specialty_name,
              ds.work_date, ds.time_slot
       FROM appointments a
       JOIN patient_profiles p ON a.profile_id = p.id
       JOIN doctors d ON a.doctor_id = d.id
       JOIN specialties s ON d.specialty_id = s.id
       JOIN doctor_schedules ds ON a.schedule_id = ds.id
       ORDER BY a.created_at DESC
       LIMIT 6`
    );

    return res.status(200).json({
      success: true,
      data: {
        summary: {
          total_patients,
          total_users,
          total_doctors,
          total_appointments,
          today_appointments
        },
        status_counts: statusCounts,
        specialty_stats: specialtyStats,
        recent_appointments: recentAppointments
      }
    });
  } catch (error) {
    next(error);
  }
}

// 2. Lấy toàn bộ danh sách phiếu khám của Bệnh viện (kèm bộ lọc Ngày, Trạng thái, Bác sĩ, Tìm kiếm)
async function getAllAppointments(req, res, next) {
  try {
    const { status, date, doctor_id, specialty_id, search } = req.query;

    let query = `
      SELECT a.*,
             p.full_name AS patient_name, p.dob AS patient_dob, p.gender AS patient_gender,
             p.phone AS patient_phone, p.cccd, p.bhyt_code, p.relationship,
             u.phone AS user_phone, u.email AS user_email,
             d.full_name AS doctor_name, d.degree, d.room_number,
             s.name AS specialty_name, s.room_location, s.base_price,
             ds.work_date, ds.time_slot
      FROM appointments a
      JOIN patient_profiles p ON a.profile_id = p.id
      JOIN users u ON a.user_id = u.id
      JOIN doctors d ON a.doctor_id = d.id
      JOIN specialties s ON d.specialty_id = s.id
      JOIN doctor_schedules ds ON a.schedule_id = ds.id
      WHERE 1=1
    `;
    const params = [];

    if (status && status !== 'all') {
      query += ` AND a.status = ?`;
      params.push(status);
    }

    if (date) {
      query += ` AND ds.work_date = ?`;
      params.push(date);
    }

    if (doctor_id) {
      query += ` AND a.doctor_id = ?`;
      params.push(doctor_id);
    }

    if (specialty_id) {
      query += ` AND d.specialty_id = ?`;
      params.push(specialty_id);
    }

    if (search && search.trim().length > 0) {
      const term = `%${search.trim()}%`;
      query += ` AND (a.booking_code LIKE ? OR p.full_name LIKE ? OR p.phone LIKE ? OR p.bhyt_code LIKE ?)`;
      params.push(term, term, term, term);
    }

    query += ` ORDER BY ds.work_date DESC, ds.time_slot ASC, a.queue_number ASC, a.id DESC`;

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

// 3. Cập nhật trạng thái phiếu khám (Duyệt, Hoàn thành, Hủy)
async function updateAppointmentStatus(req, res, next) {
  const { id } = req.params;
  const { status, cancelled_reason } = req.body;

  const validStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({
      success: false,
      message: `Trạng thái không hợp lệ. Chỉ chấp nhận: ${validStatuses.join(', ')}`
    });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [appointments] = await conn.query(
      'SELECT id, schedule_id, status FROM appointments WHERE id = ? FOR UPDATE',
      [id]
    );

    if (appointments.length === 0) {
      await conn.rollback();
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu khám.'
      });
    }

    const currentAppt = appointments[0];

    // Cập nhật trạng thái phiếu khám
    await conn.query(
      `UPDATE appointments
       SET status = ?, cancelled_reason = ?
       WHERE id = ?`,
      [status, status === 'cancelled' ? (cancelled_reason || 'Quản trị viên hủy') : null, id]
    );

    // Nếu chuyển sang cancelled từ trạng thái confirmed/pending, giảm booked_count trong doctor_schedules
    if (status === 'cancelled' && currentAppt.status !== 'cancelled') {
      await conn.query(
        `UPDATE doctor_schedules
         SET booked_count = GREATEST(0, booked_count - 1), status = 'available'
         WHERE id = ?`,
        [currentAppt.schedule_id]
      );
    }

    await conn.commit();

    return res.status(200).json({
      success: true,
      message: `Đã cập nhật trạng thái phiếu khám thành công: ${status}`
    });
  } catch (error) {
    await conn.rollback();
    next(error);
  } finally {
    conn.release();
  }
}

// 4. Nhập kết quả khám bệnh & Kê đơn thuốc (Bác sĩ/Admin trả kết quả và tự động chuyển status = 'completed')
async function createMedicalRecordForAdmin(req, res, next) {
  const {
    appointment_id,
    profile_id,
    doctor_id,
    specialty_name,
    diagnosis,
    doctor_notes,
    prescription,
    blood_pressure,
    heart_rate,
    blood_sugar,
    weight,
    height,
    exam_date
  } = req.body;

  if (!diagnosis || diagnosis.trim().length === 0) {
    return res.status(400).json({
      success: false,
      message: 'Vui lòng nhập chẩn đoán xác định của bác sĩ.'
    });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    let targetProfileId = profile_id;
    let targetDoctorId = doctor_id;
    let targetSpecialty = specialty_name || 'Khám chuyên khoa';

    // Nếu có appointment_id, lấy thông tin từ appointment
    if (appointment_id) {
      const [appts] = await conn.query(
        `SELECT a.profile_id, a.doctor_id, s.name AS specialty_name
         FROM appointments a
         JOIN doctors d ON a.doctor_id = d.id
         JOIN specialties s ON d.specialty_id = s.id
         WHERE a.id = ?`,
        [appointment_id]
      );
      if (appts.length > 0) {
        targetProfileId = targetProfileId || appts[0].profile_id;
        targetDoctorId = targetDoctorId || appts[0].doctor_id;
        targetSpecialty = targetSpecialty || appts[0].specialty_name;
      }
    }

    if (!targetProfileId) {
      await conn.rollback();
      return res.status(400).json({
        success: false,
        message: 'Không xác định được hồ sơ bệnh nhân (profile_id).'
      });
    }

    const examDateToUse = exam_date || new Date().toISOString().split('T')[0];

    // Tạo bản ghi trong medical_records
    const [recordResult] = await conn.query(
      `INSERT INTO medical_records
       (profile_id, appointment_id, doctor_id, specialty_name, diagnosis, doctor_notes, prescription,
        blood_pressure, heart_rate, blood_sugar, weight, height, exam_date)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        targetProfileId,
        appointment_id || null,
        targetDoctorId || null,
        targetSpecialty,
        diagnosis.trim(),
        doctor_notes ? doctor_notes.trim() : null,
        prescription ? prescription.trim() : null,
        blood_pressure || null,
        heart_rate || null,
        blood_sugar || null,
        weight || null,
        height || null,
        examDateToUse
      ]
    );

    // Tự động cập nhật phiếu khám sang 'completed' nếu có appointment_id
    if (appointment_id) {
      await conn.query(
        `UPDATE appointments
         SET status = 'completed'
         WHERE id = ?`,
        [appointment_id]
      );
    }

    await conn.commit();

    return res.status(201).json({
      success: true,
      message: 'Đã lưu kết quả khám bệnh & đơn thuốc thành công!',
      data: {
        record_id: recordResult.insertId,
        appointment_id,
        status: 'completed'
      }
    });
  } catch (error) {
    await conn.rollback();
    next(error);
  } finally {
    conn.release();
  }
}

// 5. CRUD CHUYÊN KHOA (SPECIALTIES)
async function getAllSpecialtiesAdmin(req, res, next) {
  try {
    const [specialties] = await pool.query(
      `SELECT s.*, COUNT(d.id) AS doctor_count
       FROM specialties s
       LEFT JOIN doctors d ON s.id = d.specialty_id
       GROUP BY s.id
       ORDER BY s.id ASC`
    );
    return res.status(200).json({ success: true, data: specialties });
  } catch (error) {
    next(error);
  }
}

async function createSpecialty(req, res, next) {
  try {
    const { name, code, icon_url, description, room_location, base_price } = req.body;
    if (!name || name.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Tên chuyên khoa không được để trống.' });
    }

    const autoCode = code || name.toLowerCase().replace(/[^a-z0-9]/g, '_');
    const [result] = await pool.query(
      `INSERT INTO specialties (name, code, icon_url, description, room_location, base_price)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        name.trim(),
        autoCode,
        icon_url || 'medical_services_outlined',
        description || '',
        room_location || 'Tầng 1',
        parseFloat(base_price) || 200000.00
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Thêm chuyên khoa mới thành công!',
      data: { id: result.insertId }
    });
  } catch (error) {
    next(error);
  }
}

async function updateSpecialty(req, res, next) {
  try {
    const { id } = req.params;
    const { name, code, icon_url, description, room_location, base_price } = req.body;

    await pool.query(
      `UPDATE specialties
       SET name = COALESCE(?, name),
           code = COALESCE(?, code),
           icon_url = COALESCE(?, icon_url),
           description = COALESCE(?, description),
           room_location = COALESCE(?, room_location),
           base_price = COALESCE(?, base_price)
       WHERE id = ?`,
      [name, code, icon_url, description, room_location, base_price, id]
    );

    return res.status(200).json({
      success: true,
      message: 'Cập nhật thông tin chuyên khoa thành công!'
    });
  } catch (error) {
    next(error);
  }
}

async function deleteSpecialty(req, res, next) {
  try {
    const { id } = req.params;

    // Kiểm tra xem chuyên khoa có bác sĩ nào không
    const [[{ doctor_count }]] = await pool.query('SELECT COUNT(*) AS doctor_count FROM doctors WHERE specialty_id = ?', [id]);
    if (doctor_count > 0) {
      return res.status(400).json({
        success: false,
        message: `Không thể xóa chuyên khoa này vì đang có ${doctor_count} bác sĩ trực thuộc. Vui lòng chuyển hoặc xóa bác sĩ trước.`
      });
    }

    await pool.query('DELETE FROM specialties WHERE id = ?', [id]);

    return res.status(200).json({
      success: true,
      message: 'Đã xóa chuyên khoa thành công.'
    });
  } catch (error) {
    next(error);
  }
}

// 6. CRUD BÁC SĨ (DOCTORS)
async function getAllDoctorsAdmin(req, res, next) {
  try {
    const [doctors] = await pool.query(
      `SELECT d.*, s.name AS specialty_name, s.room_location, s.base_price,
              COUNT(DISTINCT ds.id) AS schedule_count
       FROM doctors d
       JOIN specialties s ON d.specialty_id = s.id
       LEFT JOIN doctor_schedules ds ON d.id = ds.doctor_id
       GROUP BY d.id
       ORDER BY d.id ASC`
    );
    return res.status(200).json({ success: true, data: doctors });
  } catch (error) {
    next(error);
  }
}

async function createDoctor(req, res, next) {
  try {
    const {
      specialty_id,
      full_name,
      degree,
      avatar_url,
      bio,
      hospital_name,
      room_number,
      experience_years,
      rating
    } = req.body;

    if (!full_name || !specialty_id) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp đầy đủ: full_name và specialty_id.'
      });
    }

    const defaultAvatar = avatar_url || 'https://images.unsplash.com/photo-1622253692010-333f2da6031d';

    const [result] = await pool.query(
      `INSERT INTO doctors
       (specialty_id, full_name, degree, avatar_url, bio, hospital_name, room_number, experience_years, rating)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        specialty_id,
        full_name.trim(),
        degree || 'BS.CKI',
        defaultAvatar,
        bio || 'Bác sĩ chuyên khoa giàu kinh nghiệm.',
        hospital_name || 'Bệnh viện Đa khoa Quốc tế MEDBOOK',
        room_number || 'Phòng Khám 101',
        parseInt(experience_years, 10) || 5,
        parseFloat(rating) || 4.8
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Thêm bác sĩ mới thành công!',
      data: { id: result.insertId }
    });
  } catch (error) {
    next(error);
  }
}

async function updateDoctor(req, res, next) {
  try {
    const { id } = req.params;
    const {
      specialty_id,
      full_name,
      degree,
      avatar_url,
      bio,
      hospital_name,
      room_number,
      experience_years,
      rating
    } = req.body;

    await pool.query(
      `UPDATE doctors
       SET specialty_id = COALESCE(?, specialty_id),
           full_name = COALESCE(?, full_name),
           degree = COALESCE(?, degree),
           avatar_url = COALESCE(?, avatar_url),
           bio = COALESCE(?, bio),
           hospital_name = COALESCE(?, hospital_name),
           room_number = COALESCE(?, room_number),
           experience_years = COALESCE(?, experience_years),
           rating = COALESCE(?, rating)
       WHERE id = ?`,
      [specialty_id, full_name, degree, avatar_url, bio, hospital_name, room_number, experience_years, rating, id]
    );

    return res.status(200).json({
      success: true,
      message: 'Cập nhật thông tin bác sĩ thành công!'
    });
  } catch (error) {
    next(error);
  }
}

async function deleteDoctor(req, res, next) {
  try {
    const { id } = req.params;

    // Kiểm tra phiếu khám đang chờ của bác sĩ
    const [[{ pending_count }]] = await pool.query(
      'SELECT COUNT(*) AS pending_count FROM appointments WHERE doctor_id = ? AND status IN ("pending", "confirmed")',
      [id]
    );

    if (pending_count > 0) {
      return res.status(400).json({
        success: false,
        message: `Không thể xóa bác sĩ này vì đang có ${pending_count} lịch hẹn chờ khám. Vui lòng xử lý hoặc chuyển lịch khám trước.`
      });
    }

    await pool.query('DELETE FROM doctors WHERE id = ?', [id]);

    return res.status(200).json({
      success: true,
      message: 'Đã xóa bác sĩ thành công.'
    });
  } catch (error) {
    next(error);
  }
}

// 7. CẤU HÌNH LỊCH TRỰC VÀ KHUNG GIỜ KHÁM CỦA BÁC SĨ (SCHEDULES)
async function getDoctorSchedulesAdmin(req, res, next) {
  try {
    const { id } = req.params;
    const { date } = req.query;

    let query = 'SELECT * FROM doctor_schedules WHERE doctor_id = ?';
    const params = [id];

    if (date) {
      query += ' AND work_date = ?';
      params.push(date);
    }
    query += ' ORDER BY work_date DESC, time_slot ASC';

    const [schedules] = await pool.query(query, params);
    return res.status(200).json({ success: true, data: schedules });
  } catch (error) {
    next(error);
  }
}

async function createDoctorScheduleAdmin(req, res, next) {
  try {
    const { id } = req.params;
    const { work_date, time_slot, max_patients = 5 } = req.body;

    if (!work_date || !time_slot) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp: work_date (YYYY-MM-DD) và time_slot (VD: 08:30 - 09:00).'
      });
    }

    const [result] = await pool.query(
      `INSERT INTO doctor_schedules (doctor_id, work_date, time_slot, max_patients, booked_count, status)
       VALUES (?, ?, ?, ?, 0, 'available')
       ON DUPLICATE KEY UPDATE max_patients = VALUES(max_patients)`,
      [id, work_date, time_slot, max_patients]
    );

    return res.status(201).json({
      success: true,
      message: 'Cấu hình khung giờ trực thành công!',
      data: { id: result.insertId }
    });
  } catch (error) {
    next(error);
  }
}

async function deleteDoctorScheduleAdmin(req, res, next) {
  try {
    const { schedule_id } = req.params;

    // Kiểm tra có ai đặt slot này chưa
    const [[{ booked_count }]] = await pool.query(
      'SELECT booked_count FROM doctor_schedules WHERE id = ?',
      [schedule_id]
    );

    if (booked_count > 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể xóa khung giờ đã có bệnh nhân đặt khám.'
      });
    }

    await pool.query('DELETE FROM doctor_schedules WHERE id = ?', [schedule_id]);

    return res.status(200).json({
      success: true,
      message: 'Đã xóa khung giờ khám thành công.'
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAdminStats,
  getAllAppointments,
  updateAppointmentStatus,
  createMedicalRecordForAdmin,
  getAllSpecialtiesAdmin,
  createSpecialty,
  updateSpecialty,
  deleteSpecialty,
  getAllDoctorsAdmin,
  createDoctor,
  updateDoctor,
  deleteDoctor,
  getDoctorSchedulesAdmin,
  createDoctorScheduleAdmin,
  deleteDoctorScheduleAdmin
};
