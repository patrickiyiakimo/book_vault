import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import '../widgets/illustrations.dart';
import '../screens/book_details_screen.dart';

class SavedBooksScreen extends StatelessWidget {
  final List<Book> savedBooks;
  final Function(Book) onRemove;
  final VoidCallback onRefresh;

  const SavedBooksScreen({
    super.key,
    required this.savedBooks,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        centerTitle: false,
        title: Text(
          AppStrings.myLibrary,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.darkOrange,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: savedBooks.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: AppIllustrations.libraryIllustration(size: 190),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppStrings.noSavedBooks,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.startSaving,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: savedBooks.length,
                itemBuilder: (context, index) {
                  final book = savedBooks[index];
                  return BookListTile(
                    book: book,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailsScreen(book: book),
                        ),
                      );
                      onRefresh();
                    },
                    onSaveToggle: () => onRemove(book),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: AppColors.paleOrange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => onRemove(book),
                        icon: const Icon(
                          Icons.bookmark_remove,
                          color: AppColors.primaryOrange,
                          size: 20,
                        ),
                        tooltip: 'Remove',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}