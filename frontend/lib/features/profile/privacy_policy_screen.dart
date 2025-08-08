import 'package:flutter/material.dart';
import 'privacy_settings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kDarkGreyText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: const [
            Text(
              "Data Handling & Storage",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "All data is publicly available and stored securely using Padlet. The padlet will be locked after collation and accessed only by the research team.",
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              "Personal Data",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "No personal data is collected. Participants are instructed not to enter identifiable information unless it is already public. Any such data will be removed.",
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              "Confidentiality & Retention",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "All entries are treated with full confidentiality. No identifiable data will appear in publications or shared materials. The padlet will be retained until the app is finalized.",
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              "GDPR Compliance",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "We comply with UK GDPR. You have the right to access, rectify, and delete your data. For data concerns, contact the research team.",
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
