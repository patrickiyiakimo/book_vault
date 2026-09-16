import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class StorageService {
  static const String _savedBooksKey = 'saved_books';
  static const String _recentlyViewedKey = 'recently_viewed';
  static const String _userKey = 'user_data';
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _isLoggedInKey = 'is_logged_in';

  // Saved Books
  static Future<List<Book>> getSavedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final booksJson = prefs.getStringList(_savedBooksKey) ?? [];
    return booksJson.map((json) => Book.fromJsonForSaving(jsonDecode(json))).toList();
  }

  static Future<void> saveBook(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    final books = await getSavedBooks();
    
    if (!books.any((b) => b.id == book.id)) {
      books.add(book);
      final booksJson = books.map((book) => jsonEncode(book.toJson())).toList();
      await prefs.setStringList(_savedBooksKey, booksJson);
    }
  }

  static Future<void> removeBook(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final books = await getSavedBooks();
    books.removeWhere((book) => book.id == bookId);
    final booksJson = books.map((book) => jsonEncode(book.toJson())).toList();
    await prefs.setStringList(_savedBooksKey, booksJson);
  }

  static Future<bool> isBookSaved(String bookId) async {
    final books = await getSavedBooks();
    return books.any((book) => book.id == bookId);
  }

  // Recently Viewed
  static Future<List<Book>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final booksJson = prefs.getStringList(_recentlyViewedKey) ?? [];
    return booksJson.map((json) => Book.fromJsonForSaving(jsonDecode(json))).toList();
  }

  static Future<void> addToRecentlyViewed(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    final books = await getRecentlyViewed();
    
    books.removeWhere((b) => b.id == book.id);
    books.insert(0, book);
    
    if (books.length > 20) {
      books.removeRange(20, books.length);
    }
    
    final booksJson = books.map((book) => jsonEncode(book.toJson())).toList();
    await prefs.setStringList(_recentlyViewedKey, booksJson);
  }

  // User Data
  static Future<void> saveUserData(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode({'name': name, 'email': email}));
  }

  static Future<Map<String, String>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      final data = jsonDecode(userJson);
      return {'name': data['name'], 'email': data['email']};
    }
    return null;
  }

  // Auth State
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // First Time
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstTimeKey) ?? true;
  }

  static Future<void> setFirstTimeDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, false);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
