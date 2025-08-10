// frontend/lib/features/support_groups/support_groups_model.dart
import 'package:flutter/material.dart';

class SupportGroupModel {
  final int id;
  final String name;
  final String description;
  final String category;
  final String platform;
  final String? doctorInfo;
  final String? url;
  final String? guidelines;
  final String? meetingTime;
  final int? maxMembers;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.platform,
    this.doctorInfo,
    this.url,
    this.guidelines,
    this.meetingTime,
    this.maxMembers,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportGroupModel.fromJson(Map<String, dynamic> json) {
    return SupportGroupModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      platform: json['platform'],
      doctorInfo: json['doctor_info'],
      url: json['url'],
      guidelines: json['guidelines'],
      meetingTime: json['meeting_time'],
      maxMembers: json['max_members'],
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
      'category': category,
      'platform': platform,
      'doctor_info': doctorInfo,
      'url': url,
      'guidelines': guidelines,
      'meeting_time': meetingTime,
      'max_members': maxMembers,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get categoryDisplayName {
    switch (category) {
      case 'postnatal':
        return 'Postnatal Support';
      case 'prenatal':
        return 'Prenatal Support';
      case 'anxiety':
        return 'Anxiety Support';
      case 'depression':
        return 'Depression Support';
      case 'partner_support':
        return 'Partner Support';
      case 'general':
        return 'General Support';
      default:
        return category;
    }
  }

  String get platformDisplayName {
    switch (platform) {
      case 'online':
        return 'Online';
      case 'in_person':
        return 'In-Person';
      case 'hybrid':
        return 'Hybrid';
      default:
        return platform;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'postnatal':
        return const Color(0xFF4CAF50); // Green
      case 'prenatal':
        return const Color(0xFF2196F3); // Blue
      case 'anxiety':
        return const Color(0xFFFF9800); // Orange
      case 'depression':
        return const Color(0xFF9C27B0); // Purple
      case 'partner_support':
        return const Color(0xFF795548); // Brown
      case 'general':
        return const Color(0xFF607D8B); // Blue Grey
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  Color get platformColor {
    switch (platform) {
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

  IconData get categoryIcon {
    switch (category) {
      case 'postnatal':
        return Icons.child_care;
      case 'prenatal':
        return Icons.pregnant_woman;
      case 'anxiety':
        return Icons.psychology;
      case 'depression':
        return Icons.mood;
      case 'partner_support':
        return Icons.people;
      case 'general':
        return Icons.support;
      default:
        return Icons.group;
    }
  }

  IconData get platformIcon {
    switch (platform) {
      case 'online':
        return Icons.computer;
      case 'in_person':
        return Icons.location_on;
      case 'hybrid':
        return Icons.sync_alt;
      default:
        return Icons.group;
    }
  }

  String get shortDescription {
    if (description.length <= 100) return description;
    return '${description.substring(0, 100)}...';
  }

  bool get hasUrl => url != null && url!.isNotEmpty;
  bool get hasDoctorInfo => doctorInfo != null && doctorInfo!.isNotEmpty;
  bool get hasGuidelines => guidelines != null && guidelines!.isNotEmpty;
  bool get hasMeetingTime => meetingTime != null && meetingTime!.isNotEmpty;
  bool get hasMaxMembers => maxMembers != null && maxMembers! > 0;

  String get displayMeetingTime {
    if (!hasMeetingTime) return 'Meeting time TBD';
    return meetingTime!;
  }

  String get displayMaxMembers {
    if (!hasMaxMembers) return 'No limit';
    return '$maxMembers members max';
  }
}

class GroupMembership {
  final int id;
  final String userId;
  final int groupId;
  final DateTime joinedAt;
  final bool isActive;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupMembership({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.joinedAt,
    required this.isActive,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupMembership.fromJson(Map<String, dynamic> json) {
    return GroupMembership(
      id: json['id'],
      userId: json['user_id'],
      groupId: json['group_id'],
      joinedAt: DateTime.parse(json['joined_at']),
      isActive: json['is_active'] ?? true,
      role: json['role'] ?? 'member',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'group_id': groupId,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'moderator':
        return 'Moderator';
      case 'member':
        return 'Member';
      default:
        return role;
    }
  }

  Color get roleColor {
    switch (role) {
      case 'admin':
        return const Color(0xFFD32F2F); // Red
      case 'moderator':
        return const Color(0xFFFF9800); // Orange
      case 'member':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF757575); // Grey
    }
  }
}

class SupportGroupStats {
  final int totalGroups;
  final int activeGroups;
  final int totalMembers;
  final Map<String, int> groupsByCategory;
  final Map<String, int> groupsByPlatform;
  final List<SupportGroupModel> popularGroups;

  SupportGroupStats({
    required this.totalGroups,
    required this.activeGroups,
    required this.totalMembers,
    required this.groupsByCategory,
    required this.groupsByPlatform,
    required this.popularGroups,
  });

  factory SupportGroupStats.fromJson(Map<String, dynamic> json) {
    final popularGroupsList = json['popular_groups'] as List? ?? [];
    final popularGroups = popularGroupsList
        .map((group) => SupportGroupModel.fromJson(group))
        .toList();

    return SupportGroupStats(
      totalGroups: json['total_groups'] ?? 0,
      activeGroups: json['active_groups'] ?? 0,
      totalMembers: json['total_members'] ?? 0,
      groupsByCategory: Map<String, int>.from(json['groups_by_category'] ?? {}),
      groupsByPlatform: Map<String, int>.from(json['groups_by_platform'] ?? {}),
      popularGroups: popularGroups,
    );
  }
}