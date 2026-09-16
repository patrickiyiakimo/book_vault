import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BooksApiException implements Exception {
  final String message;
  final int? statusCode;

  const BooksApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class BooksApiService {
  static const String _googleBaseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const String _openLibraryBaseUrl = 'https://openlibrary.org';
  static const String _openLibrarySearchUrl = 'https://openlibrary.org/search.json';
  static const String _coversBaseUrl = 'https://covers.openlibrary.org/b/id';

  // Optionally provide a Google Books API key at build/run time:
  //   flutter run --dart-define=GOOGLE_BOOKS_API_KEY=your_key_here
  // When no key is supplied, the app uses the free, keyless Open Library API
  // (no rate limiting, works in the browser without CORS issues).
  static const String _apiKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

  static const int _maxRetries = 3;

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  static Future<List<Book>> searchBooks(String query, {int startIndex = 0, int maxResults = 20}) async {
    if (_apiKey.isNotEmpty) {
      return _googleSearch(query, startIndex: startIndex, maxResults: maxResults);
    }
    return _openLibrarySearch(query, maxResults: maxResults, page: (startIndex ~/ maxResults) + 1);
  }

  static Future<List<Book>> getFeaturedBooks({int maxResults = 10}) async {
    if (_apiKey.isNotEmpty) {
      return _googleSearch('subject:fiction', startIndex: 0, maxResults: maxResults, orderBy: 'relevance');
    }
    return _openLibrarySearch('subject:fiction', maxResults: maxResults, sort: 'editions');
  }

  static Future<List<Book>> getTrendingBooks({int maxResults = 10}) async {
    if (_apiKey.isNotEmpty) {
      return _googleSearch('subject:bestseller', startIndex: 0, maxResults: maxResults, orderBy: 'newest');
    }
    return _openLibrarySearch('subject:fiction', maxResults: maxResults, sort: 'new');
  }

  static Future<List<Book>> getBooksByCategory(String category, {int maxResults = 10}) async {
    if (_apiKey.isNotEmpty) {
      return _googleSearch('subject:$category', startIndex: 0, maxResults: maxResults);
    }
    return _openLibrarySearch('subject:$category', maxResults: maxResults, sort: 'editions');
  }

  static Future<Book?> getBookById(String bookId) async {
    if (_apiKey.isNotEmpty) {
      final cleanId = bookId.replaceAll(RegExp(r'^/?books/'), '');
      final uri = Uri.parse('$_googleBaseUrl/$cleanId');
      final response = await _get(uri);
      if (response?.statusCode == 200 && response != null) {
        return Book.fromJson(json.decode(response.body) as Map<String, dynamic>);
      }
      return null;
    }

    // Open Library: book ids look like "/works/OL123W".
    final cleanId = bookId.replaceAll(RegExp(r'^/?works/'), '');
    if (cleanId.isEmpty) return null;
    final uri = Uri.parse('$_openLibraryBaseUrl/works/$cleanId.json');
    final response = await _get(uri);
    if (response?.statusCode != 200 || response == null) return null;
    return _openLibraryWorkToBook(json.decode(response.body) as Map<String, dynamic>);
  }

  // --------------------------------------------------------------------------
  // Open Library provider (default)
  // --------------------------------------------------------------------------

  static Future<List<Book>> _openLibrarySearch(
    String query, {
    required int maxResults,
    int page = 1,
    String? sort,
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'limit': '$maxResults',
      'page': '$page',
      'fields': 'key,title,author_name,cover_i,first_publish_year,isbn,'
          'number_of_pages_median,subject,publisher,ratings_average,ratings_count',
    };
    if (sort != null) queryParams['sort'] = sort;

    final uri = Uri.parse(_openLibrarySearchUrl).replace(queryParameters: queryParams);
    final response = await _get(uri);

    if (response?.statusCode != 200 || response == null) {
      throw BooksApiException(
        _openLibraryErrorMessage(response) ?? 'Failed to load books',
        statusCode: response?.statusCode,
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final docs = (data['docs'] as List?) ?? const [];
    return docs
        .whereType<Map<String, dynamic>>()
        .map(_openLibraryDocToBook)
        .where((book) => book.id.isNotEmpty)
        .toList();
  }

  static Book _openLibraryDocToBook(Map<String, dynamic> doc) {
    final key = (doc['key'] as String?) ?? '';
    final coverId = doc['cover_i'];
    final authors = (doc['author_name'] as List?)?.cast<String>() ?? const [];
    final isbns = (doc['isbn'] as List?)?.cast<String>() ?? const [];
    final subjects = (doc['subject'] as List?)?.cast<String>() ?? const [];
    final publishers = (doc['publisher'] as List?)?.cast<String>() ?? const [];

    return Book(
      id: key,
      title: (doc['title'] as String?) ?? 'Untitled',
      author: authors.isNotEmpty ? authors.join(', ') : 'Unknown Author',
      thumbnail: coverId != null ? '$_coversBaseUrl/$coverId-M.jpg' : null,
      publishedDate: doc['first_publish_year']?.toString(),
      pageCount: doc['number_of_pages_median'] as int?,
      averageRating: (doc['ratings_average'] as num?)?.toDouble(),
      ratingsCount: (doc['ratings_count'] as num?)?.toInt(),
      isbn: isbns.isNotEmpty ? isbns.first : null,
      publisher: publishers.isNotEmpty ? publishers.first : null,
      categories: subjects.isNotEmpty ? subjects.take(6).toList() : null,
      infoLink: key.isNotEmpty ? 'https://openlibrary.org$key' : null,
    );
  }

  static Book _openLibraryWorkToBook(Map<String, dynamic> data) {
    final key = (data['key'] as String?) ?? '';
    final description = data['description'];
    final subjects = (data['subjects'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    String? descriptionText;
    if (description is String) {
      descriptionText = description;
    } else if (description is Map<String, dynamic>) {
      final value = description['value'];
      if (value is String) descriptionText = value;
    }

    return Book(
      id: key,
      title: (data['title'] as String?) ?? 'Untitled',
      author: 'Unknown Author',
      description: descriptionText,
      publishedDate: data['first_publish_date'] as String?,
      categories: subjects
          .map((s) => (s['name'] as String?) ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      infoLink: key.isNotEmpty ? 'https://openlibrary.org$key' : null,
    );
  }

  static String? _openLibraryErrorMessage(http.Response? response) {
    if (response == null || response.body.isEmpty) return null;
    try {
      final data = json.decode(response.body) as Map<String, dynamic>?;
      final error = data?['error'];
      if (error is String) return error;
      return null;
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Google Books provider (used only when GOOGLE_BOOKS_API_KEY is provided)
  // --------------------------------------------------------------------------

  static Future<List<Book>> _googleSearch(
    String query, {
    required int startIndex,
    required int maxResults,
    String? orderBy,
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'startIndex': '$startIndex',
      'maxResults': '$maxResults',
      'country': 'US',
      'key': _apiKey,
    };
    if (orderBy != null) queryParams['orderBy'] = orderBy;

    final uri = Uri.parse(_googleBaseUrl).replace(queryParameters: queryParams);
    final response = await _get(uri);

    if (response?.statusCode != 200 || response == null) {
      throw BooksApiException(
        _googleErrorMessage(response) ?? 'Failed to load books',
        statusCode: response?.statusCode,
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    return items.whereType<Map<String, dynamic>>().map(Book.fromJson).toList();
  }

  static String? _googleErrorMessage(http.Response? response) {
    if (response == null || response.body.isEmpty) return null;
    try {
      final data = json.decode(response.body) as Map<String, dynamic>?;
      final error = data?['error'] as Map<String, dynamic>?;
      return error?['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Shared HTTP helper with retry/backoff
  // --------------------------------------------------------------------------

  static Future<http.Response?> _get(Uri uri) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http.get(uri).timeout(const Duration(seconds: 20));
        final retryable = response.statusCode == 429 || response.statusCode >= 500;
        if (!retryable) {
          return response;
        }
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      } on TimeoutException {
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}