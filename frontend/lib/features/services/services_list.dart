import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../profile/profile.dart';
import 'services_provider.dart';
import 'services_model.dart';
import 'service_detail.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class FindServicesScreen extends StatefulWidget {
  const FindServicesScreen({super.key});

  @override
  State<FindServicesScreen> createState() => _FindServicesScreenState();
}

class _FindServicesScreenState extends State<FindServicesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedServiceType = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
      servicesProvider.loadServices(refresh: true);
    });

    // Add scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
        servicesProvider.loadMoreServices();
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
    final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
    if (query.trim().isEmpty) {
      servicesProvider.clearFilters();
    } else {
      servicesProvider.searchServices(query.trim());
    }
  }

  void _handleServiceTypeFilter(String serviceType) {
    setState(() {
      _selectedServiceType = serviceType;
    });

    final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
    if (serviceType.isEmpty) {
      servicesProvider.clearFilters();
    } else {
      servicesProvider.filterByServiceType(serviceType);
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
          'Find Services',
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
                    hintText: 'Search by service name or provider',
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

                // Service Type Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', ''),
                      const SizedBox(width: 8),
                      _buildFilterChip('Online', 'online'),
                      const SizedBox(width: 8),
                      _buildFilterChip('In-Person', 'in_person'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Hybrid', 'hybrid'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: Consumer<ServicesProvider>(
              builder: (context, servicesProvider, child) {
                if (servicesProvider.isLoading && servicesProvider.services.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (servicesProvider.error != null && servicesProvider.services.isEmpty) {
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
                          'Failed to load services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          servicesProvider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            servicesProvider.loadServices(refresh: true);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (servicesProvider.services.isEmpty) {
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
                          'No services found',
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
                    await servicesProvider.loadServices(refresh: true);
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: servicesProvider.services.length +
                        (servicesProvider.hasMorePages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= servicesProvider.services.length) {
                        // Loading indicator at the bottom
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final service = servicesProvider.services[index];
                      return _buildServiceTile(service);
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
    final isSelected = _selectedServiceType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _handleServiceTypeFilter(selected ? value : '');
      },
      selectedColor: kPrimaryBlue.withOpacity(0.2),
      checkmarkColor: kPrimaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? kPrimaryBlue : kDarkGreyText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? kPrimaryBlue : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildServiceTile(ServiceModel service) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(service: service),
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
            // Header with name and provider
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: service.serviceTypeColor.withOpacity(0.1),
                  child: Icon(
                    _getServiceTypeIcon(service.serviceType),
                    color: service.serviceTypeColor,
                    size: 20,
                  ),
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
              service.shortDescription,
              style: const TextStyle(
                fontSize: 14,
                color: kDarkGreyText,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            // Service type and location
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: service.serviceTypeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service.serviceTypeDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (service.address != null) ...[
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      service.displayAddress,
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

            // Contact methods and action
            Row(
              children: [
                if (service.contactMethods.isNotEmpty) ...[
                  Icon(
                    Icons.contact_support_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    service.contactMethods.join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const Spacer(),
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

  IconData _getServiceTypeIcon(String serviceType) {
    switch (serviceType) {
      case 'online':
        return Icons.computer;
      case 'in_person':
        return Icons.location_on;
      case 'hybrid':
        return Icons.sync_alt;
      default:
        return Icons.medical_services;
    }
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
                  // Already on Services screen
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