import 'package:flutter/material.dart';
import 'package:movie_app/services/tmdb_service.dart';
import '../models/movie.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TmdbService _tmdbService = TmdbService();
  final ScrollController _scrollController = ScrollController();

  List<Movie> _movies = [];
  int _currentPage = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchMovies();
      }
    });
  }

  Future<void> _fetchMovies() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final newMovies = await _tmdbService.fetchMovies(_currentPage);
      setState(() {
        _movies.addAll(newMovies);
        _currentPage++;
      });
    } catch (e) {
      print("Error fetching movies: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Movie Browser')),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _movies.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _movies.length) {
            return Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ));
          }
          final movie = _movies[index];
          return ListTile(
            leading: Image.network(movie.posterPath, width: 50, fit: BoxFit.cover),
            title: Text(movie.title),
            subtitle: Text("Rating: ${movie.rating}"),
            onTap: () {
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}