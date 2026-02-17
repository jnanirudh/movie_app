import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class WatchlistService {
  static const String _watchlistKey = 'user_watchlist';

  // Get all movies in watchlist
  Future<List<int>> getWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    String? watchlistJson = prefs.getString(_watchlistKey);

    if (watchlistJson == null) return [];

    List<dynamic> watchlistData = json.decode(watchlistJson);
    return watchlistData.cast<int>();
  }

  // Add movie to watchlist
  Future<void> addToWatchlist(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    List<int> watchlist = await getWatchlist();

    if (!watchlist.contains(movieId)) {
      watchlist.add(movieId);
      String watchlistJson = json.encode(watchlist);
      await prefs.setString(_watchlistKey, watchlistJson);
    }
  }

  // Remove movie from watchlist
  Future<void> removeFromWatchlist(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    List<int> watchlist = await getWatchlist();

    watchlist.remove(movieId);
    String watchlistJson = json.encode(watchlist);
    await prefs.setString(_watchlistKey, watchlistJson);
  }

  // Check if movie is in watchlist
  Future<bool> isInWatchlist(int movieId) async {
    List<int> watchlist = await getWatchlist();
    return watchlist.contains(movieId);
  }

  Future<void> saveWatchlistMovies(List<Movie> movies) async {
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
    await prefs.setString('${_watchlistKey}_movies', moviesJson);
  }

  Future<List<Movie>> getWatchlistMovies() async {
    final prefs = await SharedPreferences.getInstance();
    String? moviesJson = prefs.getString('${_watchlistKey}_movies');

    if (moviesJson == null) return [];

    List<dynamic> moviesList = json.decode(moviesJson);
    return moviesList.map((json) => Movie.fromJson(json)).toList();
  }
}