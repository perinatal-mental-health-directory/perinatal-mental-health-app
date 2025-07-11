import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kDarkGreyText = Color(0xFF424242);

class SubmitFeedbackScreen extends StatefulWidget {
  const SubmitFeedbackScreen({super.key});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  bool isAnonymous = false;
  int selectedRating = 3;
  final TextEditingController feedbackController = TextEditingController();

  void _handleSubmit() {
    // Optional: API call, validation, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your feedback!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> ratingEmojis = ['😞', '🙁', '😐', '🙂', '😄'];
    final List<String> emojiLabels = ['Very Bad', 'Bad', 'Okay', 'Good', 'Great'];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCard(
              title: 'Submit anonymously',
              subtitle:
              'Your feedback will be sent without your personal information',
              trailing: Switch(
                activeColor: Color(0xFF3A7BD5),
                inactiveTrackColor: Colors.white,
                inactiveThumbColor: Colors.grey,
                value: isAnonymous,
                onChanged: (value) {
                  setState(() {
                    isAnonymous = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'How was your experience?',
              subtitle:
              'Rate your overall satisfaction with the app or services',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(ratingEmojis.length, (index) {
                  final selected = selectedRating == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRating = index;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          ratingEmojis[index],
                          style: TextStyle(
                            fontSize: selected ? 34 : 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emojiLabels[index],
                          style: TextStyle(
                            fontSize: selected ? 14 : 12,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? kPrimaryBlue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Your Feedback',
              subtitle:
              'Share your thoughts on the app or the services you\'ve accessed',
              child: TextFormField(
                controller: feedbackController,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your feedback here',
                  filled: true,
                  fillColor: const Color(0xFFF6F6F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Send Feedback',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.2,),
                ),
              ),
            )
          ],
        ),
      ),
      // Optional bottomNavigationBar
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
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
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
            const SizedBox(height: 12),
            child,
          ]
        ],
      ),
    );
  }
}
