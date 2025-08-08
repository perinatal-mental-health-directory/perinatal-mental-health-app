import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:perinatal_app/features/auth/login_screen.dart';
import 'package:perinatal_app/features/profile/privacy_settings.dart';
import 'package:perinatal_app/features/profile/submit_feedback.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'change_password.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kDarkGreyText = Color(0xFF424242);
const kLightGrey = Color(0xFFF6F6F6);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _profileHeader(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200), // Optional border
                ),
                child: Column(
                  children: [
                    _groupedProfileOption(
                      icon: Icons.vpn_key,
                      text: 'Change Password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _groupedProfileOption(
                      icon: Icons.chat_bubble_outline,
                      text: 'Submit Feedback',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubmitFeedbackScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _groupedProfileOption(
                      icon: Icons.privacy_tip_outlined,
                      text: 'Privacy & GDPR Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: kDarkGreyText),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'My Profile',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _profileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: kPrimaryBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: const [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 36, color: kPrimaryBlue),
            ),
            SizedBox(height: 12),
            Text(
              'Jane',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'jane.@nhs.net',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            _StaffBadge()
          ],
        ),
      ),
    );
  }

  Widget _groupedProfileOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: kPrimaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'RobotoSerif',
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavBar(BuildContext context, NavigationProvider navProvider) {
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
                  // Navigate to Resources
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/services');
                    break;
                  case 3:
                  // Navigate to Groups
                    break;
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[index],
                    size: 28,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
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

class _StaffBadge extends StatelessWidget {
  const _StaffBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Parent',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: kPrimaryBlue,
        ),
      ),
    );
  }
}
