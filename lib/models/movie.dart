class Movie {
  final int id;
  final String title;
  final String posterPath;
  final String overview;
  final double rating;
  final String? releaseDate;
  final String? backdropPath;
  final int? voteCount;
  final double? popularity;
  final String? originalLanguage;
  final List<int>? genreIds;       // from home/search (TMDB-style)
  final List<String>? genreNames;  // from detail endpoint (our DB)
  final int? runtime;
  final String? certification;
  final String? director;

  Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.rating,
    this.releaseDate,
    this.backdropPath,
    this.voteCount,
    this.popularity,
    this.originalLanguage,
    this.genreIds,
    this.genreNames,
    this.runtime,
    this.certification,
    this.director,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    List<int>? genreIds;
    List<String>? genreNames;

    final rawGenres = json['genres'];
    final rawGenreIds = json['genre_ids'];

    if (rawGenres != null && rawGenres is List && rawGenres.isNotEmpty) {
      if (rawGenres.first is Map) {
        // Our backend: list of {id, name} objects
        genreNames = rawGenres
            .map((g) => (g['name'] as String?) ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      } else {
        // Plain int list
        genreIds = List<int>.from(rawGenres);
      }
    } else if (rawGenreIds != null) {
      genreIds = List<int>.from(rawGenreIds);
    }

    return Movie(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      posterPath: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : 'https://via.placeholder.com/500x750?text=No+Image',
      overview: json['overview'] ?? '',
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'],
      backdropPath: json['backdrop_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['backdrop_path']}'
          : null,
      voteCount: json['vote_count'],
      popularity: (json['popularity'] as num?)?.toDouble(),
      originalLanguage: json['original_language'],
      genreIds: genreIds,
      genreNames: genreNames,
      runtime: json['runtime'],
      certification: json['certification'],
      director: json['director'],
    );
  }

  String getGenres() {
    // Prefer names from our backend
    if (genreNames != null && genreNames!.isNotEmpty) {
      return genreNames!.take(3).join(', ');
    }

    // Fall back to mapping IDs
    if (genreIds != null && genreIds!.isNotEmpty) {
      const genreMap = {
        28: 'Action',
        12: 'Adventure',
        16: 'Animation',
        35: 'Comedy',
        80: 'Crime',
        99: 'Documentary',
        18: 'Drama',
        10751: 'Family',
        14: 'Fantasy',
        36: 'History',
        27: 'Horror',
        10402: 'Music',
        9648: 'Mystery',
        10749: 'Romance',
        878: 'Sci-Fi',
        10770: 'TV Movie',
        53: 'Thriller',
        10752: 'War',
        37: 'Western',
      };
      return genreIds!.take(3).map((id) => genreMap[id] ?? 'Unknown').join(', ');
    }

    return 'Unknown';
  }

  String getLanguageName() {
    if (originalLanguage == null) return 'Unknown';
    const languageMap = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'hi': 'Hindi',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ar': 'Arabic',
      'ta': 'Tamil',
      'te': 'Telugu',
      'tr': 'Turkish',
    };
    return languageMap[originalLanguage] ?? originalLanguage!.toUpperCase();
  }

  double get starRating => rating / 2;

  String getFormattedRuntime() {
    if (runtime == null || runtime == 0) return 'Unknown';
    final hours = runtime! ~/ 60;
    final minutes = runtime! % 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes}min';
  }
}