import '../services/api_service.dart';

class ScheduleSlot {
  final int id;
  final String timeSlot;
  final int maxPatients;
  final int bookedCount;
  final int availableSlots;
  final bool isAvailable;

  ScheduleSlot({
    required this.id,
    required this.timeSlot,
    required this.maxPatients,
    required this.bookedCount,
    required this.availableSlots,
    required this.isAvailable,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      timeSlot: json['time_slot'] ?? '',
      maxPatients: json['max_patients'] is int ? json['max_patients'] : int.parse(json['max_patients'].toString()),
      bookedCount: json['booked_count'] is int ? json['booked_count'] : int.parse(json['booked_count'].toString()),
      availableSlots: json['available_slots'] is int ? json['available_slots'] : (json['remaining_slots'] is int ? json['remaining_slots'] : 0),
      isAvailable: json['is_available'] == true || json['status'] == 'available',
    );
  }
}

class DoctorModel {
  final int id;
  final int specialtyId;
  final String fullName;
  final String degree;
  final String? avatarUrl;
  final String? bio;
  final double rating;
  final int reviewCount;
  final int patientCount;
  final int experienceYears;
  final String hospitalName;
  final String roomNumber;
  final String? specialtyName;
  final String? specialtyCode;
  final String? roomLocation;
  final double basePrice;
  final Map<String, List<ScheduleSlot>>? schedules;

  DoctorModel({
    required this.id,
    required this.specialtyId,
    required this.fullName,
    required this.degree,
    this.avatarUrl,
    this.bio,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.patientCount = 0,
    this.experienceYears = 5,
    required this.hospitalName,
    required this.roomNumber,
    this.specialtyName,
    this.specialtyCode,
    this.roomLocation,
    this.basePrice = 200000,
    this.schedules,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    Map<String, List<ScheduleSlot>>? parsedSchedules;
    if (json['schedules'] != null && json['schedules'] is Map) {
      parsedSchedules = {};
      (json['schedules'] as Map).forEach((key, val) {
        if (val is List) {
          parsedSchedules![key.toString()] = val.map((s) => ScheduleSlot.fromJson(s)).toList();
        }
      });
    }

    return DoctorModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      specialtyId: json['specialty_id'] is int ? json['specialty_id'] : int.parse(json['specialty_id'].toString()),
      fullName: json['full_name'] ?? '',
      degree: json['degree'] ?? 'BS',
      avatarUrl: resolveAvatarUrl(json['avatar_url']),
      bio: json['bio'],
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) ?? 5.0 : 5.0,
      reviewCount: json['review_count'] is int ? json['review_count'] : int.tryParse(json['review_count']?.toString() ?? '0') ?? 0,
      patientCount: json['patient_count'] is int ? json['patient_count'] : int.tryParse(json['patient_count']?.toString() ?? '0') ?? 0,
      experienceYears: json['experience_years'] is int ? json['experience_years'] : int.tryParse(json['experience_years']?.toString() ?? '5') ?? 5,
      hospitalName: json['hospital_name'] ?? 'Bệnh viện Đa khoa MedBook',
      roomNumber: json['room_number'] ?? 'Phòng Khám',
      specialtyName: json['specialty_name'],
      specialtyCode: json['specialty_code'],
      roomLocation: json['room_location'],
      basePrice: json['base_price'] != null ? double.tryParse(json['base_price'].toString()) ?? 200000 : 200000,
      schedules: parsedSchedules,
    );
  }

  static String? resolveAvatarUrl(dynamic rawUrl) {
    if (rawUrl == null) return null;
    final str = rawUrl.toString().trim();
    if (str.isEmpty) return null;
    if (str.startsWith('http://') || str.startsWith('https://')) return str;
    final host = ApiService().baseUrl.replaceAll('/api', '');
    final cleanPath = str.startsWith('/') ? str : '/$str';
    return '$host$cleanPath';
  }

  String get displayName {
    if (fullName.trim().isEmpty) return 'Bác sĩ';
    final name = fullName.trim();
    final deg = degree.trim();
    if (deg.isEmpty) return name;

    final cleanDeg = deg.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final cleanName = name.replaceAll(RegExp(r'\s+'), '').toLowerCase();

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

