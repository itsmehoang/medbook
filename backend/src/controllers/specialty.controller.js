const { pool } = require('../config/db');

// Lấy toàn bộ danh sách chuyên khoa
async function getSpecialties(req, res, next) {
  try {
    const [specialties] = await pool.query(`
      SELECT s.*, COUNT(d.id) AS doctor_count
      FROM specialties s
      LEFT JOIN doctors d ON s.id = d.specialty_id
      WHERE s.is_active = 1
      GROUP BY s.id
      ORDER BY s.id ASC
    `);

    return res.status(200).json({
      success: true,
      data: specialties
    });
  } catch (error) {
    next(error);
  }
}

// Lấy chi tiết chuyên khoa kèm danh sách bác sĩ
async function getSpecialtyById(req, res, next) {
  try {
    const { id } = req.params;

    const [specialties] = await pool.query(
      'SELECT * FROM specialties WHERE id = ? AND is_active = 1',
      [id]
    );

    if (specialties.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy chuyên khoa.'
      });
    }

    const specialty = specialties[0];

    // Lấy danh sách bác sĩ thuộc chuyên khoa này
    const [doctors] = await pool.query(
      `SELECT id, full_name, degree, avatar_url, bio, rating, review_count, patient_count, experience_years, hospital_name, room_number
       FROM doctors
       WHERE specialty_id = ?
       ORDER BY rating DESC, experience_years DESC`,
      [id]
    );

    specialty.doctors = doctors;

    return res.status(200).json({
      success: true,
      data: specialty
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getSpecialties,
  getSpecialtyById
};

