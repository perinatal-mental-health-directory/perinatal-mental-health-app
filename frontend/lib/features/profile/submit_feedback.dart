// frontend/lib/features/profile/submit_feedback.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'profile_provider.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kDarkGreyText = Color(0xFF424242);

class SubmitFeedbackScreen extends StatefulWidget {
  const SubmitFeedbackScreen({super.key});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isAnonymous = false;
  int _selectedRating = 2; // Default to "Neutral" (index 2)
  String _selectedCategory = 'general';
  final TextEditingController _feedbackController = TextEditingController();
  bool _isLoading = false;

  final List<String> _ratingEmojis = ['😞', '🙁', '😐', '🙂', '😄'];
  final List<String> _ratingLabels = ['Very Dissatisfied', 'Dissatisfied', 'Neutral', 'Satisfied', 'Very Satisfied'];
  final List<String> _ratingValues = ['Very Dissatisfied', 'Dissatisfied', 'Neutral', 'Satisfied', 'Very Satisfied'];

  final List<Map<String, String>> _categories = [
    {'value': 'general', 'label': 'General Feedback'},
    {'value': 'app_usability', 'label': 'App Usability'},
    {'value': 'services', 'label': 'Services Directory'},
    {'value': 'support', 'label': 'Support & Help'},
    {'value': 'bug_report', 'label': 'Bug Report'},
    {'value': 'feature_request', 'label': 'Feature Request'},
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final profileProvider = context.read<ProfileProvider>();

    final success = await profileProvider.submitFeedback(
      anonymous: _isAnonymous,
      rating: _ratingValues[_selectedRating],
      feedback: _feedbackController.text.trim(),
      category: _selectedCategory,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.error ?? 'Failed to submit feedback'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateFeedback(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your feedback';
    }
    if (value.trim().length < 10) {
      return 'Feedback must be at least 10 characters long';
    }
    if (value.trim().length > 1000) {
      return 'Feedback must be less than 1000 characters';
    }
    return null;
  }

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
          'Submit Feedback',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kDarkGreyText,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                        Icons.feedback,
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
                            'We Value Your Feedback',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: kDarkGreyText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Help us improve our app and services',
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

              // Anonymous Feedback Toggle
              _buildCard(
                title: 'Submit anonymously',
                subtitle: 'Your feedback will be sent without your personal information',
                trailing: Switch(
                  activeColor: kPrimaryBlue,
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() => _isAnonymous = value);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Category Selection
              _buildCard(
                title: 'Feedback Category',
                subtitle: 'Select the category that best describes your feedback',
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['value'],
                      child: Text(category['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Rating Section
              _buildCard(
                title: 'How was your experience?',
                subtitle: 'Rate your overall satisfaction with the app or services',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_ratingEmojis.length, (index) {
                    final selected = _selectedRating == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedRating = index);
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selected ? kPrimaryBlue.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _ratingEmojis[index],
                              style: TextStyle(
                                fontSize: selected ? 36 : 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _ratingLabels[index],
                            style: TextStyle(
                              fontSize: selected ? 12 : 10,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? kPrimaryBlue : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              // Feedback Text
              _buildCard(
                title: 'Your Feedback',
                subtitle: 'Share your thoughts, suggestions, or report any issues',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _feedbackController,
                      validator: _validateFeedback,
                      maxLines: 5,
                      minLines: 3,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText: 'Enter your feedback here...',
                        filled: true,
                        fillColor: const Color(0xFFF6F6F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                        ),
                        counterStyle: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Your feedback helps us improve our services',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error Display
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, child) {
                  if (profileProvider.error != null) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                              profileProvider.error!,
                              style: TextStyle(color: Colors.red[700], fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Submitting...' : 'Send Feedback',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Guidelines
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Feedback Guidelines',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Be specific about issues or suggestions\n'
                          '• Include steps to reproduce any problems\n'
                          '• Mention which device/browser you\'re using\n'
                          '• Keep feedback constructive and respectful',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    Widget? trailing,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            trailing != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kDarkGreyText,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6E6E6E),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 16),
            child,
          ]
        ],
      ),
    );
  }
}