-- ====================================================================
-- CƠ SỞ DỮ LIỆU: MEDBOOK - HỆ THỐNG ĐẶT LỊCH KHÁM & QUẢN LÝ SỨC KHỎE
-- Môi trường tương thích: MySQL 5.7+ / 8.0+ / MariaDB (Laragon, HeidiSQL)
-- ====================================================================

CREATE DATABASE IF NOT EXISTS `medbook` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `medbook`;

-- Tắt kiểm tra khóa ngoại tạm thời để khởi tạo lại bảng sạch sẽ
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `medication_reminders`;
DROP TABLE IF EXISTS `medical_records`;
DROP TABLE IF EXISTS `appointments`;
DROP TABLE IF EXISTS `doctor_schedules`;
DROP TABLE IF EXISTS `doctors`;
DROP TABLE IF EXISTS `specialties`;
DROP TABLE IF EXISTS `patient_profiles`;
DROP TABLE IF EXISTS `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- --------------------------------------------------------------------
-- 1. BẢNG USERS: Tài khoản người dùng (Bệnh nhân, Bác sĩ, Quản trị viên)
-- --------------------------------------------------------------------
CREATE TABLE `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `full_name` VARCHAR(150) NOT NULL,
  `phone` VARCHAR(20) NOT NULL UNIQUE,
  `email` VARCHAR(150) NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `role` ENUM('patient', 'doctor', 'admin') NOT NULL DEFAULT 'patient',
  `avatar_url` VARCHAR(500) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_users_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 2. BẢNG PATIENT_PROFILES: Hồ sơ người khám bệnh (Bản thân & Người thân)
-- --------------------------------------------------------------------
CREATE TABLE `patient_profiles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `full_name` VARCHAR(150) NOT NULL,
  `dob` DATE NOT NULL,
  `gender` ENUM('Nam', 'Nữ', 'Khác') NOT NULL,
  `cccd` VARCHAR(20) NULL,
  `bhyt_code` VARCHAR(30) NULL,
  `relationship` VARCHAR(50) NOT NULL DEFAULT 'Bản thân', -- 'Bản thân', 'Bố', 'Mẹ', 'Con', 'Vợ', 'Chồng', 'Khác'
  `phone` VARCHAR(20) NULL,
  `address` VARCHAR(255) NULL,
  `allergies` TEXT NULL, -- Tiền sử dị ứng thuốc/thức ăn
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_profiles_user_id` (`user_id`),
  CONSTRAINT `fk_profiles_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 3. BẢNG SPECIALTIES: Chuyên khoa bệnh viện (khớp danh mục Category Flutter)
-- --------------------------------------------------------------------
CREATE TABLE `specialties` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `name` VARCHAR(100) NOT NULL,
  `icon_url` VARCHAR(255) NULL,
  `description` TEXT NULL,
  `room_location` VARCHAR(100) NOT NULL DEFAULT 'Tầng 2 - Tòa A',
  `base_price` DECIMAL(12, 2) NOT NULL DEFAULT 200000.00,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 4. BẢNG DOCTORS: Thông tin bác sĩ chuyên khoa
-- --------------------------------------------------------------------
CREATE TABLE `doctors` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NULL UNIQUE,
  `specialty_id` INT NOT NULL,
  `full_name` VARCHAR(150) NOT NULL,
  `degree` VARCHAR(50) NOT NULL DEFAULT 'BS.CKI', -- BS.CKI, BS.CKII, ThS.BS, TS.BS, PGS.TS
  `avatar_url` VARCHAR(500) NULL,
  `bio` TEXT NULL,
  `rating` DECIMAL(2, 1) NOT NULL DEFAULT 5.0,
  `review_count` INT NOT NULL DEFAULT 0,
  `patient_count` INT NOT NULL DEFAULT 0,
  `experience_years` INT NOT NULL DEFAULT 5,
  `hospital_name` VARCHAR(150) NOT NULL DEFAULT 'Bệnh viện Đa khoa Quốc tế MEDBOOK',
  `room_number` VARCHAR(50) NOT NULL DEFAULT 'Phòng 204',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_doctors_specialty` (`specialty_id`),
  CONSTRAINT `fk_doctors_specialties` FOREIGN KEY (`specialty_id`) REFERENCES `specialties` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_doctors_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 5. BẢNG DOCTOR_SCHEDULES: Lịch trực & Khung giờ khám theo ngày
-- --------------------------------------------------------------------
CREATE TABLE `doctor_schedules` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `doctor_id` INT NOT NULL,
  `work_date` DATE NOT NULL,
  `time_slot` VARCHAR(50) NOT NULL, -- VD: "08:00 - 08:30"
  `max_patients` INT NOT NULL DEFAULT 5,
  `booked_count` INT NOT NULL DEFAULT 0,
  `status` ENUM('available', 'full', 'cancelled') NOT NULL DEFAULT 'available',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_doctor_slot` (`doctor_id`, `work_date`, `time_slot`),
  INDEX `idx_schedules_doctor_date` (`doctor_id`, `work_date`),
  CONSTRAINT `fk_schedules_doctors` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 6. BẢNG APPOINTMENTS: Phiếu đặt lịch khám bệnh
-- --------------------------------------------------------------------
CREATE TABLE `appointments` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `booking_code` VARCHAR(50) NOT NULL UNIQUE, -- VD: MB-20261023-001
  `user_id` INT NOT NULL,
  `profile_id` INT NOT NULL,
  `doctor_id` INT NOT NULL,
  `schedule_id` INT NOT NULL,
  `queue_number` INT NOT NULL, -- Số thứ tự khám (STT: 1, 2, 3...)
  `qr_data` TEXT NOT NULL,     -- Dữ liệu mã QR xuất trình tại quầy tiếp đón
  `exam_type` ENUM('BHYT', 'Dịch vụ') NOT NULL DEFAULT 'Dịch vụ',
  `symptoms` TEXT NULL,        -- Triệu chứng bệnh nhân mô tả
  `status` ENUM('pending', 'confirmed', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
  `cancelled_reason` VARCHAR(255) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_appointments_user` (`user_id`),
  INDEX `idx_appointments_status` (`status`),
  INDEX `idx_appointments_code` (`booking_code`),
  CONSTRAINT `fk_appointments_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_appointments_profiles` FOREIGN KEY (`profile_id`) REFERENCES `patient_profiles` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_appointments_doctors` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_appointments_schedules` FOREIGN KEY (`schedule_id`) REFERENCES `doctor_schedules` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 7. BẢNG MEDICAL_RECORDS: Hồ sơ bệnh án & Chỉ số sinh tồn sau khám
-- --------------------------------------------------------------------
CREATE TABLE `medical_records` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `profile_id` INT NOT NULL,
  `appointment_id` INT NULL,
  `doctor_id` INT NULL,
  `specialty_name` VARCHAR(100) NOT NULL,
  `diagnosis` TEXT NOT NULL,       -- Chẩn đoán xác định
  `doctor_notes` TEXT NULL,        -- Lời dặn dò, hẹn tái khám
  `prescription` TEXT NULL,        -- Danh mục thuốc kê đơn (dạng chuỗi hoặc JSON)
  `blood_pressure` VARCHAR(20) NULL, -- Chỉ số huyết áp: VD "120/80 mmHg"
  `heart_rate` INT NULL,             -- Nhịp tim: VD 76 bpm
  `blood_sugar` DECIMAL(5, 2) NULL,  -- Đường huyết: VD 5.8 mmol/L
  `weight` DECIMAL(5, 2) NULL,       -- Cân nặng: VD 64.5 kg
  `height` DECIMAL(5, 2) NULL,       -- Chiều cao: VD 170 cm
  `exam_date` DATE NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_records_profile` (`profile_id`),
  CONSTRAINT `fk_records_profiles` FOREIGN KEY (`profile_id`) REFERENCES `patient_profiles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_records_appointments` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_records_doctors` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 8. BẢNG MEDICATION_REMINDERS: Lịch nhắc uống thuốc hằng ngày
-- --------------------------------------------------------------------
CREATE TABLE `medication_reminders` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `profile_id` INT NOT NULL,
  `medicine_name` VARCHAR(150) NOT NULL,
  `dosage` VARCHAR(100) NOT NULL,     -- Liều lượng: VD "1 viên sau ăn no"
  `time_of_day` VARCHAR(50) NOT NULL, -- "Sáng", "Trưa", "Chiều", "Tối"
  `reminder_time` TIME NOT NULL,      -- VD "07:30:00"
  `is_taken_today` TINYINT(1) NOT NULL DEFAULT 0,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `notes` VARCHAR(255) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_reminders_user_date` (`user_id`, `is_taken_today`),
  CONSTRAINT `fk_reminders_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reminders_profiles` FOREIGN KEY (`profile_id`) REFERENCES `patient_profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ====================================================================
-- DỮ LIỆU MẪU (SAMPLE SEED DATA) - TIẾNG VIỆT PHONG PHÚ
-- Mật khẩu mặc định của mọi tài khoản mẫu: 123456
-- Hash bcrypt chuẩn: $2b$10$gon/PClV1EL7MYbK659V6.eaLOYnE1VkkJoWtwtij.BxR9B4VSdVS
-- ====================================================================

-- 1. USERS
INSERT INTO `users` (`id`, `full_name`, `phone`, `email`, `password_hash`, `role`, `avatar_url`) VALUES
(1, 'Nguyễn Văn An', '0987654321', 'nguyenvanan@medbook.vn', '$2b$10$gon/PClV1EL7MYbK659V6.eaLOYnE1VkkJoWtwtij.BxR9B4VSdVS', 'patient', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde'),
(2, 'Trần Thị Mai', '0912345678', 'tranmai@medbook.vn', '$2b$10$gon/PClV1EL7MYbK659V6.eaLOYnE1VkkJoWtwtij.BxR9B4VSdVS', 'patient', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330'),
(3, 'Quản Trị Viên', '0900000000', 'admin@medbook.vn', '$2b$10$gon/PClV1EL7MYbK659V6.eaLOYnE1VkkJoWtwtij.BxR9B4VSdVS', 'admin', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e');

-- 2. PATIENT_PROFILES (Hồ sơ của user 1)
INSERT INTO `patient_profiles` (`id`, `user_id`, `full_name`, `dob`, `gender`, `cccd`, `bhyt_code`, `relationship`, `phone`, `address`, `allergies`) VALUES
(1, 1, 'Nguyễn Văn An', '1992-05-18', 'Nam', '001092008899', 'DN4010123456789', 'Bản thân', '0987654321', 'Số 45 Tràng Tiền, Hoàn Kiếm, Hà Nội', 'Dị ứng thuốc kháng sinh Penicillin'),
(2, 1, 'Nguyễn Thị Hoa', '1965-10-12', 'Nữ', '001165003322', 'HT2010987654321', 'Mẹ', '0983112233', 'Số 45 Tràng Tiền, Hoàn Kiếm, Hà Nội', 'Tiền sử tăng huyết áp nhẹ, không dị ứng thuốc'),
(3, 1, 'Nguyễn Minh Quân', '2019-08-20', 'Nam', '001219001144', 'TE1010556677889', 'Con', '0987654321', 'Số 45 Tràng Tiền, Hoàn Kiếm, Hà Nội', 'Dị ứng phấn hoa và hải sản cua ghẹ');

-- 3. SPECIALTIES (6 chuyên khoa khớp hoàn toàn icon/UI Flutter)
INSERT INTO `specialties` (`id`, `code`, `name`, `icon_url`, `description`, `room_location`, `base_price`) VALUES
(1, 'cardiology', 'Tim Mạch', 'favorite_border_outlined', 'Khám, siêu âm tim, tầm soát tăng huyết áp, rối loạn nhịp tim và bệnh mạch vành.', 'Tầng 2 - Tòa A (Khu A201)', 300000.00),
(2, 'dermatology', 'Da Liễu', 'health_and_safety_outlined', 'Chăm sóc và điều trị chuyên sâu mụn trứng cá, viêm da cơ địa, nám da và trẻ hóa da.', 'Tầng 3 - Tòa B (Khu B305)', 250000.00),
(3, 'pediatrics', 'Nhi Khoa', 'medical_services_outlined', 'Khám tổng quát sơ sinh, dinh dưỡng, tiêm chủng và bệnh đường hô hấp trẻ em.', 'Tầng 1 - Tòa C (Khu C102)', 200000.00),
(4, 'dentist', 'Nha Khoa', 'person_2_outlined', 'Khám và thẩm mỹ răng miệng, tẩy trắng, niềng răng, nhổ răng khôn không đau.', 'Tầng 4 - Tòa A (Khu A402)', 220000.00),
(5, 'emergencyMedicine', 'Cấp Cứu & Hồi Sức', 'local_pharmacy_outlined', 'Tiếp nhận xử trí khẩn cấp 24/7 các ca đột quỵ, chấn thương, ngộ độc và suy hô hấp.', 'Tầng 1 - Tòa Nhà Trung Tâm (Sảnh E1)', 350000.00),
(6, 'familyMedicine', 'Bác Sĩ Gia Đình', 'medical_information_outlined', 'Quản lý sức khỏe định kỳ toàn diện, chăm sóc bệnh mãn tính và tư vấn y tế từ xa.', 'Tầng 2 - Tòa B (Khu B208)', 200000.00);

-- 4. DOCTORS (10 bác sĩ giỏi, học vị cao, kinh nghiệm phong phú)
INSERT INTO `doctors` (`id`, `user_id`, `specialty_id`, `full_name`, `degree`, `avatar_url`, `bio`, `rating`, `review_count`, `patient_count`, `experience_years`, `hospital_name`, `room_number`) VALUES
(1, NULL, 1, 'PGS.TS Trần Nam Phong', 'PGS.TS', '/images/doctors/doc_1.jpg', 'Chuyên gia tim mạch hàng đầu với hơn 22 năm cống hiến tại Viện Tim Mạch Quốc Gia. Từng tu nghiệp chuyên sâu tại Pháp và Nhật Bản về can thiệp tim mạch.', 4.9, 320, 4800, 22, 'Bệnh viện Đa khoa Quốc tế MEDBOOK', 'Phòng Khám Tim Mạch 201'),
(2, NULL, 1, 'ThS.BS Nguyễn Thu Hà', 'ThS.BS', '/images/doctors/doc_2.jpg', 'Chuyên môn sâu về suy tim, rối loạn nhịp tim và theo dõi tim mạch thai kỳ. Phong cách tận tâm, chu đáo và nhẹ nhàng với bệnh nhân.', 4.8, 185, 2300, 11, 'Bệnh viện Đa khoa Quốc tế MEDBOOK', 'Phòng Khám Tim Mạch 202'),
(3, NULL, 2, 'TS.BS Lê Thanh Tùng', 'TS.BS', '/images/doctors/doc_3.jpg', 'Tốt nghiệp Tiến sĩ Da liễu Đại học Y Hà Nội. Chuyên gia điều trị các bệnh tự miễn ngoài da, trứng cá nặng và ứng dụng Laser thẩm mỹ.', 4.7, 210, 3100, 15, 'Bệnh viện Đa khoa Quốc tế MEDBOOK', 'Phòng Da Liễu B301'),
(4, NULL, 2, 'BS.CKI Phạm Quỳnh Chi', 'BS.CKI', '/images/doctors/doc_4.jpg', 'Bác sĩ chuyên khoa Da liễu giàu kinh nghiệm trong chăm sóc phục hồi da tổn thương sau kem trộn, nám sạm và viêm da tiếp xúc dị ứng.', 4.9, 140, 1900, 8, 'Bệnh viện Đa khoa Quốc tế MEDBOOK', 'Phòng Da Liễu B302'),
(5, NULL, 3, 'BS.CKII Hoàng Đức Thắng', 'BS.CKII', '/images/doctors/doc_5.jpg', 'Nguyên Phó Trưởng khoa Nhi BV Bạch Mai. Chuyên gia hàng đầu về hen phế quản trẻ em, viêm tiểu phế quản và các bệnh lý nhiễm khuẩn sơ sinh.', 4.9, 410, 6200, 20, 'Bệnh viện Đa khoa Quốc tế MEDBOOK', 'Phòng Khám Nhi C101'),
(6, NULL, 3, 'ThS.BS Đặng Lan Anh', 'ThS.BS', '/images/doctors/doc_6.jpg', 'Thạc sĩ Nhi khoa Đại học Y Dược TP.HCM. Rất kiên nhẫn, gần gũi với trẻ nhỏ, chuyên tư vấn chế độ dinh dưỡng và theo dõi tăng trưởng trẻ biếng ăn.', 4.8, 290, 3400, 9, 'Bệnh viện Đa khoa Quốc tế MEDBOOK', 'Phòng Khám Nhi C102'),
(7, NULL, 4, 'BS.CKI Vũ Quốc Đạt', 'BS.CKI', '/images/doctors/doc_7.jpg', 'Bác sĩ Răng Hàm Mặt chuyên sâu về cấy ghép Implant kỹ thuật số, nhổ răng khôn không sang chấn bằng công nghệ sóng siêu âm Piezotome.', 4.8, 175, 2100, 10, 'Bệnh viện Đa khoa Quốc tế MEDBOOK', 'Phòng Nha Khoa A401'),
(8, NULL, 4, 'ThS.BS Bùi Hương Giang', 'ThS.BS', '/images/doctors/doc_8.jpg', 'Thành viên Hiệp hội Nắn chỉnh răng Việt Nam. Chuyên gia chỉnh nha thẩm mỹ trong suốt Invisalign và niềng răng mắc cài thông minh.', 4.9, 160, 1800, 12, 'Bệnh viện Đa khoa Quốc tế MEDBOOK', 'Phòng Nha Khoa A402'),
(9, NULL, 5, 'BS.CKII Ngô Trọng Nhân', 'BS.CKII', '/images/doctors/doc_9.jpg', 'Chuyên gia Hồi sức Cấp cứu với hơn 18 năm phản ứng nhanh tại tuyến đầu, giàu kinh nghiệm cấp cứu ngừng tuần hoàn và đa chấn thương.', 4.7, 130, 2900, 18, 'Bệnh viện Đa khoa Quốc tế MEDBOOK', 'Khu Cấp Cứu E1'),
(10, NULL, 6, 'TS.BS Mai Diệu Linh', 'TS.BS', '/images/doctors/doc_10.jpg', 'Bác sĩ Gia đình uy tín, nguyên giảng viên trường Đại học Y Hà Nội. Chuyên gia tư vấn phòng bệnh toàn diện và theo dõi bệnh nhân tiểu đường, mỡ máu.', 4.8, 245, 3700, 14, 'Bệnh viện Đa khoa Quốc tế MEDBOOK', 'Phòng Khám Gia Đình B208');

-- 5. DOCTOR_SCHEDULES: Khung giờ khám linh hoạt trong các ngày tới
-- Tạo lịch khám cho Bác sĩ 1 (Tim Mạch - PGS.TS Trần Nam Phong)
INSERT INTO `doctor_schedules` (`id`, `doctor_id`, `work_date`, `time_slot`, `max_patients`, `booked_count`, `status`) VALUES
(1, 1, '2026-10-24', '08:00 - 08:30', 4, 1, 'available'),
(2, 1, '2026-10-24', '08:30 - 09:00', 4, 0, 'available'),
(3, 1, '2026-10-24', '09:00 - 09:30', 4, 4, 'full'),
(4, 1, '2026-10-24', '09:30 - 10:00', 4, 2, 'available'),
(5, 1, '2026-10-24', '14:00 - 14:30', 4, 0, 'available'),
(6, 1, '2026-10-24', '14:30 - 15:00', 4, 0, 'available'),
(7, 1, '2026-10-25', '08:30 - 09:00', 4, 0, 'available'),
(8, 1, '2026-10-25', '09:00 - 09:30', 4, 1, 'available');

-- Lịch cho Bác sĩ 3 (Da Liễu - TS.BS Lê Thanh Tùng)
INSERT INTO `doctor_schedules` (`id`, `doctor_id`, `work_date`, `time_slot`, `max_patients`, `booked_count`, `status`) VALUES
(9, 3, '2026-10-24', '08:00 - 08:30', 5, 0, 'available'),
(10, 3, '2026-10-24', '08:30 - 09:00', 5, 2, 'available'),
(11, 3, '2026-10-24', '09:30 - 10:00', 5, 1, 'available'),
(12, 3, '2026-10-25', '14:00 - 14:30', 5, 0, 'available');

-- Lịch cho Bác sĩ 5 (Nhi Khoa - BS.CKII Hoàng Đức Thắng)
INSERT INTO `doctor_schedules` (`id`, `doctor_id`, `work_date`, `time_slot`, `max_patients`, `booked_count`, `status`) VALUES
(13, 5, '2026-10-24', '08:30 - 09:00', 5, 1, 'available'),
(14, 5, '2026-10-24', '09:00 - 09:30', 5, 0, 'available'),
(15, 5, '2026-10-25', '08:30 - 09:00', 5, 0, 'available');

-- Lịch cho Bác sĩ 7 (Nha Khoa - BS.CKI Vũ Quốc Đạt)
INSERT INTO `doctor_schedules` (`id`, `doctor_id`, `work_date`, `time_slot`, `max_patients`, `booked_count`, `status`) VALUES
(16, 7, '2026-10-24', '10:00 - 10:30', 3, 0, 'available'),
(17, 7, '2026-10-24', '10:30 - 11:00', 3, 1, 'available');

-- Lịch cho Bác sĩ 10 (Gia Đình - TS.BS Mai Diệu Linh)
INSERT INTO `doctor_schedules` (`id`, `doctor_id`, `work_date`, `time_slot`, `max_patients`, `booked_count`, `status`) VALUES
(18, 10, '2026-10-24', '08:00 - 08:30', 4, 1, 'available'),
(19, 10, '2026-10-24', '14:00 - 14:30', 4, 0, 'available');

-- 6. APPOINTMENTS (3 phiếu khám mẫu hiển thị trực tiếp trên app)
INSERT INTO `appointments` (`id`, `booking_code`, `user_id`, `profile_id`, `doctor_id`, `schedule_id`, `queue_number`, `qr_data`, `exam_type`, `symptoms`, `status`, `created_at`) VALUES
-- Phiếu khám sắp tới của Nguyễn Văn An (khám Tim Mạch với PGS.TS Trần Nam Phong)
(1, 'MB-20261024-001', 1, 1, 1, 1, 1, '{"code":"MB-20261024-001","patient":"Nguyễn Văn An","doctor":"PGS.TS Trần Nam Phong","date":"2026-10-24","slot":"08:00 - 08:30","stt":1}', 'Dịch vụ', 'Hay hồi hộp, đau thắt ngực nhẹ khi leo cầu thang', 'confirmed', '2026-10-23 10:00:00'),

-- Phiếu khám của Mẹ (Nguyễn Thị Hoa)
(2, 'MB-20261024-002', 1, 2, 10, 18, 1, '{"code":"MB-20261024-002","patient":"Nguyễn Thị Hoa","doctor":"TS.BS Mai Diệu Linh","date":"2026-10-24","slot":"08:00 - 08:30","stt":1}', 'BHYT', 'Kiểm tra huyết áp định kỳ và tư vấn điều chỉnh thuốc', 'confirmed', '2026-10-23 11:30:00'),

-- Phiếu khám đã hoàn thành trong quá khứ của Con (Nguyễn Minh Quân)
(3, 'MB-20261015-089', 1, 3, 5, 13, 3, '{"code":"MB-20261015-089","patient":"Nguyễn Minh Quân","doctor":"BS.CKII Hoàng Đức Thắng","date":"2026-10-15","slot":"08:30 - 09:00","stt":3}', 'BHYT', 'Sốt nhẹ 38 độ, ho húng hắng về đêm, ngạt mũi', 'completed', '2026-10-15 08:15:00');

-- 7. MEDICAL_RECORDS (Hồ sơ khám chữa bệnh & chỉ số sinh tồn mẫu)
INSERT INTO `medical_records` (`id`, `profile_id`, `appointment_id`, `doctor_id`, `specialty_name`, `diagnosis`, `doctor_notes`, `prescription`, `blood_pressure`, `heart_rate`, `blood_sugar`, `weight`, `height`, `exam_date`) VALUES
(1, 1, 1, 1, 'Tim Mạch', 'Tăng huyết áp độ 1 - Rối loạn nhịp tim xoang nhẹ', 'Hạn chế ăn mặn, giảm dầu mỡ, ngủ đủ 7-8 tiếng/ngày. Tái khám sau 30 ngày.', '1. Amlodipine 5mg: 1 viên uống sáng sau ăn\n2. Concor 2.5mg: 1 viên uống sáng', '135/85 mmHg', 78, 5.4, 68.0, 172.0, '2026-10-10'),
(2, 3, 3, 5, 'Nhi Khoa', 'Viêm họng cấp thể nhẹ do virus - Viêm mũi xuất tiết', 'Giữ ấm cổ ngực, xịt rửa mũi bằng nước muối sinh lý ấm ngày 3 lần. Uống nhiều nước ấm.', '1. Siro Prospan: 2.5ml x 3 lần/ngày sau ăn\n2. Hapacol 250mg: Uống 1 gói khi sốt trên 38.5 độ', '100/65 mmHg', 95, 4.8, 18.5, 108.0, '2026-10-15');

-- 8. MEDICATION_REMINDERS (Lịch nhắc uống thuốc hôm nay của Nguyễn Văn An)
INSERT INTO `medication_reminders` (`id`, `user_id`, `profile_id`, `medicine_name`, `dosage`, `time_of_day`, `reminder_time`, `is_taken_today`, `start_date`, `end_date`, `notes`) VALUES
(1, 1, 1, 'Amlodipine 5mg', '1 viên', 'Sáng', '07:30:00', 1, '2026-10-10', '2026-11-10', 'Uống sau bữa ăn sáng 15 phút với nhiều nước'),
(2, 1, 1, 'Concor 2.5mg', '1 viên', 'Trưa', '12:00:00', 0, '2026-10-10', '2026-11-10', 'Uống sau bữa ăn trưa'),
(3, 1, 1, 'Vitamin C 500mg', '1 viên sủi', 'Tối', '19:30:00', 0, '2026-10-10', '2026-11-10', 'Pha với 150ml nước lọc, uống sau ăn');
