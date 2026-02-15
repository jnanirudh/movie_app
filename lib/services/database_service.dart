import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addReview(String userId, int movieId, int rating, String comment) async {
    await _db.collection('reviews').add({
      'userId': userId,
      'movieId': movieId,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(), // Automatically sets the time
    });
  }
}