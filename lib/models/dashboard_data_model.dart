import 'user_model.dart';
import 'appointment_model.dart';
import 'medication_reminder_model.dart';
import 'specialty_model.dart';
import 'doctor_model.dart';

class MedicationSummary {
  final int total;
  final int taken;
  final int pending;
  final List<MedicationReminderModel> list;

  MedicationSummary({
    required this.total,
    required this.taken,
    required this.pending,
    required this.list,
  });

  factory MedicationSummary.fromJson(Map<String, dynamic> json) {
    var rawList = json['list'] as List? ?? [];
    List<MedicationReminderModel> meds = rawList.map((m) => MedicationReminderModel.fromJson(m)).toList();
    return MedicationSummary(
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      taken: json['taken'] is int ? json['taken'] : int.tryParse(json['taken']?.toString() ?? '0') ?? 0,
      pending: json['pending'] is int ? json['pending'] : int.tryParse(json['pending']?.toString() ?? '0') ?? 0,
      list: meds,
    );
  }
}

class DashboardDataModel {
  final UserModel? user;
  final AppointmentModel? upcomingAppointment;
  final MedicationSummary? medications;
  final List<SpecialtyModel> specialties;
  final List<DoctorModel> topDoctors;

  DashboardDataModel({
    this.user,
    this.upcomingAppointment,
    this.medications,
    required this.specialties,
    required this.topDoctors,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    UserModel? user;
    if (json['user'] != null) {
      user = UserModel.fromJson(json['user']);
    }

    AppointmentModel? upcoming;
    if (json['upcoming_appointment'] != null) {
      upcoming = AppointmentModel.fromJson(json['upcoming_appointment']);
    }

    MedicationSummary? meds;
    if (json['medications'] != null) {
      meds = MedicationSummary.fromJson(json['medications']);
    }

    var specList = json['specialties'] as List? ?? [];
    List<SpecialtyModel> specs = specList.map((s) => SpecialtyModel.fromJson(s)).toList();

    var docList = json['top_doctors'] as List? ?? [];
    List<DoctorModel> docs = docList.map((d) => DoctorModel.fromJson(d)).toList();

    return DashboardDataModel(
      user: user,
      upcomingAppointment: upcoming,
      medications: meds,
      specialties: specs,
      topDoctors: docs,
    );
  }
}

