import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/specialty_model.dart';
import '../models/doctor_model.dart';
import '../models/patient_profile_model.dart';
import '../models/appointment_model.dart';
import '../models/medication_reminder_model.dart';
import '../models/dashboard_data_model.dart';
import '../models/medical_record_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _tokenKey = 'medbook_jwt_token';

  // Cấu hình URL linh hoạt giữa Web, Android Emulator và Desktop
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 trỏ về localhost của máy host trong Android Emulator
      return 'http://10.0.2.2:3000/api';
    } else {
      // Windows, macOS, Linux, iOS Simulator
      return 'http://localhost:3000/api';
    }
  }

  // Quản lý Token trong SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ==========================================
  // AUTH APIS
  // ==========================================
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['data']['token'];
      await saveToken(token);
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại.');
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'email': email,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201 && data['success'] == true) {
      final token = data['data']['token'];
      await saveToken(token);
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Đăng ký tài khoản không thành công.');
    }
  }

  Future<UserModel> getMe() async {
    final url = Uri.parse('$baseUrl/auth/me');
    final response = await http.get(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Không thể lấy thông tin người dùng.');
    }
  }

  // ==========================================
  // DASHBOARD API
  // ==========================================
  Future<DashboardDataModel> getDashboard() async {
    final url = Uri.parse('$baseUrl/dashboard');
    final response = await http.get(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      return DashboardDataModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Lỗi khi tải dữ liệu trang chủ.');
    }
  }

  // ==========================================
  // SPECIALTIES & DOCTORS
  // ==========================================
  Future<List<SpecialtyModel>> getSpecialties() async {
    final url = Uri.parse('$baseUrl/specialties');
    final response = await http.get(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      var list = data['data'] as List;
      return list.map((item) => SpecialtyModel.fromJson(item)).toList();
    } else {
      throw Exception(data['message'] ?? 'Lỗi khi lấy danh sách chuyên khoa.');
    }
  }

  Future<List<DoctorModel>> getDoctors({int? specialtyId, String? search, String? sort}) async {
    String queryParams = '';
    final params = <String>[];
    if (specialtyId != null) params.add('specialty_id=$specialtyId');
    if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
    if (sort != null) params.add('sort=$sort');
    if (params.isNotEmpty) queryParams = '?${params.join('&')}';

    final url = Uri.parse('$baseUrl/doctors$queryParams');
    final response = await http.get(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      var list = data['data'] as List;
      return list.map((item) => DoctorModel.fromJson(item)).toList();
    } else {
      throw Exception(data['message'] ?? 'Lỗi khi lấy danh sách bác sĩ.');
    }
  }

  Future<DoctorModel> getDoctorById(int doctorId) async {
    final url = Uri.parse('$baseUrl/doctors/$doctorId');
    final response = await http.get(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      return DoctorModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Không tìm thấy thông tin bác sĩ.');
    }
  }

  // ==========================================
  // PATIENT PROFILES
  // ==========================================
  Future<List<PatientProfileModel>> getProfiles() async {
    final url = Uri.parse('$baseUrl/profiles');
    final response = await http.get(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      var list = data['data'] as List;
      return list.map((item) => PatientProfileModel.fromJson(item)).toList();
    } else {
      throw Exception(data['message'] ?? 'Lỗi khi lấy danh sách hồ sơ người khám.');
    }
  }

  Future<PatientProfileModel> createProfile({
    required String fullName,
    required String dob,
    required String gender,
    String? cccd,
    String? bhytCode,
    String relationship = 'Bản thân',
    String? phone,
    String? address,
    String? allergies,
  }) async {
    final url = Uri.parse('$baseUrl/profiles');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'full_name': fullName,
        'dob': dob,
        'gender': gender,
        'cccd': cccd,
        'bhyt_code': bhytCode,
        'relationship': relationship,
        'phone': phone,
        'address': address,
        'allergies': allergies,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201 && data['success'] == true) {
      return PatientProfileModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Không thể tạo hồ sơ người bệnh.');
    }
  }

  // ==========================================
  // APPOINTMENTS
  // ==========================================
  Future<AppointmentModel> createAppointment({
    int? profileId,
    required int doctorId,
    int? scheduleId,
    String? workDate,
    String? timeSlot,
    String examType = 'Dịch vụ',
    String? symptoms,
  }) async {
    final url = Uri.parse('$baseUrl/appointments');
    final body = <String, dynamic>{
      'doctor_id': doctorId,
      'exam_type': examType,
    };
    if (profileId != null) body['profile_id'] = profileId;
    if (scheduleId != null) body['schedule_id'] = scheduleId;
    if (workDate != null && workDate.isNotEmpty) {
      body['work_date'] = workDate;
      body['appointment_date'] = workDate;
    }
    if (timeSlot != null && timeSlot.isNotEmpty) body['time_slot'] = timeSlot;
    if (symptoms != null && symptoms.trim().isNotEmpty) body['symptoms'] = symptoms.trim();

    final headers = await _getHeaders();
    debugPrint('[ApiService] Gửi yêu cầu POST $url');
    debugPrint('[ApiService] Headers: $headers');
    debugPrint('[ApiService] Body: ${jsonEncode(body)}');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    debugPrint('[ApiService] Response HTTP ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if ((response.statusCode == 201 || response.statusCode == 200) && data['success'] == true) {
      return AppointmentModel.fromJson(data['data']);
    } else {
      final msg = data['message'] ?? 'Đặt lịch khám thất bại. Vui lòng thử lại.';
      debugPrint('[ApiService Error] Lỗi Server trả về: $msg');
      throw Exception(msg);
    }
  }

  Future<List<AppointmentModel>> getAppointments({String? status, int? profileId}) async {
    String queryParams = '';
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (profileId != null) params.add('profile_id=$profileId');
    if (params.isNotEmpty) queryParams = '?${params.join('&')}';

    final url = Uri.parse('$baseUrl/appointments$queryParams');
    final response = await http.get(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      var list = data['data'] as List;
      return list.map((item) => AppointmentModel.fromJson(item)).toList();
    } else {
      throw Exception(data['message'] ?? 'Lỗi khi tải danh sách phiếu khám.');
    }
  }

  Future<AppointmentModel> getAppointmentById(String idOrCode) async {
    final url = Uri.parse('$baseUrl/appointments/$idOrCode');
    final response = await http.get(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      return AppointmentModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Không tìm thấy phiếu khám.');
    }
  }

  Future<void> cancelAppointment(int appointmentId, {String? reason}) async {
    final url = Uri.parse('$baseUrl/appointments/$appointmentId/cancel');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'reason': reason ?? 'Người bệnh tự hủy hẹn'}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể hủy lịch khám.');
    }
  }

  // ==========================================
  // MEDICATIONS
  // ==========================================
  Future<List<MedicationReminderModel>> getMedications({int? profileId, bool? activeOnly}) async {
    String queryParams = '';
    final params = <String>[];
    if (profileId != null) params.add('profile_id=$profileId');
    if (activeOnly != null) params.add('active_only=$activeOnly');
    if (params.isNotEmpty) queryParams = '?${params.join('&')}';

    final url = Uri.parse('$baseUrl/medications$queryParams');
    final response = await http.get(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      var list = data['data'] as List;
      return list.map((item) => MedicationReminderModel.fromJson(item)).toList();
    } else {
      throw Exception(data['message'] ?? 'Lỗi khi tải danh sách nhắc thuốc.');
    }
  }

  Future<MedicationReminderModel> createMedication({
    required int profileId,
    required String medicineName,
    required String dosage,
    required String timeOfDay,
    required String reminderTime,
    required String startDate,
    required String endDate,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/medications');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'profile_id': profileId,
        'medicine_name': medicineName,
        'dosage': dosage,
        'time_of_day': timeOfDay,
        'reminder_time': reminderTime,
        'start_date': startDate,
        'end_date': endDate,
        'notes': notes,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201 && data['success'] == true) {
      return MedicationReminderModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Thêm nhắc thuốc thất bại.');
    }
  }

  Future<void> deleteMedication(int medicationId) async {
    final url = Uri.parse('$baseUrl/medications/$medicationId');
    final response = await http.delete(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể xóa lịch nhắc thuốc.');
    }
  }

  Future<void> toggleMedication(int medicationId) async {
    final url = Uri.parse('$baseUrl/medications/$medicationId/toggle');
    final response = await http.patch(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi khi cập nhật trạng thái uống thuốc.');
    }
  }

  // ==========================================
  // MEDICAL RECORDS
  // ==========================================
  Future<List<MedicalRecordModel>> getMedicalRecords({int? profileId}) async {
    String queryParams = profileId != null ? '?profile_id=$profileId' : '';
    final url = Uri.parse('$baseUrl/medical-records$queryParams');
    final response = await http.get(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      var list = data['data'] as List;
      return list.map((item) => MedicalRecordModel.fromJson(item)).toList();
    } else {
      throw Exception(data['message'] ?? 'Lỗi khi tải hồ sơ bệnh án.');
    }
  }

  Future<MedicalRecordModel> createMedicalRecord({
    required int profileId,
    required String specialtyName,
    required String diagnosis,
    required String examDate,
    String? doctorNotes,
    String? prescription,
    String? bloodPressure,
    int? heartRate,
    double? bloodSugar,
    double? weight,
  }) async {
    final url = Uri.parse('$baseUrl/medical-records');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'profile_id': profileId,
        'specialty_name': specialtyName,
        'diagnosis': diagnosis,
        'exam_date': examDate,
        'doctor_notes': doctorNotes,
        'prescription': prescription,
        'blood_pressure': bloodPressure,
        'heart_rate': heartRate,
        'blood_sugar': bloodSugar,
        'weight': weight,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201 && data['success'] == true) {
      return MedicalRecordModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Không thể tạo hồ sơ bệnh án.');
    }
  }

  Future<void> deleteMedicalRecord(int id) async {
    final url = Uri.parse('$baseUrl/medical-records/$id');
    final response = await http.delete(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể xóa hồ sơ bệnh án.');
    }
  }

  // ==========================================
  // PROFILE UPDATE / DELETE
  // ==========================================
  Future<PatientProfileModel> updateProfile(int id, {
    String? fullName,
    String? dob,
    String? gender,
    String? cccd,
    String? bhytCode,
    String? relationship,
    String? phone,
    String? address,
    String? allergies,
  }) async {
    final url = Uri.parse('$baseUrl/profiles/$id');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'full_name': fullName,
        'dob': dob,
        'gender': gender,
        'cccd': cccd,
        'bhyt_code': bhytCode,
        'relationship': relationship,
        'phone': phone,
        'address': address,
        'allergies': allergies,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['success'] == true) {
      return PatientProfileModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Cập nhật hồ sơ thất bại.');
    }
  }

  Future<void> deleteProfile(int id) async {
    final url = Uri.parse('$baseUrl/profiles/$id');
    final response = await http.delete(url, headers: await _getHeaders());
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể xóa hồ sơ.');
    }
  }
}

