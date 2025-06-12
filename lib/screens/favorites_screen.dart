import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/arxiv_paper.dart';
import '../widgets/paper_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesBox = Hive.box<ArxivPaper>('favorites');
    final favorites = favoritesBox.values.toList().reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: favorites.isEmpty
          ? const Center(child: Text('No favorites yet.'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final paper = favorites[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: PaperCard(paper: paper),
                );
              },
            ),
    );
  }
}
