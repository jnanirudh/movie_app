import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review.dart';

class ReviewService {
  static const String _reviewsKey = 'movie_reviews';
  static const String _currentUserKey = 'current_user_id';

  // Get current user ID (you can replace this with actual authentication later)
  Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_currentUserKey);
    if (userId == null) {
      // Generate a unique user ID if not exists
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_currentUserKey, userId);
    }
    return userId;
  }

  // Get all reviews for a movie
  Future<List<Review>> getReviews(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    String key = '${_reviewsKey}_$movieId';
    String? reviewsJson = prefs.getString(key);

    if (reviewsJson == null) return [];

    List<dynamic> reviewsList = json.decode(reviewsJson);
    return reviewsList.map((json) => Review.fromJson(json)).toList();
  }

  // Add a review for a movie
  Future<void> addReview(int movieId, Review review) async {
    final prefs = await SharedPreferences.getInstance();
    String key = '${_reviewsKey}_$movieId';

    List<Review> reviews = await getReviews(movieId);

    // Remove any existing review from this user
    reviews.removeWhere((r) => r.userId == review.userId);

    // Add new review at the beginning
    reviews.insert(0, review);

    // Save to SharedPreferences
    String reviewsJson = json.encode(reviews.map((r) => r.toJson()).toList());
    await prefs.setString(key, reviewsJson);
  }

  // Get user's review for a specific movie
  Future<Review?> getUserReview(int movieId, String userId) async {
    List<Review> reviews = await getReviews(movieId);
    try {
      return reviews.firstWhere((r) => r.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Delete user's review
  Future<void> deleteReview(int movieId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String key = '${_reviewsKey}_$movieId';

    List<Review> reviews = await getReviews(movieId);
    reviews.removeWhere((r) => r.userId == userId);

    String reviewsJson = json.encode(reviews.map((r) => r.toJson()).toList());
    await prefs.setString(key, reviewsJson);
  }
}