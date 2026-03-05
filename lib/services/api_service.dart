import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/movie.dart';
import '../models/review.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000';
  static const _storage = FlutterSecureStorage();
  static const Duration _timeout = Duration(seconds: 15);

  // ─── TOKEN MANAGEMENT ────────────────────────────────────────────────────────

  static Future<void> _saveToken(String accessToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── CORE HTTP HELPERS ───────────────────────────────────────────────────────

  static Future<http.Response> _get(String path, {bool auth = true}) async {
    final headers = auth ? await _authHeaders() : {'Content-Type': 'application/json'};
    return await http
        .get(Uri.parse('$_baseUrl$path'), headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> _post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final headers = auth ? await _authHeaders() : {'Content-Type': 'application/json'};
    return await http
        .post(Uri.parse('$_baseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
  }

  static Future<http.Response> _put(String path, Map<String, dynamic> body) async {
    return await http
        .put(Uri.parse('$_baseUrl$path'),
        headers: await _authHeaders(), body: jsonEncode(body))
        .timeout(_timeout);
  }

  static Future<http.Response> _delete(String path) async {
    return await http
        .delete(Uri.parse('$_baseUrl$path'), headers: await _authHeaders())
        .timeout(_timeout);
  }

  // ─── AUTH ────────────────────────────────────────────────────────────────────

  /// Sign up with phone or email + password.
  /// Pass either [phone] or [email], not necessarily both.
  static Future<String?> signup({
    String? phone,
    String? email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _post('/auth/signup', {
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'display_name': displayName,
      }, auth: false);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveToken(data['access_token']);
        return null; // null = success
      }
      return jsonDecode(response.body)['detail'] ?? 'Registration failed';
    } on TimeoutException {
      return 'Connection timed out. Please try again.';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  /// Login with phone or email + password.
  static Future<String?> login({
    String? phone,
    String? email,
    required String password,
  }) async {
    try {
      final response = await _post('/auth/login', {
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        'password': password,
      }, auth: false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['access_token']);
        return null; // null = success
      }
      return jsonDecode(response.body)['detail'] ?? 'Login failed';
    } on TimeoutException {
      return 'Connection timed out. Please try again.';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  static Future<void> logout() async {
    await clearTokens();
  }

  /// Get current user profile from /auth/me
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _get('/auth/me');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update display name or avatar.
  static Future<bool> updateProfile({String? displayName, String? avatarUrl}) async {
    try {
      final response = await _put('/auth/me', {
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─── MOVIES ──────────────────────────────────────────────────────────────────

  static Future<List<Movie>> fetchMovies(int page) async {
    try {
      final response = await _get('/api/v1/movies/popular?page=$page');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'];
        return results.map((json) => Movie.fromJson(json)).toList();
      }
      throw Exception('Failed to load movies: ${response.statusCode}');
    } on TimeoutException {
      throw Exception('Connection timed out.');
    } catch (e) {
      throw Exception('Failed to load movies: $e');
    }
  }

  static Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return [];
    try {
      final encoded = Uri.encodeQueryComponent(query);
      final response = await _get('/api/v1/movies/search?query=$encoded&page=$page');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'];
        return results.map((json) => Movie.fromJson(json)).toList();
      }
      throw Exception('Search failed: ${response.statusCode}');
    } on TimeoutException {
      throw Exception('Search timed out.');
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  static Future<Movie> fetchMovieDetails(int movieId) async {
    try {
      final response = await _get('/api/v1/movies/$movieId');
      if (response.statusCode == 200) return Movie.fromJson(jsonDecode(response.body));
      if (response.statusCode == 404) throw Exception('Movie not found.');
      throw Exception('Failed to load movie details: ${response.statusCode}');
    } on TimeoutException {
      throw Exception('Connection timed out.');
    } catch (e) {
      throw Exception('Failed to load movie details: $e');
    }
  }

  // ─── REVIEWS ─────────────────────────────────────────────────────────────────

  static Future<List<Review>> getReviews(int movieId) async {
    try {
      final response = await _get('/api/v1/reviews/movie/$movieId');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final reviews = data.map((json) => Review(
          userId: json['user_id'],
          userName: json['display_name'] ?? 'Anonymous',
          rating: (json['rating'] as num).toDouble(),
          comment: json['comment'],
          timestamp: DateTime.parse(json['created_at']),
        )).toList();
        reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return reviews;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> addReview(int movieId, double rating, String comment) async {
    final response = await _post('/api/v1/reviews/movie/$movieId', {
      'rating': rating,
      'comment': comment,
    });
    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to add review');
    }
  }

  static Future<void> updateReview(String reviewId,
      {double? rating, String? comment}) async {
    final response = await _put('/api/v1/reviews/$reviewId', {
      if (rating != null) 'rating': rating,
      if (comment != null) 'comment': comment,
    });
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update review');
    }
  }

  static Future<void> deleteReview(String reviewId) async {
    final response = await _delete('/api/v1/reviews/$reviewId');
    if (response.statusCode != 204) throw Exception('Failed to delete review');
  }

  static Future<List<Map<String, dynamic>>> getMyReviews() async {
    try {
      final response = await _get('/api/v1/reviews/user/me');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── WATCHLIST ───────────────────────────────────────────────────────────────

  static Future<List<Movie>> getWatchlistMovies() async {
    try {
      final response = await _get('/api/v1/watchlist/');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((entry) => Movie.fromJson(entry['movie'])).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> isInWatchlist(int movieId) async {
    try {
      final response = await _get('/api/v1/watchlist/check/$movieId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['in_watchlist'] as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> addToWatchlist(int movieId) async {
    final response = await _post('/api/v1/watchlist/', {'movie_id': movieId});
    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to add to watchlist');
    }
  }

  static Future<void> removeFromWatchlist(int movieId) async {
    final response = await _delete('/api/v1/watchlist/$movieId');
    if (response.statusCode != 204) throw Exception('Failed to remove from watchlist');
  }
}