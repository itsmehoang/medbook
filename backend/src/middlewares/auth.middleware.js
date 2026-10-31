const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // "Bearer TOKEN"

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Không tìm thấy mã xác thực. Vui lòng đăng nhập.'
    });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'medbook_super_secret_jwt_key_2026_@#!', (err, user) => {
    if (err) {
      return res.status(403).json({
        success: false,
        message: 'Mã token không hợp lệ hoặc đã hết hạn.'
      });
    }

    req.user = user;
    next();
  });
}

function authorizeRoles(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền thực hiện chức năng này.'
      });
    }
    next();
  };
}

module.exports = {
  authenticateToken,
  authorizeRoles
};

