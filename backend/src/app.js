const path = require('path');
const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');
const { notFoundHandler, errorHandler } = require('./middlewares/error.middleware');

// Khởi tạo app
const app = express();

// Các cấu hình Middleware cơ bản
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Cấu hình phục vụ giao diện Web Quản trị (Admin Portal)
app.use('/admin', express.static(path.join(__dirname, '../public/admin')));
app.use(express.static(path.join(__dirname, '../public')));
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/admin/index.html'));
});

// Cấu hình Swagger API Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customSiteTitle: 'MEDBOOK API Documentation',
  customCss: '.swagger-ui .topbar { display: block; }'
}));

// Route kiểm tra trạng thái máy chủ (Health Check)
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'online',
    system: 'MEDBOOK Healthcare & Doctor Booking Backend',
    version: '1.0.0',
    documentation: '/api-docs',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', uptime: process.uptime() });
});

// Import và gắn các tuyến API
const authRoutes = require('./routes/auth.routes');
const profileRoutes = require('./routes/profile.routes');
const specialtyRoutes = require('./routes/specialty.routes');
const doctorRoutes = require('./routes/doctor.routes');
const appointmentRoutes = require('./routes/appointment.routes');
const medicalRecordRoutes = require('./routes/medical_record.routes');
const medicationRoutes = require('./routes/medication.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const adminRoutes = require('./routes/admin.routes');

app.use('/api/auth', authRoutes);
app.use('/api/profiles', profileRoutes);
app.use('/api/specialties', specialtyRoutes);
app.use('/api/doctors', doctorRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/medical-records', medicalRecordRoutes);
app.use('/api/medications', medicationRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/admin', adminRoutes);

// Xử lý 404 và Error Handling
app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;

