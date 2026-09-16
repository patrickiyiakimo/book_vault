class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? thumbnail;
  final String? publishedDate;
  final int? pageCount;
  final double? averageRating;
  final int? ratingsCount;
  final String? isbn;
  final String? publisher;
  final List<String>? categories;
  final String? infoLink;
  final bool isSaved;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.thumbnail,
    this.publishedDate,
    this.pageCount,
    this.averageRating,
    this.ratingsCount,
    this.isbn,
    this.publisher,
    this.categories,
    this.infoLink,
    this.isSaved = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};

    String? thumbnail = imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'];
    if (thumbnail != null) {
      thumbnail = thumbnail.replaceAll('http://', 'https://');
    }

    String author = 'Unknown Author';
    if (volumeInfo['authors'] != null && (volumeInfo['authors'] as List).isNotEmpty) {
      author = (volumeInfo['authors'] as List).join(', ');
    }

    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Untitled',
      author: author,
      description: volumeInfo['description'],
      thumbnail: thumbnail,
      publishedDate: volumeInfo['publishedDate'],
      pageCount: volumeInfo['pageCount'],
      averageRating: volumeInfo['averageRating']?.toDouble(),
      ratingsCount: volumeInfo['ratingsCount'],
      isbn: _getIsbn(volumeInfo),
      publisher: volumeInfo['publisher'],
      categories: volumeInfo['categories']?.cast<String>(),
      infoLink: volumeInfo['infoLink'],
    );
  }

  static String? _getIsbn(Map<String, dynamic> volumeInfo) {
    final identifiers = volumeInfo['industryIdentifiers'] as List?;
    if (identifiers != null) {
      for (var id in identifiers) {
        if (id['type'] == 'ISBN_13') return id['identifier'];
        if (id['type'] == 'ISBN_10') return id['identifier'];
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'thumbnail': thumbnail,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'averageRating': averageRating,
      'ratingsCount': ratingsCount,
      'isbn': isbn,
      'publisher': publisher,
      'categories': categories,
      'infoLink': infoLink,
    };
  }

  factory Book.fromJsonForSaving(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      author: json['author'] ?? 'Unknown Author',
      description: json['description'],
      thumbnail: json['thumbnail'],
      publishedDate: json['publishedDate'],
      pageCount: json['pageCount'],
      averageRating: json['averageRating']?.toDouble(),
      ratingsCount: json['ratingsCount'],
      isbn: json['isbn'],
      publisher: json['publisher'],
      categories: json['categories']?.cast<String>(),
      infoLink: json['infoLink'],
      isSaved: true,
    );
  }

  Book copyWith({bool? isSaved}) {
    return Book(
      id: id,
      title: title,
      author: author,
      description: description,
      thumbnail: thumbnail,
      publishedDate: publishedDate,
      pageCount: pageCount,
      averageRating: averageRating,
      ratingsCount: ratingsCount,
      isbn: isbn,
      publisher: publisher,
      categories: categories,
      infoLink: infoLink,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
