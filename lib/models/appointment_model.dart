import 'doctor_model.dart';

class AppointmentModel {
  final int id;
  final String bookingCode;
  final int userId;
  final int profileId;
  final int doctorId;
  final int scheduleId;
  final int queueNumber;
  final String qrData;
  final String examType;
  final String? symptoms;
  final String status;
  final String? patientName;
  final String? patientDob;
  final String? patientGender;
  final String? bhytCode;
  final String? doctorName;
  final String? doctorDegree;
  final String? doctorAvatar;
  final String? hospitalName;
  final String? roomNumber;
  final String? specialtyName;
  final String? roomLocation;
  final String? workDate;
  final String? timeSlot;
  final double? basePrice;
  final String? createdAt;

  AppointmentModel({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.profileId,
    required this.doctorId,
    required this.scheduleId,
    required this.queueNumber,
    required this.qrData,
    this.examType = 'Dịch vụ',
    this.symptoms,
    required this.status,
    this.patientName,
    this.patientDob,
    this.patientGender,
    this.bhytCode,
    this.doctorName,
    this.doctorDegree,
    this.doctorAvatar,
    this.hospitalName,
    this.roomNumber,
    this.specialtyName,
    this.roomLocation,
    this.workDate,
    this.timeSlot,
    this.basePrice,
    this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bookingCode: json['booking_code']?.toString() ?? '',
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      profileId: json['profile_id'] is int ? json['profile_id'] : int.tryParse(json['profile_id']?.toString() ?? '0') ?? 0,
      doctorId: json['doctor_id'] is int ? json['doctor_id'] : int.tryParse(json['doctor_id']?.toString() ?? '0') ?? 0,
      scheduleId: json['schedule_id'] is int ? json['schedule_id'] : int.tryParse(json['schedule_id']?.toString() ?? '0') ?? 0,
      queueNumber: json['queue_number'] is int ? json['queue_number'] : int.tryParse(json['queue_number']?.toString() ?? '1') ?? 1,
      qrData: json['qr_data']?.toString() ?? '',
      examType: json['exam_type']?.toString() ?? 'Dịch vụ',
      symptoms: json['symptoms'],
      status: json['status'] ?? 'pending',
      patientName: json['patient_name'],
      patientDob: json['patient_dob'],
      patientGender: json['patient_gender'],
      bhytCode: json['bhyt_code'],
      doctorName: json['doctor_name'],
      doctorDegree: json['degree'] ?? json['doctor_degree'],
      doctorAvatar: DoctorModel.resolveAvatarUrl(json['doctor_avatar'] ?? json['avatar_url']),
      hospitalName: json['hospital_name'],
      roomNumber: json['room_number'],
      specialtyName: json['specialty_name'],
      roomLocation: json['room_location'],
      workDate: json['work_date'],
      timeSlot: json['time_slot'],
      basePrice: json['base_price'] != null ? double.tryParse(json['base_price'].toString()) : null,
      createdAt: json['created_at'],
    );
  }

  String get doctorFullName {
    if (doctorName == null || doctorName!.trim().isEmpty) return 'Bác sĩ';
    final name = doctorName!.trim();
    final deg = (doctorDegree ?? '').trim();
    if (deg.isEmpty) return name;

    // Chuẩn hóa chuỗi để so sánh (bỏ khoảng trắng và chuyển chữ thường)
    final cleanDeg = deg.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final cleanName = name.replaceAll(RegExp(r'\s+'), '').toLowerCase();

    // Nếu tên đã bắt đầu bằng học vị hoặc các tiền tố học vị phổ biến thì không lặp lại
    if (cleanName.startsWith(cleanDeg) ||
        cleanName.startsWith('bs.') ||
        cleanName.startsWith('pgs.') ||
        cleanName.startsWith('ts.') ||
        cleanName.startsWith('ths.')) {
      return name;
    }
    return '$deg $name';
  }
}

