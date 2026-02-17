import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review.dart';

class ReviewService {
  // Get current user ID from Firebase
  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    return user.uid;
  }

  // This now uses Firebase UID directly
  Future<String> getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user.uid;
    throw Exception('No user logged in');
  }

  // Reviews key is user-specific
  String _reviewsKey(int movieId) => 'movie_reviews_${movieId}_$_userId';

  // Get all reviews for a movie
  Future<List<Review>> getReviews(int movieId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? reviewsJson = prefs.getString(_reviewsKey(movieId));
      if (reviewsJson == null) return [];
      List<dynamic> reviewsList = json.decode(reviewsJson);
      return reviewsList.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  // Add a review for a movie
  Future<void> addReview(int movieId, Review review) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Review> reviews = await getReviews(movieId);

      // Remove any existing review from this user
      reviews.removeWhere((r) => r.userId == _userId);

      // Add new review at the beginning
      reviews.insert(0, review);

      String reviewsJson = json.encode(reviews.map((r) => r.toJson()).toList());
      await prefs.setString(_reviewsKey(movieId), reviewsJson);
    } catch (e) {
      print('Error adding review: $e');
    }
  }

  // Get user's review for a specific movie
  Future<Review?> getUserReview(int movieId, String userId) async {
    try {
      List<Review> reviews = await getReviews(movieId);
      return reviews.firstWhere((r) => r.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Delete user's review
  Future<void> deleteReview(int movieId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Review> reviews = await getReviews(movieId);
      reviews.removeWhere((r) => r.userId == userId);
      String reviewsJson = json.encode(reviews.map((r) => r.toJson()).toList());
      await prefs.setString(_reviewsKey(movieId), reviewsJson);
    } catch (e) {
      print('Error deleting review: $e');
    }
  }
}