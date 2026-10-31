class MedicationReminderModel {
  final int id;
  final String medicineName;
  final String dosage;
  final String timeOfDay;
  final String reminderTime;
  bool isTakenToday;
  final String? startDate;
  final String? endDate;
  final String? notes;
  final String? patientName;

  MedicationReminderModel({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.timeOfDay,
    required this.reminderTime,
    required this.isTakenToday,
    this.startDate,
    this.endDate,
    this.notes,
    this.patientName,
  });

  factory MedicationReminderModel.fromJson(Map<String, dynamic> json) {
    return MedicationReminderModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      medicineName: json['medicine_name'] ?? '',
      dosage: json['dosage'] ?? '',
      timeOfDay: json['time_of_day'] ?? 'Sáng',
      reminderTime: json['reminder_time'] ?? '08:00:00',
      isTakenToday: json['is_taken_today'] == 1 || json['is_taken_today'] == true,
      startDate: json['start_date'],
      endDate: json['end_date'],
      notes: json['notes'],
      patientName: json['patient_name'],
    );
  }
}

