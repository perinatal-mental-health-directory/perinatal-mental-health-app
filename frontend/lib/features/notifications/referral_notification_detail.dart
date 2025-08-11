// frontend/lib/features/notifications/referral_notification_detail.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../referrals/referral_model.dart';
import '../referrals/referral_provider.dart';
import '../services/services_provider.dart';
import '../services/service_detail.dart';
import '../resources/resources_provider.dart';
import '../resources/resources_detail.dart';
import '../support_groups/support_groups_provider.dart';
import '../support_groups/support_group_detail.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class ReferralNotificationDetail extends StatefulWidget {
  final ReferralModel referral;

  const ReferralNotificationDetail({
    super.key,
    required this.referral,
  });

  @override
  State<ReferralNotificationDetail> createState() => _ReferralNotificationDetailState();
}

class _ReferralNotificationDetailState extends State<ReferralNotificationDetail> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Mark as viewed if it was pending
    if (widget.referral.isPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markAsViewed();
      });
    }
  }

  Future<void> _markAsViewed() async {
    final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
    await referralProvider.updateReferralStatus(widget.referral.id, 'viewed');
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
          'Referral Details',
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
                color: widget.referral.statusColor,
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
                          widget.referral.referralTypeIcon,
                          color: widget.referral.statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.referral.itemTitle ?? 'Unknown Item',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.referral.referralTypeDisplayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.referral.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.referral.statusIcon,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.referral.statusDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Referred by Section
            _buildSection(
              'Referred by',
              Icons.person,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.referral.referrerName ?? 'Healthcare Professional',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kDarkGreyText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NHS Healthcare Professional',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Referral Note Section
            _buildSection(
              'Referral Note',
              Icons.message,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kLightGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  widget.referral.reason,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: kDarkGreyText,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Item Description (if available)
            if (widget.referral.itemDescription != null && widget.referral.itemDescription!.isNotEmpty) ...[
              _buildSection(
                'About this ${widget.referral.referralTypeDisplayName}',
                Icons.info_outline,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    widget.referral.itemDescription!,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: kDarkGreyText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Referral Information
            _buildSection(
              'Referral Information',
              Icons.assignment,
              Column(
                children: [
                  _buildInfoRow('Referral Type', widget.referral.referralTypeDisplayName),
                  _buildInfoRow('Status', widget.referral.statusDisplayName),
                  _buildInfoRow('Priority', widget.referral.urgencyText),
                  _buildInfoRow('Received', _formatDate(widget.referral.createdAt)),
                  if (widget.referral.updatedAt != widget.referral.createdAt)
                    _buildInfoRow('Last Updated', _formatDate(widget.referral.updatedAt)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons (only for pending referrals)
            if (widget.referral.isPending || widget.referral.isViewed) ...[
              Consumer<ReferralProvider>(
                builder: (context, referralProvider, _) {
                  return Column(
                    children: [
                      // Accept Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUpdating ? null : () => _updateReferralStatus('accepted'),
                          icon: _isUpdating
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Icon(Icons.check_circle),
                          label: Text(_isUpdating ? 'Processing...' : 'Accept & View ${widget.referral.referralTypeDisplayName}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kActionGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Decline Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isUpdating ? null : () => _showDeclineDialog(),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Decline Referral'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ] else if (widget.referral.isAccepted) ...[
              // Show accepted status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kActionGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kActionGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: kActionGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have accepted this referral',
                        style: TextStyle(
                          color: kActionGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (widget.referral.isDeclined) ...[
              // Show declined status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cancel,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have declined this referral',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kDarkGreyText,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: kDarkGreyText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _updateReferralStatus(String status) async {
    setState(() {
      _isUpdating = true;
    });

    final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
    final success = await referralProvider.updateReferralStatus(widget.referral.id, status);

    setState(() {
      _isUpdating = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Referral accepted successfully'
                : 'Referral declined',
          ),
          backgroundColor: status == 'accepted' ? kActionGreen : Colors.orange,
        ),
      );

      // If accepted, navigate to the referred item
      if (status == 'accepted') {
        // Show loading message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Opening ${widget.referral.referralTypeDisplayName.toLowerCase()}...'),
              ],
            ),
            backgroundColor: kPrimaryBlue,
            duration: const Duration(seconds: 1),
          ),
        );

        await _navigateToReferredItem();
      } else {
        // Close the screen after decline
        Navigator.pop(context);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            referralProvider.error ?? 'Failed to update referral status',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToReferredItem() async {
    try {
      switch (widget.referral.referralType) {
        case 'service':
          await _navigateToService();
          break;
        case 'resource':
          await _navigateToResource();
          break;
        case 'support_group':
          await _navigateToSupportGroup();
          break;
        default:
        // Just close the screen if we don't know the type
          Navigator.pop(context);
      }
    } catch (e) {
      print('Error navigating to referred item: $e');
      // Close the screen if navigation fails
      Navigator.pop(context);
    }
  }

  Future<void> _navigateToService() async {
    try {
      // Load the full service details
      final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
      await servicesProvider.loadServiceDetails(widget.referral.itemId);

      if (servicesProvider.selectedService != null && mounted) {
        // Close current screen first
        Navigator.pop(context);

        // Navigate to service detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(service: servicesProvider.selectedService!),
          ),
        );
      } else {
        throw Exception('Service not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open service details'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _navigateToResource() async {
    try {
      // Load the full resource details
      final resourcesProvider = Provider.of<ResourcesProvider>(context, listen: false);
      await resourcesProvider.loadResourceDetails(widget.referral.itemId);

      if (resourcesProvider.selectedResource != null && mounted) {
        // Close current screen first
        Navigator.pop(context);

        // Navigate to resource detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceDetailScreen(resource: resourcesProvider.selectedResource!),
          ),
        );
      } else {
        throw Exception('Resource not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open resource details'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _navigateToSupportGroup() async {
    try {
      // Load the full support group details
      final supportGroupsProvider = Provider.of<SupportGroupsProvider>(context, listen: false);
      await supportGroupsProvider.loadSupportGroupDetails(int.parse(widget.referral.itemId));

      if (supportGroupsProvider.selectedGroup != null && mounted) {
        // Close current screen first
        Navigator.pop(context);

        // Navigate to support group detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SupportGroupDetailScreen(group: supportGroupsProvider.selectedGroup!),
          ),
        );
      } else {
        throw Exception('Support group not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open support group details'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showDeclineDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Referral'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to decline this ${widget.referral.referralTypeDisplayName.toLowerCase()}?'),
            const SizedBox(height: 8),
            Text(
              'This will notify the healthcare professional that you have declined their referral.',
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
              'Decline',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateReferralStatus('declined');
    }
  }
}