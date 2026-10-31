const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');

// Đăng ký tài khoản mới
async function register(req, res, next) {
  try {
    const { full_name, phone, email, password } = req.body;

    if (!full_name || !phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp đầy đủ: họ tên, số điện thoại và mật khẩu.'
      });
    }

    // Kiểm tra số điện thoại đã tồn tại chưa
    const [existingUsers] = await pool.query(
      'SELECT id FROM users WHERE phone = ? LIMIT 1',
      [phone]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Số điện thoại này đã được đăng ký trong hệ thống.'
      });
    }

    // Băm mật khẩu bằng bcrypt
    const saltRounds = 10;
    const password_hash = await bcrypt.hash(password, saltRounds);

    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      // Tạo user mới
      const [userResult] = await connection.query(
        `INSERT INTO users (full_name, phone, email, password_hash, role)
         VALUES (?, ?, ?, ?, 'patient')`,
        [full_name.trim(), phone.trim(), email ? email.trim() : null, password_hash]
      );

      const newUserId = userResult.insertId;

      // Tự động khởi tạo hồ sơ y tế mặc định "Bản thân" cho người dùng
      await connection.query(
        `INSERT INTO patient_profiles (user_id, full_name, dob, gender, phone, relationship)
         VALUES (?, ?, '1995-01-01', 'Nam', ?, 'Bản thân')`,
        [newUserId, full_name.trim(), phone.trim()]
      );

      await connection.commit();

      // Sinh token JWT
      const token = jwt.sign(
        { id: newUserId, phone, full_name, role: 'patient' },
        process.env.JWT_SECRET || 'medbook_super_secret_jwt_key_2026_@#!',
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      return res.status(201).json({
        success: true,
        message: 'Đăng ký tài khoản thành công.',
        data: {
          token,
          user: {
            id: newUserId,
            full_name,
            phone,
            email,
            role: 'patient',
            avatar_url: null
          }
        }
      });
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  } catch (error) {
    next(error);
  }
}

// Đăng nhập
async function login(req, res, next) {
  try {
    const { phone, email, password } = req.body;
    const loginIdentifier = (phone || email || '').trim();

    if (!loginIdentifier || !password) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp số điện thoại hoặc email và mật khẩu.'
      });
    }

    const [users] = await pool.query(
      'SELECT id, full_name, phone, email, password_hash, role, avatar_url, created_at FROM users WHERE phone = ? OR email = ? LIMIT 1',
      [loginIdentifier, loginIdentifier]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Số điện thoại hoặc mật khẩu không chính xác.'
      });
    }

    const user = users[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Số điện thoại hoặc mật khẩu không chính xác.'
      });
    }

    // Sinh token JWT
    const token = jwt.sign(
      { id: user.id, phone: user.phone, full_name: user.full_name, role: user.role },
      process.env.JWT_SECRET || 'medbook_super_secret_jwt_key_2026_@#!',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    delete user.password_hash;

    return res.status(200).json({
      success: true,
      message: 'Đăng nhập thành công.',
      data: {
        token,
        user
      }
    });
  } catch (error) {
    next(error);
  }
}

// Lấy thông tin user hiện tại
async function getMe(req, res, next) {
  try {
    const userId = req.user.id;
    const [users] = await pool.query(
      'SELECT id, full_name, phone, email, role, avatar_url, created_at FROM users WHERE id = ? LIMIT 1',
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng.'
      });
    }

    return res.status(200).json({
      success: true,
      data: users[0]
    });
  } catch (error) {
    next(error);
  }
}

// Cập nhật thông tin tài khoản
async function updateMe(req, res, next) {
  try {
    const userId = req.user.id;
    const { full_name, email, avatar_url } = req.body;

    await pool.query(
      `UPDATE users
       SET full_name = COALESCE(?, full_name),
           email = COALESCE(?, email),
           avatar_url = COALESCE(?, avatar_url)
       WHERE id = ?`,
      [full_name, email, avatar_url, userId]
    );

    const [updatedUsers] = await pool.query(
      'SELECT id, full_name, phone, email, role, avatar_url, updated_at FROM users WHERE id = ?',
      [userId]
    );

    return res.status(200).json({
      success: true,
      message: 'Cập nhật thông tin thành công.',
      data: updatedUsers[0]
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  register,
  login,
  getMe,
  updateMe
};
