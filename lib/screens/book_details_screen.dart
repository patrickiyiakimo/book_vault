import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/book.dart';
import '../services/books_api_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/navigation.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late Book _book;
  bool _isSaved = false;
  bool _showFullDescription = false;
  bool _isLoadingSave = true;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _checkIfSaved();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final book = widget.book;
    // Open Library search results have no description; fetch the full record.
    if (book.description == null && book.infoLink != null) {
      try {
        final details = await BooksApiService.getBookById(book.id);
        if (!mounted) return;
        if (details != null) {
          setState(() {
            _book = Book(
              id: details.id.isNotEmpty ? details.id : book.id,
              title: details.title.isNotEmpty && details.title != 'Untitled' ? details.title : book.title,
              author: book.author,
              description: details.description,
              thumbnail: book.thumbnail,
              publishedDate: details.publishedDate ?? book.publishedDate,
              pageCount: book.pageCount,
              averageRating: book.averageRating,
              ratingsCount: book.ratingsCount,
              isbn: book.isbn,
              publisher: book.publisher,
              categories: details.categories?.isNotEmpty == true ? details.categories : book.categories,
              infoLink: details.infoLink ?? book.infoLink,
              isSaved: _book.isSaved,
            );
          });
        }
      } catch (_) {
        // Ignore enrichment failures; the list data is still shown.
      }
    }
  }

  Future<void> _checkIfSaved() async {
    final isSaved = await StorageService.isBookSaved(_book.id);
    if (mounted) {
      setState(() {
        _isSaved = isSaved;
        _isLoadingSave = false;
      });
    }
  }

  Future<void> _toggleSave() async {
    setState(() => _isLoadingSave = true);
    if (_isSaved) {
      await StorageService.removeBook(_book.id);
      if (!mounted) return;
      setState(() => _isSaved = false);
      _showSnackBar(AppStrings.bookRemoved, AppColors.mediumGray);
    } else {
      await StorageService.addToRecentlyViewed(_book);
      await StorageService.saveBook(_book.copyWith(isSaved: true));
      if (!mounted) return;
      setState(() => _isSaved = true);
      _showSnackBar(AppStrings.bookSaved, AppColors.primaryOrange);
    }
    if (mounted) {
      setState(() => _isLoadingSave = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    final description = book.description ?? 'No description available for this book.';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: CustomAppBar(
        title: 'Book Details',
        showBackButton: true,
        actions: [
          GestureDetector(
            onTap: _toggleSave,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isSaved ? AppColors.primaryOrange : AppColors.offWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: _isSaved ? AppColors.white : AppColors.darkGray,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverSection(book),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.author,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsRow(book),
                  const SizedBox(height: 20),
                  if (book.publisher != null || book.isbn != null) ...[
                    _buildInfoRow(
                      Icons.business,
                      'Published by',
                      book.publisher ?? 'Unknown',
                    ),
                    if (book.publisher != null) const SizedBox(height: 8),
                    if (book.isbn != null)
                      _buildInfoRow(
                        Icons.tag,
                        'ISBN',
                        book.isbn!,
                      ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showFullDescription || description.length < 250
                        ? description
                        : '${description.substring(0, 250)}...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.darkGray,
                      height: 1.6,
                    ),
                  ),
                  if (description.length > 250)
                    InkWell(
                      onTap: () => setState(() => _showFullDescription = !_showFullDescription),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _showFullDescription ? AppStrings.showLess : AppStrings.readMore,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (book.categories != null && book.categories!.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: book.categories!.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.paleOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  PrimaryButton(
                    text: _isSaved ? AppStrings.unsaveBook : AppStrings.saveBook,
                    onPressed: _toggleSave,
                    isLoading: _isLoadingSave,
                    icon: _isSaved ? Icons.bookmark_remove : Icons.bookmark_add,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverSection(Book book) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.paleOrange,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(6, 10),
                  ),
                ],
              ),
              child: book.thumbnail != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CachedNetworkImage(
                        imageUrl: book.thumbnail!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.menu_book, size: 60, color: AppColors.primaryOrange),
                      ),
                    )
                  : const Icon(Icons.menu_book, size: 60, color: AppColors.primaryOrange),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRatingBadge(book),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.calendar_today_outlined,
                  label: AppStrings.publishedDate,
                  value: _formatDate(book.publishedDate ?? 'Unknown'),
                ),
                const SizedBox(height: 12),
                _buildDetailItem(
                  icon: Icons.menu_book_outlined,
                  label: AppStrings.pages,
                  value: book.pageCount != null ? '${book.pageCount}' : 'Unknown',
                ),
                const SizedBox(height: 12),
                _buildDetailItem(
                  icon: Icons.star_outline,
                  label: 'Rating',
                  value: book.averageRating != null
                      ? book.averageRating!.toStringAsFixed(1)
                      : 'N/A',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(Book book) {
    final rating = book.averageRating ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating.round() ? Icons.star : Icons.star_border,
              color: AppColors.gold,
              size: 20,
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          '${rating > 0 ? rating.toStringAsFixed(1) : 'No'} rating'
          '${book.ratingsCount != null ? ' (${book.ratingsCount!} reviews)' : ''}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.mediumGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Book book) {
    final hasRating = book.averageRating != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (hasRating) ...[
          _buildStatItem(
            icon: Icons.star,
            value: book.averageRating!.toStringAsFixed(1),
            label: 'Rating',
            color: AppColors.gold,
          ),
          _buildDivider(),
        ],
        _buildStatItem(
          icon: Icons.menu_book,
          value: book.pageCount != null ? '${book.pageCount}' : 'N/A',
          label: 'Pages',
          color: AppColors.primaryOrange,
        ),
        _buildDivider(),
        _buildStatItem(
          icon: Icons.person_outline,
          value: (book.author.contains(',') ? '${book.author.split(',').length}' : '1'),
          label: book.author.contains(',') ? 'Authors' : 'Author',
          color: AppColors.primaryOrange,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.lightGray,
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.paleOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.mediumGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty || date == 'Unknown') return 'Unknown';
    try {
      final parts = date.split('-');
      if (parts.length >= 3) {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final monthIndex = int.tryParse(parts[1]) ?? 1;
        return '${months[monthIndex - 1]} ${parts[2]}, ${parts[0]}';
      }
      return date;
    } catch (_) {
      return date;
    }
  }
}