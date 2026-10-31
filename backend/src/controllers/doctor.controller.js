const { pool } = require('../config/db');

// Lấy danh sách bác sĩ kèm lọc theo chuyên khoa hoặc tìm kiếm
async function getDoctors(req, res, next) {
  try {
    const { specialty_id, search, sort } = req.query;

    let query = `
      SELECT d.*, s.name AS specialty_name, s.code AS specialty_code, s.room_location, s.base_price
      FROM doctors d
      JOIN specialties s ON d.specialty_id = s.id
      WHERE 1=1
    `;
    const params = [];

    if (specialty_id) {
      query += ` AND d.specialty_id = ?`;
      params.push(specialty_id);
    }

    if (search) {
      query += ` AND (d.full_name LIKE ? OR d.bio LIKE ? OR s.name LIKE ?)`;
      const searchPattern = `%${search.trim()}%`;
      params.push(searchPattern, searchPattern, searchPattern);
    }

    if (sort === 'experience') {
      query += ` ORDER BY d.experience_years DESC`;
    } else {
      query += ` ORDER BY d.rating DESC, d.patient_count DESC`;
    }

    const [doctors] = await pool.query(query, params);

    return res.status(200).json({
      success: true,
      count: doctors.length,
      data: doctors
    });
  } catch (error) {
    next(error);
  }
}

// Lấy chi tiết thông tin bác sĩ kèm lịch làm việc
async function getDoctorById(req, res, next) {
  try {
    const { id } = req.params;

    const [doctors] = await pool.query(
      `SELECT d.*, s.name AS specialty_name, s.code AS specialty_code, s.room_location, s.base_price
       FROM doctors d
       JOIN specialties s ON d.specialty_id = s.id
       WHERE d.id = ?
       LIMIT 1`,
      [id]
    );

    if (doctors.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bác sĩ.'
      });
    }

    const doctor = doctors[0];

    // Lấy lịch khám của bác sĩ (từ ngày hôm nay trở đi)
    const now = new Date();
    const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    let [schedules] = await pool.query(
      `SELECT id, work_date, time_slot, max_patients, booked_count, status
       FROM doctor_schedules
       WHERE doctor_id = ? AND work_date >= ?
       ORDER BY work_date ASC, time_slot ASC`,
      [id, today]
    );

    // Nếu chưa có lịch khám từ ngày hôm nay trở đi, tự động tạo lịch mẫu cho 7 ngày tới
    if (schedules.length === 0) {
      const defaultSlots = [
        '08:00 - 08:30',
        '08:30 - 09:00',
        '09:00 - 09:30',
        '09:30 - 10:00',
        '10:00 - 10:30',
        '14:00 - 14:30',
        '14:30 - 15:00',
        '15:00 - 15:30',
        '15:30 - 16:00'
      ];
      for (let dayOffset = 0; dayOffset < 7; dayOffset++) {
        const d = new Date();
        d.setDate(d.getDate() + dayOffset);
        const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

        for (const slot of defaultSlots) {
          try {
            await pool.query(
              `INSERT IGNORE INTO doctor_schedules (doctor_id, work_date, time_slot, max_patients, booked_count, status)
               VALUES (?, ?, ?, 5, 0, 'available')`,
              [id, dateStr, slot]
            );
          } catch (_) {}
        }
      }

      const [reloadedSchedules] = await pool.query(
        `SELECT id, work_date, time_slot, max_patients, booked_count, status
         FROM doctor_schedules
         WHERE doctor_id = ? AND work_date >= ?
         ORDER BY work_date ASC, time_slot ASC`,
        [id, today]
      );
      schedules = reloadedSchedules;
    }

    // Gom nhóm lịch khám theo ngày để Flutter render calendar/date picker dễ dàng
    const schedulesByDate = {};
    schedules.forEach(schedule => {
      if (!schedulesByDate[schedule.work_date]) {
        schedulesByDate[schedule.work_date] = [];
      }
      schedulesByDate[schedule.work_date].push({
        id: schedule.id,
        time_slot: schedule.time_slot,
        max_patients: schedule.max_patients,
        booked_count: schedule.booked_count,
        available_slots: Math.max(0, schedule.max_patients - schedule.booked_count),
        is_available: schedule.status === 'available' && schedule.booked_count < schedule.max_patients
      });
    });

    doctor.schedules = schedulesByDate;

    return res.status(200).json({
      success: true,
      data: doctor
    });
  } catch (error) {
    next(error);
  }
}

// Lấy danh sách khung giờ khám theo ngày cụ thể của một bác sĩ
async function getDoctorSchedulesByDate(req, res, next) {
  try {
    const { id } = req.params;
    const { date } = req.query; // YYYY-MM-DD

    if (!date) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng truyền tham số ngày khám query date (định dạng YYYY-MM-DD).'
      });
    }

    const [schedules] = await pool.query(
      `SELECT id, work_date, time_slot, max_patients, booked_count, status,
              (max_patients - booked_count) AS remaining_slots
       FROM doctor_schedules
       WHERE doctor_id = ? AND work_date = ?
       ORDER BY time_slot ASC`,
      [id, date]
    );

    const formattedSchedules = schedules.map(s => ({
      id: s.id,
      work_date: s.work_date,
      time_slot: s.time_slot,
      max_patients: s.max_patients,
      booked_count: s.booked_count,
      remaining_slots: Math.max(0, s.remaining_slots),
      is_available: s.status === 'available' && s.booked_count < s.max_patients
    }));

    return res.status(200).json({
      success: true,
      data: formattedSchedules
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getDoctors,
  getDoctorById,
  getDoctorSchedulesByDate
};

