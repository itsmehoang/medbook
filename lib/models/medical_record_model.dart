import 'doctor_model.dart';

class MedicalRecordModel {
  final int id;
  final int profileId;
  final int? appointmentId;
  final int? doctorId;
  final String specialtyName;
  final String diagnosis;
  final String? doctorNotes;
  final String? prescription;
  final String? bloodPressure;
  final int? heartRate;
  final double? bloodSugar;
  final double? weight;
  final double? height;
  final String examDate;
  final String? patientName;
  final String? doctorName;
  final String? doctorDegree;
  final String? doctorAvatar;
  final String? bookingCode;

  MedicalRecordModel({
    required this.id,
    required this.profileId,
    this.appointmentId,
    this.doctorId,
    required this.specialtyName,
    required this.diagnosis,
    this.doctorNotes,
    this.prescription,
    this.bloodPressure,
    this.heartRate,
    this.bloodSugar,
    this.weight,
    this.height,
    required this.examDate,
    this.patientName,
    this.doctorName,
    this.doctorDegree,
    this.doctorAvatar,
    this.bookingCode,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      profileId: json['profile_id'] is int ? json['profile_id'] : int.parse(json['profile_id'].toString()),
      appointmentId: json['appointment_id'] != null
          ? (json['appointment_id'] is int ? json['appointment_id'] : int.tryParse(json['appointment_id'].toString()))
          : null,
      doctorId: json['doctor_id'] != null
          ? (json['doctor_id'] is int ? json['doctor_id'] : int.tryParse(json['doctor_id'].toString()))
          : null,
      specialtyName: json['specialty_name'] ?? 'Khám tổng quát',
      diagnosis: json['diagnosis'] ?? '',
      doctorNotes: json['doctor_notes'],
      prescription: json['prescription'],
      bloodPressure: json['blood_pressure'],
      heartRate: json['heart_rate'] != null ? int.tryParse(json['heart_rate'].toString()) : null,
      bloodSugar: json['blood_sugar'] != null ? double.tryParse(json['blood_sugar'].toString()) : null,
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      height: json['height'] != null ? double.tryParse(json['height'].toString()) : null,
      examDate: json['exam_date'] ?? '',
      patientName: json['patient_name'],
      doctorName: json['doctor_name'],
      doctorDegree: json['doctor_degree'],
      doctorAvatar: DoctorModel.resolveAvatarUrl(json['doctor_avatar']),
      bookingCode: json['booking_code'],
    );
  }

  String get doctorDisplayName {
    if (doctorName == null || doctorName!.isEmpty) return 'Bác sĩ phụ trách';
    if (doctorDegree != null && doctorDegree!.isNotEmpty) {
      return '$doctorDegree $doctorName';
    }
    return doctorName!;
  }
}

