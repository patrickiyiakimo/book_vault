import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/book.dart';
import '../services/books_api_service.dart';
import '../services/storage_service.dart';
import '../widgets/book_card.dart';
import '../widgets/common_widgets.dart';
import '../widgets/navigation.dart';
import '../screens/search_screen.dart';
import '../screens/saved_books_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/book_details_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _profileRefreshTick = 0;
  final GlobalKey _searchKey = GlobalKey();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Book> _featuredBooks = [];
  List<Book> _trendingBooks = [];
  List<Book> _categoryBooks = [];
  List<Book> _savedBooks = [];
  final Map<String, bool> _savedStatus = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait<Object>([
        BooksApiService.getFeaturedBooks(),
        BooksApiService.getTrendingBooks(),
        BooksApiService.getBooksByCategory('fantasy'),
      ]);

      final featured = results[0] as List<Book>;
      final trending = results[1] as List<Book>;
      final category = results[2] as List<Book>;

      final savedBooks = await StorageService.getSavedBooks();

      if (!mounted) return;

      setState(() {
        _featuredBooks = featured;
        _trendingBooks = trending;
        _categoryBooks = category;
        _savedBooks = savedBooks;
        _isLoading = false;
      });

      for (final book in {...featured, ...trending, ...category}) {
        _savedStatus[book.id] = savedBooks.any((b) => b.id == book.id);
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // A 429 rate limit from the Google Books API is very common without an
      // API key. Fall back to whatever we already have instead of a hard error.
      final savedBooks = await StorageService.getSavedBooks();
      if (!mounted) return;
      if (_featuredBooks.isEmpty && _trendingBooks.isEmpty && _categoryBooks.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      } else {
        setState(() {
          _isLoading = false;
          _savedBooks = savedBooks;
        });
      }
    }
  }

  Future<void> _toggleSaveBook(Book book) async {
    final isSaved = _savedStatus[book.id] ?? false;
    if (isSaved) {
      await StorageService.removeBook(book.id);
      _savedStatus[book.id] = false;
      if (_currentIndex == 2) {
        _savedBooks = await StorageService.getSavedBooks();
      }
    } else {
      await StorageService.saveBook(book.copyWith(isSaved: true));
      _savedStatus[book.id] = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _refreshSavedBooks() async {
    final saved = await StorageService.getSavedBooks();
    if (mounted) {
      setState(() {
        _savedBooks = saved;
        for (final book in saved) {
          _savedStatus[book.id] = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      SearchScreen(key: _searchKey),
      SavedBooksScreen(
        savedBooks: _savedBooks,
        onRemove: (book) => _toggleSaveBook(book),
        onRefresh: _refreshSavedBooks,
      ),
      ProfileScreen(
        savedBooksCount: _savedBooks.length,
        refreshTick: _profileRefreshTick,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _refreshSavedBooks();
          }
          if (index == 3) {
            setState(() => _profileRefreshTick++);
          }
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _buildHomeAppBar(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildHomeContent(),
      ),
    );
  }

  Widget _buildHomeAppBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BookVault',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      Text(
                        'Discover your next read',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSavedCountBadge(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedCountBadge() {
    return InkWell(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.bookmarks_outlined,
              color: AppColors.primaryGreen,
              size: 22,
            ),
            if (_savedBooks.isNotEmpty)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${_savedBooks.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading books...', fullScreen: false);
    }

    if (_hasError) {
      return ErrorState(
        message: _errorMessage,
        onRetry: _loadData,
      );
    }

    // Hero banner section
    final heroBook = _featuredBooks.isNotEmpty ? _featuredBooks.first : null;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          if (heroBook != null) _buildHeroBanner(heroBook),
          const SizedBox(height: 24),
          SectionHeader(
            title: AppStrings.featuredBooks,
            onSeeAll: () => _showAllBooks(_featuredBooks, 'Featured Books'),
          ),
          const SizedBox(height: 12),
          _buildHorizontalBookList(_featuredBooks),
          const SizedBox(height: 24),
          SectionHeader(
            title: AppStrings.trendingNow,
            onSeeAll: () => _showAllBooks(_trendingBooks, 'Trending Now'),
          ),
          const SizedBox(height: 12),
          _buildHorizontalBookList(_trendingBooks),
          const SizedBox(height: 24),
          SectionHeader(
            title: AppStrings.categories,
          ),
          const SizedBox(height: 12),
          _buildCategoriesRow(),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Fantasy Picks',
            onSeeAll: () => _showAllBooks(_categoryBooks, 'Fantasy Picks'),
          ),
          const SizedBox(height: 12),
          _buildHorizontalBookList(_categoryBooks),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(Book book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _openBookDetails(book),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'FEATURED',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Read Now',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Center(
child: Container(
                           width: 90,
                           height: 130,
                           decoration: BoxDecoration(
                             color: AppColors.white,
                             borderRadius: BorderRadius.circular(14),
                             boxShadow: [
                               BoxShadow(
                                 color: AppColors.black.withOpacity(0.18),
                                 blurRadius: 16,
                                 offset: const Offset(4, 8),
                               ),
                             ],
                           ),
                           child: book.thumbnail != null
                               ? ClipRRect(
                                   borderRadius: BorderRadius.circular(14),
                                   child: Image.network(
                                    book.thumbnail!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        const Icon(Icons.menu_book, color: AppColors.primaryGreen, size: 40),
                                  ),
                                )
                              : const Icon(Icons.menu_book, color: AppColors.primaryGreen, size: 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalBookList(List<Book> books) {
    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: BookCard(
            book: books[index].copyWith(isSaved: _savedStatus[books[index].id] ?? false),
            onTap: () => _openBookDetails(books[index]),
            showSaveButton: true,
            onSaveToggle: () => _toggleSaveBook(books[index]),
            width: 140,
            height: 190,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppStrings.bookCategories.length,
        itemBuilder: (context, index) {
          final category = AppStrings.bookCategories[index];
          final icons = [
            Icons.auto_stories,
            Icons.lightbulb_outline,
            Icons.science_outlined,
            Icons.history_edu,
            Icons.person_outline,
            Icons.code,
            Icons.psychology_alt,
            Icons.favorite_outline,
            Icons.search,
            Icons.self_improvement,
            Icons.trending_up,
            Icons.psychology,
          ];
return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _openCategoryBooks(category),
            child: Container(
              width: 85,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.paleGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icons[index % icons.length],
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  void _openBookDetails(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailsScreen(book: book)),
    );
    _refreshSavedBooks();
  }

  void _showAllBooks(List<Book> books, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AllBooksScreen(
          books: books,
          title: title,
          onToggleSave: (book) => _toggleSaveBook(book),
          savedStatus: _savedStatus,
        ),
      ),
    );
  }

  void _openCategoryBooks(String category) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CategoryBooksScreen(category: category),
      ),
    );
  }
}

class _AllBooksScreen extends StatelessWidget {
  final List<Book> books;
  final String title;
  final Function(Book) onToggleSave;
  final Map<String, bool> savedStatus;

  const _AllBooksScreen({
    required this.books,
    required this.title,
    required this.onToggleSave,
    required this.savedStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: CustomAppBar(
        title: title,
        showBackButton: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookListTile(
            book: book.copyWith(isSaved: savedStatus[book.id] ?? false),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookDetailsScreen(book: book)),
            ),
            onSaveToggle: () => onToggleSave(book),
          );
        },
      ),
    );
  }
}

class _CategoryBooksScreen extends StatefulWidget {
  final String category;

  const _CategoryBooksScreen({required this.category});

  @override
  State<_CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<_CategoryBooksScreen> {
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = BooksApiService.getBooksByCategory(widget.category, maxResults: 20);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: CustomAppBar(
        title: widget.category,
        showBackButton: true,
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading books...');
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _booksFuture = BooksApiService.getBooksByCategory(widget.category, maxResults: 20);
              }),
            );
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return const EmptyState(
              icon: Icons.book_outlined,
              title: 'No books found',
              subtitle: 'No books available for this category',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return BookListTile(
                book: book,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookDetailsScreen(book: book)),
                ),
                onSaveToggle: () async {
                  final isSaved = await StorageService.isBookSaved(book.id);
                  if (isSaved) {
                    await StorageService.removeBook(book.id);
                  } else {
                    await StorageService.saveBook(book.copyWith(isSaved: true));
                  }
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isSaved ? 'Book removed from saved' : 'Book saved successfully!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: isSaved ? AppColors.mediumGray : AppColors.primaryGreen,
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}