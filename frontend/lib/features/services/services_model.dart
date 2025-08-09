// lib/models/service_model.dart
import 'package:flutter/material.dart';

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String providerName;
  final String? contactEmail;
  final String? contactPhone;
  final String? websiteUrl;
  final String? address;
  final String serviceType;
  final String? availabilityHours;
  final String? eligibilityCriteria;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.providerName,
    this.contactEmail,
    this.contactPhone,
    this.websiteUrl,
    this.address,
    required this.serviceType,
    this.availabilityHours,
    this.eligibilityCriteria,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      providerName: json['provider_name'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      websiteUrl: json['website_url'],
      address: json['address'],
      serviceType: json['service_type'],
      availabilityHours: json['availability_hours'],
      eligibilityCriteria: json['eligibility_criteria'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'provider_name': providerName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'website_url': websiteUrl,
      'address': address,
      'service_type': serviceType,
      'availability_hours': availabilityHours,
      'eligibility_criteria': eligibilityCriteria,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get serviceTypeDisplayName {
    switch (serviceType) {
      case 'online':
        return 'Online';
      case 'in_person':
        return 'In-Person';
      case 'hybrid':
        return 'Hybrid';
      default:
        return serviceType;
    }
  }

  Color get serviceTypeColor {
    switch (serviceType) {
      case 'online':
        return const Color(0xFF2196F3); // Blue
      case 'in_person':
        return const Color(0xFF4CAF50); // Green
      case 'hybrid':
        return const Color(0xFFFFC107); // Amber
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  String get shortDescription {
    if (description.length <= 100) return description;
    return '${description.substring(0, 100)}...';
  }

  bool get hasContact => contactEmail != null || contactPhone != null;

  bool get hasWebsite => websiteUrl != null && websiteUrl!.isNotEmpty;

  String get displayAddress {
    if (address == null || address!.isEmpty) {
      return serviceType == 'online' ? 'Online Service' : 'Contact for location';
    }
    return address!;
  }

  List<String> get contactMethods {
    final methods = <String>[];
    if (contactEmail != null && contactEmail!.isNotEmpty) methods.add('Email');
    if (contactPhone != null && contactPhone!.isNotEmpty) methods.add('Phone');
    if (websiteUrl != null && websiteUrl!.isNotEmpty) methods.add('Website');
    return methods;
  }
}