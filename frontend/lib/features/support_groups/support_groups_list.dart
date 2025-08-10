// frontend/lib/features/support_groups/support_groups_list.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../profile/profile.dart';
import 'support_groups_provider.dart';
import 'support_groups_model.dart';
import 'support_group_detail.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);
const kActionGreen = Color(0xFF4CAF50);

class SupportGroupsListScreen extends StatefulWidget {
  const SupportGroupsListScreen({super.key});

  @override
  State<SupportGroupsListScreen> createState() => _SupportGroupsListScreenState();
}

class _SupportGroupsListScreenState extends State<SupportGroupsListScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = '';
  String _selectedPlatform = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supportGroupsProvider = Provider.of<SupportGroupsProvider>(context, listen: false);
      supportGroupsProvider.loadSupportGroups(refresh: true);
      supportGroupsProvider.loadUserGroups();
    });

    // Add scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final supportGroupsProvider = Provider.of<SupportGroupsProvider>(context, listen: false);
        supportGroupsProvider.loadMoreSupportGroups();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    final supportGroupsProvider = Provider.of<SupportGroupsProvider>(context, listen: false);
    if (query.trim().isEmpty) {
      supportGroupsProvider.clearFilters();
    } else {
      supportGroupsProvider.searchSupportGroups(query.trim());
    }
  }

  void _handleCategoryFilter(String category) {
    setState(() {
      _selectedCategory = category;
    });

    final supportGroupsProvider = Provider.of<SupportGroupsProvider>(context, listen: false);
    if (category.isEmpty) {
      supportGroupsProvider.clearFilters();
    } else {
      supportGroupsProvider.filterByCategory(category);
    }
  }

  void _handlePlatformFilter(String platform) {
    setState(() {
      _selectedPlatform = platform;
    });

    final supportGroupsProvider = Provider.of<SupportGroupsProvider>(context, listen: false);
    if (platform.isEmpty) {
      supportGroupsProvider.clearFilters();
    } else {
      supportGroupsProvider.filterByPlatform(platform);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDarkGreyText),
          onPressed: () {
            final navProvider = Provider.of<NavigationProvider>(context, listen: false);
            navProvider.updateIndex(0);
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Support Groups',
          style: TextStyle(
            color: kDarkGreyText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: kDarkGreyText),
            iconSize: 26,
            onPressed: () {},
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
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
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
                // Search Bar
                TextFormField(
                  controller: _searchController,
                  onChanged: _handleSearch,
                  decoration: InputDecoration(
                    hintText: 'Search by group name or category',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: kPrimaryBlue),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _handleSearch('');
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: kLightGrey,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', ''),
                      const SizedBox(width: 8),
                      _buildFilterChip('Postnatal', 'postnatal'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Prenatal', 'prenatal'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Anxiety', 'anxiety'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Depression', 'depression'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Partner Support', 'partner_support'),
                      const SizedBox(width: 8),
                      _buildFilterChip('General', 'general'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Platform Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPlatformChip('All', ''),
                      const SizedBox(width: 8),
                      _buildPlatformChip('Online', 'online'),
                      const SizedBox(width: 8),
                      _buildPlatformChip('In-Person', 'in_person'),
                      const SizedBox(width: 8),
                      _buildPlatformChip('Hybrid', 'hybrid'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Support Groups List
          Expanded(
            child: Consumer<SupportGroupsProvider>(
              builder: (context, supportGroupsProvider, child) {
                if (supportGroupsProvider.isLoading && supportGroupsProvider.supportGroups.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (supportGroupsProvider.error != null && supportGroupsProvider.supportGroups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load support groups',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          supportGroupsProvider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            supportGroupsProvider.loadSupportGroups(refresh: true);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (supportGroupsProvider.supportGroups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No support groups found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await supportGroupsProvider.refreshAll();
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: supportGroupsProvider.supportGroups.length +
                        (supportGroupsProvider.hasMorePages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= supportGroupsProvider.supportGroups.length) {
                        // Loading indicator at the bottom
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final group = supportGroupsProvider.supportGroups[index];
                      final isUserMember = supportGroupsProvider.isUserMemberOfGroup(group.id);
                      return _buildSupportGroupTile(group, isUserMember);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<NavigationProvider>(
        builder: (context, navProvider, _) => _buildBottomNavBar(navProvider),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _handleCategoryFilter(selected ? value : '');
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

  Widget _buildPlatformChip(String label, String value) {
    final isSelected = _selectedPlatform == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _handlePlatformFilter(selected ? value : '');
      },
      selectedColor: kActionGreen.withOpacity(0.2),
      checkmarkColor: kActionGreen,
      labelStyle: TextStyle(
        color: isSelected ? kActionGreen : kDarkGreyText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? kActionGreen : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildSupportGroupTile(SupportGroupModel group, bool isUserMember) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SupportGroupDetailScreen(group: group),
          ),
        );
      },
      child: Container(
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
            // Header with name and membership status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: group.categoryColor.withOpacity(0.1),
                  child: Icon(
                    group.categoryIcon,
                    color: group.categoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isUserMember)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kActionGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Joined',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        group.categoryDisplayName,
                        style: const TextStyle(
                          color: kDarkGreyText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              group.shortDescription,
              style: const TextStyle(
                fontSize: 14,
                color: kDarkGreyText,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            // Platform and meeting time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: group.platformColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        group.platformIcon,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        group.platformDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (group.hasMeetingTime) ...[
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      group.displayMeetingTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Doctor info and action
            Row(
              children: [
                if (group.hasDoctorInfo) ...[
                  Icon(
                    Icons.medical_services,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Professional support available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
                if (!group.hasDoctorInfo) const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: kPrimaryBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(NavigationProvider navProvider) {
    final items = [
      Icons.home,
      Icons.menu_book,
      FontAwesomeIcons.heartPulse,
      Icons.group,
    ];

    final labels = ['Home', 'Resources', 'Services', 'Groups'];

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
                navProvider.updateIndex(index);
                switch (index) {
                  case 0:
                    Navigator.pushReplacementNamed(context, '/dashboard');
                    break;
                  case 1:
                    Navigator.pushReplacementNamed(context, '/resources');
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(context, '/services');
                    break;
                  case 3:
                  // Already on Support Groups screen
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