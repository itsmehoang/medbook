require('dotenv').config();
const app = require('./src/app');
const { testConnection } = require('./src/config/db');

const PORT = process.env.PORT || 3000;

async function startServer() {
  console.log('========================================================');
  console.log('       MEDBOOK HEALTHCARE SYSTEM - NODE.JS BACKEND      ');
  console.log('========================================================');

  // Kiểm tra kết nối cơ sở dữ liệu
  await testConnection();

  app.listen(PORT, () => {
    console.log(`[Server] Máy chủ đang chạy tại: http://localhost:${PORT}`);
    console.log(`[Swagger] Tài liệu API tương tác tại: http://localhost:${PORT}/api-docs`);
    console.log(`[Health] Kiểm tra trạng thái tại: http://localhost:${PORT}/health`);
    console.log('========================================================');
  });
}

startServer();

