// frontend/lib/features/dashboard/professional_dashboard.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:perinatal_app/features/profile/profile.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../referrals/referral_list_screen.dart';
import '../resources/resources_detail.dart';
import '../resources/resources_list.dart';
import '../resources/resources_model.dart';
import '../resources/resources_provider.dart';
import '../services/services_provider.dart';
import '../referrals/create_referral_screen.dart';
import '../referrals/referral_provider.dart';
import '../../providers/auth_provider.dart';
import '../services/services_model.dart';
import '../services/services_list.dart';
import '../services/service_detail.dart';
import '../support_groups/support_groups_list.dart';

/// Primary palette used throughout the app
const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  State<ProfessionalDashboardScreen> createState() => _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState extends State<ProfessionalDashboardScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
      final resourcesProvider = Provider.of<ResourcesProvider>(context, listen: false);
      final referralProvider = Provider.of<ReferralProvider>(context, listen: false);

      if (navProvider.currentIndex != 0) {
        navProvider.updateIndex(0);
      }

      // Load featured services and resources for dashboard
      servicesProvider.loadFeaturedServices();
      resourcesProvider.loadFeaturedResources();

      // Load referral data for professionals
      referralProvider.loadSentReferrals(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey[200]),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
                final resourcesProvider = Provider.of<ResourcesProvider>(context, listen: false);
                final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
                await Future.wait([
                  servicesProvider.loadFeaturedServices(),
                  resourcesProvider.loadFeaturedResources(),
                  referralProvider.loadSentReferrals(refresh: true),
                ]);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _greetingCard(),
                    const SizedBox(height: 24),
                    _sectionTitle('Quick Actions'),
                    const SizedBox(height: 8),
                    _quickActionsGrid(),
                    const SizedBox(height: 24),
                    _sectionTitle('Referral Overview'),
                    const SizedBox(height: 8),
                    _referralStatsCard(),
                    const SizedBox(height: 24),
                    _sectionTitleWithLink('Featured Services', onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FindServicesScreen()),
                      );
                    }),
                    const SizedBox(height: 8),
                    _featuredServicesSection(),
                    const SizedBox(height: 24),
                    _sectionTitleWithLink('Featured Resources', onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ResourcesListScreen()),
                      );
                    }),
                    const SizedBox(height: 8),
                    _featuredResourcesSection(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNavBar(),
    );
  }

  // ───────────────────────────── AppBar ──────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          'assets/images/shield.png',
          height: 12,
          width: 12,
        ),
      ),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kDarkGreyText,
              fontSize: 18,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Consumer<ReferralProvider>(
          builder: (context, referralProvider, _) {
            final pendingCount = referralProvider.pendingSentCount;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.assignment, color: kDarkGreyText),
                  iconSize: 27,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReferralsListScreen()),
                    );
                  },
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Container(
          margin: const EdgeInsets.only(right: 8.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black,
              width: 1.5,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 15,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.person_outline, color: kDarkGreyText, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── Greeting Blue Card ───────────────────────
  Widget _greetingCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userName = authProvider.user?['full_name'] ?? 'User';
        final firstName = userName.split(' ')[0];
        final userRole = authProvider.getUserRoleDisplayName();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: kPrimaryBlue,
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
              Center(
                child: Text(
                  'Welcome $firstName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Manage referrals and support your clients',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Access professional resources and tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────── Section Title ──────────────────────────
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _sectionTitleWithLink(String title, {required VoidCallback onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _sectionTitle(title),
        InkWell(
          onTap: onViewAll,
          child: const Text(
            'View All',
            style: TextStyle(
              color: kPrimaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: kPrimaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── Quick Actions Grid ───────────────────────
  Widget _quickActionsGrid() {
    final actions = [
      ('Add Referral', Icons.person_add, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateReferralScreen()),
        );
      }),
      ('View Referrals', Icons.assignment, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReferralsListScreen()),
        );
      }),
      ('Find Services', Icons.search, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FindServicesScreen()),
        );
      }),
      ('Resources', Icons.menu_book, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResourcesListScreen()),
        );
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 110,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (_, index) {
        final (title, icon, onTap) = actions[index];
        return InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kLightGrey,
                  child: Icon(icon, color: kPrimaryBlue, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────── Referral Stats Card ───────────────────────
  Widget _referralStatsCard() {
    return Consumer<ReferralProvider>(
      builder: (context, referralProvider, child) {
        final stats = referralProvider.getSentReferralStats();

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
              Row(
                children: [
                  Icon(Icons.analytics, color: kPrimaryBlue, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Your Referrals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReferralsListScreen()),
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: kPrimaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Sent',
                      '${stats['total'] ?? 0}',
                      kPrimaryBlue,
                      Icons.send,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Pending',
                      '${stats['pending'] ?? 0}',
                      Colors.orange,
                      Icons.schedule,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Accepted',
                      '${stats['accepted'] ?? 0}',
                      kActionGreen,
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: kDarkGreyText,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ───────────────────── Featured Services Section ──────────────────────
  Widget _featuredServicesSection() {
    return Consumer<ServicesProvider>(
      builder: (context, servicesProvider, child) {
        if (servicesProvider.isFeaturedLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (servicesProvider.error != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load services: ${servicesProvider.error}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          );
        }

        if (servicesProvider.featuredServices.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No featured services available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: servicesProvider.featuredServices.map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _featuredServiceTile(service),
            );
          }).toList(),
        );
      },
    );
  }

  // ───────────────────── Featured Service Card ──────────────────────
  Widget _featuredServiceTile(ServiceModel service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kLightGrey,
                child: Icon(FontAwesomeIcons.heartPulse, color: kPrimaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.providerName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kDarkGreyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            service.shortDescription,
            style: const TextStyle(fontSize: 14, color: kDarkGreyText),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildServiceTag(
                service.serviceTypeDisplayName,
                service.serviceTypeColor,
                Colors.white,
              ),
              if (service.address != null && service.serviceType != 'online')
                _buildServiceTag(
                  'Location Available',
                  const Color(0xFFE0E0E0),
                  kDarkGreyText,
                ),
              if (service.hasContact)
                _buildServiceTag(
                  'Contact Available',
                  const Color(0xFFE8F5E8),
                  kActionGreen,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (service.address != null)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: kDarkGreyText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          service.displayAddress,
                          style: const TextStyle(fontSize: 12, color: kDarkGreyText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kActionGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailScreen(service: service),
                    ),
                  );
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateReferralScreen(
                        preSelectedItemId: service.id,
                        preSelectedItemType: 'service',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Refer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tag (chip-like) widget
  Widget _buildServiceTag(String text, Color bgColor, Color fontColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _featuredResourcesSection() {
    return Consumer<ResourcesProvider>(
      builder: (context, resourcesProvider, child) {
        if (resourcesProvider.isFeaturedLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (resourcesProvider.error != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load resources: ${resourcesProvider.error}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          );
        }

        if (resourcesProvider.featuredResources.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No featured resources available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: resourcesProvider.featuredResources.take(2).map((resource) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _featuredResourceTile(resource),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _featuredResourceTile(ResourceModel resource) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: resource.resourceTypeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  resource.resourceTypeIcon,
                  color: resource.resourceTypeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resource.resourceTypeDisplayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kDarkGreyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            resource.shortDescription,
            style: const TextStyle(fontSize: 14, color: kDarkGreyText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: resource.resourceTypeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  resource.targetAudienceDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kActionGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResourceDetailScreen(resource: resource),
                    ),
                  );
                },
                child: const Text(
                  'Read More',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateReferralScreen(
                        preSelectedItemId: resource.id,
                        preSelectedItemType: 'resource',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Refer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────── Bottom Navigation Bar ──────────────────────
  Widget _bottomNavBar() {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final items = [
      Icons.home,
      Icons.menu_book,
      Icons.assignment, // Changed from heartPulse to assignment for referrals
      Icons.group,
    ];

    final labels = ['Home', 'Resources', 'Referrals', 'Groups'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        color: kPrimaryBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isSelected = navProvider.currentIndex == index;

            return GestureDetector(
              onTap: () {
                if (navProvider.currentIndex == index) return;

                navProvider.updateIndex(index);

                switch (index) {
                  case 0:
                  // Already on dashboard
                    break;
                  case 1:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ResourcesListScreen()),
                    );
                    break;
                  case 2:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReferralsListScreen()),
                    );
                    break;
                  case 3:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SupportGroupsListScreen()),
                    );
                    break;
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[index],
                    size: 28,
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    child: Text(labels[index]),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}