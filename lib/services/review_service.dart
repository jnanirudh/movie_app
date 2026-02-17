import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID from Firebase
  Future<String> getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user.uid;
    throw Exception('No user logged in');
  }

  // Get current user's display name or email
  String getCurrentUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Anonymous';
    // Use display name if available, otherwise use email prefix
    return user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous';
  }

  // Get ALL reviews for a movie (from all users)
  Stream<List<Review>> getReviewsStream(int movieId) {
    return _firestore
        .collection('reviews')
        .where('movieId', isEqualTo: movieId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Review(
          userId: data['userId'],
          userName: data['userName'],
          rating: (data['rating'] as num).toDouble(),
          comment: data['comment'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  // Get reviews as a Future (one-time fetch)
  Future<List<Review>> getReviews(int movieId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('movieId', isEqualTo: movieId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Review(
          userId: data['userId'],
          userName: data['userName'],
          rating: (data['rating'] as num).toDouble(),
          comment: data['comment'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  Future<void> addReview(int movieId, Review review) async {
    try {
      String docId = '${review.userId}_$movieId';
      await _firestore.collection('reviews').doc(docId).set({
        'movieId': movieId,
        'userId': review.userId,
        'userName': review.userName,
        'rating': review.rating,
        'comment': review.comment,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  // Get user's review for a specific movie
  Future<Review?> getUserReview(int movieId, String userId) async {
    try {
      String docId = '${userId}_$movieId';
      final doc = await _firestore.collection('reviews').doc(docId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return Review(
        userId: data['userId'],
        userName: data['userName'],
        rating: (data['rating'] as num).toDouble(),
        comment: data['comment'],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
    } catch (e) {
      print('Error getting user review: $e');
      return null;
    }
  }

  // Delete user's review
  Future<void> deleteReview(int movieId, String userId) async {
    try {
      String docId = '${userId}_$movieId';
      await _firestore.collection('reviews').doc(docId).delete();
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }

  // Get all reviews by a specific user (for profile screen)
  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting user reviews: $e');
      return [];
    }
  }
}