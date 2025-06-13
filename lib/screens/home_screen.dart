import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/arxiv_paper.dart';
import '../services/arxiv_service.dart';
import '../widgets/paper_card.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ArxivService _arxivService = ArxivService();
  final int _batchSize = 10;
  List<ArxivPaper> _papers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentIndex = 0;
  int _loadedCount = 0;
  late Box<ArxivPaper> _favoritesBox;
  bool _isFavoritesBoxReady = false;
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _initHiveAndLoad();
  }

  Future<void> _initHiveAndLoad() async {
    try {
      if (!Hive.isBoxOpen('favorites')) {
        _favoritesBox = await Hive.openBox<ArxivPaper>('favorites');
      } else {
        _favoritesBox = Hive.box<ArxivPaper>('favorites');
      }
      
      print('[Hive] Favorites box opened successfully');
      print('[Hive] Current favorites count: ${_favoritesBox.length}');
      
      setState(() {
        _isFavoritesBoxReady = true;
      });
      
      _loadPapers();
    } catch (e, stackTrace) {
      print('[Hive] Error initializing favorites box: $e');
      print('[Hive] Stack trace: $stackTrace');
      setState(() {
        _isFavoritesBoxReady = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing favorites: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPapers() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final papers = await _arxivService.searchPapers(start: _loadedCount, maxResults: _batchSize);
      setState(() {
        _papers.addAll(papers);
        _loadedCount += papers.length;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load papers')),
        );
      }
    }
  }

  Future<void> _onSwipeRight(int index) async {
    if (!_isFavoritesBoxReady) {
      return;
    }

    final paper = _papers[index];
    try {
      print('[Hive] Attempting to add paper to favorites: ${paper.id} | ${paper.title}');
      
      final existingPapers = _favoritesBox.values.where((fav) => fav.id == paper.id);
      if (existingPapers.isEmpty) {
        await _favoritesBox.add(paper);
        print('[Hive] Successfully added to favorites: ${paper.id} | ${paper.title}');
        print('[Hive] Current favorites count: ${_favoritesBox.length}');
      } else {
        print('[Hive] Paper already in favorites: ${paper.id} | ${paper.title}');
      }
    } catch (e, stackTrace) {
      print('[Hive] Error adding to favorites: $e');
      print('[Hive] Stack trace: $stackTrace');
    }
  }

  void _onSwipeLeft(int index) {
    // No action needed for left swipe
  }

  void _maybeLoadMore() {
    if (_papers.length - _currentIndex <= 3 && !_isLoadingMore) {
      _loadPapers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inquira',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
                        tooltip: 'Favorites',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoritesScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Card Swiper
            Expanded(
              child: (!_isFavoritesBoxReady)
                  ? const Center(child: CircularProgressIndicator())
                  : _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              Expanded(
                                child: CardSwiper(
                                  controller: _swiperController,
                                  cardsCount: _papers.length,
                                  onSwipe: (previousIndex, currentIndex, direction) {
                                    if (direction == CardSwiperDirection.right) {
                                      _onSwipeRight(previousIndex);
                                    } else if (direction == CardSwiperDirection.left) {
                                      _onSwipeLeft(previousIndex);
                                    }
                                    if (currentIndex != null) {
                                      _currentIndex = currentIndex;
                                    }
                                    _maybeLoadMore();
                                    return true;
                                  },
                                  numberOfCardsDisplayed: 2,
                                  backCardOffset: const Offset(0, 20),
                                  padding: const EdgeInsets.all(8.0),
                                  cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
                                    Color tintColor = Colors.transparent;
                                    
                                    if (horizontalThresholdPercentage != null) {
                                      if (horizontalThresholdPercentage > 0.1) {
                                        // Swiping right - green tint
                                        tintColor = Colors.green.withOpacity(0.3);
                                      } else if (horizontalThresholdPercentage < -0.1) {
                                        // Swiping left - red tint
                                        tintColor = Colors.red.withOpacity(0.3);
                                      }
                                    }
                                    
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Stack(
                                        children: [
                                          PaperCard(
                                            paper: _papers[index],
                                            isFront: true,
                                          ),
                                          if (tintColor != Colors.transparent)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: tintColor,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Action buttons
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.close,
                                      color: Colors.red,
                                      onTap: () => _swiperController.swipeLeft(),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.favorite,
                                      color: Colors.green,
                                      onTap: () => _swiperController.swipeRight(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        child: Icon(
          icon,
          color: color,
          size: 30,
        ),
      ),
    );
  }
}
