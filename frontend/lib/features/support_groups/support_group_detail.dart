// frontend/lib/features/support_groups/support_group_detail.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'support_groups_model.dart';
import 'support_groups_provider.dart';
import '../../providers/auth_provider.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class SupportGroupDetailScreen extends StatefulWidget {
  final SupportGroupModel group;

  const SupportGroupDetailScreen({
    super.key,
    required this.group,
  });

  @override
  State<SupportGroupDetailScreen> createState() => _SupportGroupDetailScreenState();
}

class _SupportGroupDetailScreenState extends State<SupportGroupDetailScreen> with WidgetsBindingObserver {
  bool _isJoining = false;
  bool _isLeaving = false;
  bool _hasLaunchedUrl = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supportGroupsProvider = Provider.of<SupportGroupsProvider>(context, listen: false);
      supportGroupsProvider.loadGroupMembers(widget.group.id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground after launching URL
    if (state == AppLifecycleState.resumed && _hasLaunchedUrl) {
      _hasLaunchedUrl = false;
      _showJoinConfirmationDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDarkGreyText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Support Group',
          style: TextStyle(
            color: kDarkGreyText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.group.categoryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(
                          widget.group.categoryIcon,
                          color: widget.group.categoryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.group.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.group.categoryDisplayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildGroupTag(
                        widget.group.platformDisplayName,
                        Colors.white,
                        widget.group.categoryColor,
                        widget.group.platformIcon,
                      ),
                      const SizedBox(width: 8),
                      Consumer<SupportGroupsProvider>(
                        builder: (context, provider, _) {
                          if (provider.isUserMemberOfGroup(widget.group.id)) {
                            return _buildGroupTag(
                              'Member',
                              kActionGreen,
                              Colors.white,
                              Icons.check_circle,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description Section
            _buildSection(
              'About This Group',
              Icons.info_outline,
              Text(
                widget.group.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: kDarkGreyText,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Meeting Information
            if (widget.group.hasMeetingTime) ...[
              _buildSection(
                'Meeting Schedule',
                Icons.schedule,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.displayMeetingTime,
                      style: const TextStyle(
                        fontSize: 16,
                        color: kDarkGreyText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Platform: ${widget.group.platformDisplayName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Professional Support
            if (widget.group.hasDoctorInfo) ...[
              _buildSection(
                'Professional Support',
                Icons.medical_services,
                Text(
                  widget.group.doctorInfo!,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: kDarkGreyText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Guidelines
            if (widget.group.hasGuidelines) ...[
              _buildSection(
                'Group Guidelines',
                Icons.rule,
                Text(
                  widget.group.guidelines!,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: kDarkGreyText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Group Information
            _buildSection(
              'Group Information',
              Icons.group,
              Column(
                children: [
                  _buildInfoRow('Platform', widget.group.platformDisplayName),
                  if (widget.group.hasMaxMembers) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Capacity', widget.group.displayMaxMembers),
                  ],
                  const SizedBox(height: 8),
                  Consumer<SupportGroupsProvider>(
                    builder: (context, provider, _) {
                      final memberCount = provider.getMemberCount(widget.group.id);
                      if (memberCount > 0) {
                        return _buildInfoRow('Current Members', '$memberCount members');
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Consumer<SupportGroupsProvider>(
              builder: (context, supportGroupsProvider, _) {
                final isUserMember = supportGroupsProvider.isUserMemberOfGroup(widget.group.id);

                return Column(
                  children: [
                    // Join/Leave Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isJoining || _isLeaving) ? null : () {
                          if (isUserMember) {
                            _leaveGroup();
                          } else {
                            _handleJoinGroup();
                          }
                        },
                        icon: _isJoining || _isLeaving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Icon(isUserMember ? Icons.exit_to_app : Icons.group_add),
                        label: Text(_isJoining
                            ? 'Joining...'
                            : _isLeaving
                            ? 'Leaving...'
                            : isUserMember
                            ? 'Leave Group'
                            : 'Join Group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUserMember ? Colors.red[600] : kActionGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Join Meeting Button (only for members with URL)
                    if (isUserMember && widget.group.hasUrl) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _joinMeeting(),
                          icon: const Icon(Icons.video_call),
                          label: const Text('Join Meeting'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Share Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _shareGroup(),
                        icon: const Icon(Icons.share),
                        label: const Text('Share Group'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: kPrimaryBlue),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: kPrimaryBlue, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kDarkGreyText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: content,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: kDarkGreyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupTag(String text, Color bgColor, Color fontColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fontColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: fontColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleJoinGroup() async {
    // If group has URL, open it first, then show confirmation dialog when app resumes
    if (widget.group.hasUrl) {
      try {
        final Uri groupUri = Uri.parse(widget.group.url!);
        if (await canLaunchUrl(groupUri)) {
          _hasLaunchedUrl = true;
          await launchUrl(groupUri, mode: LaunchMode.externalApplication);
          // The confirmation dialog will be shown when the app resumes
        } else {
          throw Exception('Could not launch group URL');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open group link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // If no URL, join directly
      await _joinGroupDirectly();
    }
  }

  Future<void> _showJoinConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              widget.group.categoryIcon,
              color: widget.group.categoryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Join Confirmation',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Did you successfully join "${widget.group.name}"?'),
            const SizedBox(height: 8),
            Text(
              'If you joined the group through the website or platform, tap "Yes" to add it to your joined groups.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kActionGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, I joined'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _joinGroupDirectly();
    }
  }

  Future<void> _joinGroupDirectly() async {
    setState(() {
      _isJoining = true;
    });

    final supportGroupsProvider = Provider.of<SupportGroupsProvider>(context, listen: false);
    final success = await supportGroupsProvider.joinGroup(widget.group.id);

    setState(() {
      _isJoining = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Successfully joined ${widget.group.name}!'),
              ),
            ],
          ),
          backgroundColor: kActionGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(supportGroupsProvider.error ?? 'Failed to join group'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _leaveGroup() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to leave "${widget.group.name}"?'),
            const SizedBox(height: 8),
            Text(
              'You can rejoin this group at any time.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLeaving = true;
    });

    final supportGroupsProvider = Provider.of<SupportGroupsProvider>(context, listen: false);
    final success = await supportGroupsProvider.leaveGroup(widget.group.id);

    setState(() {
      _isLeaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Left ${widget.group.name}'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(supportGroupsProvider.error ?? 'Failed to leave group'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _joinMeeting() async {
    if (!widget.group.hasUrl) return;

    try {
      final Uri meetingUri = Uri.parse(widget.group.url!);
      if (await canLaunchUrl(meetingUri)) {
        await launchUrl(meetingUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch meeting URL');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open meeting link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareGroup() {
    final shareText = '''
Check out this mental health Support Group: ${widget.group.name}

${widget.group.description}

${widget.group.hasUrl ? '\nRead more: ${widget.group.url}' : ''}

Shared from Perinatal Mental Health App
''';

    Share.share(
      shareText,
      subject: widget.group.name,
    );
  }
}
