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
      Uri.parse('$_baseUrl/search/movie?api_key=$_apiKey&query=$query'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search movies');
    }
  }
}