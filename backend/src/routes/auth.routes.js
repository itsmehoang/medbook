const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticateToken } = require('../middlewares/auth.middleware');

/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: Quản lý xác thực và tài khoản người dùng
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Đăng ký tài khoản người dùng mới
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - full_name
 *               - phone
 *               - password
 *             properties:
 *               full_name:
 *                 type: string
 *                 example: Nguyễn Văn An
 *               phone:
 *                 type: string
 *                 example: "0987654321"
 *               email:
 *                 type: string
 *                 example: nguyenvanan@medbook.vn
 *               password:
 *                 type: string
 *                 example: "123456"
 *     responses:
 *       201:
 *         description: Đăng ký thành công, trả về token và thông tin user
 *       400:
 *         description: Thiếu thông tin bắt buộc
 *       409:
 *         description: Số điện thoại đã được đăng ký
 */
router.post('/register', authController.register);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Đăng nhập vào hệ thống
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phone
 *               - password
 *             properties:
 *               phone:
 *                 type: string
 *                 example: "0987654321"
 *               password:
 *                 type: string
 *                 example: "123456"
 *     responses:
 *       200:
 *         description: Đăng nhập thành công, trả về JWT token
 *       401:
 *         description: Sai số điện thoại hoặc mật khẩu
 */
router.post('/login', authController.login);

/**
 * @swagger
 * /api/auth/me:
 *   get:
 *     summary: Lấy thông tin tài khoản hiện tại
 *     tags: [Auth]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Trả về thông tin người dùng đang đăng nhập
 *       401:
 *         description: Chưa xác thực hoặc token hết hạn
 */
router.get('/me', authenticateToken, authController.getMe);

/**
 * @swagger
 * /api/auth/me:
 *   put:
 *     summary: Cập nhật thông tin tài khoản hiện tại
 *     tags: [Auth]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               full_name:
 *                 type: string
 *                 example: Nguyễn Văn An
 *               email:
 *                 type: string
 *                 example: nguyenvanan@medbook.vn
 *               avatar_url:
 *                 type: string
 *                 example: https://images.unsplash.com/photo-1535713875002-d1d0cf377fde
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 */
router.put('/me', authenticateToken, authController.updateMe);

module.exports = router;

