const { pool } = require('../config/db');

// Lấy danh sách hồ sơ bệnh án (có thể lọc theo profile_id)
async function getMedicalRecords(req, res, next) {
  try {
    const userId = req.user.id;
    const { profile_id } = req.query;

    let query = `
      SELECT mr.*,
             p.full_name AS patient_name, p.dob AS patient_dob, p.gender AS patient_gender, p.relationship,
             d.full_name AS doctor_name, d.degree AS doctor_degree, d.avatar_url AS doctor_avatar
      FROM medical_records mr
      JOIN patient_profiles p ON mr.profile_id = p.id
      LEFT JOIN doctors d ON mr.doctor_id = d.id
      WHERE p.user_id = ?
    `;
    const params = [userId];

    if (profile_id) {
      query += ` AND mr.profile_id = ?`;
      params.push(profile_id);
    }

    query += ` ORDER BY mr.exam_date DESC, mr.id DESC`;

    const [records] = await pool.query(query, params);

    return res.status(200).json({
      success: true,
      count: records.length,
      data: records
    });
  } catch (error) {
    next(error);
  }
}

// Lấy chi tiết một bệnh án theo ID
async function getMedicalRecordById(req, res, next) {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const [records] = await pool.query(
      `SELECT mr.*,
              p.full_name AS patient_name, p.dob AS patient_dob, p.gender AS patient_gender, p.relationship, p.allergies,
              d.full_name AS doctor_name, d.degree AS doctor_degree, d.avatar_url AS doctor_avatar,
              a.booking_code
       FROM medical_records mr
       JOIN patient_profiles p ON mr.profile_id = p.id
       LEFT JOIN doctors d ON mr.doctor_id = d.id
       LEFT JOIN appointments a ON mr.appointment_id = a.id
       WHERE mr.id = ? AND p.user_id = ?
       LIMIT 1`,
      [id, userId]
    );

    if (records.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy hồ sơ bệnh án.'
      });
    }

    return res.status(200).json({
      success: true,
      data: records[0]
    });
  } catch (error) {
    next(error);
  }
}

// Tạo bệnh án / ghi nhận chỉ số sức khỏe mới
async function createMedicalRecord(req, res, next) {
  try {
    const userId = req.user.id;
    const {
      profile_id,
      appointment_id,
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

    if (!profile_id || !specialty_name || !diagnosis || !exam_date) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp đầy đủ: profile_id, specialty_name, diagnosis và exam_date.'
      });
    }

    // Kiểm tra quyền sở hữu profile
    const [profiles] = await pool.query(
      'SELECT id FROM patient_profiles WHERE id = ? AND user_id = ?',
      [profile_id, userId]
    );

    if (profiles.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy hồ sơ người bệnh.'
      });
    }

    const [result] = await pool.query(
      `INSERT INTO medical_records
       (profile_id, appointment_id, doctor_id, specialty_name, diagnosis, doctor_notes, prescription, blood_pressure, heart_rate, blood_sugar, weight, height, exam_date)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        profile_id,
        appointment_id || null,
        doctor_id || null,
        specialty_name.trim(),
        diagnosis.trim(),
        doctor_notes || null,
        prescription || null,
        blood_pressure || null,
        heart_rate || null,
        blood_sugar || null,
        weight || null,
        height || null,
        exam_date
      ]
    );

    const [newRecord] = await pool.query(
      'SELECT * FROM medical_records WHERE id = ?',
      [result.insertId]
    );

    return res.status(201).json({
      success: true,
      message: 'Lưu bệnh án thành công.',
      data: newRecord[0]
    });
  } catch (error) {
    next(error);
  }
}

// Cập nhật bệnh án
async function updateMedicalRecord(req, res, next) {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const {
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

    // Kiểm tra quyền
    const [records] = await pool.query(
      `SELECT mr.id FROM medical_records mr
       JOIN patient_profiles p ON mr.profile_id = p.id
       WHERE mr.id = ? AND p.user_id = ?`,
      [id, userId]
    );

    if (records.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bệnh án hoặc bạn không có quyền cập nhật.'
      });
    }

    await pool.query(
      `UPDATE medical_records
       SET specialty_name = COALESCE(?, specialty_name),
           diagnosis = COALESCE(?, diagnosis),
           doctor_notes = COALESCE(?, doctor_notes),
           prescription = COALESCE(?, prescription),
           blood_pressure = COALESCE(?, blood_pressure),
           heart_rate = COALESCE(?, heart_rate),
           blood_sugar = COALESCE(?, blood_sugar),
           weight = COALESCE(?, weight),
           height = COALESCE(?, height),
           exam_date = COALESCE(?, exam_date)
       WHERE id = ?`,
      [specialty_name, diagnosis, doctor_notes, prescription, blood_pressure, heart_rate, blood_sugar, weight, height, exam_date, id]
    );

    const [updated] = await pool.query('SELECT * FROM medical_records WHERE id = ?', [id]);

    return res.status(200).json({
      success: true,
      message: 'Cập nhật bệnh án thành công.',
      data: updated[0]
    });
  } catch (error) {
    next(error);
  }
}

// Xóa một bản ghi bệnh án
async function deleteMedicalRecord(req, res, next) {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const [records] = await pool.query(
      `SELECT mr.id FROM medical_records mr
       JOIN patient_profiles p ON mr.profile_id = p.id
       WHERE mr.id = ? AND p.user_id = ?`,
      [id, userId]
    );

    if (records.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bệnh án.'
      });
    }

    await pool.query('DELETE FROM medical_records WHERE id = ?', [id]);

    return res.status(200).json({
      success: true,
      message: 'Đã xóa bệnh án thành công.'
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getMedicalRecords,
  getMedicalRecordById,
  createMedicalRecord,
  updateMedicalRecord,
  deleteMedicalRecord
};

