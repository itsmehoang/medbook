const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointment.controller');
const { authenticateToken } = require('../middlewares/auth.middleware');

router.use(authenticateToken); // Tất cả API đặt khám đều yêu cầu xác thực JWT

/**
 * @swagger
 * tags:
 *   name: Appointments
 *   description: Quản lý đặt lịch khám, phiếu khám điện tử, mã QR và hủy lịch
 */

/**
 * @swagger
 * /api/appointments:
 *   post:
 *     summary: Đặt lịch khám bệnh mới (Transaction an toàn, chống trùng và quá tải slot)
 *     tags: [Appointments]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - profile_id
 *               - doctor_id
 *               - schedule_id
 *             properties:
 *               profile_id:
 *                 type: integer
 *                 example: 1
 *               doctor_id:
 *                 type: integer
 *                 example: 1
 *               schedule_id:
 *                 type: integer
 *                 example: 2
 *               exam_type:
 *                 type: string
 *                 enum: [BHYT, Dịch vụ]
 *                 example: Dịch vụ
 *               symptoms:
 *                 type: string
 *                 example: Hay đau thắt ngực khi gắng sức, hồi hộp trống ngực
 *     responses:
 *       201:
 *         description: Đặt lịch thành công, trả về phiếu khám kèm mã booking_code, STT và qr_data
 *       400:
 *         description: Khung giờ đã đầy hoặc đã có lịch trùng
 *       404:
 *         description: Không tìm thấy hồ sơ hoặc bác sĩ
 */
router.post('/', appointmentController.createAppointment);

/**
 * @swagger
 * /api/appointments:
 *   get:
 *     summary: Lấy danh sách phiếu khám của người dùng hiện tại
 *     tags: [Appointments]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *       - name: status
 *         schema:
 *           type: string
 *           enum: [pending, confirmed, completed, cancelled]
 *         description: Lọc theo trạng thái phiếu khám
 *       - in: query
 *       - name: profile_id
 *         schema:
 *           type: integer
 *         description: Lọc theo hồ sơ người khám cụ thể
 *     responses:
 *       200:
 *         description: Danh sách phiếu khám
 */
router.get('/', appointmentController.getAppointments);

/**
 * @swagger
 * /api/appointments/{id}:
 *   get:
 *     summary: Lấy chi tiết một phiếu khám theo ID hoặc theo mã booking_code
 *     tags: [Appointments]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *       - name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID phiếu khám hoặc mã booking_code (VD MB-20261024-001)
 *     responses:
 *       200:
 *         description: Chi tiết phiếu khám và mã QR xuất trình
 *       404:
 *         description: Không tìm thấy phiếu khám
 */
router.get('/:id', appointmentController.getAppointmentById);

/**
 * @swagger
 * /api/appointments/{id}/cancel:
 *   put:
 *     summary: Hủy một lịch hẹn khám bệnh
 *     tags: [Appointments]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *       - name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               reason:
 *                 type: string
 *                 example: Bận công tác đột xuất
 *     responses:
 *       200:
 *         description: Hủy lịch khám thành công
 *       400:
 *         description: Phiếu khám đã hoàn tất hoặc đã hủy trước đó
 */
router.put('/:id/cancel', appointmentController.cancelAppointment);

module.exports = router;

