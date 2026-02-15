class Movie {
  final int id;
  final String title;
  final String posterPath;
  final String overview;
  final double rating;

  Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.rating,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? 'No Title',

      posterPath: 'https://image.tmdb.org/t/p/w500${json['poster_path']}',
      overview: json['overview'] ?? '',
      rating: (json['vote_average'] as num).toDouble(),
    );
  }
}