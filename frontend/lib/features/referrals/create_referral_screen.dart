// frontend/lib/features/referrals/create_referral_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'referral_provider.dart';
import 'referral_model.dart';
import '../services/services_provider.dart';
import '../services/services_model.dart';
import '../resources/resources_provider.dart';
import '../resources/resources_model.dart';
import '../support_groups/support_groups_provider.dart';
import '../support_groups/support_groups_model.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class CreateReferralScreen extends StatefulWidget {
  final String? preSelectedItemId;
  final String? preSelectedItemType;
  final String? preSelectedUserId;

  const CreateReferralScreen({
    super.key,
    this.preSelectedItemId,
    this.preSelectedItemType,
    this.preSelectedUserId,
  });

  @override
  State<CreateReferralScreen> createState() => _CreateReferralScreenState();
}

class _CreateReferralScreenState extends State<CreateReferralScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();

  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  UserSearchResult? _selectedUser;
  dynamic _selectedItem; // Can be ServiceModel, ResourceModel, or SupportGroupModel
  String _selectedItemType = 'service'; // 'service', 'resource', 'support_group'
  bool _isUrgent = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set pre-selected values if provided
    if (widget.preSelectedItemType != null) {
      _selectedItemType = widget.preSelectedItemType!;
      _tabController.index = _getTabIndexForType(widget.preSelectedItemType!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load initial data
      _loadItemsForSelectedType();

      // Pre-select user if provided
      if (widget.preSelectedUserId != null) {
        _preSelectUser(widget.preSelectedUserId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _userSearchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int _getTabIndexForType(String type) {
    switch (type) {
      case 'service': return 0;
      case 'resource': return 1;
      case 'support_group': return 2;
      default: return 0;
    }
  }

  String _getTypeForTabIndex(int index) {
    switch (index) {
      case 0: return 'service';
      case 1: return 'resource';
      case 2: return 'support_group';
      default: return 'service';
    }
  }

  void _loadItemsForSelectedType() {
    switch (_selectedItemType) {
      case 'service':
        Provider.of<ServicesProvider>(context, listen: false).loadServices(refresh: true);
        break;
      case 'resource':
        Provider.of<ResourcesProvider>(context, listen: false).loadResources(refresh: true);
        break;
      case 'support_group':
        Provider.of<SupportGroupsProvider>(context, listen: false).loadSupportGroups(refresh: true);
        break;
    }
  }

  Future<void> _preSelectUser(String userId) async {
    // This would require an API call to get user details by ID
    // For now, we'll just trigger a search if we have other user info
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0: return _selectedUser != null;
      case 1: return _selectedItem != null;
      case 2: return _reasonController.text.trim().isNotEmpty;
      default: return false;
    }
  }

  Future<void> _createReferral() async {
    if (_selectedUser == null || _selectedItem == null || _reasonController.text.trim().isEmpty) {
      _showError('Please complete all required fields');
      return;
    }

    final request = CreateReferralRequest(
      referredTo: _selectedUser!.id,
      referralType: _selectedItemType,
      itemId: _getItemId(_selectedItem),
      reason: _reasonController.text.trim(),
      isUrgent: _isUrgent,
    );

    final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
    final success = await referralProvider.createReferral(request);

    if (success && mounted) {
      _showSuccess('Referral created successfully');
      Navigator.pop(context, true);
    } else if (mounted) {
      _showError(referralProvider.error ?? 'Failed to create referral');
    }
  }

  String _getItemId(dynamic item) {
    if (item is ServiceModel) return item.id;
    if (item is ResourceModel) return item.id;
    if (item is SupportGroupModel) return item.id.toString();
    return '';
  }

  String _getItemTitle(dynamic item) {
    if (item is ServiceModel) return item.name;
    if (item is ResourceModel) return item.title;
    if (item is SupportGroupModel) return item.name;
    return '';
  }

  String _getItemDescription(dynamic item) {
    if (item is ServiceModel) return item.shortDescription;
    if (item is ResourceModel) return item.shortDescription;
    if (item is SupportGroupModel) return item.shortDescription;
    return '';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kActionGreen,
      ),
    );
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
          'Create Referral',
          style: TextStyle(
            color: kDarkGreyText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 3,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentStep = page);
              },
              children: [
                _buildSelectUserPage(),
                _buildSelectItemPage(),
                _buildReferralDetailsPage(),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: kPrimaryBlue),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: Consumer<ReferralProvider>(
                    builder: (context, referralProvider, child) {
                      return ElevatedButton(
                        onPressed: referralProvider.isCreating ? null : () {
                          if (_currentStep < 2) {
                            if (_canProceedFromStep(_currentStep)) {
                              _nextStep();
                            } else {
                              _showError(_getStepErrorMessage(_currentStep));
                            }
                          } else {
                            _createReferral();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kActionGreen,
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: referralProvider.isCreating
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
                          _currentStep == 2 ? 'Create Referral' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepErrorMessage(int step) {
    switch (step) {
      case 0: return 'Please select a user to refer to';
      case 1: return 'Please select an item to refer';
      case 2: return 'Please provide a reason for the referral';
      default: return 'Please complete the required fields';
    }
  }

  Widget _buildSelectUserPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for the user you want to refer to',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // User Search
          TextFormField(
            controller: _userSearchController,
            onChanged: (value) {
              final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
              if (value.trim().length >= 3) {
                referralProvider.searchUsers(value);
              } else {
                referralProvider.clearSearchResults();
              }
            },
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _userSearchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _userSearchController.clear();
                  Provider.of<ReferralProvider>(context, listen: false).clearSearchResults();
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search Results
          Consumer<ReferralProvider>(
            builder: (context, referralProvider, child) {
              if (referralProvider.isSearching) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (_userSearchController.text.trim().length >= 3 && referralProvider.searchResults.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              if (referralProvider.searchResults.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Type at least 3 characters to search for users',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: referralProvider.searchResults.map((user) {
                  final isSelected = _selectedUser?.id == user.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedUser = user;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimaryBlue.withOpacity(0.1) : Colors.white,
                          border: Border.all(
                            color: isSelected ? kPrimaryBlue : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: user.roleColor.withOpacity(0.1),
                              child: Icon(
                                user.roleIcon,
                                color: user.roleColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isSelected ? kPrimaryBlue : kDarkGreyText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: user.roleColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      user.roleDisplayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: kActionGreen,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectItemPage() {
    return Column(
      children: [
        // Item Type Tabs
        Container(
          margin: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Item to Refer',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose what you want to refer to the user',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                onTap: (index) {
                  setState(() {
                    _selectedItemType = _getTypeForTabIndex(index);
                    _selectedItem = null; // Clear selection when changing type
                  });
                  _loadItemsForSelectedType();
                },
                labelColor: kPrimaryBlue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: kPrimaryBlue,
                tabs: const [
                  Tab(text: 'Services'),
                  Tab(text: 'Resources'),
                  Tab(text: 'Groups'),
                ],
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildServicesList(),
              _buildResourcesList(),
              _buildSupportGroupsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesList() {
    return Consumer<ServicesProvider>(
      builder: (context, servicesProvider, child) {
        if (servicesProvider.isLoading && servicesProvider.services.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (servicesProvider.services.isEmpty) {
          return const Center(
            child: Text(
              'No services available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: servicesProvider.services.length,
          itemBuilder: (context, index) {
            final service = servicesProvider.services[index];
            final isSelected = _selectedItem == service;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedItem = service;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimaryBlue.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: isSelected ? kPrimaryBlue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: service.serviceTypeColor.withOpacity(0.1),
                            child: Icon(
                              Icons.medical_services,
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected ? kPrimaryBlue : kDarkGreyText,
                                  ),
                                ),
                                Text(
                                  service.providerName,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: kActionGreen,
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.shortDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kDarkGreyText,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResourcesList() {
    return Consumer<ResourcesProvider>(
      builder: (context, resourcesProvider, child) {
        if (resourcesProvider.isLoading && resourcesProvider.resources.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (resourcesProvider.resources.isEmpty) {
          return const Center(
            child: Text(
              'No resources available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: resourcesProvider.resources.length,
          itemBuilder: (context, index) {
            final resource = resourcesProvider.resources[index];
            final isSelected = _selectedItem == resource;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedItem = resource;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimaryBlue.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: isSelected ? kPrimaryBlue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected ? kPrimaryBlue : kDarkGreyText,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (resource.hasAuthor)
                                  Text(
                                    'by ${resource.author!}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: kActionGreen,
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resource.shortDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kDarkGreyText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kActionGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              resource.targetAudienceDisplayName,
                              style: const TextStyle(
                                color: kActionGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSupportGroupsList() {
    return Consumer<SupportGroupsProvider>(
      builder: (context, supportGroupsProvider, child) {
        if (supportGroupsProvider.isLoading && supportGroupsProvider.supportGroups.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (supportGroupsProvider.supportGroups.isEmpty) {
          return const Center(
            child: Text(
              'No support groups available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: supportGroupsProvider.supportGroups.length,
          itemBuilder: (context, index) {
            final group = supportGroupsProvider.supportGroups[index];
            final isSelected = _selectedItem == group;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedItem = group;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimaryBlue.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: isSelected ? kPrimaryBlue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
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
                                Text(
                                  group.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected ? kPrimaryBlue : kDarkGreyText,
                                  ),
                                ),
                                Text(
                                  group.categoryDisplayName,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: kActionGreen,
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        group.shortDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kDarkGreyText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (group.hasDoctorInfo)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Professional Support',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReferralDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Referral Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Provide details for this referral',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Referral Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kLightGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Referral Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Referring to:', _selectedUser?.fullName ?? ''),
                _buildSummaryRow('User email:', _selectedUser?.email ?? ''),
                _buildSummaryRow('Item type:', _selectedItemType.replaceAll('_', ' ').toUpperCase()),
                _buildSummaryRow('Item title:', _getItemTitle(_selectedItem)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Reason field
          const Text(
            'Reason for Referral *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Please explain why you are referring this item to the user...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Urgency toggle
          Row(
            children: [
              Switch(
                value: _isUrgent,
                onChanged: (value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
                activeColor: kActionGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mark as Urgent',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Urgent referrals will be highlighted to the user',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
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
}