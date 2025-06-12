import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFavoritesBox();
  }

  Future<void> _initFavoritesBox() async {
    try {
      if (!Hive.isBoxOpen('favorites')) {
        _favoritesBox = await Hive.openBox<ArxivPaper>('favorites');
      } else {
        _favoritesBox = Hive.box<ArxivPaper>('favorites');
      }
      
      print('[FavoritesScreen] Favorites box opened successfully');
      print('[FavoritesScreen] Current favorites count: ${_favoritesBox.length}');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('[FavoritesScreen] Error initializing favorites box: $e');
      print('[FavoritesScreen] Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading favorites',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initFavoritesBox,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Swipe right on papers to add them to your favorites',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _favoritesBox.length,
                      itemBuilder: (context, index) {
                        final paper = _favoritesBox.getAt(index);
                        if (paper == null) return const SizedBox.shrink();
                        return PaperCard(
                          paper: paper,
                          isCompact: true,
                        );
                      },
                    ),
    );
  }
}
