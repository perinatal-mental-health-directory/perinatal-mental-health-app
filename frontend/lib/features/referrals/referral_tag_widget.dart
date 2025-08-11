// frontend/lib/features/referrals/referral_tag_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'referral_provider.dart';
import 'referral_model.dart';
import '../../providers/auth_provider.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);

class ReferralTagWidget extends StatelessWidget {
  final String itemId;
  final String itemType; // 'service', 'resource', 'support_group'
  final bool showDetails;
  final bool compact;

  const ReferralTagWidget({
    super.key,
    required this.itemId,
    required this.itemType,
    this.showDetails = false,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ReferralProvider>(
      builder: (context, authProvider, referralProvider, child) {
        // Only show for parents/service users
        final userRole = authProvider.user?['role'];
        if (userRole != 'service_user') {
          return const SizedBox.shrink();
        }

        // Check if this item has been referred to the user
        final referral = referralProvider.getReferralForItem(itemId, itemType);
        if (referral == null) {
          return const SizedBox.shrink();
        }

        if (showDetails) {
          return _buildDetailedReferralCard(referral);
        }

        return _buildCompactReferralTag(referral);
      },
    );
  }

  Widget _buildCompactReferralTag(ReferralModel referral) {
    Color tagColor;
    String tagText;
    IconData tagIcon;

    switch (referral.status) {
      case 'pending':
        tagColor = Colors.orange;
        tagText = 'NHS Referred';
        tagIcon = Icons.medical_services;
        break;
      case 'accepted':
        tagColor = kActionGreen;
        tagText = 'NHS Referred';
        tagIcon = Icons.check_circle;
        break;
      case 'viewed':
        tagColor = kPrimaryBlue;
        tagText = 'NHS Referred';
        tagIcon = Icons.visibility;
        break;
      case 'declined':
        return const SizedBox.shrink(); // Don't show declined referrals
      default:
        tagColor = Colors.grey;
        tagText = 'NHS Referred';
        tagIcon = Icons.info;
    }

    if (referral.isUrgent) {
      tagColor = Colors.red;
      tagText = 'URGENT NHS Referral';
      tagIcon = Icons.priority_high;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: tagColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tagIcon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            tagText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReferralCard(ReferralModel referral) {
    Color tagColor;
    String tagText;
    IconData tagIcon;

    switch (referral.status) {
      case 'pending':
        tagColor = Colors.orange;
        tagText = 'NHS Referred';
        tagIcon = Icons.medical_services;
        break;
      case 'accepted':
        tagColor = kActionGreen;
        tagText = 'NHS Referred';
        tagIcon = Icons.check_circle;
        break;
      case 'viewed':
        tagColor = kPrimaryBlue;
        tagText = 'NHS Referred';
        tagIcon = Icons.visibility;
        break;
      case 'declined':
        return const SizedBox.shrink();
      default:
        tagColor = Colors.grey;
        tagText = 'NHS Referred';
        tagIcon = Icons.info;
    }

    if (referral.isUrgent) {
      tagColor = Colors.red;
      tagText = 'URGENT NHS Referral';
      tagIcon = Icons.priority_high;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tagColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tagIcon,
                color: tagColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tagText,
                  style: TextStyle(
                    color: tagColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (referral.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Referred by: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Expanded(
                child: Text(
                  referral.referrerName ?? 'Healthcare Professional',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
          if (referral.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tagColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Referral Note:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    referral.reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatDate(referral.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              if (referral.isPending) ...[
                Consumer<ReferralProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      children: [
                        TextButton(
                          onPressed: () => _updateReferralStatus(context, referral.id, 'declined'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => _updateReferralStatus(context, referral.id, 'accepted'),
                          style: TextButton.styleFrom(
                            foregroundColor: kActionGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateReferralStatus(BuildContext context, String referralId, String status) async {
    final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
    final success = await referralProvider.updateReferralStatus(referralId, status);

    if (success && context.mounted) {
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
    } else if (context.mounted) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Wrapper widgets for easy integration
class ServiceTileWithReferral extends StatelessWidget {
  final dynamic service; // ServiceModel
  final Widget originalTile;

  const ServiceTileWithReferral({
    super.key,
    required this.service,
    required this.originalTile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReferralTagWidget(
          itemId: service.id,
          itemType: 'service',
          showDetails: true,
        ),
        originalTile,
      ],
    );
  }
}

class ResourceTileWithReferral extends StatelessWidget {
  final dynamic resource; // ResourceModel
  final Widget originalTile;

  const ResourceTileWithReferral({
    super.key,
    required this.resource,
    required this.originalTile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReferralTagWidget(
          itemId: resource.id,
          itemType: 'resource',
          showDetails: true,
        ),
        originalTile,
      ],
    );
  }
}

class SupportGroupTileWithReferral extends StatelessWidget {
  final dynamic supportGroup; // SupportGroupModel
  final Widget originalTile;

  const SupportGroupTileWithReferral({
    super.key,
    required this.supportGroup,
    required this.originalTile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReferralTagWidget(
          itemId: supportGroup.id.toString(),
          itemType: 'support_group',
          showDetails: true,
        ),
        originalTile,
      ],
    );
  }
}