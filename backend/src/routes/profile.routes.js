const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profile.controller');
const { authenticateToken } = require('../middlewares/auth.middleware');

router.use(authenticateToken); // Tất cả API hồ sơ đều yêu cầu xác thực JWT

/**
 * @swagger
 * tags:
 *   name: Profiles
 *   description: Quản lý hồ sơ bệnh nhân (Bản thân và Người thân trong gia đình)
 */

/**
 * @swagger
 * /api/profiles:
 *   get:
 *     summary: Lấy danh sách hồ sơ y tế của tài khoản hiện tại
 *     tags: [Profiles]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sách hồ sơ bệnh nhân
 */
router.get('/', profileController.getProfiles);

/**
 * @swagger
 * /api/profiles/{id}:
 *   get:
 *     summary: Lấy chi tiết một hồ sơ bệnh nhân theo ID
 *     tags: [Profiles]
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
 *         description: Chi tiết hồ sơ
 *       404:
 *         description: Không tìm thấy hồ sơ
 */
router.get('/:id', profileController.getProfileById);

/**
 * @swagger
 * /api/profiles:
 *   post:
 *     summary: Tạo mới một hồ sơ bệnh nhân (Bản thân/Bố/Mẹ/Con...)
 *     tags: [Profiles]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - full_name
 *               - dob
 *               - gender
 *             properties:
 *               full_name:
 *                 type: string
 *                 example: Trần Thị Mai
 *               dob:
 *                 type: string
 *                 format: date
 *                 example: "1968-07-20"
 *               gender:
 *                 type: string
 *                 enum: [Nam, Nữ, Khác]
 *                 example: Nữ
 *               cccd:
 *                 type: string
 *                 example: "001168002233"
 *               bhyt_code:
 *                 type: string
 *                 example: "HT2010987654321"
 *               relationship:
 *                 type: string
 *                 example: Mẹ
 *               phone:
 *                 type: string
 *                 example: "0912345678"
 *               address:
 *                 type: string
 *                 example: 45 Tràng Tiền, Hà Nội
 *               allergies:
 *                 type: string
 *                 example: Không có tiền sử dị ứng
 *     responses:
 *       201:
 *         description: Tạo hồ sơ thành công
 */
router.post('/', profileController.createProfile);

/**
 * @swagger
 * /api/profiles/{id}:
 *   put:
 *     summary: Cập nhật thông tin hồ sơ bệnh nhân
 *     tags: [Profiles]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *       - name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               full_name:
 *                 type: string
 *               dob:
 *                 type: string
 *                 format: date
 *               gender:
 *                 type: string
 *               cccd:
 *                 type: string
 *               bhyt_code:
 *                 type: string
 *               relationship:
 *                 type: string
 *               phone:
 *                 type: string
 *               address:
 *                 type: string
 *               allergies:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 */
router.put('/:id', profileController.updateProfile);

/**
 * @swagger
 * /api/profiles/{id}:
 *   delete:
 *     summary: Xóa một hồ sơ bệnh nhân
 *     tags: [Profiles]
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
 *       400:
 *         description: Không thể xóa vì đã có dữ liệu khám chữa bệnh
 */
router.delete('/:id', profileController.deleteProfile);

module.exports = router;

