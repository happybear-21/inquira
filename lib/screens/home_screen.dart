import 'package:flutter/material.dart';
import '../models/arxiv_paper.dart';
import '../services/arxiv_service.dart';
import '../widgets/paper_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ArxivService _arxivService = ArxivService();
  List<ArxivPaper> _papers = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadPapers();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPapers() async {
    try {
      final papers = await _arxivService.searchPapers();
      setState(() {
        _papers = papers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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
      _animationController.forward().then((_) {
        setState(() {
          _currentIndex++;
          _animationController.reset();
        });
      });
    }
  }

  void _onSwipeLeft() {
    if (_currentIndex < _papers.length) {
      setState(() {
        _currentIndex++;
      });
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
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _papers.isEmpty
                      ? const Center(
                          child: Text('No papers available'),
                        )
                      : Stack(
                          children: [
                            if (_currentIndex < _papers.length)
                              Positioned.fill(
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
                                    child: PaperCard(
                                      paper: _papers[_currentIndex],
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentIndex + 1 < _papers.length)
                              Positioned.fill(
                                child: Transform.translate(
                                  offset: const Offset(40, 40),
                                  child: PaperCard(
                                    paper: _papers[_currentIndex + 1],
                                  ),
                                ),
                              ),
                          ],
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
                    onTap: _onSwipeLeft,
                  ),
                  _buildActionButton(
                    icon: Icons.favorite,
                    color: Colors.green,
                    onTap: _onSwipeRight,
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
