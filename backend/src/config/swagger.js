const swaggerJSDoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'MEDBOOK Healthcare & Doctor Booking API',
      version: '1.0.0',
      description: `
Tài liệu RESTful API cho ứng dụng **MEDBOOK** (Đặt lịch khám bệnh, Quản lý hồ sơ sức khỏe & Theo dõi điều trị).
Hỗ trợ đầy đủ xác thực JWT Bearer, Transaction an toàn cho đặt lịch, tra cứu chuyên khoa, bác sĩ và lịch nhắc uống thuốc.
      `,
      contact: {
        name: 'MEDBOOK Developer Support',
        email: 'support@medbook.vn'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Máy chủ phát triển nội bộ (Local Development Server)'
      }
    ],
    components: {
      securitySchemes: {
        BearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Nhập mã token JWT theo định dạng: Bearer <token>'
        }
      }
    }
  },
  apis: ['./src/routes/*.js']
};

const swaggerSpec = swaggerJSDoc(options);

module.exports = swaggerSpec;

