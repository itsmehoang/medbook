class PatientProfileModel {
  final int id;
  final int userId;
  final String fullName;
  final String dob;
  final String gender;
  final String? cccd;
  final String? bhytCode;
  final String relationship;
  final String? phone;
  final String? address;
  final String? allergies;

  PatientProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.dob,
    required this.gender,
    this.cccd,
    this.bhytCode,
    this.relationship = 'Bản thân',
    this.phone,
    this.address,
    this.allergies,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      fullName: json['full_name'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? 'Nam',
      cccd: json['cccd'],
      bhytCode: json['bhyt_code'],
      relationship: json['relationship'] ?? 'Bản thân',
      phone: json['phone'],
      address: json['address'],
      allergies: json['allergies'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'dob': dob,
      'gender': gender,
      'cccd': cccd,
      'bhyt_code': bhytCode,
      'relationship': relationship,
      'phone': phone,
      'address': address,
      'allergies': allergies,
    };
  }
}

