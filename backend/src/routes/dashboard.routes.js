const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboard.controller');
const { authenticateToken } = require('../middlewares/auth.middleware');

router.use(authenticateToken);

/**
 * @swagger
 * tags:
 *   name: Dashboard
 *   description: Dữ liệu tổng hợp toàn diện cho màn hình chính (Home Screen)
 */

/**
 * @swagger
 * /api/dashboard:
 *   get:
 *     summary: Lấy dữ liệu tổng hợp cho trang chủ (phiếu khám gần nhất, nhắc thuốc hôm nay, chuyên khoa và bác sĩ nổi bật)
 *     tags: [Dashboard]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Trả về đầy đủ khối dữ liệu cho màn hình Home
 */
router.get('/', dashboardController.getDashboardData);

module.exports = router;

