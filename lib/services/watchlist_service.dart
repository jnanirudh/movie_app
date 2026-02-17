import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class WatchlistService {
  // Get current user ID - tied to Firebase Auth
  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    return user.uid;
  }

  // Keys are now user-specific
  String get _watchlistKey => 'user_watchlist_$_userId';
  String get _watchlistMoviesKey => 'user_watchlist_movies_$_userId';

  // Get all movie IDs in watchlist
  Future<List<int>> getWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? watchlistJson = prefs.getString(_watchlistKey);
      if (watchlistJson == null) return [];
      List<dynamic> watchlistData = json.decode(watchlistJson);
      return watchlistData.cast<int>();
    } catch (e) {
      print('Error getting watchlist: $e');
      return [];
    }
  }

  // Add movie to watchlist
  Future<void> addToWatchlist(int movieId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<int> watchlist = await getWatchlist();
      if (!watchlist.contains(movieId)) {
        watchlist.add(movieId);
        await prefs.setString(_watchlistKey, json.encode(watchlist));
      }
    } catch (e) {
      print('Error adding to watchlist: $e');
    }
  }

  // Remove movie from watchlist
  Future<void> removeFromWatchlist(int movieId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<int> watchlist = await getWatchlist();
      watchlist.remove(movieId);
      await prefs.setString(_watchlistKey, json.encode(watchlist));
    } catch (e) {
      print('Error removing from watchlist: $e');
    }
  }

  // Check if movie is in watchlist
  Future<bool> isInWatchlist(int movieId) async {
    try {
      List<int> watchlist = await getWatchlist();
      return watchlist.contains(movieId);
    } catch (e) {
      print('Error checking watchlist: $e');
      return false;
    }
  }

  // Save full movie objects for display in profile
  Future<void> saveWatchlistMovies(List<Movie> movies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String moviesJson = json.encode(movies.map((m) => {
        'id': m.id,
        'title': m.title,
        'poster_path': m.posterPath.replaceAll('https://image.tmdb.org/t/p/w500', ''),
        'overview': m.overview,
        'vote_average': m.rating,
        'release_date': m.releaseDate,
        'genre_ids': m.genreIds,
        'original_language': m.originalLanguage,
      }).toList());
      await prefs.setString(_watchlistMoviesKey, moviesJson);
    } catch (e) {
      print('Error saving watchlist movies: $e');
    }
  }

  // Get full movie objects
  Future<List<Movie>> getWatchlistMovies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? moviesJson = prefs.getString(_watchlistMoviesKey);
      if (moviesJson == null) return [];
      List<dynamic> moviesList = json.decode(moviesJson);
      return moviesList.map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      print('Error getting watchlist movies: $e');
      return [];
    }
  }
}