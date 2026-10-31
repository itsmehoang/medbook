const { pool } = require('../config/db');

// Lấy danh sách nhắc lịch uống thuốc
async function getMedications(req, res, next) {
  try {
    const userId = req.user.id;
    const { profile_id, active_only } = req.query;

    let query = `
      SELECT m.*, p.full_name AS patient_name, p.relationship
      FROM medication_reminders m
      JOIN patient_profiles p ON m.profile_id = p.id
      WHERE m.user_id = ?
    `;
    const params = [userId];

    if (profile_id) {
      query += ` AND m.profile_id = ?`;
      params.push(profile_id);
    }

    if (active_only === 'true') {
      const today = new Date().toISOString().split('T')[0];
      query += ` AND m.start_date <= ? AND m.end_date >= ?`;
      params.push(today, today);
    }

    query += ` ORDER BY m.reminder_time ASC, m.id ASC`;

    const [medications] = await pool.query(query, params);

    return res.status(200).json({
      success: true,
      count: medications.length,
      data: medications
    });
  } catch (error) {
    next(error);
  }
}

// Thêm lịch nhắc uống thuốc mới
async function createMedication(req, res, next) {
  try {
    const userId = req.user.id;
    const { profile_id, medicine_name, dosage, time_of_day, reminder_time, start_date, end_date, notes } = req.body;

    if (!profile_id || !medicine_name || !dosage || !time_of_day || !reminder_time || !start_date || !end_date) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng điền đầy đủ các thông tin: profile_id, tên thuốc, liều lượng, buổi uống, giờ nhắc và thời gian điều trị.'
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
      `INSERT INTO medication_reminders
       (user_id, profile_id, medicine_name, dosage, time_of_day, reminder_time, is_taken_today, start_date, end_date, notes)
       VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?)`,
      [userId, profile_id, medicine_name.trim(), dosage.trim(), time_of_day.trim(), reminder_time, start_date, end_date, notes || null]
    );

    const [newMed] = await pool.query('SELECT * FROM medication_reminders WHERE id = ?', [result.insertId]);

    return res.status(201).json({
      success: true,
      message: 'Thêm nhắc lịch uống thuốc thành công.',
      data: newMed[0]
    });
  } catch (error) {
    next(error);
  }
}

// Chuyển đổi trạng thái đã uống / chưa uống hôm nay (Toggle status)
async function toggleTakenToday(req, res, next) {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const [medications] = await pool.query(
      'SELECT id, is_taken_today, medicine_name FROM medication_reminders WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (medications.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy lịch nhắc thuốc.'
      });
    }

    const currentStatus = medications[0].is_taken_today;
    const newStatus = currentStatus === 1 ? 0 : 1;

    await pool.query(
      'UPDATE medication_reminders SET is_taken_today = ? WHERE id = ?',
      [newStatus, id]
    );

    return res.status(200).json({
      success: true,
      message: newStatus === 1 ? `Đã uống thuốc "${medications[0].medicine_name}" hôm nay.` : `Đã chuyển về chưa uống thuốc "${medications[0].medicine_name}".`,
      data: {
        id: Number(id),
        is_taken_today: newStatus
      }
    });
  } catch (error) {
    next(error);
  }
}

// Cập nhật thông tin nhắc thuốc
async function updateMedication(req, res, next) {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { medicine_name, dosage, time_of_day, reminder_time, start_date, end_date, notes } = req.body;

    const [medications] = await pool.query(
      'SELECT id FROM medication_reminders WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (medications.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy lịch nhắc thuốc.'
      });
    }

    await pool.query(
      `UPDATE medication_reminders
       SET medicine_name = COALESCE(?, medicine_name),
           dosage = COALESCE(?, dosage),
           time_of_day = COALESCE(?, time_of_day),
           reminder_time = COALESCE(?, reminder_time),
           start_date = COALESCE(?, start_date),
           end_date = COALESCE(?, end_date),
           notes = COALESCE(?, notes)
       WHERE id = ? AND user_id = ?`,
      [medicine_name, dosage, time_of_day, reminder_time, start_date, end_date, notes, id, userId]
    );

    const [updated] = await pool.query('SELECT * FROM medication_reminders WHERE id = ?', [id]);

    return res.status(200).json({
      success: true,
      message: 'Cập nhật lịch nhắc thuốc thành công.',
      data: updated[0]
    });
  } catch (error) {
    next(error);
  }
}

// Xóa lịch nhắc thuốc
async function deleteMedication(req, res, next) {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const [medications] = await pool.query(
      'SELECT id FROM medication_reminders WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (medications.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy lịch nhắc thuốc.'
      });
    }

    await pool.query('DELETE FROM medication_reminders WHERE id = ? AND user_id = ?', [id, userId]);

    return res.status(200).json({
      success: true,
      message: 'Đã xóa lịch nhắc thuốc thành công.'
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getMedications,
  createMedication,
  toggleTakenToday,
  updateMedication,
  deleteMedication
};

