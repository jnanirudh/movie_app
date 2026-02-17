import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TmdbService {
  final String apiKey = '7a3e84b6daa52f28721a22d7484dcfb9';
  final String baseUrl = 'https://api.themoviedb.org/3';

  // Add timeout duration
  final Duration _timeout = Duration(seconds: 15);

  // Fetch popular movies
  Future<List<Movie>> fetchMovies(int page) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/movie/popular?api_key=$apiKey&page=$page'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        return results.map((movieJson) => Movie.fromJson(movieJson)).toList();
      } else {
        throw Exception('Failed to load movies: Server returned ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Request timeout: $e');
      throw Exception('Connection timed out. Please check your internet connection and try again.');
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on FormatException catch (e) {
      print('Invalid response format: $e');
      throw Exception('Invalid response from server.');
    } catch (e) {
      print('Unexpected error fetching movies: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Search movies by query
  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await http
          .get(
        Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=$encodedQuery'),
      )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search movies: Server returned ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Search timeout: $e');
      throw Exception('Search timed out. Please try again.');
    } on http.ClientException catch (e) {
      print('Network error during search: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on FormatException catch (e) {
      print('Invalid search response format: $e');
      throw Exception('Invalid response from server.');
    } catch (e) {
      print('Unexpected error searching movies: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Fetch movie details
  Future<Movie> fetchMovieDetails(int movieId) async {
    try {
      final response = await http
          .get(
        Uri.parse(
            '$baseUrl/movie/$movieId?api_key=$apiKey&append_to_response=credits,release_dates'
        ),
      )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract director from credits
        String? director;
        if (data['credits'] != null && data['credits']['crew'] != null) {
          final crew = data['credits']['crew'] as List;
          try {
            final directorData = crew.firstWhere(
                  (person) => person['job'] == 'Director',
              orElse: () => null,
            );
            director = directorData?['name'];
          } catch (e) {
            print('Error extracting director: $e');
          }
        }

        // Extract US certification
        String? certification;
        if (data['release_dates'] != null && data['release_dates']['results'] != null) {
          final releaseDates = data['release_dates']['results'] as List;
          try {
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
          } catch (e) {
            print('Error extracting certification: $e');
          }
        }

        // Add extra fields to the JSON
        data['director'] = director;
        data['certification'] = certification;

        return Movie.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Movie not found.');
      } else {
        throw Exception('Failed to load movie details: Server returned ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Movie details timeout: $e');
      throw Exception('Connection timed out. Please try again.');
    } on http.ClientException catch (e) {
      print('Network error fetching movie details: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on FormatException catch (e) {
      print('Invalid movie details response format: $e');
      throw Exception('Invalid response from server.');
    } catch (e) {
      print('Unexpected error fetching movie details: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }
}