// lib/features/journey/journey_provider.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'journey_model.dart';

class JourneyProvider with ChangeNotifier {
  // Journey Entries
  List<JourneyEntry> _entries = [];
  JourneyEntry? _todaysEntry;
  bool _isEntriesLoading = false;
  bool _isTodaysEntryLoading = false;

  // Journey Goals
  List<JourneyGoal> _goals = [];
  bool _isGoalsLoading = false;

  // Journey Stats & Analytics
  JourneyStats? _stats;
  JourneyInsights? _insights;
  List<JourneyMilestone> _milestones = [];
  bool _isStatsLoading = false;
  bool _isInsightsLoading = false;
  bool _isMilestonesLoading = false;

  // Error handling
  String? _error;

  // Getters
  List<JourneyEntry> get entries => _entries;
  JourneyEntry? get todaysEntry => _todaysEntry;
  bool get isEntriesLoading => _isEntriesLoading;
  bool get isTodaysEntryLoading => _isTodaysEntryLoading;

  List<JourneyGoal> get goals => _goals;
  List<JourneyGoal> get activeGoals => _goals.where((g) => g.status == 'active').toList();
  List<JourneyGoal> get completedGoals => _goals.where((g) => g.status == 'completed').toList();
  bool get isGoalsLoading => _isGoalsLoading;

  JourneyStats? get stats => _stats;
  JourneyInsights? get insights => _insights;
  List<JourneyMilestone> get milestones => _milestones;
  bool get isStatsLoading => _isStatsLoading;
  bool get isInsightsLoading => _isInsightsLoading;
  bool get isMilestonesLoading => _isMilestonesLoading;

  String? get error => _error;

  // Clear error method
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Journey Entries Methods

  // Create a new journey entry
  Future<bool> createJourneyEntry(CreateJourneyEntryRequest request) async {
    _error = null;
    notifyListeners();

    try {
      final entryData = await ApiService.createJourneyEntry(request);
      final newEntry = JourneyEntry.fromJson(entryData);

      // Add to entries list and sort by date
      _entries.insert(0, newEntry);
      _entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));

      // Update today's entry if it's for today
      final today = DateTime.now();
      if (newEntry.entryDate.year == today.year &&
          newEntry.entryDate.month == today.month &&
          newEntry.entryDate.day == today.day) {
        _todaysEntry = newEntry;
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Create journey entry failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Get today's entry
  Future<void> loadTodaysEntry() async {
    _isTodaysEntryLoading = true;
    _error = null;
    notifyListeners();

    try {
      final entryData = await ApiService.getTodaysJourneyEntry();
      _todaysEntry = JourneyEntry.fromJson(entryData);
      print('Today\'s entry loaded successfully');
    } catch (e) {
      print('Load today\'s entry failed: $e');
      _todaysEntry = null;
      // Don't set error for missing today's entry - it's normal
    }

    _isTodaysEntryLoading = false;
    notifyListeners();
  }

  // Load journey entries
  Future<void> loadJourneyEntries({
    int page = 1,
    int pageSize = 30,
    String? startDate,
    String? endDate,
    bool isInitialLoad = false,
  }) async {
    if (isInitialLoad) {
      _isEntriesLoading = true;
      _entries.clear();
    }
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getJourneyEntries(
        page: page,
        pageSize: pageSize,
        startDate: startDate,
        endDate: endDate,
      );

      final List<JourneyEntry> newEntries = (response['entries'] as List)
          .map((entry) => JourneyEntry.fromJson(entry))
          .toList();

      if (isInitialLoad || page == 1) {
        _entries = newEntries;
      } else {
        _entries.addAll(newEntries);
      }

      print('Journey entries loaded: ${newEntries.length} entries');
    } catch (e) {
      print('Load journey entries failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isEntriesLoading = false;
    notifyListeners();
  }

  // Update journey entry
  Future<bool> updateJourneyEntry(String entryId, Map<String, dynamic> updates) async {
    _error = null;
    notifyListeners();

    try {
      final entryData = await ApiService.updateJourneyEntry(entryId, updates);
      final updatedEntry = JourneyEntry.fromJson(entryData);

      // Update in entries list
      final index = _entries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        _entries[index] = updatedEntry;
      }

      // Update today's entry if it matches
      if (_todaysEntry?.id == entryId) {
        _todaysEntry = updatedEntry;
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Update journey entry failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Delete journey entry
  Future<bool> deleteJourneyEntry(String entryId) async {
    _error = null;
    notifyListeners();

    try {
      await ApiService.deleteJourneyEntry(entryId);

      // Remove from entries list
      _entries.removeWhere((e) => e.id == entryId);

      // Clear today's entry if it matches
      if (_todaysEntry?.id == entryId) {
        _todaysEntry = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Delete journey entry failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Journey Goals Methods

  // Create a new journey goal
  Future<bool> createJourneyGoal(CreateJourneyGoalRequest request) async {
    _error = null;
    notifyListeners();

    try {
      final goalData = await ApiService.createJourneyGoal(request);
      final newGoal = JourneyGoal.fromJson(goalData);

      _goals.insert(0, newGoal);

      notifyListeners();
      return true;
    } catch (e) {
      print('Create journey goal failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Load journey goals
  Future<void> loadJourneyGoals({String? status}) async {
    _isGoalsLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getJourneyGoals(status: status);

      final List<JourneyGoal> loadedGoals = (response['goals'] as List)
          .map((goal) => JourneyGoal.fromJson(goal))
          .toList();

      _goals = loadedGoals;
      print('Journey goals loaded: ${loadedGoals.length} goals');
    } catch (e) {
      print('Load journey goals failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isGoalsLoading = false;
    notifyListeners();
  }

  // Update journey goal
  Future<bool> updateJourneyGoal(String goalId, Map<String, dynamic> updates) async {
    _error = null;
    notifyListeners();

    try {
      final goalData = await ApiService.updateJourneyGoal(goalId, updates);
      final updatedGoal = JourneyGoal.fromJson(goalData);

      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        _goals[index] = updatedGoal;
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Update journey goal failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Delete journey goal
  Future<bool> deleteJourneyGoal(String goalId) async {
    _error = null;
    notifyListeners();

    try {
      await ApiService.deleteJourneyGoal(goalId);
      _goals.removeWhere((g) => g.id == goalId);

      notifyListeners();
      return true;
    } catch (e) {
      print('Delete journey goal failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Complete goal
  Future<bool> completeGoal(String goalId) async {
    return updateJourneyGoal(goalId, {'status': 'completed'});
  }

  // Analytics Methods

  // Load journey statistics
  Future<void> loadJourneyStats() async {
    _isStatsLoading = true;
    _error = null;
    notifyListeners();

    try {
      final statsData = await ApiService.getJourneyStats();
      _stats = JourneyStats.fromJson(statsData);
      print('Journey stats loaded successfully');
    } catch (e) {
      print('Load journey stats failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isStatsLoading = false;
    notifyListeners();
  }

  // Load journey insights
  Future<void> loadJourneyInsights() async {
    _isInsightsLoading = true;
    _error = null;
    notifyListeners();

    try {
      final insightsData = await ApiService.getJourneyInsights();
      _insights = JourneyInsights.fromJson(insightsData);
      print('Journey insights loaded successfully');
    } catch (e) {
      print('Load journey insights failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isInsightsLoading = false;
    notifyListeners();
  }

  // Load journey milestones
  Future<void> loadJourneyMilestones({int limit = 10}) async {
    _isMilestonesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getJourneyMilestones(limit: limit);

      final List<JourneyMilestone> loadedMilestones = (response['milestones'] as List)
          .map((milestone) => JourneyMilestone.fromJson(milestone))
          .toList();

      _milestones = loadedMilestones;
      print('Journey milestones loaded: ${loadedMilestones.length} milestones');
    } catch (e) {
      print('Load journey milestones failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isMilestonesLoading = false;
    notifyListeners();
  }

  // Utility Methods

  // Load all journey data
  Future<void> loadAllJourneyData() async {
    await Future.wait([
      loadTodaysEntry(),
      loadJourneyEntries(isInitialLoad: true),
      loadJourneyGoals(),
      loadJourneyStats(),
      loadJourneyInsights(),
      loadJourneyMilestones(),
    ]);
  }

  // Check if user has entry for today
  bool get hasTodaysEntry => _todaysEntry != null;

  // Get entry for specific date
  JourneyEntry? getEntryForDate(DateTime date) {
    return _entries.firstWhere(
          (entry) =>
      entry.entryDate.year == date.year &&
          entry.entryDate.month == date.month &&
          entry.entryDate.day == date.day,
      orElse: () => null as JourneyEntry,
    );
  }

  // Get mood streak information
  int get currentMoodStreak => _stats?.currentStreak ?? 0;
  int get longestMoodStreak => _stats?.longestStreak ?? 0;

  // Get recent entries for quick access
  List<JourneyEntry> get recentEntries => _entries.take(7).toList();

  // Get weekly mood chart data
  List<DailyMoodData> get weeklyMoodData => _stats?.weeklyMoodData ?? [];

  // Check if user has any goals
  bool get hasGoals => _goals.isNotEmpty;

  // Check if user has active goals
  bool get hasActiveGoals => activeGoals.isNotEmpty;

  // Get overdue goals
  List<JourneyGoal> get overdueGoals =>
      _goals.where((goal) => goal.isOverdue).toList();

  // Get goals by type
  List<JourneyGoal> getGoalsByType(String type) =>
      _goals.where((goal) => goal.goalType == type).toList();

  // Get average mood for period
  double getAverageMoodForPeriod(List<JourneyEntry> entries) {
    if (entries.isEmpty) return 0.0;

    int totalMood = entries.fold(0, (sum, entry) => sum + entry.moodRating);
    return totalMood / entries.length;
  }

  // Get mood trend for recent entries
  String getMoodTrendForEntries(List<JourneyEntry> entries) {
    if (entries.length < 3) return 'stable';

    // Take first 3 and last 3 entries
    final recentEntries = entries.take(3).toList();
    final olderEntries = entries.skip(entries.length - 3).take(3).toList();

    final recentAvg = getAverageMoodForPeriod(recentEntries);
    final olderAvg = getAverageMoodForPeriod(olderEntries);

    final diff = recentAvg - olderAvg;

    if (diff > 0.3) return 'improving';
    if (diff < -0.3) return 'declining';
    return 'stable';
  }

  // Clear all data (for logout)
  void clearAllData() {
    _entries.clear();
    _todaysEntry = null;
    _goals.clear();
    _stats = null;
    _insights = null;
    _milestones.clear();
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    await loadAllJourneyData();
  }
}