// frontend/lib/features/referrals/referrals_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'referral_provider.dart';
import 'referral_model.dart';
import 'create_referral_screen.dart';
import '../../providers/auth_provider.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class ReferralsListScreen extends StatefulWidget {
  const ReferralsListScreen({super.key});

  @override
  State<ReferralsListScreen> createState() => _ReferralsListScreenState();
}

class _ReferralsListScreenState extends State<ReferralsListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _sentScrollController = ScrollController();
  final ScrollController _receivedScrollController = ScrollController();

  String _selectedStatus = '';
  String _selectedType = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Load appropriate data based on user role
      final userRole = authProvider.user?['role'];
      if (userRole == 'professional' || userRole == 'nhs_staff') {
        referralProvider.loadSentReferrals(refresh: true);
        _tabController.index = 0; // Start with sent referrals for professionals
      } else {
        referralProvider.loadReceivedReferrals(refresh: true);
        _tabController.index = 1; // Start with received referrals for parents
      }
    });

    // Add scroll listeners for pagination
    _sentScrollController.addListener(() {
      if (_sentScrollController.position.pixels >=
          _sentScrollController.position.maxScrollExtent - 200) {
        final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
        referralProvider.loadMoreSentReferrals();
      }
    });

    _receivedScrollController.addListener(() {
      if (_receivedScrollController.position.pixels >=
          _receivedScrollController.position.maxScrollExtent - 200) {
        final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
        referralProvider.loadMoreReceivedReferrals();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sentScrollController.dispose();
    _receivedScrollController.dispose();
    super.dispose();
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
          'Referrals',
          style: TextStyle(
            color: kDarkGreyText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final userRole = authProvider.user?['role'];
              if (userRole == 'professional' || userRole == 'nhs_staff') {
                return IconButton(
                  icon: const Icon(Icons.add, color: kPrimaryBlue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateReferralScreen()),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: _buildAppBarBottom(),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final userRole = authProvider.user?['role'];

          if (userRole == 'service_user') {
            // Parents only see received referrals
            return _buildReceivedReferralsTab();
          }

          return Column(
            children: [
              // Filter Section
              _buildFilterSection(),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSentReferralsTab(),
                    _buildReceivedReferralsTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Filter
          Row(
            children: [
              const Text(
                'Status: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', '', _selectedStatus),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending', _selectedStatus),
                      const SizedBox(width: 8),
                      _buildFilterChip('Accepted', 'accepted', _selectedStatus),
                      const SizedBox(width: 8),
                      _buildFilterChip('Declined', 'declined', _selectedStatus),
                      const SizedBox(width: 8),
                      _buildFilterChip('Viewed', 'viewed', _selectedStatus),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Type Filter
          Row(
            children: [
              const Text(
                'Type: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', '', _selectedType),
                      const SizedBox(width: 8),
                      _buildFilterChip('Services', 'service', _selectedType),
                      const SizedBox(width: 8),
                      _buildFilterChip('Resources', 'resource', _selectedType),
                      const SizedBox(width: 8),
                      _buildFilterChip('Groups', 'support_group', _selectedType),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue) {
    final isSelected = selectedValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (label.contains('All')) {
            if (label == 'All' && _selectedStatus == value) {
              _selectedStatus = '';
            } else if (label == 'All' && _selectedType == value) {
              _selectedType = '';
            } else {
              if (value == '') {
                _selectedStatus = '';
              } else {
                _selectedType = '';
              }
            }
          } else {
            if (['pending', 'accepted', 'declined', 'viewed'].contains(value)) {
              _selectedStatus = selected ? value : '';
            } else {
              _selectedType = selected ? value : '';
            }
          }
        });
        _applyFilters();
      },
      selectedColor: kPrimaryBlue.withOpacity(0.2),
      checkmarkColor: kPrimaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? kPrimaryBlue : kDarkGreyText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? kPrimaryBlue : Colors.grey[300]!,
      ),
    );
  }

  void _applyFilters() {
    final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
    if (_tabController.index == 0) {
      referralProvider.loadSentReferrals(
        refresh: true,
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        referralType: _selectedType.isEmpty ? null : _selectedType,
      );
    } else {
      referralProvider.loadReceivedReferrals(
        refresh: true,
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        referralType: _selectedType.isEmpty ? null : _selectedType,
      );
    }
  }

  Widget _buildSentReferralsTab() {
    return Consumer<ReferralProvider>(
      builder: (context, referralProvider, child) {
        if (referralProvider.isLoading && referralProvider.sentReferrals.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (referralProvider.sentReferrals.isEmpty) {
          return _buildEmptyState(
            'No sent referrals',
            'You haven\'t sent any referrals yet',
            Icons.send,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateReferralScreen()),
              );
            },
            'Create Referral',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await referralProvider.loadSentReferrals(refresh: true);
          },
          child: ListView.separated(
            controller: _sentScrollController,
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: referralProvider.sentReferrals.length +
                (referralProvider.hasSentMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= referralProvider.sentReferrals.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final referral = referralProvider.sentReferrals[index];
              return _buildSentReferralTile(referral);
            },
          ),
        );
      },
    );
  }

  Widget _buildReceivedReferralsTab() {
    return Consumer<ReferralProvider>(
      builder: (context, referralProvider, child) {
        if (referralProvider.isLoading && referralProvider.receivedReferrals.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (referralProvider.receivedReferrals.isEmpty) {
          return _buildEmptyState(
            'No referrals received',
            'You haven\'t received any referrals yet',
            Icons.inbox,
            null,
            null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await referralProvider.loadReceivedReferrals(refresh: true);
          },
          child: ListView.separated(
            controller: _receivedScrollController,
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: referralProvider.receivedReferrals.length +
                (referralProvider.hasReceivedMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= referralProvider.receivedReferrals.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final referral = referralProvider.receivedReferrals[index];
              return _buildReceivedReferralTile(referral);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, VoidCallback? onPressed, String? buttonText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            if (onPressed != null && buttonText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kActionGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentReferralTile(ReferralModel referral) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: referral.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  referral.referralTypeIcon,
                  color: referral.statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referral.itemTitle ?? 'Unknown Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'To: ${referral.recipientName ?? 'Unknown User'}',
                      style: const TextStyle(
                        color: kDarkGreyText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: referral.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          referral.statusIcon,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          referral.statusDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
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
            ],
          ),

          const SizedBox(height: 12),

          // Reason
          Text(
            referral.reason,
            style: const TextStyle(
              fontSize: 14,
              color: kDarkGreyText,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Bottom row with metadata
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  referral.referralTypeDisplayName,
                  style: const TextStyle(
                    color: kPrimaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(referral.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedReferralTile(ReferralModel referral) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: referral.isPending ? kPrimaryBlue : Colors.black12,
          width: referral.isPending ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type and urgency
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: referral.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  referral.referralTypeIcon,
                  color: referral.statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referral.itemTitle ?? 'Unknown Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'From: ${referral.referrerName ?? 'Unknown Professional'}',
                      style: const TextStyle(
                        color: kDarkGreyText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: referral.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          referral.statusIcon,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          referral.statusDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reason
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kLightGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Referral Note:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: kDarkGreyText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  referral.reason,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kDarkGreyText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Item description if available
          if (referral.itemDescription != null && referral.itemDescription!.isNotEmpty) ...[
            Text(
              referral.itemDescription!,
              style: const TextStyle(
                fontSize: 14,
                color: kDarkGreyText,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons for pending referrals
          if (referral.isPending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateReferralStatus(referral.id, 'declined'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateReferralStatus(referral.id, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kActionGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Bottom row with metadata
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  referral.referralTypeDisplayName,
                  style: const TextStyle(
                    color: kPrimaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(referral.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateReferralStatus(String referralId, String status) async {
    final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
    final success = await referralProvider.updateReferralStatus(referralId, status);

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
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  PreferredSizeWidget? _buildAppBarBottom() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];

    if (userRole == 'service_user') {
      // Parents only see received referrals - no tabs needed
      return null;
    }

    return TabBar(
      controller: _tabController,
      labelColor: kPrimaryBlue,
      unselectedLabelColor: Colors.grey,
      indicatorColor: kPrimaryBlue,
      tabs: const [
        Tab(text: 'Sent'),
        Tab(text: 'Received'),
      ],
    );
  }
}