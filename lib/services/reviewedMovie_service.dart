import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/movie.dart';

class ReviewedMoviesService {
  // Save a reviewed movie for profile display
  static Future<void> saveReviewedMovie(Movie movie, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'reviewed_movies_$userId';

    Map<int, dynamic> reviewedMovies = {};
    String? existingJson = prefs.getString(key);

    if (existingJson != null) {
      Map<String, dynamic> existing = json.decode(existingJson);
      existing.forEach((k, v) {
        reviewedMovies[int.parse(k)] = v;
      });
    }

    reviewedMovies[movie.id] = {
      'id': movie.id,
      'title': movie.title,
      'poster_path': movie.posterPath.replaceAll('https://image.tmdb.org/t/p/w500', ''),
      'overview': movie.overview,
      'vote_average': movie.rating,
      'release_date': movie.releaseDate,
      'genre_ids': movie.genreIds,
      'original_language': movie.originalLanguage,
    };

    String jsonString = json.encode(reviewedMovies.map((k, v) => MapEntry(k.toString(), v)));
    await prefs.setString(key, jsonString);
  }

  // Get all reviewed movies
  static Future<Map<int, Movie>> getReviewedMovies(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String? reviewedMoviesJson = prefs.getString('reviewed_movies_$userId');

    if (reviewedMoviesJson == null) return {};

    Map<String, dynamic> data = json.decode(reviewedMoviesJson);
    Map<int, Movie> reviewedMovies = {};

    data.forEach((key, value) {
      reviewedMovies[int.parse(key)] = Movie.fromJson(value);
    });

    return reviewedMovies;
  }
}