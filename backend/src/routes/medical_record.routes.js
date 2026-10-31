const express = require('express');
const router = express.Router();
const medicalRecordController = require('../controllers/medical_record.controller');
const { authenticateToken } = require('../middlewares/auth.middleware');

router.use(authenticateToken);

/**
 * @swagger
 * tags:
 *   name: MedicalRecords
 *   description: Quản lý hồ sơ bệnh án, lịch sử khám, đơn thuốc và chỉ số sức khỏe
 */

/**
 * @swagger
 * /api/medical-records:
 *   get:
 *     summary: Lấy danh sách toàn bộ hồ sơ bệnh án của gia đình
 *     tags: [MedicalRecords]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *       - name: profile_id
 *         schema:
 *           type: integer
 *         description: Lọc theo hồ sơ người bệnh cụ thể
 *     responses:
 *       200:
 *         description: Danh sách bệnh án kèm chỉ số sinh tồn
 */
router.get('/', medicalRecordController.getMedicalRecords);

/**
 * @swagger
 * /api/medical-records/{id}:
 *   get:
 *     summary: Lấy chi tiết một hồ sơ bệnh án theo ID
 *     tags: [MedicalRecords]
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
 *         description: Chi tiết hồ sơ bệnh án
 */
router.get('/:id', medicalRecordController.getMedicalRecordById);

/**
 * @swagger
 * /api/medical-records:
 *   post:
 *     summary: Tạo mới hồ sơ bệnh án / lưu chỉ số khám sức khỏe
 *     tags: [MedicalRecords]
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
 *               - specialty_name
 *               - diagnosis
 *               - exam_date
 *             properties:
 *               profile_id:
 *                 type: integer
 *                 example: 1
 *               specialty_name:
 *                 type: string
 *                 example: Tim Mạch
 *               diagnosis:
 *                 type: string
 *                 example: Huyết áp độ 1, rối loạn lipid máu nhẹ
 *               doctor_notes:
 *                 type: string
 *                 example: Giảm ăn mặn, tập thể dục 30 phút mỗi ngày
 *               prescription:
 *                 type: string
 *                 example: "Amlodipine 5mg: 1 viên/ngày sáng"
 *               blood_pressure:
 *                 type: string
 *                 example: 125/80 mmHg
 *               heart_rate:
 *                 type: integer
 *                 example: 76
 *               blood_sugar:
 *                 type: number
 *                 example: 5.6
 *               weight:
 *                 type: number
 *                 example: 65.5
 *               exam_date:
 *                 type: string
 *                 format: date
 *                 example: "2026-10-23"
 *     responses:
 *       201:
 *         description: Lưu bệnh án thành công
 */
router.post('/', medicalRecordController.createMedicalRecord);

/**
 * @swagger
 * /api/medical-records/{id}:
 *   put:
 *     summary: Cập nhật thông tin hồ sơ bệnh án
 *     tags: [MedicalRecords]
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
router.put('/:id', medicalRecordController.updateMedicalRecord);

/**
 * @swagger
 * /api/medical-records/{id}:
 *   delete:
 *     summary: Xóa một hồ sơ bệnh án
 *     tags: [MedicalRecords]
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
router.delete('/:id', medicalRecordController.deleteMedicalRecord);

module.exports = router;
