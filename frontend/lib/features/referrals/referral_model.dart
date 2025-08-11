// frontend/lib/features/referrals/referral_model.dart
import 'package:flutter/material.dart';

class ReferralModel {
  final String id;
  final String referredBy; // Professional/NHS staff user ID
  final String referredTo; // Parent user ID
  final String referralType; // 'service', 'resource', 'support_group'
  final String itemId; // ID of the service/resource/support group
  final String reason;
  final String status; // 'pending', 'accepted', 'declined', 'viewed'
  final bool isUrgent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  // Additional fields for display
  final String? referrerName;
  final String? recipientName;
  final String? itemTitle;
  final String? itemDescription;

  ReferralModel({
    required this.id,
    required this.referredBy,
    required this.referredTo,
    required this.referralType,
    required this.itemId,
    required this.reason,
    required this.status,
    required this.isUrgent,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.referrerName,
    this.recipientName,
    this.itemTitle,
    this.itemDescription,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: json['id'],
      referredBy: json['referred_by'],
      referredTo: json['referred_to'],
      referralType: json['referral_type'],
      itemId: json['item_id'],
      reason: json['reason'],
      status: json['status'],
      isUrgent: json['is_urgent'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      metadata: json['metadata'],
      referrerName: json['referrer_name'],
      recipientName: json['recipient_name'],
      itemTitle: json['item_title'],
      itemDescription: json['item_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referred_by': referredBy,
      'referred_to': referredTo,
      'referral_type': referralType,
      'item_id': itemId,
      'reason': reason,
      'status': status,
      'is_urgent': isUrgent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
      'referrer_name': referrerName,
      'recipient_name': recipientName,
      'item_title': itemTitle,
      'item_description': itemDescription,
    };
  }

  // Helper getters
  String get referralTypeDisplayName {
    switch (referralType) {
      case 'service':
        return 'Service';
      case 'resource':
        return 'Resource';
      case 'support_group':
        return 'Support Group';
      default:
        return referralType;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'viewed':
        return 'Viewed';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFC107); // Amber
      case 'accepted':
        return const Color(0xFF4CAF50); // Green
      case 'declined':
        return const Color(0xFFF44336); // Red
      case 'viewed':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  IconData get referralTypeIcon {
    switch (referralType) {
      case 'service':
        return Icons.medical_services;
      case 'resource':
        return Icons.menu_book;
      case 'support_group':
        return Icons.group;
      default:
        return Icons.assignment;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'viewed':
        return Icons.visibility;
      default:
        return Icons.help_outline;
    }
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isViewed => status == 'viewed';

  String get urgencyText => isUrgent ? 'Urgent' : 'Standard';

  Color get urgencyColor => isUrgent
      ? const Color(0xFFF44336) // Red for urgent
      : const Color(0xFF4CAF50); // Green for standard
}

class CreateReferralRequest {
  final String referredTo;
  final String referralType;
  final String itemId;
  final String reason;
  final bool isUrgent;
  final Map<String, dynamic>? metadata;

  CreateReferralRequest({
    required this.referredTo,
    required this.referralType,
    required this.itemId,
    required this.reason,
    required this.isUrgent,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'referred_to': referredTo,
      'referral_type': referralType,
      'item_id': itemId,
      'reason': reason,
      'is_urgent': isUrgent,
      'metadata': metadata,
    };
  }
}

class UserSearchResult {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phoneNumber;
  final DateTime createdAt;

  UserSearchResult({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phoneNumber,
    required this.createdAt,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
      phoneNumber: json['phone_number'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get roleDisplayName {
    switch (role.toLowerCase()) {
      case 'service_user':
        return 'Parent';
      case 'professional':
        return 'Professional';
      case 'nhs_staff':
        return 'NHS Staff';
      case 'charity':
        return 'Charity';
      default:
        return role;
    }
  }

  Color get roleColor {
    switch (role.toLowerCase()) {
      case 'service_user':
        return const Color(0xFF4CAF50); // Green
      case 'professional':
        return const Color(0xFF2196F3); // Blue
      case 'nhs_staff':
        return const Color(0xFFF44336); // Red
      case 'charity':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  IconData get roleIcon {
    switch (role.toLowerCase()) {
      case 'service_user':
        return Icons.person;
      case 'professional':
        return Icons.work;
      case 'nhs_staff':
        return Icons.local_hospital;
      case 'charity':
        return Icons.favorite;
      default:
        return Icons.person_outline;
    }
  }

  bool get canReceiveReferrals => role.toLowerCase() == 'service_user';
}