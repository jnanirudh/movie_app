import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Movie> _results = [];
  final TmdbService _service = TmdbService();

  void _search(String query) async {
    if (query.isEmpty) return;
    // We'll add a search method to your TmdbService soon!
    // final results = await _service.searchMovies(query);
    // setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(hintText: "Search movies...", border: InputBorder.none),
          onChanged: _search,
        ),
      ),
      body: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) => ListTile(title: Text(_results[index].title)),
      ),
    );
  }
}