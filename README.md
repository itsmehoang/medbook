<div align="center">

  <h1>🏥 MedBook - Hệ Thống Đặt Lịch Khám Bệnh Trực Tuyến</h1>
  <p>
    <b>Giải pháp y tế số giúp kết nối bệnh nhân với bác sĩ và cơ sở y tế một cách nhanh chóng, tiện lợi.</b>
  </p>

  <!-- Huy hiệu công nghệ (Badges) -->
  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
    <img src="https://img.shields.io/badge/REST_API-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="REST API" />
    <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
  </p>

  <p>
    <a href="#-giới-thiệu">Giới thiệu</a> •
    <a href="#-tính-năng-nổi-bật">Tính năng</a> •
    <a href="#-công-nghệ-sử-dụng">Công nghệ</a> •
    <a href="#-cấu-trúc-dự-án">Cấu trúc</a> •
    <a href="#-cài-đặt--chạy-dự-án">Cài đặt</a>
  </p>
</div>

---

## 📖 Giới thiệu

**MedBook** là ứng dụng di động đa nền tảng được phát triển bằng **Flutter**, hỗ trợ người dùng dễ dàng tìm kiếm bác sĩ theo chuyên khoa, đặt lịch hẹn khám bệnh trực tuyến và quản lý hồ sơ sức khỏe cá nhân. Dự án hướng tới việc giảm thiểu thời gian chờ đợi tại bệnh viện và tối ưu hóa quy trình quản lý lịch hẹn cho các phòng khám, cơ sở y tế.

---

## ✨ Tính năng nổi bật

### 👤 Dành cho Bệnh nhân (User)
* **Xác thực người dùng:** Đăng ký, đăng nhập, quên mật khẩu và bảo mật tài khoản.
* **Tìm kiếm & Tra cứu:** Tìm kiếm bác sĩ theo tên, chuyên khoa (Nội khoa, Nhi khoa, Da liễu, Tim mạch...), xem thông tin chi tiết, kinh nghiệm và đánh giá của bác sĩ.
* **Đặt lịch khám thông minh:** Chọn ngày khám, khung giờ trống theo thời gian thực và điền mô tả triệu chứng ban đầu.
* **Quản lý lịch hẹn:** Theo dõi trạng thái lịch hẹn (*Chờ xác nhận, Đã xác nhận, Đã hoàn thành, Đã hủy*), hỗ trợ đổi lịch hoặc hủy lịch nhanh chóng.
* **Hồ sơ sức khỏe & Lịch sử khám:** Lưu trữ thông tin cá nhân, lịch sử các lần khám và đơn thuốc/chẩn đoán từ bác sĩ.
* **Thông báo (Notifications):** Nhắc nhở lịch khám sắp tới và cập nhật trạng thái lịch hẹn tức thì.

### 👨‍⚕️ Dành cho Bác sĩ / Quản trị viên (Doctor / Admin)
* **Quản lý lịch làm việc:** Thiết lập ca trực, khung giờ nhận bệnh nhân trong tuần.
* **Duyệt lịch hẹn:** Xác nhận hoặc từ chối yêu cầu đặt lịch từ bệnh nhân.
* **Cập nhật kết quả khám:** Ghi nhận chẩn đoán và ghi chú y tế sau khi hoàn tất ca khám.
* **Thống kê tổng quan:** Theo dõi số lượng bệnh nhân, tỷ lệ đặt lịch theo ngày/tháng.

---

## 🛠 Công nghệ sử dụng

| Thành phần | Công nghệ / Thư viện | Mô tả |
| :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev/) | Xây dựng giao diện đa nền tảng (Android / iOS) |
| **Ngôn ngữ** | [Dart](https://dart.dev/) | Ngôn ngữ lập trình chính của ứng dụng |
| **Quản lý trạng thái** | Provider / Bloc / GetX | Quản lý state và luồng dữ liệu trong ứng dụng *(chỉnh lại theo thư viện bạn dùng)* |
| **Backend / Database** | Firebase / Node.js & MySQL | Lưu trữ dữ liệu người dùng, bác sĩ và lịch hẹn *(chỉnh lại theo hệ thống của bạn)* |
| **Networking** | HTTP / Dio | Giao tiếp RESTful API |
| **Local Storage** | Shared Preferences | Lưu trữ phiên đăng nhập và cài đặt cục bộ |

---

## 📱 Giao diện ứng dụng (Screenshots)

> *Mẹo: Bạn hãy chụp màn hình ứng dụng, tải lên thư mục `assets/screenshots/` trong project và thay đường dẫn vào bảng dưới đây.*

<div align="center">
  <table>
    <tr>
      <td align="center"><b>Màn hình Đăng nhập</b></td>
      <td align="center"><b>Trang chủ & Chuyên khoa</b></td>
      <td align="center"><b>Chi tiết Bác sĩ</b></td>
      <td align="center"><b>Đặt lịch hẹn</b></td>
    </tr>
    <tr>
      <td><img src="<img width="366" height="802" alt="image" src="https://github.com/user-attachments/assets/41f63e75-f05a-429f-b415-3864d239735a" />
" width="200"/></td>
      <td><img src="https://via.placeholder.com/200x400.png?text=Home+Screen" width="200"/></td>
      <td><img src="https://via.placeholder.com/200x400.png?text=Doctor+Detail" width="200"/></td>
      <td><img src="https://via.placeholder.com/200x400.png?text=Booking+Screen" width="200"/></td>
    </tr>
  </table>
</div>

---

## 📂 Cấu trúc dự án

```text
medbook/
├── android/                 # Cấu hình gốc cho nền tảng Android
├── ios/                     # Cấu hình gốc cho nền tảng iOS
├── assets/                  # Chứa hình ảnh, icons, fonts chữ
│   ├── images/
│   └── icons/
├── lib/                     # Mã nguồn chính của ứng dụng
│   ├── core/                # Các hằng số (constants), màu sắc, themes, utils
│   ├── models/              # Các lớp dữ liệu (User, Doctor, Appointment, Specialty...)
│   ├── services/            # Xử lý gọi API, xác thực, cơ sở dữ liệu
│   ├── providers/           # Quản lý trạng thái (State Management)
│   ├── screens/             # Các màn hình giao diện chính
│   │   ├── auth/            # Đăng nhập, Đăng ký
│   │   ├── home/            # Trang chủ, Tìm kiếm
│   │   ├── booking/         # Chọn giờ, Đặt lịch khám
│   │   ├── appointment/     # Danh sách lịch hẹn
│   │   └── profile/         # Hồ sơ cá nhân
│   ├── widgets/             # Các thành phần UI tái sử dụng (Custom Button, Doctor Card...)
│   └── main.dart            # Điểm khởi chạy ứng dụng
├── pubspec.yaml             # Khai báo các thư viện (dependencies) và tài nguyên
└── README.md                # Tài liệu hướng dẫn dự án
