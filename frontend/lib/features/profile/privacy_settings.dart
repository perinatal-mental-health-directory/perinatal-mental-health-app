// frontend/lib/features/profile/privacy_settings.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'privacy_provider.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kDarkGreyText = Color(0xFF424242);
const kLightGrey = Color(0xFFF6F6F6);

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load privacy preferences when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrivacyProvider>().loadPrivacyPreferences();
    });
  }

  void _showDataRetentionInfo() async {
    final privacyProvider = context.read<PrivacyProvider>();
    final retentionInfo = await privacyProvider.getDataRetentionInfo();

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Data Retention & GDPR Compliance"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Data Retention Policy",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  retentionInfo?['retention_policy'] ??
                      "Your personal data is retained only as long as necessary to provide services or as required by law. "
                          "After that, data is securely deleted or anonymized.",
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  "GDPR Rights",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  retentionInfo?['gdpr_rights'] ??
                      "Under GDPR, you have the right to:\n"
                          "• Access your personal data\n"
                          "• Rectify inaccurate data\n"
                          "• Erase your data\n"
                          "• Restrict processing\n"
                          "• Data portability\n"
                          "• Object to processing",
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                if (retentionInfo?['last_updated'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Last updated: ${retentionInfo!['last_updated']}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
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
  }

  void _requestDataDownload() async {
    final privacyProvider = context.read<PrivacyProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Request Data Download"),
        content: const Text(
          "We'll prepare a copy of your personal data and send it to your registered email address. "
              "This may take up to 30 days to process.",
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
            child: const Text("Request"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await privacyProvider.requestDataDownload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success
                    ? "Data download request submitted successfully"
                    : privacyProvider.error ?? "Failed to submit request"
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _requestAccountDeletion() async {
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want to delete your account? This action cannot be undone. "
                  "All your data will be permanently removed.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason for deletion (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete Account"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final privacyProvider = context.read<PrivacyProvider>();
      final success = await privacyProvider.requestAccountDeletion(
        reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success
                    ? "Account deletion request submitted. You will be contacted shortly."
                    : privacyProvider.error ?? "Failed to submit request"
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }

    reasonController.dispose();
  }

  void _exportData() async {
    final privacyProvider = context.read<PrivacyProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Preparing your data export..."),
          ],
        ),
      ),
    );

    final exportData = await privacyProvider.exportUserData();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (exportData != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("Data Export Ready"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Your data has been exported successfully."),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exportData.length > 200
                        ? "${exportData.substring(0, 200)}..."
                        : exportData,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(privacyProvider.error ?? "Failed to export data"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      body: Consumer<PrivacyProvider>(
        builder: (context, privacyProvider, child) {
          if (privacyProvider.isLoading && privacyProvider.preferences.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => privacyProvider.loadPrivacyPreferences(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kPrimaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kPrimaryBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.privacy_tip,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Privacy Matters',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: kDarkGreyText,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Control how your data is used and shared',
                                style: TextStyle(
                                  color: kDarkGreyText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Privacy Preferences",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Privacy Toggles
                  _buildPrivacyToggle(
                    title: "Data Analytics",
                    subtitle: "Allow anonymous usage analytics to improve our services",
                    value: privacyProvider.analyticsEnabled,
                    onChanged: (value) => privacyProvider.updatePreference('analytics_enabled', value),
                    icon: Icons.analytics_outlined,
                  ),

                  _buildPrivacyToggle(
                    title: "Data Sharing with Healthcare Providers",
                    subtitle: "Share anonymized data with approved NHS and healthcare partners",
                    value: privacyProvider.dataSharingEnabled,
                    onChanged: (value) => privacyProvider.updatePreference('data_sharing_enabled', value),
                    icon: Icons.share_outlined,
                  ),

                  _buildPrivacyToggle(
                    title: "Cookies & Local Storage",
                    subtitle: "Allow cookies to improve your experience and save preferences",
                    value: privacyProvider.cookiesEnabled,
                    onChanged: (value) => privacyProvider.updatePreference('cookies_enabled', value),
                    icon: Icons.cookie_outlined,
                  ),

                  _buildPrivacyToggle(
                    title: "Marketing Communications",
                    subtitle: "Receive emails about new features and health resources",
                    value: privacyProvider.marketingEmailsEnabled,
                    onChanged: (value) => privacyProvider.updatePreference('marketing_emails_enabled', value),
                    icon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Text(
                    "Data Management",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Data Management Options
                  _buildActionTile(
                    icon: Icons.download_outlined,
                    title: "Download My Data",
                    subtitle: "Get a copy of your personal data",
                    onTap: _requestDataDownload,
                  ),

                  _buildActionTile(
                    icon: Icons.upload_outlined,
                    title: "Export Data",
                    subtitle: "View and export your data in JSON format",
                    onTap: _exportData,
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Text(
                    "Legal & Compliance",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildActionTile(
                    icon: Icons.policy_outlined,
                    title: "Privacy Policy",
                    subtitle: "Read our full privacy policy",
                    onTap: _openPrivacyPolicy,
                  ),

                  _buildActionTile(
                    icon: Icons.info_outline,
                    title: "Data Retention & GDPR",
                    subtitle: "Learn about data retention and your rights",
                    onTap: _showDataRetentionInfo,
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Text(
                    "Account Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildActionTile(
                    icon: Icons.delete_forever_outlined,
                    title: "Delete Account",
                    subtitle: "Permanently delete your account and all data",
                    onTap: _requestAccountDeletion,
                    isDestructive: true,
                  ),

                  const SizedBox(height: 24),

                  // Error Display
                  if (privacyProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              privacyProvider.error!,
                              style: TextStyle(color: Colors.red[700], fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red[700], size: 20),
                            onPressed: () => privacyProvider.clearError(),
                          ),
                        ],
                      ),
                    ),

                  // Reset to Defaults
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text("Reset to Defaults"),
                            content: const Text(
                              "This will reset all privacy settings to their default values. "
                                  "Are you sure you want to continue?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Reset"),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          final success = await privacyProvider.resetToDefaultPreferences();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    success
                                        ? "Privacy settings reset to defaults"
                                        : "Failed to reset settings"
                                ),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text("Reset to Defaults"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivacyToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Consumer<PrivacyProvider>(
      builder: (context, privacyProvider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: kPrimaryBlue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kDarkGreyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6E6E6E),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: value,
                onChanged: privacyProvider.isLoading ? null : onChanged,
                activeColor: kPrimaryBlue,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : kPrimaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : kPrimaryBlue,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDestructive ? Colors.red : kDarkGreyText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6E6E6E),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        tileColor: Colors.white,
      ),
    );
  }
}