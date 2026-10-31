const { pool } = require('../config/db');

// API tổng hợp dữ liệu toàn diện cho màn hình Home của MedBook
async function getDashboardData(req, res, next) {
  try {
    const userId = req.user.id;
    const today = new Date().toISOString().split('T')[0];

    // 1. Lấy thông tin người dùng
    const [users] = await pool.query(
      'SELECT id, full_name, phone, email, avatar_url FROM users WHERE id = ?',
      [userId]
    );
    const currentUser = users[0] || null;

    // 2. Lấy phiếu khám sắp tới gần nhất (upcoming appointment)
    const [upcomingAppointments] = await pool.query(
      `SELECT a.id, a.booking_code, a.user_id, a.profile_id, a.doctor_id, a.schedule_id,
              a.queue_number, a.qr_data, a.exam_type, a.status, a.symptoms,
              p.full_name AS patient_name, p.relationship,
              d.full_name AS doctor_name, d.degree AS doctor_degree, d.avatar_url AS doctor_avatar, d.hospital_name, d.room_number,
              s.name AS specialty_name, s.room_location, s.base_price,
              ds.work_date, ds.time_slot
       FROM appointments a
       JOIN patient_profiles p ON a.profile_id = p.id
       JOIN doctors d ON a.doctor_id = d.id
       JOIN specialties s ON d.specialty_id = s.id
       JOIN doctor_schedules ds ON a.schedule_id = ds.id
       WHERE a.user_id = ? AND a.status IN ('confirmed', 'pending') AND ds.work_date >= ?
       ORDER BY ds.work_date ASC, ds.time_slot ASC
       LIMIT 1`,
      [userId, today]
    );

    // 3. Lấy danh sách thuốc cần uống hôm nay
    const [todayMedications] = await pool.query(
      `SELECT m.id, m.medicine_name, m.dosage, m.time_of_day, m.reminder_time, m.is_taken_today, m.notes,
              p.full_name AS patient_name
       FROM medication_reminders m
       JOIN patient_profiles p ON m.profile_id = p.id
       WHERE m.user_id = ? AND m.start_date <= ? AND m.end_date >= ?
       ORDER BY m.reminder_time ASC`,
      [userId, today, today]
    );

    const totalMeds = todayMedications.length;
    const takenMeds = todayMedications.filter(m => m.is_taken_today === 1).length;

    // 4. Lấy danh sách chuyên khoa nổi bật (cho Categories bar)
    const [specialties] = await pool.query(`
      SELECT s.*, COUNT(d.id) AS doctor_count
      FROM specialties s
      LEFT JOIN doctors d ON s.id = d.specialty_id
      WHERE s.is_active = 1
      GROUP BY s.id
      ORDER BY s.id ASC
    `);

    // 5. Lấy danh sách bác sĩ hàng đầu (Top Doctors)
    const [topDoctors] = await pool.query(`
      SELECT d.*, s.name AS specialty_name, s.code AS specialty_code, s.room_location, s.base_price
      FROM doctors d
      JOIN specialties s ON d.specialty_id = s.id
      ORDER BY d.rating DESC, d.patient_count DESC
      LIMIT 6
    `);

    return res.status(200).json({
      success: true,
      data: {
        user: currentUser,
        upcoming_appointment: upcomingAppointments.length > 0 ? upcomingAppointments[0] : null,
        medications: {
          total: totalMeds,
          taken: takenMeds,
          pending: totalMeds - takenMeds,
          list: todayMedications
        },
        specialties,
        top_doctors: topDoctors
      }
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getDashboardData
};

