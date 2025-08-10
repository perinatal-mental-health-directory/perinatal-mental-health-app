// frontend/lib/features/resources/resources_list.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../profile/profile.dart';
import 'resources_provider.dart';
import 'resources_model.dart';
import 'resources_detail.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class ResourcesListScreen extends StatefulWidget {
  const ResourcesListScreen({super.key});

  @override
  State<ResourcesListScreen> createState() => _ResourcesListScreenState();
}

class _ResourcesListScreenState extends State<ResourcesListScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedResourceType = '';
  String _selectedTargetAudience = '';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resourcesProvider = Provider.of<ResourcesProvider>(context, listen: false);
      resourcesProvider.loadResources(refresh: true);
    });

    // Add scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final resourcesProvider = Provider.of<ResourcesProvider>(context, listen: false);
        resourcesProvider.loadMoreResources();
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
    final resourcesProvider = Provider.of<ResourcesProvider>(context, listen: false);
    if (query.trim().isEmpty) {
      resourcesProvider.clearFilters();
    } else {
      resourcesProvider.searchResources(query.trim());
    }
  }

  void _handleResourceTypeFilter(String resourceType) {
    setState(() {
      _selectedResourceType = resourceType;
    });

    final resourcesProvider = Provider.of<ResourcesProvider>(context, listen: false);
    if (resourceType.isEmpty) {
      resourcesProvider.clearFilters();
    } else {
      resourcesProvider.filterByResourceType(resourceType);
    }
  }

  void _handleTargetAudienceFilter(String audience) {
    setState(() {
      _selectedTargetAudience = audience;
    });

    final resourcesProvider = Provider.of<ResourcesProvider>(context, listen: false);
    if (audience.isEmpty) {
      resourcesProvider.clearFilters();
    } else {
      resourcesProvider.filterByTargetAudience(audience);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedResourceType = '';
      _selectedTargetAudience = '';
    });
    _searchController.clear();

    final resourcesProvider = Provider.of<ResourcesProvider>(context, listen: false);
    resourcesProvider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchAndFilterSection(),

          // Resources List
          Expanded(
            child: Consumer<ResourcesProvider>(
              builder: (context, resourcesProvider, child) {
                if (resourcesProvider.isLoading && resourcesProvider.resources.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (resourcesProvider.error != null && resourcesProvider.resources.isEmpty) {
                  return _buildErrorState(resourcesProvider);
                }

                if (resourcesProvider.resources.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await resourcesProvider.loadResources(refresh: true);
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: resourcesProvider.resources.length +
                        (resourcesProvider.hasMorePages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= resourcesProvider.resources.length) {
                        // Loading indicator at the bottom
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final resource = resourcesProvider.resources[index];
                      return _buildResourceTile(resource);
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

  AppBar _buildAppBar() {
    return AppBar(
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
        'Mental Health Resources',
        style: TextStyle(
          color: kDarkGreyText,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
            color: kDarkGreyText,
          ),
          onPressed: () {
            setState(() {
              _showFilters = !_showFilters;
            });
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

  Widget _buildSearchAndFilterSection() {
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
          // Search Bar
          TextFormField(
            controller: _searchController,
            onChanged: _handleSearch,
            decoration: InputDecoration(
              hintText: 'Search resources by title, content, or tags',
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

          // Filter Section (collapsible)
          if (_showFilters) ...[
            const SizedBox(height: 16),

            // Resource Type Filter
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Resource Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Types', ''),
                  const SizedBox(width: 8),
                  _buildFilterChip('Articles', 'article'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Videos', 'video'),
                  const SizedBox(width: 8),
                  _buildFilterChip('PDFs', 'pdf'),
                  const SizedBox(width: 8),
                  _buildFilterChip('External Links', 'external_link'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Infographics', 'infographic'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Target Audience Filter
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Target Audience',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAudienceFilterChip('All Audiences', ''),
                  const SizedBox(width: 8),
                  _buildAudienceFilterChip('New Mothers', 'new_mothers'),
                  const SizedBox(width: 8),
                  _buildAudienceFilterChip('Professionals', 'professionals'),
                  const SizedBox(width: 8),
                  _buildAudienceFilterChip('General', 'general'),
                  const SizedBox(width: 8),
                  _buildAudienceFilterChip('Partners', 'partners'),
                  const SizedBox(width: 8),
                  _buildAudienceFilterChip('Families', 'families'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Clear Filters Button
            if (_selectedResourceType.isNotEmpty ||
                _selectedTargetAudience.isNotEmpty ||
                _searchController.text.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear All Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimaryBlue,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedResourceType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _handleResourceTypeFilter(selected ? value : '');
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

  Widget _buildAudienceFilterChip(String label, String value) {
    final isSelected = _selectedTargetAudience == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _handleTargetAudienceFilter(selected ? value : '');
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

  Widget _buildResourceTile(ResourceModel resource) {
    return InkWell(
      onTap: () {
        // Increment view count
        final resourcesProvider = Provider.of<ResourcesProvider>(context, listen: false);
        resourcesProvider.incrementViewCount(resource.id as int);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceDetailScreen(resource: resource),
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
            // Header with type icon and featured badge
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
                      if (resource.hasAuthor) ...[
                        const SizedBox(height: 2),
                        Text(
                          'by ${resource.author!}',
                          style: const TextStyle(
                            color: kDarkGreyText,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (resource.isFeatured)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Featured',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              resource.shortDescription,
              style: const TextStyle(
                fontSize: 14,
                color: kDarkGreyText,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Tags
            if (resource.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: resource.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10,
                        color: kDarkGreyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // Bottom row with metadata and action
            Row(
              children: [
                // Resource type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: resource.resourceTypeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resource.resourceTypeDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Target audience
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kActionGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resource.targetAudienceDisplayName,
                    style: TextStyle(
                      color: kActionGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Spacer(),

                // Metadata
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (resource.estimatedReadTime != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            resource.estimatedReadTimeText,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${resource.viewCount} views',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ResourcesProvider resourcesProvider) {
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
            'Failed to load resources',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resourcesProvider.error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              resourcesProvider.loadResources(refresh: true);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No resources found',
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
                  // Already on Resources screen
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(context, '/services');
                    break;
                  case 3:
                  // TODO: Navigate to groups
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support Groups coming soon!')),
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