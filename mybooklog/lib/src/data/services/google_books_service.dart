import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../models/book_search_result.dart';

/// Raised when a Google Books request fails or returns a non-200 status.
class GoogleBooksException implements Exception {
  GoogleBooksException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// One page of search results plus the reported total (used for paging).
class GoogleBooksPage {
  const GoogleBooksPage({required this.results, required this.totalItems});
  final List<BookSearchResult> results;
  final int? totalItems;
}

/// Thin, injectable wrapper around the Google Books REST API. The [http.Client]
/// and [timeout] are injectable so the service can be unit-tested without real
/// network access.
class GoogleBooksService {
  GoogleBooksService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static const int pageSize = 20;
  static const String _base = 'https://www.googleapis.com/books/v1/volumes';

  /// Builds the `q=` clause from optional title/author fields. Empty when both
  /// are blank. Pure and unit-testable.
  static String buildQuery({required String title, required String author}) {
    final parts = <String>[];
    final t = title.trim();
    final a = author.trim();
    if (t.isNotEmpty) parts.add('intitle:${Uri.encodeQueryComponent(t)}');
    if (a.isNotEmpty) parts.add('inauthor:${Uri.encodeQueryComponent(a)}');
    return parts.isEmpty ? '' : parts.join('+');
  }

  /// Runs a search (optionally paged via [startIndex]) and returns normalized
  /// results. Throws [GoogleBooksException] on transport/status failures.
  Future<GoogleBooksPage> search(String query, {int startIndex = 0}) async {
    final url = Uri.parse(
      '$_base?q=$query&startIndex=$startIndex&maxResults=$pageSize'
      '&key=${AppConfig.googleBooksApiKey}',
    );
    final response = await _client.get(url).timeout(timeout);
    if (response.statusCode != 200) {
      throw GoogleBooksException(
        'Google Books API returned status ${response.statusCode}',
      );
    }
    final payload = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    final items = payload['items'] as List<dynamic>?;
    return GoogleBooksPage(
      results: items == null
          ? const <BookSearchResult>[]
          : BookSearchResult.listFromGoogleItems(items),
      totalItems: payload['totalItems'] as int?,
    );
  }

  /// Fetches a specific volume by id and returns its preferred ISBN, or null.
  Future<String?> fetchPreferredIsbnForVolume(String volumeId) async {
    final url = Uri.parse(
      '$_base/${Uri.encodeComponent(volumeId)}?key=${AppConfig.googleBooksApiKey}',
    );
    final response = await _client.get(url).timeout(timeout);
    if (response.statusCode != 200) return null;
    final payload = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    final volumeInfo = payload['volumeInfo'] as Map<String, dynamic>?;
    if (volumeInfo == null) return null;
    return BookSearchResult.extractPreferredIsbn(
      volumeInfo['industryIdentifiers'],
    );
  }
}
