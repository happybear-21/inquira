import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/arxiv_paper.dart';
import '../services/arxiv_service.dart';
import '../widgets/paper_card.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ArxivService _arxivService = ArxivService();
  final int _batchSize = 10;
  List<ArxivPaper> _papers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentIndex = 0;
  int _loadedCount = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isDragging = false;
  late Box<ArxivPaper> _favoritesBox;

  @override
  void initState() {
    super.initState();
    _initHiveAndLoad();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _initHiveAndLoad() async {
    _favoritesBox = await Hive.openBox<ArxivPaper>('favorites');
    _loadPapers();
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _onSwipeRight() {
    if (_currentIndex < _papers.length) {
      // Save to favorites
      final paper = _papers[_currentIndex];
      if (!_favoritesBox.values.any((fav) => fav.id == paper.id)) {
        _favoritesBox.add(paper);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to favorites!')),
        );
      }
      _animationController.forward().then((_) {
        setState(() {
          _currentIndex++;
          _animationController.reset();
        });
        _maybeLoadMore();
      });
    }
  }

  void _onSwipeLeft() {
    if (_currentIndex < _papers.length) {
      setState(() {
        _currentIndex++;
      });
      _maybeLoadMore();
    }
  }

  void _maybeLoadMore() {
    // If 3 cards left, load more
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inquira',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite),
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _papers.isEmpty
                      ? const Center(
                          child: Text('No papers available'),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Only show two cards: the top (front) and the next (back)
                              if (_currentIndex + 1 < _papers.length)
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOut,
                                  top: 30,
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 350),
                                    scale: 0.92,
                                    curve: Curves.easeOut,
                                    child: PaperCard(
                                      paper: _papers[_currentIndex + 1],
                                      isFront: false,
                                    ),
                                  ),
                                ),
                              if (_currentIndex < _papers.length)
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOut,
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onHorizontalDragEnd: (details) {
                                      if (details.primaryVelocity! > 0) {
                                        _onSwipeRight();
                                      } else if (details.primaryVelocity! < 0) {
                                        _onSwipeLeft();
                                      }
                                    },
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: Opacity(
                                        opacity: 1.0, // Ensure top card is fully opaque
                                        child: PaperCard(
                                          paper: _papers[_currentIndex],
                                          isFront: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_isLoadingMore)
                                const Positioned(
                                  bottom: 16,
                                  left: 0,
                                  right: 0,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                            ],
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    color: Colors.red,
                    onTap: () {
                      _onSwipeLeft();
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.favorite,
                    color: Colors.green,
                    onTap: () {
                      _onSwipeRight();
                    },
                  ),
                ],
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
