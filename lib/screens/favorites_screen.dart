import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:another_flushbar/flushbar.dart';
import '../models/arxiv_paper.dart';
import '../widgets/paper_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Box<ArxivPaper> _favoritesBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      if (!Hive.isBoxOpen('favorites')) {
        _favoritesBox = await Hive.openBox<ArxivPaper>('favorites');
      } else {
        _favoritesBox = Hive.box<ArxivPaper>('favorites');
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing favorites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorites: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeFromFavorites(ArxivPaper paper) async {
    try {
      final index = _favoritesBox.values.toList().indexWhere((p) => p.id == paper.id);
      if (index != -1) {
        await _favoritesBox.deleteAt(index);
        setState(() {});
        _showCustomToast(
          context,
          'Removed from favorites',
          icon: Icons.delete_outline,
          color: Colors.red,
        );
      }
    } catch (e) {
      print('Error removing from favorites: $e');
      _showCustomToast(
        context,
        'Error removing from favorites',
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<bool> _showDeleteConfirmation(ArxivPaper paper) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Remove from Favorites',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Text(
            'Are you sure you want to remove this paper from your favorites?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await _removeFromFavorites(paper);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${paper.title}" from favorites'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove paper: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return false;
      }
    }
    return false;
  }

  void _showCustomToast(BuildContext context, String message, {required IconData icon, required Color color}) {
    Flushbar(
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      backgroundColor: color.withOpacity(0.95),
      icon: Icon(icon, color: Colors.white, size: 28),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      duration: const Duration(milliseconds: 1200),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 400),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoritesBox.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Swipe right on papers to add them to favorites',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoritesBox.length,
                  itemBuilder: (context, index) {
                    final paper = _favoritesBox.getAt(index);
                    if (paper == null) return const SizedBox.shrink();
                    return Dismissible(
                      key: Key(paper.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await _showDeleteConfirmation(paper);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: PaperCard(
                          paper: paper,
                          isCompact: true,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
