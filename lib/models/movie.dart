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
  final List<int>? genreIds;
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
    this.runtime,
    this.certification,
    this.director,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      posterPath: 'https://image.tmdb.org/t/p/w500${json['poster_path']}',
      overview: json['overview'] ?? '',
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'],
      backdropPath: json['backdrop_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['backdrop_path']}'
          : null,
      voteCount: json['vote_count'],
      popularity: (json['popularity'] as num?)?.toDouble(),
      originalLanguage: json['original_language'],
      genreIds: json['genre_ids'] != null
          ? List<int>.from(json['genre_ids'])
          : null,
      runtime: json['runtime'],
      certification: json['certification'],
      director: json['director'],
    );
  }

  // Helper method to get genre names
  String getGenres() {
    if (genreIds == null || genreIds!.isEmpty) return 'Unknown';

    final genreMap = {
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
      878: 'Science Fiction',
      10770: 'TV Movie',
      53: 'Thriller',
      10752: 'War',
      37: 'Western',
    };

    return genreIds!
        .take(3) // Limit to first 3 genres
        .map((id) => genreMap[id] ?? 'Unknown')
        .join(', ');
  }

  // Helper method to get language name
  String getLanguageName() {
    if (originalLanguage == null) return 'Unknown';

    final languageMap = {
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
    if (runtime == null) return 'Unknown';
    final hours = runtime! ~/ 60;
    final minutes = runtime! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
}