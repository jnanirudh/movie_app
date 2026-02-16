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
    );
  }
}