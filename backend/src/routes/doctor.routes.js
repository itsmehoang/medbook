const express = require('express');
const router = express.Router();
const doctorController = require('../controllers/doctor.controller');

/**
 * @swagger
 * tags:
 *   name: Doctors
 *   description: Danh sách bác sĩ, tìm kiếm, lọc theo khoa và lịch làm việc
 */

/**
 * @swagger
 * /api/doctors:
 *   get:
 *     summary: Lấy danh sách bác sĩ (hỗ trợ lọc theo chuyên khoa, tìm kiếm)
 *     tags: [Doctors]
 *     parameters:
 *       - in: query
 *       - name: specialty_id
 *         schema:
 *           type: integer
 *         description: Lọc theo ID chuyên khoa
 *       - in: query
 *       - name: search
 *         schema:
 *           type: string
 *         description: Tìm theo tên bác sĩ hoặc chuyên khoa
 *       - in: query
 *       - name: sort
 *         schema:
 *           type: string
 *           enum: [rating, experience]
 *         description: Tiêu chí sắp xếp
 *     responses:
 *       200:
 *         description: Danh sách bác sĩ phù hợp
 */
router.get('/', doctorController.getDoctors);

/**
 * @swagger
 * /api/doctors/{id}:
 *   get:
 *     summary: Lấy chi tiết bác sĩ kèm toàn bộ khung giờ khám
 *     tags: [Doctors]
 *     parameters:
 *       - in: path
 *       - name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Chi tiết bác sĩ và lịch trực
 *       404:
 *         description: Không tìm thấy bác sĩ
 */
router.get('/:id', doctorController.getDoctorById);

/**
 * @swagger
 * /api/doctors/{id}/schedules:
 *   get:
 *     summary: Lấy danh sách khung giờ khám của bác sĩ theo ngày cụ thể
 *     tags: [Doctors]
 *     parameters:
 *       - in: path
 *       - name: id
 *         required: true
 *         schema:
 *           type: integer
 *       - in: query
 *       - name: date
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: Ngày cần tra cứu lịch (VD 2026-10-24)
 *     responses:
 *       200:
 *         description: Danh sách khung giờ và số chỗ còn trống
 */
router.get('/:id/schedules', doctorController.getDoctorSchedulesByDate);

module.exports = router;

