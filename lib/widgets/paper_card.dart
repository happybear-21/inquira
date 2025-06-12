import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/arxiv_paper.dart';

class PaperCard extends StatefulWidget {
  final ArxivPaper paper;
  final bool isFront;
  final bool isCompact;

  const PaperCard({
    super.key,
    required this.paper,
    this.isFront = true,
    this.isCompact = false,
  });

  @override
  State<PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends State<PaperCard> {
  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the paper. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening the paper: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePaper() async {
    try {
      final String shareText = '${widget.paper.title}\n\n'
          'Authors: ${widget.paper.authors.join(", ")}\n\n'
          'Read the paper here: ${widget.paper.pdfUrl}';
      
      await Share.share(
        shareText,
        subject: widget.paper.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing paper: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\n+'), ' ') // Replace multiple newlines with single space
        .replaceAll(RegExp(r'\r+'), ' ') // Replace carriage returns with space
        .replaceAll(RegExp(r'\t+'), ' ') // Replace tabs with space
        .trim(); // Remove leading/trailing whitespace
  }

  String _formatAuthors(List<String> authors) {
    if (authors.isEmpty) return '';
    if (authors.length == 1) return authors[0];
    if (authors.length == 2) return '${authors[0]} and ${authors[1]}';
    return '${authors.sublist(0, authors.length - 1).join(", ")} and ${authors.last}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return widget.isCompact ? _buildCompactCard(context) : _buildFullCard(context);
  }

  Widget _buildCompactCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _cleanText(widget.paper.title),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatAuthors(widget.paper.authors),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: _sharePaper,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.article),
                  label: const Text('Read Paper'),
                  onPressed: () => _launchUrl(widget.paper.pdfUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _cleanText(widget.paper.title),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: widget.paper.categories.map((category) {
                return Chip(
                  label: Text(_cleanText(category)),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text(
              _formatAuthors(widget.paper.authors),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _cleanText(widget.paper.abstract),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(widget.paper.publishedDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      onPressed: _sharePaper,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.article),
                      label: const Text('Read Paper'),
                      onPressed: () => _launchUrl(widget.paper.pdfUrl),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 