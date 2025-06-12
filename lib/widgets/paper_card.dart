import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/arxiv_paper.dart';

class PaperCard extends StatelessWidget {
  final ArxivPaper paper;
  final bool isFront;

  const PaperCard({
    super.key,
    required this.paper,
    this.isFront = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500, // Fixed height for the card
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paper.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final category in paper.categories.take(3))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Authors: ${paper.authors.join(", ")}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      paper.abstract,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, y').format(paper.publishedDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Open PDF
                      },
                      child: const Text('Read Paper'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 