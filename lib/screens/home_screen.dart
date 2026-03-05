import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/movie.dart';
import 'movieDetail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Movie> _movies = [];
  int _currentPage = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchMovies();
      }
    });
  }

  Future<void> _fetchMovies() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final newMovies = await ApiService.fetchMovies(_currentPage);
      setState(() {
        _movies.addAll(newMovies);
        _currentPage++;
      });
    } catch (e) {
      print('Error fetching movies: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movie Browser')),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        itemCount: _movies.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _movies.length) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator()));
          }
          final movie = _movies[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            elevation: 4,
            child: InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => MovieDetailScreen(movie: movie))),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        movie.posterPath,
                        width: 120,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 180,
                            color: Colors.grey[300],
                            child: const Icon(Icons.movie, size: 50)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(movie.title,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (movie.releaseDate != null)
                            Text('Release: ${movie.releaseDate}',
                                style: TextStyle(
                                    fontSize: 17, color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Text('Genre: ${movie.getGenres()}',
                              style: TextStyle(
                                  fontSize: 17, color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Text('Language: ${movie.getLanguageName()}',
                              style: TextStyle(
                                  fontSize: 17, color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Text('Rating: ${movie.rating}',
                              style: TextStyle(
                                  fontSize: 17, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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