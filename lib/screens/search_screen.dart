import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/book.dart';
import '../services/books_api_service.dart';
import '../services/storage_service.dart';
import '../widgets/book_card.dart';
import '../widgets/common_widgets.dart';
import '../widgets/illustrations.dart';
import '../screens/book_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Book> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounce = Timer(const Duration(milliseconds: 800), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = '';
    });

    try {
      final results = await BooksApiService.searchBooks(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSearching = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _toggleSave(Book book) async {
    final isSaved = await StorageService.isBookSaved(book.id);
    if (isSaved) {
      await StorageService.removeBook(book.id);
    } else {
      await StorageService.saveBook(book.copyWith(isSaved: true));
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved ? 'Book removed from saved' : 'Book saved successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSaved ? AppColors.mediumGray : AppColors.primaryOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _buildSearchBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkOrange,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.black,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 15,
                color: AppColors.mediumGray,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.primaryOrange, size: 22),
              suffixIcon: _isSearching
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                        ),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.close, color: AppColors.mediumGray, size: 20),
                        )
                      : null,
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Searching books...');
    }

    if (_errorMessage.isNotEmpty) {
      return ErrorState(
        message: _errorMessage,
        onRetry: () => _performSearch(_searchController.text.trim()),
      );
    }

    if (!_hasSearched) {
      return _buildInitialSearchView();
    }

    if (_results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: AppStrings.noResultsFound,
        subtitle: AppStrings.tryDifferentKeywords,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildSearchResultItem(_results[index]),
    );
  }

  Widget _buildInitialSearchView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          AppIllustrations.libraryIllustration(size: 190),
          const SizedBox(height: 24),
          Text(
            'Discover Books',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search millions of books\nby title, author, or ISBN',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.mediumGray,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Popular Searches',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Harry Potter',
              'Romance',
              'Science Fiction',
              'Business',
              'Python',
              'Psychology',
              'History',
              'Classics',
            ].map((query) {
              return InkWell(
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.paleOrange,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    query,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Book book) {
    return FutureBuilder<bool>(
      future: StorageService.isBookSaved(book.id),
      builder: (context, snapshot) {
        final isSaved = snapshot.data ?? false;
        return BookListTile(
          book: book.copyWith(isSaved: isSaved),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookDetailsScreen(book: book)),
          ),
          onSaveToggle: () => _toggleSave(book),
        );
      },
    );
  }
}