// lib/features/journey/journey_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'journey_provider.dart';
import 'journey_model.dart';

/// Primary palette used throughout the app
const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final journeyProvider = Provider.of<JourneyProvider>(context, listen: false);
      journeyProvider.loadAllJourneyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          final journeyProvider = Provider.of<JourneyProvider>(context, listen: false);
          await journeyProvider.refreshAllData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Consumer<JourneyProvider>(
            builder: (context, journeyProvider, child) {
              if (journeyProvider.isStatsLoading && journeyProvider.stats == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(journeyProvider),
                  const SizedBox(height: 24),
                  _buildTodaysEntrySection(journeyProvider),
                  const SizedBox(height: 24),
                  _buildStatsOverview(journeyProvider),
                  const SizedBox(height: 24),
                  _buildActiveGoalsSection(journeyProvider),
                  const SizedBox(height: 24),
                  _buildRecentMilestonesSection(journeyProvider),
                  const SizedBox(height: 24),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(context),
        backgroundColor: kActionGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Your Journey',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: kDarkGreyText,
          fontSize: 24,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.insights, color: kPrimaryBlue),
          onPressed: () {
            // TODO: Navigate to detailed insights page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Detailed insights coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(JourneyProvider provider) {
    final stats = provider.stats;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryBlue, kPrimaryBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back! 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (stats != null) ...[
            Text(
              'You\'ve made ${stats.totalEntries} journal entries',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            if (stats.currentStreak > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.currentStreak} day streak!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            const Text(
              'Start your mental wellness journey today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodaysEntrySection(JourneyProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today\'s Check-in',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kDarkGreyText,
              ),
            ),
            if (provider.hasTodaysEntry)
              TextButton(
                onPressed: () => _showEditEntryDialog(context, provider.todaysEntry!),
                child: const Text('Edit', style: TextStyle(color: kPrimaryBlue)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: provider.hasTodaysEntry ? kLightGrey : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: provider.hasTodaysEntry ? Colors.grey[300]! : Colors.blue[200]!,
            ),
          ),
          child: provider.hasTodaysEntry
              ? _buildTodaysEntryContent(provider.todaysEntry!)
              : _buildNoEntryContent(),
        ),
      ],
    );
  }

  Widget _buildTodaysEntryContent(JourneyEntry entry) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: entry.moodColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            entry.moodEmoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mood: ${entry.moodLabel}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (entry.notes != null && entry.notes!.isNotEmpty)
                Text(
                  entry.notes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'No notes for today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoEntryContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_circle_outline,
            color: kPrimaryBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No entry yet today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to add your first entry and start tracking your mental wellness',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview(JourneyProvider provider) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kDarkGreyText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Entries',
                stats.totalEntries.toString(),
                Icons.edit_note,
                kPrimaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Current Streak',
                '${stats.currentStreak} days',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Average Mood',
                stats.averageMood.toStringAsFixed(1),
                Icons.mood,
                kActionGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Goals',
                '${stats.completedGoals}/${stats.activeGoals + stats.completedGoals}',
                Icons.flag,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGoalsSection(JourneyProvider provider) {
    final activeGoals = provider.activeGoals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Goals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kDarkGreyText,
              ),
            ),
            TextButton(
              onPressed: () => _showAddGoalDialog(context),
              child: const Text('Add Goal', style: TextStyle(color: kPrimaryBlue)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeGoals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Column(
              children: [
                Icon(Icons.flag_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No active goals yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Set your first goal to guide your journey',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...activeGoals.take(3).map((goal) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildGoalCard(goal),
          )),
      ],
    );
  }

  Widget _buildGoalCard(JourneyGoal goal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: goal.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              goal.goalTypeIcon,
              color: goal.statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  goal.goalTypeDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (goal.targetDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Target: ${goal.targetDate!.day}/${goal.targetDate!.month}/${goal.targetDate!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: goal.isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: goal.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showCompleteGoalDialog(context, goal),
            icon: const Icon(Icons.check_circle_outline, color: kActionGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMilestonesSection(JourneyProvider provider) {
    final milestones = provider.milestones;

    if (milestones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Achievements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kDarkGreyText,
          ),
        ),
        const SizedBox(height: 12),
        ...milestones.take(3).map((milestone) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMilestoneCard(milestone),
        )),
      ],
    );
  }

  Widget _buildMilestoneCard(JourneyMilestone milestone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: milestone.milestoneColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: milestone.milestoneColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            milestone.milestoneIcon,
            color: milestone.milestoneColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (milestone.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    milestone.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kDarkGreyText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'View History',
                Icons.history,
                    () {
                  // TODO: Navigate to journey history
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Journey history coming soon!')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Insights',
                Icons.analytics,
                    () {
                  // TODO: Navigate to detailed insights
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Detailed insights coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: kPrimaryBlue, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kDarkGreyText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showAddEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddEntryDialog(),
    );
  }

  void _showEditEntryDialog(BuildContext context, JourneyEntry entry) {
    showDialog(
      context: context,
      builder: (context) => _EditEntryDialog(entry: entry),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddGoalDialog(),
    );
  }

  void _showCompleteGoalDialog(BuildContext context, JourneyGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Goal?'),
        content: Text('Mark "${goal.title}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<JourneyProvider>(context, listen: false);
              final success = await provider.completeGoal(goal.id);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Goal completed! 🎉')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kActionGreen),
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Simple Add Entry Dialog
class _AddEntryDialog extends StatefulWidget {
  @override
  State<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<_AddEntryDialog> {
  int _moodRating = 3;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Today\'s Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How are you feeling today?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final emojis = ['😢', '😟', '😐', '😊', '😄'];
              return InkWell(
                onTap: () => setState(() => _moodRating = rating),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _moodRating == rating ? kPrimaryBlue.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final provider = Provider.of<JourneyProvider>(context, listen: false);
            final request = CreateJourneyEntryRequest(
              moodRating: _moodRating,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
            );

            final success = await provider.createJourneyEntry(request);

            if (success && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry added successfully!')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: kActionGreen),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Simple Edit Entry Dialog
class _EditEntryDialog extends StatefulWidget {
  final JourneyEntry entry;

  const _EditEntryDialog({required this.entry});

  @override
  State<_EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<_EditEntryDialog> {
  late int _moodRating;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _moodRating = widget.entry.moodRating;
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How are you feeling?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final emojis = ['😢', '😟', '😐', '😊', '😄'];
              return InkWell(
                onTap: () => setState(() => _moodRating = rating),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _moodRating == rating ? kPrimaryBlue.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final provider = Provider.of<JourneyProvider>(context, listen: false);
            final updates = {
              'mood_rating': _moodRating,
              'notes': _notesController.text.isEmpty ? null : _notesController.text,
            };

            final success = await provider.updateJourneyEntry(widget.entry.id, updates);

            if (success && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry updated successfully!')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: kActionGreen),
          child: const Text('Update', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Simple Add Goal Dialog
class _AddGoalDialog extends StatefulWidget {
  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _titleController = TextEditingController();
  String _goalType = 'mood';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Goal Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _goalType,
            decoration: const InputDecoration(
              labelText: 'Goal Type',
              border: OutlineInputBorder(),
            ),
            items: JourneyConstants.goalTypeDisplayNames.entries
                .map((entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            ))
                .toList(),
            onChanged: (value) => setState(() => _goalType = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_titleController.text.trim().isEmpty) return;

            final provider = Provider.of<JourneyProvider>(context, listen: false);
            final request = CreateJourneyGoalRequest(
              title: _titleController.text.trim(),
              goalType: _goalType,
            );

            final success = await provider.createJourneyGoal(request);

            if (success && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal added successfully!')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: kActionGreen),
          child: const Text('Add Goal', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}