import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:perinatal_app/features/profile/profile.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

/// Primary palette used throughout the app
const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      if (navProvider.currentIndex != 0) {
        navProvider.updateIndex(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey[200]),
          Expanded(
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
                  _sectionTitleWithLink('Featured Services', onViewAll: () {}),
                  const SizedBox(height: 8),
                  _featuredServiceTile(
                    title: 'Perinatal Depression Support',
                    description:
                    'Confidential support for mothers experiencing depression during the perinatal period.',
                    tags: [
                      _buildServiceTag('NHS Approved', kPrimaryBlue,Colors.white),
                      _buildServiceTag('Online & In‑Person', const Color(0xFFE0E0E0),kDarkGreyText),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _featuredServiceTile(
                    title: 'Anxiety & Stress Management',
                    description:
                    'Workshops and counselling to help manage anxiety and stress during the perinatal journey.',
                    tags: [
                      _buildServiceTag('Charity Led',const Color(0xFFFFF9C4) ,const Color(0xFFFFC107)),
                      _buildServiceTag('In‑Person', const Color(0xFFE0E0E0),kDarkGreyText),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitleWithLink('Upcoming Support Groups', onViewAll: () {}),
                  const SizedBox(height: 8),
                  _upcomingGroupTile(
                    title: 'New Parents Connect',
                    schedule: 'Every Monday, 10:00 AM',
                    location: 'Online via Zoom',
                    participants: '15 Participants',
                  ),
                  const SizedBox(height: 16),
                  _upcomingGroupTile(
                    title: 'Mindful Motherhood',
                    schedule: 'Wednesdays, 6:30 PM',
                    location: 'Community Center Hall',
                    participants: '10 Participants',
                  ),
                  const SizedBox(height: 12),
                ],
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
        children: [
          const Text(
            'Your Mental Wellness',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kDarkGreyText,
              fontSize: 18,
            ),
          ),
          const Text(
            'Journey',
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
        IconButton(
          icon: const Icon(Icons.notifications_none, color: kDarkGreyText),
          iconSize: 27,
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
    );
  }

  // ─────────────────────── Greeting Blue Card ───────────────────────
  Widget _greetingCard() {
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
          // Hello Jane centered at the top
          const Center(
            child: Text(
              'Hello Jane!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              'Your journey to mental wellness is important',
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
              'Explore resources tailored for you',
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
              decorationColor: kPrimaryBlue// Underlined
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── Quick Actions Grid ───────────────────────
  Widget _quickActionsGrid() {
    final actions = [
      ('Find Services', Icons.search),
      ('Support Groups', Icons.group),
      ('Resources', Icons.menu_book),
      ('Your Journey', FontAwesomeIcons.heartPulse), // Use heart pulse icon here
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
        final (title, icon) = actions[index];
        return InkWell(
          onTap: () {},
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

  // ───────────────────── Featured Service Card ──────────────────────
  Widget _featuredServiceTile({
    required String title,
    required String description,
    required List<Widget> tags,
  }) {
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
              const CircleAvatar(
                radius: 18,
                backgroundColor: kLightGrey,
                child: Icon(FontAwesomeIcons.heartPulse, color: kPrimaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: kDarkGreyText),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: -4, children: tags),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kActionGreen,
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {},
              child: const Text(
                'View Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold, // Bold text
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tag (chip‑like) widget
  Widget _buildServiceTag(String text, Color bgColor,Color fontColor) {
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
          color: (bgColor == kPrimaryBlue) ? Colors.white : fontColor,
          fontWeight:
          (bgColor == kPrimaryBlue) ? FontWeight.bold : FontWeight.bold,
        ),
      ),
    );
  }

  // ───────────────────── Upcoming Group Card ────────────────────────
  Widget _upcomingGroupTile({
    required String title,
    required String schedule,
    required String location,
    required String participants,
  }) {
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
              const CircleAvatar(
                radius: 18,
                backgroundColor: kLightGrey,
                child: Icon(Icons.calendar_today_outlined,
                    color: kPrimaryBlue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(schedule,
              style: const TextStyle(fontSize: 14, color: kDarkGreyText)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: kDarkGreyText),
              const SizedBox(width: 4),
              Text(location,
                  style: const TextStyle(fontSize: 14, color: kDarkGreyText)),
              const SizedBox(width: 12),
              const Icon(Icons.group,
                  size: 16, color: kDarkGreyText),
              const SizedBox(width: 4),
              Text(participants,
                  style: const TextStyle(fontSize: 14, color: kDarkGreyText)),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kActionGreen,
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {},
              child: const Text(
                'Learn More',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold, // Bold text
                ),
              ),
            ),
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
                if (navProvider.currentIndex == index) return;

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
                    Navigator.pushReplacementNamed(context, '/groups');
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