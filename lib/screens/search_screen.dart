import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/arxiv_paper.dart';
import '../services/arxiv_service.dart';
import '../widgets/paper_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ArxivService _arxivService = ArxivService();
  final TextEditingController _searchController = TextEditingController();
  final int _batchSize = 10;
  List<ArxivPaper> _papers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _start = 0;
  bool _hasMore = true;
  late Box<ArxivPaper> _favoritesBox;
  bool _isFavoritesBoxReady = false;

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
      
      setState(() {
        _isFavoritesBoxReady = true;
        _isLoading = false; // Set loading to false initially
      });
    } catch (e) {
      print('Error initializing favorites box: $e');
      setState(() {
        _isFavoritesBoxReady = false;
        _isLoading = false; // Set loading to false even on error
      });
    }
  }

  Future<void> _loadPapers({bool refresh = false}) async {
    if (_isLoading || (!refresh && !_hasMore)) return;
    if (!mounted) return;

    // Don't load if search is empty
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _papers = [];
        _hasMore = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      if (refresh) {
        _start = 0;
        _papers = [];
        _hasMore = true;
      }
    });

    try {
      final papers = await _arxivService.searchPapers(
        searchQuery: _searchController.text.trim(),
        start: _start,
        maxResults: _batchSize,
      );

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _papers = papers;
        } else {
          _papers.addAll(papers);
        }
        _start += papers.length;
        _hasMore = papers.length == _batchSize;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading papers: $e'); // Debug print
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isFavorite(ArxivPaper paper) {
    return _favoritesBox.values.any((fav) => fav.id == paper.id);
  }

  Future<void> _toggleFavorite(ArxivPaper paper) async {
    if (!_isFavoritesBoxReady) return;

    try {
      final existingPapers = _favoritesBox.values.where((fav) => fav.id == paper.id);
      if (existingPapers.isEmpty) {
        await _favoritesBox.add(paper);
      } else {
        final key = _favoritesBox.keys.firstWhere(
          (key) => _favoritesBox.get(key)?.id == paper.id,
        );
        await _favoritesBox.delete(key);
      }
      setState(() {}); // Refresh UI
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Papers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search papers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _papers = [];
                            _hasMore = false;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _loadPapers(refresh: true),
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _loadPapers(refresh: true),
            ),
          ),
          // Papers List
          Expanded(
            child: _isLoading && _papers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _papers.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Enter a search term to find papers'
                              : 'No papers found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo is ScrollEndNotification) {
                            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
                              if (_hasMore && !_isLoading) {
                                _loadPapers();
                              }
                            }
                          }
                          return true;
                        },
                        child: ListView.builder(
                          itemCount: _papers.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _papers.length) {
                              return _hasMore
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }
                            final paper = _papers[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: PaperCard(
                                paper: paper,
                                isCompact: true,
                                onFavoriteToggle: () => _toggleFavorite(paper),
                                isFavorite: _isFavorite(paper),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 