# MEDBOOK - HỆ THỐNG BACKEND NODE.JS & MYSQL

Hệ thống RESTful API hoàn chỉnh phục vụ ứng dụng di động **MEDBOOK (Đặt lịch khám bệnh tại bệnh viện, quản lý hồ sơ sức khỏe và theo dõi điều trị)**.

---

## 1. Yêu Cầu Môi Trường
- **Node.js**: v18+ hoặc v20+ (Khuyên dùng v20 LTS trở lên)
- **MySQL / MariaDB**: Chạy trên **Laragon**, **XAMPP** hoặc **HeidiSQL / MySQL Workbench**.
  - Host: `127.0.0.1` hoặc `localhost`
  - Port: `3306`
  - User: `root`
  - Password: ` ` *(mặc định để trống trên Laragon)*

---

## 2. Khởi Tạo Cơ Sở Dữ Liệu MySQL
1. Bật MySQL trên Laragon hoặc XAMPP.
2. Mở công cụ quản lý CSDL (HeidiSQL, phpMyAdmin, hoặc MySQL CLI).
3. Mở file [backend/database/medbook.sql](file:///C:/Users/DELL/Doctor-Booking-App/backend/database/medbook.sql) và nhấn **Execute / Run** toàn bộ file.
4. Hệ thống sẽ tự động tạo database `medbook`, 8 bảng cốt lõi với khóa ngoại và nạp toàn bộ dữ liệu mẫu (Users, Bác sĩ, Khung giờ, Bệnh án, Đơn thuốc, Lịch nhắc thuốc).

> **Tài khoản kiểm thử tạo sẵn:**
> - Bệnh nhân 1: SĐT `0987654321` | Mật khẩu: `123456`
> - Bệnh nhân 2: SĐT `0912345678` | Mật khẩu: `123456`
> - Quản trị viên: SĐT `0900000000` | Mật khẩu: `123456`
> - Nếu đã import database trước khi sửa lỗi này, chạy lệnh sau trong MySQL để cập nhật mật khẩu tài khoản quản trị hiện có:
>   ```sql
>   UPDATE users
>   SET password_hash = '$2b$10$uBa58/99br.BPegyoFgUHegsj1lb1OCpSzPWfxOigtMtCaYpwAL8K'
>   WHERE phone = '0900000000';
>   ```

---

## 3. Cài Đặt Thư Viện & Khởi Động Server

Từ thư mục `backend/`:
```bash
# Cài đặt các gói phụ thuộc
npm install

# Khởi chạy server ở chế độ giám sát tự động tải lại (watch mode)
npm run dev

# Hoặc chạy thông thường
npm start
```

---

## 4. Tài Liệu API & Swagger UI

Truy cập giao diện Swagger UI tương tác trực tiếp trên trình duyệt:
👉 **[http://localhost:3000/api-docs](http://localhost:3000/api-docs)**

---

## 5. Danh Sách Các Endpoint API Cốt Lõi

### A. Xác thực người dùng (`/api/auth`)
| Method | Endpoint | Mô tả | Quyền |
|---|---|---|---|
| POST | `/api/auth/register` | Đăng ký tài khoản người dùng mới | Public |
| POST | `/api/auth/login` | Đăng nhập tài khoản, trả về JWT token | Public |
| GET | `/api/auth/me` | Lấy thông tin tài khoản người dùng đang đăng nhập | Bearer Token |
| PUT | `/api/auth/me` | Cập nhật thông tin tài khoản (Họ tên, email, avatar) | Bearer Token |

### B. Quản lý hồ sơ bệnh nhân (`/api/profiles`)
| Method | Endpoint | Mô tả | Quyền |
|---|---|---|---|
| GET | `/api/profiles` | Lấy danh sách hồ sơ (Bản thân, Bố, Mẹ, Con...) | Bearer Token |
| GET | `/api/profiles/:id` | Lấy chi tiết một hồ sơ y tế | Bearer Token |
| POST | `/api/profiles` | Tạo hồ sơ người khám bệnh mới | Bearer Token |
| PUT | `/api/profiles/:id` | Cập nhật thông tin thẻ BHYT, CCCD, tiền sử dị ứng | Bearer Token |
| DELETE | `/api/profiles/:id` | Xóa hồ sơ (kèm kiểm tra lịch sử khám) | Bearer Token |

### C. Chuyên khoa & Bác sĩ (`/api/specialties`, `/api/doctors`)
| Method | Endpoint | Mô tả | Quyền |
|---|---|---|---|
| GET | `/api/specialties` | Danh sách 6 chuyên khoa bệnh viện (khớp UI Flutter) | Public |
| GET | `/api/specialties/:id` | Chi tiết khoa kèm danh sách bác sĩ thuộc khoa | Public |
| GET | `/api/doctors` | Lấy danh sách bác sĩ (lọc theo khoa `?specialty_id=`, tìm kiếm `?search=`) | Public |
| GET | `/api/doctors/:id` | Chi tiết bác sĩ kèm khung giờ khám theo ngày | Public |
| GET | `/api/doctors/:id/schedules` | Danh sách khung giờ khám theo ngày `?date=YYYY-MM-DD` | Public |

### D. Đặt lịch khám bệnh (`/api/appointments`)
| Method | Endpoint | Mô tả | Quyền |
|---|---|---|---|
| POST | `/api/appointments` | Đặt lịch khám mới (Transaction an toàn, kiểm tra chống trùng lịch, tự sinh STT, mã phiếu `MB-...` và QR code) | Bearer Token |
| GET | `/api/appointments` | Lấy danh sách phiếu khám của người dùng (lọc `?status=`) | Bearer Token |
| GET | `/api/appointments/:id` | Xem chi tiết phiếu khám điện tử và chuỗi QR | Bearer Token |
| PUT | `/api/appointments/:id/cancel` | Hủy lịch hẹn khám và giải phóng chỗ | Bearer Token |

### E. Hồ sơ bệnh án & Chỉ số sinh tồn (`/api/medical-records`)
| Method | Endpoint | Mô tả | Quyền |
|---|---|---|---|
| GET | `/api/medical-records` | Lấy lịch sử khám bệnh, chỉ số huyết áp, nhịp tim, đơn thuốc | Bearer Token |
| GET | `/api/medical-records/:id` | Chi tiết một lần khám và dặn dò của bác sĩ | Bearer Token |
| POST | `/api/medical-records` | Tạo hồ sơ bệnh án mới | Bearer Token |
| PUT | `/api/medical-records/:id` | Chỉnh sửa nội dung bệnh án | Bearer Token |
| DELETE | `/api/medical-records/:id` | Xóa bản ghi bệnh án | Bearer Token |

### F. Nhắc lịch uống thuốc (`/api/medications`)
| Method | Endpoint | Mô tả | Quyền |
|---|---|---|---|
| GET | `/api/medications` | Danh sách các loại thuốc cần uống (hỗ trợ `?active_only=true`) | Bearer Token |
| POST | `/api/medications` | Thêm lịch nhắc uống thuốc | Bearer Token |
| PATCH | `/api/medications/:id/toggle` | Đánh dấu Đã uống / Chưa uống hôm nay (1 chạm) | Bearer Token |
| PUT | `/api/medications/:id` | Sửa thông tin thuốc và liều lượng | Bearer Token |
| DELETE | `/api/medications/:id` | Xóa nhắc nhở thuốc | Bearer Token |

### G. Trang chủ tổng hợp (`/api/dashboard`)
| Method | Endpoint | Mô tả | Quyền |
|---|---|---|---|
| GET | `/api/dashboard` | Cung cấp toàn bộ dữ liệu cần thiết cho màn hình Home (phiếu khám gần nhất, số cữ thuốc cần uống hôm nay, chuyên khoa và bác sĩ hàng đầu) | Bearer Token |
