import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user.uid;
    throw Exception('No user logged in');
  }

  String getCurrentUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Anonymous';
    return user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous';
  }

  // Get ALL reviews for a movie
  Future<List<Review>> getReviews(int movieId) async {
    try {
      print('🔍 Fetching reviews for movieId: $movieId');
      final snapshot = await _firestore
          .collection('reviews')
          .where('movieId', isEqualTo: movieId)
          .get();

      print('📦 Docs found: ${snapshot.docs.length}');

      final reviews = snapshot.docs.map((doc) {
        final data = doc.data();
        return Review(
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? 'Anonymous',
          rating: (data['rating'] as num).toDouble(),
          comment: data['comment'] ?? '',
          timestamp: data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();

      // Sort by most recent
      reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reviews;
    } catch (e) {
      print('❌ Error getting reviews: $e');
      return [];
    }
  }

  // Get all reviews by a specific user with movie info
  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    try {
      print('🔍 Getting reviews for userId: $userId');
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      print('✅ Found ${snapshot.docs.length} reviews');

      final reviews = snapshot.docs.map((doc) => doc.data()).toList();

      // Sort by most recent
      reviews.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return reviews;
    } catch (e) {
      print('❌ Error getting user reviews: $e');
      return [];
    }
  }

  // Add or update review
  Future<void> addReview(int movieId, Review review) async {
    try {
      print('📝 Adding review for movieId: $movieId by ${review.userId}');
      String docId = '${review.userId}_$movieId';

      await _firestore.collection('reviews').doc(docId).set({
        'movieId': movieId,
        'userId': review.userId,
        'userName': review.userName,
        'rating': review.rating,
        'comment': review.comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Review added: $docId');
    } catch (e) {
      print('❌ Error adding review: $e');
      rethrow;
    }
  }

  // Get specific user review for a movie
  Future<Review?> getUserReview(int movieId, String userId) async {
    try {
      String docId = '${userId}_$movieId';
      final doc = await _firestore.collection('reviews').doc(docId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return Review(
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? 'Anonymous',
        rating: (data['rating'] as num).toDouble(),
        comment: data['comment'] ?? '',
        timestamp: data['timestamp'] != null
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e) {
      print('❌ Error getting user review: $e');
      return null;
    }
  }

  // Delete review
  Future<void> deleteReview(int movieId, String userId) async {
    try {
      String docId = '${userId}_$movieId';
      await _firestore.collection('reviews').doc(docId).delete();
      print('✅ Review deleted: $docId');
    } catch (e) {
      print('❌ Error deleting review: $e');
      rethrow;
    }
  }
}