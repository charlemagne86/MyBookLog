import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../models/book_search_result.dart';

/// The error raised when the internet book search fails — for example when
/// there is no connection, or Google's service reports a problem.
class GoogleBooksException implements Exception {
  GoogleBooksException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// One "page" of search results (results arrive in batches of 20) together
/// with Google's count of how many matches exist in total. The total lets
/// the results screen know whether more pages remain to be fetched.
class GoogleBooksPage {
  const GoogleBooksPage({required this.results, required this.totalItems});
  final List<BookSearchResult> results;
  final int? totalItems;
}

/// The app's connection to Google's public book database, used to look up
/// books by title and/or author when the user wants to add one.
///
/// Each request gives up after 10 seconds rather than leaving the user
/// staring at a spinner forever. The network pieces can be swapped out with
/// pretend versions so automated tests can run without real internet access.
class GoogleBooksService {
  GoogleBooksService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static const int pageSize = 20;
  static const String _base = 'https://www.googleapis.com/books/v1/volumes';

  /// Google's own "no cover available" placeholder is a tiny flat-color
  /// graphic — real cover art, with actual illustration detail, is
  /// consistently larger than this. Used by [isThumbnailValid] to tell the
  /// two apart by file size when a byte count is available.
  static const int _minValidThumbnailBytes = 2000;

  /// Turns what the user typed (a title, an author, or both) into the exact
  /// search phrase Google's service expects — e.g. title "Dune" and author
  /// "Herbert" become "intitle:Dune+inauthor:Herbert". Special characters are
  /// safely encoded, and blank fields are simply left out. If both fields are
  /// blank, the result is empty and the caller knows not to search at all.
  static String buildQuery({required String title, required String author}) {
    final parts = <String>[];
    final t = title.trim();
    final a = author.trim();
    if (t.isNotEmpty) parts.add('intitle:${Uri.encodeQueryComponent(t)}');
    if (a.isNotEmpty) parts.add('inauthor:${Uri.encodeQueryComponent(a)}');
    return parts.isEmpty ? '' : parts.join('+');
  }

  /// Sends the search to Google and returns one page of tidied-up results.
  ///
  /// [startIndex] says how many results to skip — page 2 starts at 20, page 3
  /// at 40, and so on. If Google reports a problem or the connection fails,
  /// a [GoogleBooksException] is raised for the screen to show as an error.
  Future<GoogleBooksPage> search(String query, {int startIndex = 0}) async {
    // Assemble the full request address: the search phrase, which page we
    // want, and our access key.
    final url = Uri.parse(
      '$_base?q=$query&startIndex=$startIndex&maxResults=$pageSize'
      '&key=${AppConfig.googleBooksApiKey}',
    );
    final response = await _client.get(url).timeout(timeout);
    // Status 200 is the web's code for "everything went fine".
    if (response.statusCode != 200) {
      throw GoogleBooksException(
        'Google Books API returned status ${response.statusCode}',
      );
    }
    // Unpack the reply and convert each found book into our tidy format.
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

  /// Looks up one specific book by Google's internal ID and returns its ISBN.
  ///
  /// This is the fallback used when a search result arrived without an ISBN:
  /// the full record for that one book often contains it. Returns nothing
  /// (rather than raising an error) if it still can't be found.
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

  /// BUSINESS LOGIC:
  /// Google sometimes lists a book without ever having real cover art on
  /// file. When that happens, the cover URL either fails to load or loads
  /// a tiny generic placeholder graphic instead of the book's actual
  /// cover. Showing users one of those as if it were the real cover reads
  /// as broken or wrong, so every candidate cover is checked before it's
  /// saved to the shelf (see [SearchResultsPage._resolveBestThumbnail]).
  ///
  /// TECHNICAL:
  /// A HEAD request confirms the image is reachable without downloading
  /// it. A cover only counts as valid when the server returns 200, reports
  /// an `image/*` content type, and — when the server discloses a byte
  /// count — is bigger than [_minValidThumbnailBytes]. Any network failure
  /// (timeout, DNS, connection refused) is treated as "not valid" rather
  /// than propagated, since a slow/broken cover check should never block
  /// adding the book itself.
  Future<bool> isThumbnailValid(String url) async {
    if (url.isEmpty) return false;
    try {
      final response = await _client.head(Uri.parse(url)).timeout(timeout);
      if (response.statusCode != 200) return false;
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.startsWith('image/')) return false;
      final lengthHeader = response.headers['content-length'];
      final length = lengthHeader != null ? int.tryParse(lengthHeader) : null;
      if (length != null && length < _minValidThumbnailBytes) return false;
      return true;
    } catch (_) {
      return false;
    }
  }
}
