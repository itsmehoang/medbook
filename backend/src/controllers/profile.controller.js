const { pool } = require('../config/db');

// Lấy danh sách hồ sơ bệnh nhân của người dùng hiện tại
async function getProfiles(req, res, next) {
  try {
    const userId = req.user.id;
    const [profiles] = await pool.query(
      `SELECT id, user_id, full_name, dob, gender, cccd, bhyt_code, relationship, phone, address, allergies, created_at, updated_at
       FROM patient_profiles
       WHERE user_id = ?
       ORDER BY (relationship = 'Bản thân') DESC, id ASC`,
      [userId]
    );

    return res.status(200).json({
      success: true,
      data: profiles
    });
  } catch (error) {
    next(error);
  }
}

// Lấy chi tiết một hồ sơ bệnh nhân
async function getProfileById(req, res, next) {
  try {
    const userId = req.user.id;
    const profileId = req.params.id;

    const [profiles] = await pool.query(
      `SELECT id, user_id, full_name, dob, gender, cccd, bhyt_code, relationship, phone, address, allergies, created_at, updated_at
       FROM patient_profiles
       WHERE id = ? AND user_id = ?
       LIMIT 1`,
      [profileId, userId]
    );

    if (profiles.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy hồ sơ người khám bệnh.'
      });
    }

    return res.status(200).json({
      success: true,
      data: profiles[0]
    });
  } catch (error) {
    next(error);
  }
}

// Thêm hồ sơ bệnh nhân mới (Bản thân / Bố / Mẹ / Con / Vợ / Chồng)
async function createProfile(req, res, next) {
  try {
    const userId = req.user.id;
    const { full_name, dob, gender, cccd, bhyt_code, relationship, phone, address, allergies } = req.body;

    if (!full_name || !dob || !gender) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp đầy đủ họ tên, ngày sinh và giới tính.'
      });
    }

    const [result] = await pool.query(
      `INSERT INTO patient_profiles
       (user_id, full_name, dob, gender, cccd, bhyt_code, relationship, phone, address, allergies)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        full_name.trim(),
        dob,
        gender,
        cccd ? cccd.trim() : null,
        bhyt_code ? bhyt_code.trim() : null,
        relationship ? relationship.trim() : 'Bản thân',
        phone ? phone.trim() : null,
        address ? address.trim() : null,
        allergies ? allergies.trim() : null
      ]
    );

    const [newProfile] = await pool.query(
      'SELECT * FROM patient_profiles WHERE id = ?',
      [result.insertId]
    );

    return res.status(201).json({
      success: true,
      message: 'Tạo hồ sơ bệnh nhân thành công.',
      data: newProfile[0]
    });
  } catch (error) {
    next(error);
  }
}

// Cập nhật hồ sơ bệnh nhân
async function updateProfile(req, res, next) {
  try {
    const userId = req.user.id;
    const profileId = req.params.id;
    const { full_name, dob, gender, cccd, bhyt_code, relationship, phone, address, allergies } = req.body;

    // Kiểm tra quyền sở hữu hồ sơ
    const [existing] = await pool.query(
      'SELECT id FROM patient_profiles WHERE id = ? AND user_id = ?',
      [profileId, userId]
    );

    if (existing.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy hồ sơ hoặc bạn không có quyền chỉnh sửa.'
      });
    }

    await pool.query(
      `UPDATE patient_profiles
       SET full_name = COALESCE(?, full_name),
           dob = COALESCE(?, dob),
           gender = COALESCE(?, gender),
           cccd = COALESCE(?, cccd),
           bhyt_code = COALESCE(?, bhyt_code),
           relationship = COALESCE(?, relationship),
           phone = COALESCE(?, phone),
           address = COALESCE(?, address),
           allergies = COALESCE(?, allergies)
       WHERE id = ? AND user_id = ?`,
      [full_name, dob, gender, cccd, bhyt_code, relationship, phone, address, allergies, profileId, userId]
    );

    const [updated] = await pool.query(
      'SELECT * FROM patient_profiles WHERE id = ?',
      [profileId]
    );

    return res.status(200).json({
      success: true,
      message: 'Cập nhật hồ sơ thành công.',
      data: updated[0]
    });
  } catch (error) {
    next(error);
  }
}

// Xóa hồ sơ bệnh nhân
async function deleteProfile(req, res, next) {
  try {
    const userId = req.user.id;
    const profileId = req.params.id;

    // Kiểm tra xem hồ sơ có tồn tại không
    const [profiles] = await pool.query(
      'SELECT id, relationship FROM patient_profiles WHERE id = ? AND user_id = ?',
      [profileId, userId]
    );

    if (profiles.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy hồ sơ bệnh nhân.'
      });
    }

    // Kiểm tra xem hồ sơ này đã có phiếu khám chưa
    const [appointments] = await pool.query(
      'SELECT id FROM appointments WHERE profile_id = ? LIMIT 1',
      [profileId]
    );

    if (appointments.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể xóa hồ sơ đã có lịch sử đặt khám. Bạn có thể chỉnh sửa thông tin thay vì xóa.'
      });
    }

    await pool.query('DELETE FROM patient_profiles WHERE id = ? AND user_id = ?', [profileId, userId]);

    return res.status(200).json({
      success: true,
      message: 'Đã xóa hồ sơ bệnh nhân thành công.'
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getProfiles,
  getProfileById,
  createProfile,
  updateProfile,
  deleteProfile
};

