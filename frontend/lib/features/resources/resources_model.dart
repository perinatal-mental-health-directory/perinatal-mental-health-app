// frontend/lib/features/resources/resources_model.dart
import 'package:flutter/material.dart';

class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String resourceType;
  final String? url;
  final String? author;
  final List<String> tags;
  final String targetAudience;
  final int? estimatedReadTime;
  final bool isFeatured;
  final bool isActive;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.resourceType,
    this.url,
    this.author,
    required this.tags,
    required this.targetAudience,
    this.estimatedReadTime,
    required this.isFeatured,
    required this.isActive,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      content: json['content'],
      resourceType: json['resource_type'],
      url: json['url'],
      author: json['author'],
      tags: List<String>.from(json['tags'] ?? []),
      targetAudience: json['target_audience'],
      estimatedReadTime: json['estimated_read_time'],
      isFeatured: json['is_featured'] ?? false,
      isActive: json['is_active'] ?? true,
      viewCount: json['view_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'resource_type': resourceType,
      'url': url,
      'author': author,
      'tags': tags,
      'target_audience': targetAudience,
      'estimated_read_time': estimatedReadTime,
      'is_featured': isFeatured,
      'is_active': isActive,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get resourceTypeDisplayName {
    switch (resourceType) {
      case 'article':
        return 'Article';
      case 'video':
        return 'Video';
      case 'pdf':
        return 'PDF';
      case 'external_link':
        return 'External Link';
      case 'infographic':
        return 'Infographic';
      default:
        return resourceType;
    }
  }

  Color get resourceTypeColor {
    switch (resourceType) {
      case 'article':
        return const Color(0xFF2196F3); // Blue
      case 'video':
        return const Color(0xFFE91E63); // Pink
      case 'pdf':
        return const Color(0xFFF44336); // Red
      case 'external_link':
        return const Color(0xFF9C27B0); // Purple
      case 'infographic':
        return const Color(0xFF00BCD4); // Cyan
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  IconData get resourceTypeIcon {
    switch (resourceType) {
      case 'article':
        return Icons.article;
      case 'video':
        return Icons.play_circle_filled;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'external_link':
        return Icons.link;
      case 'infographic':
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  String get shortDescription {
    if (description.length <= 120) return description;
    return '${description.substring(0, 120)}...';
  }

  String get targetAudienceDisplayName {
    switch (targetAudience) {
      case 'new_mothers':
        return 'New Mothers';
      case 'professionals':
        return 'Professionals';
      case 'general':
        return 'General';
      case 'partners':
        return 'Partners';
      case 'families':
        return 'Families';
      default:
        return targetAudience;
    }
  }

  String get estimatedReadTimeText {
    if (estimatedReadTime == null) return '';
    if (estimatedReadTime == 1) return '1 min read';
    return '$estimatedReadTime mins read';
  }

  bool get hasUrl => url != null && url!.isNotEmpty;

  bool get hasAuthor => author != null && author!.isNotEmpty;
}