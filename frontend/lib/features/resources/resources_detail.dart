// frontend/lib/features/resources/resource_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'resources_model.dart';

const kPrimaryBlue = Color(0xFF3A7BD5);
const kActionGreen = Color(0xFF4CAF50);
const kLightGrey = Color(0xFFF6F6F6);
const kDarkGreyText = Color(0xFF424242);

class ResourceDetailScreen extends StatefulWidget {
  final ResourceModel resource;

  const ResourceDetailScreen({
    super.key,
    required this.resource,
  });

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),

            const SizedBox(height: 24),

            // Content Section
            _buildContentSection(),

            const SizedBox(height: 24),

            // Tags Section
            if (widget.resource.tags.isNotEmpty) ...[
              _buildTagsSection(),
              const SizedBox(height: 24),
            ],

            // External Link Section
            if (widget.resource.hasUrl) ...[
              _buildExternalLinkSection(),
              const SizedBox(height: 32),
            ],

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: kDarkGreyText),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Resource Details',
        style: TextStyle(
          color: kDarkGreyText,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: _isBookmarked ? kActionGreen : kDarkGreyText,
          ),
          onPressed: () {
            setState(() {
              _isBookmarked = !_isBookmarked;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: kDarkGreyText),
          onPressed: _shareResource,
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.resource.resourceTypeColor,
            widget.resource.resourceTypeColor.withOpacity(0.8),
          ],
        ),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.resource.resourceTypeIcon,
                  color: widget.resource.resourceTypeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.resource.resourceTypeDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.resource.isFeatured)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            widget.resource.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          if (widget.resource.hasAuthor) ...[
            const SizedBox(height: 8),
            Text(
              'by ${widget.resource.author!}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              _buildInfoChip(
                icon: Icons.visibility,
                text: '${widget.resource.viewCount} views',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.people,
                text: widget.resource.targetAudienceDisplayName,
              ),
              if (widget.resource.estimatedReadTime != null) ...[
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.access_time,
                  text: widget.resource.estimatedReadTimeText,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description, color: kPrimaryBlue, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kDarkGreyText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kLightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            widget.resource.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: kDarkGreyText,
            ),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Icon(Icons.article, color: kPrimaryBlue, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Content',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kDarkGreyText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SelectableText(
            widget.resource.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: kDarkGreyText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label, color: kPrimaryBlue, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kDarkGreyText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.resource.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimaryBlue.withOpacity(0.3)),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExternalLinkSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'External Resource',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This resource links to external content for additional information.',
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchURL(widget.resource.url!),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open External Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
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
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Content'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kActionGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareResource,
                icon: const Icon(Icons.share),
                label: const Text('Share Resource'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isBookmarked = !_isBookmarked;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isBookmarked
                        ? 'Added to your reading list'
                        : 'Removed from reading list',
                  ),
                  backgroundColor: _isBookmarked ? kActionGreen : Colors.grey,
                ),
              );
            },
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            label: Text(_isBookmarked ? 'Saved to Reading List' : 'Save to Reading List'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isBookmarked ? kActionGreen : kPrimaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: _isBookmarked ? kActionGreen : kPrimaryBlue,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Resource Info Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resource Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: kDarkGreyText,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Type', widget.resource.resourceTypeDisplayName),
              _buildInfoRow('Target Audience', widget.resource.targetAudienceDisplayName),
              if (widget.resource.estimatedReadTime != null)
                _buildInfoRow('Reading Time', widget.resource.estimatedReadTimeText),
              _buildInfoRow('Views', '${widget.resource.viewCount}'),
              _buildInfoRow('Published', _formatDate(widget.resource.createdAt)),
              if (widget.resource.updatedAt != widget.resource.createdAt)
                _buildInfoRow('Last Updated', _formatDate(widget.resource.updatedAt)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kDarkGreyText,
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard() {
    final textToCopy = '''
${widget.resource.title}

${widget.resource.description}

${widget.resource.content}

${widget.resource.hasUrl ? '\nLink: ${widget.resource.url}' : ''}
''';

    Clipboard.setData(ClipboardData(text: textToCopy));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Content copied to clipboard'),
        backgroundColor: kActionGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareResource() {
    final shareText = '''
Check out this mental health resource: ${widget.resource.title}

${widget.resource.description}

${widget.resource.hasUrl ? '\nRead more: ${widget.resource.url}' : ''}

Shared from Perinatal Mental Health App
''';

    Share.share(
      shareText,
      subject: widget.resource.title,
    );
  }
}