import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../profile/profile.dart';

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

  final List<Map<String, dynamic>> services = [
    {
      'title': 'Willow Tree Perinatal Hub',
      'type': 'Support Group',
      'location': 'St, SE1',
      'nhs': true,
    },
    {
      'title': 'Bright Start Clinic',
      'type': 'NHS Team',
      'location': 'Manchester, M13',
      'nhs': true,
    },
    {
      'title': 'Mindful Mums Workshop',
      'type': 'Therapy Services',
      'location': 'Bristol, BS8',
      'nhs': false,
    },
    {
      'title': 'Safe Haven Charity',
      'type': 'Community Support',
      'location': 'Birmingham, B15',
      'nhs': true,
    },
    {
      'title': 'Parenting Pathways',
      'type': 'Online Resources',
      'location': 'Remote',
      'nhs': false,
    },
    {
      'title': 'New Beginnings Counselling',
      'type': 'Private Practice',
      'location': 'Leeds, LS2',
      'nhs': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'Search by service name, location or type',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: kLightGrey,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(FontAwesomeIcons.flask, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(service['type'], style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(service['location'], style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      if (service['nhs']) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimaryBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'NHS Referral',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ]
                    ],
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
                  // Handle Resources navigation
                    break;
                  case 2:
                  // Already on Services screen
                    break;
                  case 3:
                  // Handle Groups navigation
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
