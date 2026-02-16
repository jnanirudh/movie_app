import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TmdbService {
  final String apiKey = '7a3e84b6daa52f28721a22d7484dcfb9';
  final String baseUrl = 'https://api.themoviedb.org/3';

  // Fetch popular movies
  Future<List<Movie>> fetchMovies(int page) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/popular?api_key=$apiKey&page=$page'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((movieJson) => Movie.fromJson(movieJson)).toList();
    } else {
      throw Exception('Failed to load movies');
    }
  }
  // Search movies by query
  Future<List<Movie>> searchMovies(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=$query'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search movies');
    }
  }

  Future<Movie> fetchMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/movie/$movieId?api_key=$apiKey&append_to_response=credits,release_dates'
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Extract director from credits
      String? director;
      if (data['credits'] != null && data['credits']['crew'] != null) {
        final crew = data['credits']['crew'] as List;
        final directorData = crew.firstWhere(
              (person) => person['job'] == 'Director',
          orElse: () => null,
        );
        director = directorData?['name'];
      }

      // Extract US certification
      String? certification;
      if (data['release_dates'] != null && data['release_dates']['results'] != null) {
        final releaseDates = data['release_dates']['results'] as List;
        final usRelease = releaseDates.firstWhere(
              (release) => release['iso_3166_1'] == 'US',
          orElse: () => null,
        );
        if (usRelease != null && usRelease['release_dates'] != null) {
          final releases = usRelease['release_dates'] as List;
          if (releases.isNotEmpty) {
            certification = releases[0]['certification'];
          }
        }
      }

      // Add extra fields to the JSON
      data['director'] = director;
      data['certification'] = certification;

      return Movie.fromJson(data);
    } else {
      throw Exception('Failed to load movie details');
    }
  }
}