const express = require('express');
const router = express.Router();
const specialtyController = require('../controllers/specialty.controller');

/**
 * @swagger
 * tags:
 *   name: Specialties
 *   description: Danh mục chuyên khoa bệnh viện (khớp UI Categories)
 */

/**
 * @swagger
 * /api/specialties:
 *   get:
 *     summary: Lấy danh sách toàn bộ các chuyên khoa
 *     tags: [Specialties]
 *     responses:
 *       200:
 *         description: Danh sách chuyên khoa kèm số lượng bác sĩ
 */
router.get('/', specialtyController.getSpecialties);

/**
 * @swagger
 * /api/specialties/{id}:
 *   get:
 *     summary: Lấy thông tin chi tiết một chuyên khoa kèm danh sách bác sĩ
 *     tags: [Specialties]
 *     parameters:
 *       - in: path
 *       - name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Chi tiết chuyên khoa
 *       404:
 *         description: Không tìm thấy chuyên khoa
 */
router.get('/:id', specialtyController.getSpecialtyById);

module.exports = router;

