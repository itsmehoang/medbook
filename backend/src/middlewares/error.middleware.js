// Middleware xử lý 404 Route Not Found
function notFoundHandler(req, res, next) {
  res.status(404).json({
    success: false,
    message: `Không tìm thấy tài nguyên: ${req.method} ${req.originalUrl}`
  });
}

// Middleware xử lý lỗi hệ thống toàn cục
function errorHandler(err, req, res, next) {
  console.error('[System Error]', err);

  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    message: err.message || 'Đã xảy ra lỗi nội bộ phía máy chủ.',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
}

module.exports = {
  notFoundHandler,
  errorHandler
};

