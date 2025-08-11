// lib/features/journey/journey_model.dart

import 'package:flutter/material.dart';

class JourneyEntry {
  final String id;
  final String userId;
  final DateTime entryDate;
  final int moodRating;
  final int? anxietyLevel;
  final int? sleepQuality;
  final int? energyLevel;
  final String? notes;
  final List<String> activities;
  final List<String> symptoms;
  final String? gratitudeNote;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  JourneyEntry({
    required this.id,
    required this.userId,
    required this.entryDate,
    required this.moodRating,
    this.anxietyLevel,
    this.sleepQuality,
    this.energyLevel,
    this.notes,
    this.activities = const [],
    this.symptoms = const [],
    this.gratitudeNote,
    this.isPrivate = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JourneyEntry.fromJson(Map<String, dynamic> json) {
    return JourneyEntry(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      entryDate: DateTime.parse(json['entry_date']),
      moodRating: json['mood_rating'] ?? 3,
      anxietyLevel: json['anxiety_level'],
      sleepQuality: json['sleep_quality'],
      energyLevel: json['energy_level'],
      notes: json['notes'],
      activities: List<String>.from(json['activities'] ?? []),
      symptoms: List<String>.from(json['symptoms'] ?? []),
      gratitudeNote: json['gratitude_note'],
      isPrivate: json['is_private'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'entry_date': entryDate.toIso8601String().split('T')[0],
      'mood_rating': moodRating,
      'anxiety_level': anxietyLevel,
      'sleep_quality': sleepQuality,
      'energy_level': energyLevel,
      'notes': notes,
      'activities': activities,
      'symptoms': symptoms,
      'gratitude_note': gratitudeNote,
      'is_private': isPrivate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get moodEmoji {
    switch (moodRating) {
      case 1:
        return '😢';
      case 2:
        return '😟';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  String get moodLabel {
    switch (moodRating) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }

  Color get moodColor {
    switch (moodRating) {
      case 1:
        return Colors.red[700]!;
      case 2:
        return Colors.orange[700]!;
      case 3:
        return Colors.grey[600]!;
      case 4:
        return Colors.green[600]!;
      case 5:
        return Colors.green[800]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

class JourneyGoal {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final String goalType;
  final String status;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  JourneyGoal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.targetDate,
    required this.goalType,
    required this.status,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JourneyGoal.fromJson(Map<String, dynamic> json) {
    return JourneyGoal(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : null,
      goalType: json['goal_type'] ?? '',
      status: json['status'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'target_date': targetDate?.toIso8601String().split('T')[0],
      'goal_type': goalType,
      'status': status,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get goalTypeDisplayName {
    switch (goalType) {
      case 'mood':
        return 'Mood Improvement';
      case 'sleep':
        return 'Sleep Quality';
      case 'exercise':
        return 'Physical Activity';
      case 'mindfulness':
        return 'Mindfulness & Meditation';
      case 'social':
        return 'Social Connection';
      case 'custom':
        return 'Personal Goal';
      default:
        return 'Goal';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'active':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'paused':
        return 'Paused';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get goalTypeIcon {
    switch (goalType) {
      case 'mood':
        return Icons.mood;
      case 'sleep':
        return Icons.bedtime;
      case 'exercise':
        return Icons.fitness_center;
      case 'mindfulness':
        return Icons.self_improvement;
      case 'social':
        return Icons.people;
      case 'custom':
        return Icons.flag;
      default:
        return Icons.flag;
    }
  }

  bool get isOverdue {
    if (targetDate == null || isCompleted) return false;
    return DateTime.now().isAfter(targetDate!);
  }
}

class JourneyMilestone {
  final String id;
  final String userId;
  final String milestoneType;
  final String title;
  final String? description;
  final DateTime achievedAt;
  final DateTime createdAt;

  JourneyMilestone({
    required this.id,
    required this.userId,
    required this.milestoneType,
    required this.title,
    this.description,
    required this.achievedAt,
    required this.createdAt,
  });

  factory JourneyMilestone.fromJson(Map<String, dynamic> json) {
    return JourneyMilestone(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      milestoneType: json['milestone_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      achievedAt: DateTime.parse(json['achieved_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  IconData get milestoneIcon {
    switch (milestoneType) {
      case 'first_entry':
        return Icons.start;
      case 'week_streak':
        return Icons.local_fire_department;
      case 'month_streak':
        return Icons.emoji_events;
      case 'first_goal':
        return Icons.flag;
      case 'mood_stable':
        return Icons.favorite;
      case 'year_complete':
        return Icons.celebration;
      default:
        return Icons.star;
    }
  }

  Color get milestoneColor {
    switch (milestoneType) {
      case 'first_entry':
        return Colors.blue;
      case 'week_streak':
        return Colors.orange;
      case 'month_streak':
        return Colors.amber;
      case 'first_goal':
        return Colors.purple;
      case 'mood_stable':
        return Colors.pink;
      case 'year_complete':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }
}

class JourneyStats {
  final int totalEntries;
  final int currentStreak;
  final int longestStreak;
  final double averageMood;
  final String moodTrend;
  final int completedGoals;
  final int activeGoals;
  final int totalMilestones;
  final List<JourneyMilestone> recentMilestones;
  final Map<String, int> moodBreakdown;
  final List<DailyMoodData> weeklyMoodData;

  JourneyStats({
    required this.totalEntries,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageMood,
    required this.moodTrend,
    required this.completedGoals,
    required this.activeGoals,
    required this.totalMilestones,
    required this.recentMilestones,
    required this.moodBreakdown,
    required this.weeklyMoodData,
  });

  factory JourneyStats.fromJson(Map<String, dynamic> json) {
    return JourneyStats(
      totalEntries: json['total_entries'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      averageMood: (json['average_mood'] ?? 0.0).toDouble(),
      moodTrend: json['mood_trend'] ?? 'stable',
      completedGoals: json['completed_goals'] ?? 0,
      activeGoals: json['active_goals'] ?? 0,
      totalMilestones: json['total_milestones'] ?? 0,
      recentMilestones: (json['recent_milestones'] as List?)
          ?.map((m) => JourneyMilestone.fromJson(m))
          .toList() ?? [],
      moodBreakdown: Map<String, int>.from(json['mood_breakdown'] ?? {}),
      weeklyMoodData: (json['weekly_mood_data'] as List?)
          ?.map((d) => DailyMoodData.fromJson(d))
          .toList() ?? [],
    );
  }

  String get moodTrendDisplayName {
    switch (moodTrend) {
      case 'improving':
        return 'Improving';
      case 'declining':
        return 'Needs Attention';
      case 'stable':
        return 'Stable';
      default:
        return 'Unknown';
    }
  }

  Color get moodTrendColor {
    switch (moodTrend) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      case 'stable':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get moodTrendIcon {
    switch (moodTrend) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      case 'stable':
        return Icons.trending_flat;
      default:
        return Icons.help;
    }
  }
}

class DailyMoodData {
  final String date;
  final int? moodRating;
  final bool hasEntry;

  DailyMoodData({
    required this.date,
    this.moodRating,
    required this.hasEntry,
  });

  factory DailyMoodData.fromJson(Map<String, dynamic> json) {
    return DailyMoodData(
      date: json['date'] ?? '',
      moodRating: json['mood_rating'],
      hasEntry: json['has_entry'] ?? false,
    );
  }
}

class JourneyInsights {
  final List<String> moodPatterns;
  final List<String> recommendations;
  final List<String> achievements;
  final List<String> nextGoals;

  JourneyInsights({
    required this.moodPatterns,
    required this.recommendations,
    required this.achievements,
    required this.nextGoals,
  });

  factory JourneyInsights.fromJson(Map<String, dynamic> json) {
    return JourneyInsights(
      moodPatterns: List<String>.from(json['mood_patterns'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      achievements: List<String>.from(json['achievements'] ?? []),
      nextGoals: List<String>.from(json['next_goals'] ?? []),
    );
  }
}

// Request models for creating/updating entries
class CreateJourneyEntryRequest {
  final String? entryDate; // YYYY-MM-DD format
  final int moodRating;
  final int? anxietyLevel;
  final int? sleepQuality;
  final int? energyLevel;
  final String? notes;
  final List<String> activities;
  final List<String> symptoms;
  final String? gratitudeNote;
  final bool isPrivate;

  CreateJourneyEntryRequest({
    this.entryDate,
    required this.moodRating,
    this.anxietyLevel,
    this.sleepQuality,
    this.energyLevel,
    this.notes,
    this.activities = const [],
    this.symptoms = const [],
    this.gratitudeNote,
    this.isPrivate = true,
  });

  Map<String, dynamic> toJson() {
    return {
      if (entryDate != null) 'entry_date': entryDate,
      'mood_rating': moodRating,
      if (anxietyLevel != null) 'anxiety_level': anxietyLevel,
      if (sleepQuality != null) 'sleep_quality': sleepQuality,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (notes != null) 'notes': notes,
      'activities': activities,
      'symptoms': symptoms,
      if (gratitudeNote != null) 'gratitude_note': gratitudeNote,
      'is_private': isPrivate,
    };
  }
}

class CreateJourneyGoalRequest {
  final String title;
  final String? description;
  final String? targetDate; // YYYY-MM-DD format
  final String goalType;

  CreateJourneyGoalRequest({
    required this.title,
    this.description,
    this.targetDate,
    required this.goalType,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (targetDate != null) 'target_date': targetDate,
      'goal_type': goalType,
    };
  }
}

// Predefined activities and symptoms for easy selection
class JourneyConstants {
  static const List<String> commonActivities = [
    'Exercise',
    'Meditation',
    'Reading',
    'Social time',
    'Work',
    'Self-care',
    'Therapy',
    'Nature walk',
    'Creative activity',
    'Music',
    'Cooking',
    'Cleaning',
  ];

  static const List<String> commonSymptoms = [
    'Anxiety',
    'Sadness',
    'Stress',
    'Fatigue',
    'Irritability',
    'Mood swings',
    'Sleep issues',
    'Worry',
    'Overwhelmed',
    'Restlessness',
    'Difficulty concentrating',
    'Physical tension',
  ];

  static const List<String> goalTypes = [
    'mood',
    'sleep',
    'exercise',
    'mindfulness',
    'social',
    'custom',
  ];

  static const Map<String, String> goalTypeDisplayNames = {
    'mood': 'Mood Improvement',
    'sleep': 'Sleep Quality',
    'exercise': 'Physical Activity',
    'mindfulness': 'Mindfulness & Meditation',
    'social': 'Social Connection',
    'custom': 'Personal Goal',
  };
}