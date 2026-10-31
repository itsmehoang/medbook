const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'medbook',
  waitForConnections: true,
  connectionLimit: 15,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  dateStrings: true // Giữ nguyên định dạng YYYY-MM-DD và time string cho date/time
});

// Hàm kiểm tra kết nối khi khởi động server
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log(`[Database] Đã kết nối thành công đến MySQL: ${process.env.DB_NAME || 'medbook'} @ ${process.env.DB_HOST || '127.0.0.1'}`);
    connection.release();
    return true;
  } catch (error) {
    console.error(`[Database Error] Không thể kết nối tới MySQL:`, error.message);
    console.error(`[Tip] Hãy đảm bảo bạn đã bật MySQL trên Laragon/XAMPP và import file 'backend/database/medbook.sql'.`);
    return false;
  }
}

module.exports = {
  pool,
  testConnection
};

