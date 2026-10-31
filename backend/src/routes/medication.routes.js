const express = require('express');
const router = express.Router();
const medicationController = require('../controllers/medication.controller');
const { authenticateToken } = require('../middlewares/auth.middleware');

router.use(authenticateToken);

/**
 * @swagger
 * tags:
 *   name: Medications
 *   description: Nhắc lịch uống thuốc hằng ngày và theo dõi tuân thủ phác đồ điều trị
 */

/**
 * @swagger
 * /api/medications:
 *   get:
 *     summary: Lấy danh sách lịch nhắc uống thuốc
 *     tags: [Medications]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *       - name: profile_id
 *         schema:
 *           type: integer
 *         description: Lọc theo thành viên gia đình
 *       - in: query
 *       - name: active_only
 *         schema:
 *           type: boolean
 *         description: Chỉ lấy các thuốc đang trong đợt điều trị (start_date <= today <= end_date)
 *     responses:
 *       200:
 *         description: Danh sách cữ thuốc
 */
router.get('/', medicationController.getMedications);

/**
 * @swagger
 * /api/medications:
 *   post:
 *     summary: Tạo mới nhắc lịch uống thuốc
 *     tags: [Medications]
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
 *               - medicine_name
 *               - dosage
 *               - time_of_day
 *               - reminder_time
 *               - start_date
 *               - end_date
 *             properties:
 *               profile_id:
 *                 type: integer
 *                 example: 1
 *               medicine_name:
 *                 type: string
 *                 example: Amlodipine 5mg
 *               dosage:
 *                 type: string
 *                 example: 1 viên sau ăn sáng
 *               time_of_day:
 *                 type: string
 *                 example: Sáng
 *               reminder_time:
 *                 type: string
 *                 example: "07:30:00"
 *               start_date:
 *                 type: string
 *                 format: date
 *                 example: "2026-10-23"
 *               end_date:
 *                 type: string
 *                 format: date
 *                 example: "2026-11-23"
 *               notes:
 *                 type: string
 *                 example: Uống nhiều nước lọc
 *     responses:
 *       201:
 *         description: Thêm nhắc thuốc thành công
 */
router.post('/', medicationController.createMedication);

/**
 * @swagger
 * /api/medications/{id}/toggle:
 *   patch:
 *     summary: Bật/Tắt trạng thái đã uống thuốc hôm nay
 *     tags: [Medications]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *       - name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Cập nhật trạng thái thành công
 */
router.patch('/:id/toggle', medicationController.toggleTakenToday);

/**
 * @swagger
 * /api/medications/{id}:
 *   put:
 *     summary: Cập nhật thông tin nhắc thuốc
 *     tags: [Medications]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *       - name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 */
router.put('/:id', medicationController.updateMedication);

/**
 * @swagger
 * /api/medications/{id}:
 *   delete:
 *     summary: Xóa một lịch nhắc thuốc
 *     tags: [Medications]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *       - name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Xóa thành công
 */
router.delete('/:id', medicationController.deleteMedication);

module.exports = router;

