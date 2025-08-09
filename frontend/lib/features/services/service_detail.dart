// lib/features/services/service_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services_model.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;

  const ServiceDetailScreen({
    super.key,
    required this.service,
  });

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
          'Service Details',
          style: TextStyle(
            color: kDarkGreyText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(
                          FontAwesomeIcons.heartPulse,
                          color: kPrimaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service.providerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildServiceTag(
                    service.serviceTypeDisplayName,
                    Colors.white,
                    kPrimaryBlue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description Section
            _buildSection(
              'About This Service',
              Icons.info_outline,
              Text(
                service.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: kDarkGreyText,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact Information
            if (service.hasContact) ...[
              _buildSection(
                'Contact Information',
                Icons.contact_phone,
                Column(
                  children: [
                    if (service.contactEmail != null) ...[
                      _buildContactItem(
                        Icons.email_outlined,
                        'Email',
                        service.contactEmail!,
                            () => _launchEmail(service.contactEmail!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (service.contactPhone != null) ...[
                      _buildContactItem(
                        Icons.phone_outlined,
                        'Phone',
                        service.contactPhone!,
                            () => _launchPhone(service.contactPhone!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (service.websiteUrl != null) ...[
                      _buildContactItem(
                        Icons.language,
                        'Website',
                        service.websiteUrl!,
                            () => _launchWebsite(service.websiteUrl!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Location Information
            if (service.address != null) ...[
              _buildSection(
                'Location',
                Icons.location_on_outlined,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.address!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: kDarkGreyText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMaps(service.address!),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Get Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kActionGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Eligibility Criteria
            if (service.eligibilityCriteria != null) ...[
              _buildSection(
                'Eligibility Criteria',
                Icons.checklist,
                Text(
                  service.eligibilityCriteria!,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: kDarkGreyText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Service Type Information
            _buildSection(
              'Service Delivery',
              Icons.computer,
              _buildServiceTypeInfo(),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: service.hasContact
                        ? () => _showContactOptions(context)
                        : null,
                    icon: const Icon(Icons.contact_support),
                    label: const Text('Get in Touch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kActionGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareService(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Service'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: kPrimaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: kPrimaryBlue, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kDarkGreyText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: content,
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kLightGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: kPrimaryBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kDarkGreyText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.open_in_new,
              color: kPrimaryBlue,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeInfo() {
    String description;
    IconData icon;

    switch (service.serviceType) {
      case 'online':
        description = 'This service is delivered entirely online through video calls, chat, or digital platforms.';
        icon = Icons.computer;
        break;
      case 'in_person':
        description = 'This service requires in-person attendance at the specified location.';
        icon = Icons.location_on;
        break;
      case 'hybrid':
        description = 'This service offers both online and in-person options for your convenience.';
        icon = Icons.sync_alt;
        break;
      default:
        description = 'Service delivery method information not available.';
        icon = Icons.help_outline;
    }

    return Row(
      children: [
        Icon(icon, color: service.serviceTypeColor, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: kDarkGreyText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTag(String text, Color bgColor, Color fontColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _launchWebsite(String url) async {
    final Uri websiteUri = Uri.parse(url);
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchMaps(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (service.contactEmail != null)
              ListTile(
                leading: const Icon(Icons.email_outlined, color: kPrimaryBlue),
                title: const Text('Send Email'),
                subtitle: Text(service.contactEmail!),
                onTap: () {
                  Navigator.pop(context);
                  _launchEmail(service.contactEmail!);
                },
              ),
            if (service.contactPhone != null)
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: kPrimaryBlue),
                title: const Text('Call'),
                subtitle: Text(service.contactPhone!),
                onTap: () {
                  Navigator.pop(context);
                  _launchPhone(service.contactPhone!);
                },
              ),
            if (service.websiteUrl != null)
              ListTile(
                leading: const Icon(Icons.language, color: kPrimaryBlue),
                title: const Text('Visit Website'),
                subtitle: Text(service.websiteUrl!),
                onTap: () {
                  Navigator.pop(context);
                  _launchWebsite(service.websiteUrl!);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _shareService(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
      ),
    );
  }
}