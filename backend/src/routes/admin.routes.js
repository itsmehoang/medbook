const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { authenticateToken, authorizeRoles } = require('../middlewares/auth.middleware');

// Mọi route quản trị đều yêu cầu đăng nhập và có role là 'admin' hoặc 'doctor'
router.use(authenticateToken);
router.use(authorizeRoles('admin', 'doctor'));

// 1. Thống kê Dashboard
router.get('/stats', adminController.getAdminStats);

// 2. Quản lý Điều phối Phiếu đặt khám
router.get('/appointments', adminController.getAllAppointments);
router.put('/appointments/:id/status', adminController.updateAppointmentStatus);

// 3. Trả kết quả khám & Kê đơn thuốc (tự động complete phiếu khám)
router.post('/medical-records', adminController.createMedicalRecordForAdmin);

// 4. CRUD Chuyên khoa
router.get('/specialties', adminController.getAllSpecialtiesAdmin);
router.post('/specialties', adminController.createSpecialty);
router.put('/specialties/:id', adminController.updateSpecialty);
router.delete('/specialties/:id', adminController.deleteSpecialty);

// 5. CRUD Bác sĩ
router.get('/doctors', adminController.getAllDoctorsAdmin);
router.post('/doctors', adminController.createDoctor);
router.put('/doctors/:id', adminController.updateDoctor);
router.delete('/doctors/:id', adminController.deleteDoctor);

// 6. Cấu hình lịch trực bác sĩ
router.get('/doctors/:id/schedules', adminController.getDoctorSchedulesAdmin);
router.post('/doctors/:id/schedules', adminController.createDoctorScheduleAdmin);
router.delete('/schedules/:schedule_id', adminController.deleteDoctorScheduleAdmin);

module.exports = router;
