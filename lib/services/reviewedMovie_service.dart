import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/movie.dart';

class ReviewedMoviesService {
  // Save a reviewed movie for profile display
  static Future<void> saveReviewedMovie(Movie movie, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Key is now user-specific using Firebase UID
      String key = 'reviewed_movies_$userId';

      Map<String, dynamic> reviewedMovies = {};
      String? existingJson = prefs.getString(key);

      if (existingJson != null) {
        reviewedMovies = json.decode(existingJson);
      }

      reviewedMovies[movie.id.toString()] = {
        'id': movie.id,
        'title': movie.title,
        'poster_path': movie.posterPath.replaceAll('https://image.tmdb.org/t/p/w500', ''),
        'overview': movie.overview,
        'vote_average': movie.rating,
        'release_date': movie.releaseDate,
        'genre_ids': movie.genreIds,
        'original_language': movie.originalLanguage,
      };

      await prefs.setString(key, json.encode(reviewedMovies));
    } catch (e) {
      print('Error saving reviewed movie: $e');
    }
  }

  // Get all reviewed movies for current user
  static Future<Map<int, Movie>> getReviewedMovies(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? reviewedMoviesJson = prefs.getString('reviewed_movies_$userId');

      if (reviewedMoviesJson == null) return {};

      Map<String, dynamic> data = json.decode(reviewedMoviesJson);
      Map<int, Movie> reviewedMovies = {};

      data.forEach((key, value) {
        try {
          reviewedMovies[int.parse(key)] = Movie.fromJson(value);
        } catch (e) {
          print('Error parsing movie: $e');
        }
      });

      return reviewedMovies;
    } catch (e) {
      print('Error getting reviewed movies: $e');
      return {};
    }
  }

  // Delete reviewed movie (when review is deleted)
  static Future<void> deleteReviewedMovie(int movieId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String key = 'reviewed_movies_$userId';
      String? existingJson = prefs.getString(key);

      if (existingJson == null) return;

      Map<String, dynamic> reviewedMovies = json.decode(existingJson);
      reviewedMovies.remove(movieId.toString());

      await prefs.setString(key, json.encode(reviewedMovies));
    } catch (e) {
      print('Error deleting reviewed movie: $e');
    }
  }
}