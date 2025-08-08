import 'package:flutter/material.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kDarkGreyText = Color(0xFF424242);
const kLightGrey = Color(0xFFF6F6F6);

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool consentGiven = true;
  bool dataSharingEnabled = true;
  bool allowCookies = true;

  void _toggleConsent(bool value) {
    setState(() {
      consentGiven = value;
    });
    // TODO: Send preference to backend
  }

  void _toggleDataSharing(bool value) {
    setState(() {
      dataSharingEnabled = value;
    });
    // TODO: Send preference to backend
  }

  void _toggleAllowCookies(bool value) {
    setState(() {
      allowCookies = value;
    });
    // TODO: Save cookie preferences
  }

  void _requestAccountDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Confirm Account Deletion"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Account Deletion Request"),
          content: const Text(
            "Your request has been sent. You will be contacted shortly.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void _openPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "We are committed to protecting your personal information in accordance with the UK GDPR and Data Protection Act. "
                "Your data is used only with your consent and strictly for the purpose of improving services and providing appropriate support. "
                "You can update your preferences at any time. Your data will never be shared without your permission. "
                "For detailed inquiries, please contact support.",
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _requestDataDownload() {
    // TODO: Implement data portability request backend flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Data download request submitted"),
        backgroundColor: kPrimaryBlue, // Use your defined blue color here
      ),
    );
  }


  void _showDataRetentionAndGDPR() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Data Retention & GDPR Compliance"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Data Retention",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Your personal data is retained only as long as necessary to provide services or as required by law. "
                    "After that, data is securely deleted or anonymized.",
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 20),
              Text(
                "GDPR Compliance",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "We are fully compliant with the UK GDPR regulations. You have the right to access, rectify, and delete your data at any time. "
                    "For more details, please view our privacy policy or contact support.",
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kDarkGreyText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy & GDPR Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Privacy Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text("Allow Data Tracking"),
              subtitle: const Text("Enable anonymized analytics to improve our services"),
              value: consentGiven,
              onChanged: _toggleConsent,
              activeColor: kPrimaryBlue,
            ),

            SwitchListTile(
              title: const Text("Allow Data Sharing"),
              subtitle: const Text("Permit secure sharing with approved NHS and charity professionals"),
              value: dataSharingEnabled,
              onChanged: _toggleDataSharing,
              activeColor: kPrimaryBlue,
            ),

            SwitchListTile(
              title: const Text("Allow Cookies"),
              subtitle: const Text("Help us improve your experience with cookies"),
              value: allowCookies,
              onChanged: _toggleAllowCookies,
              activeColor: kPrimaryBlue,
            ),

            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(Icons.download, color: kPrimaryBlue),
              title: const Text("Request My Data"),
              subtitle: const Text("Receive a copy of your personal data to your email"),
              onTap: _requestDataDownload,
            ),

            const SizedBox(height: 20),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.policy, color: kPrimaryBlue),
              title: const Text("View Full Privacy Policy"),
              onTap: _openPrivacyPolicy,
            ),

            ListTile(
              leading: const Icon(Icons.info_outline, color: kPrimaryBlue),
              title: const Text("Data Retention & GDPR Compliance"),
              onTap: _showDataRetentionAndGDPR,
            ),

            ListTile(
              leading: const Icon(Icons.delete_forever, color: kPrimaryBlue),
              title: const Text("Request Account Deletion"),
              onTap: _requestAccountDeletion,
            ),

            const Divider(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
