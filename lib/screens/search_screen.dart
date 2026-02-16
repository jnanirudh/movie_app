import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../models/movie.dart';
import 'movieDetail_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _searchController = TextEditingController();

  List<Movie> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  void _searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _tmdbService.searchMovies(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print("Error searching movies: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search movies...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white60),
          ),
          style: TextStyle(color: Colors.white, fontSize: 18),
          onChanged: _searchMovies,
        )
            : Text('Search Movies'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Search for movies'
              : 'No results found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final movie = _searchResults[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            elevation: 4,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailScreen(movie: movie),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        movie.posterPath,
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Rating: ${movie.rating}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Genre: ${movie.getGenres()}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
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
    _searchController.dispose();
    super.dispose();
  }
}