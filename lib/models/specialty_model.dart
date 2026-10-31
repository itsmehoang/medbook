import 'package:flutter/material.dart';

class SpecialtyModel {
  final int id;
  final String code;
  final String name;
  final String? iconUrl;
  final String? description;
  final String roomLocation;
  final double basePrice;
  final int doctorCount;

  SpecialtyModel({
    required this.id,
    required this.code,
    required this.name,
    this.iconUrl,
    this.description,
    required this.roomLocation,
    required this.basePrice,
    this.doctorCount = 0,
  });

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      iconUrl: json['icon_url'],
      description: json['description'],
      roomLocation: json['room_location'] ?? 'Tầng 2 - Tòa A',
      basePrice: json['base_price'] != null ? double.tryParse(json['base_price'].toString()) ?? 200000 : 200000,
      doctorCount: json['doctor_count'] is int ? json['doctor_count'] : int.tryParse(json['doctor_count']?.toString() ?? '0') ?? 0,
    );
  }

  IconData get iconData {
    switch (code) {
      case 'cardiology':
        return Icons.favorite_border_outlined;
      case 'dermatology':
        return Icons.health_and_safety_outlined;
      case 'pediatrics':
        return Icons.child_care_outlined;
      case 'dentist':
        return Icons.medical_services_outlined;
      case 'emergencyMedicine':
        return Icons.local_pharmacy_outlined;
      case 'familyMedicine':
        return Icons.medical_information_outlined;
      default:
        return Icons.medical_services_outlined;
    }
  }
}

