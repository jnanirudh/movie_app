import 'package:flutter/material.dart';
import '../models/movie.dart'; //gets movie data
import '../models/review.dart'; //gets review data
import '../services/tmdb_service.dart';
import '../services/review_service.dart';
import '../services/watchlist_service.dart';
import '../services/reviewedMovie_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  _MovieDetailScreenState createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final TmdbService _tmdbService = TmdbService();
  final ReviewService _reviewService = ReviewService();
  final WatchlistService _watchlistService = WatchlistService();

  Movie? _detailedMovie;
  bool _isLoading = true;
  bool _isBookmarked = false;
  bool _isDescriptionExpanded = false;

  List<Review> _reviews = [];
  Review? _userReview;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMovieDetails();
    _loadReviews();
    _checkWatchlistStatus();
  }

  Future<void> _loadMovieDetails() async {
    try {
      final detailedMovie = await _tmdbService.fetchMovieDetails(widget.movie.id);
      setState(() {
        _detailedMovie = detailedMovie;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading movie details: $e");
      setState(() {
        _detailedMovie = widget.movie;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkWatchlistStatus() async {
    bool inWatchlist = await _watchlistService.isInWatchlist(widget.movie.id);
    setState(() {
      _isBookmarked = inWatchlist;
    });
  }

  Future<void> _toggleWatchlist() async {
    if (_isBookmarked) {
      await _watchlistService.removeFromWatchlist(widget.movie.id);

      // Also remove from saved movies
      List<Movie> watchlistMovies = await _watchlistService.getWatchlistMovies();
      watchlistMovies.removeWhere((m) => m.id == widget.movie.id);
      await _watchlistService.saveWatchlistMovies(watchlistMovies);
    } else {
      await _watchlistService.addToWatchlist(widget.movie.id);

      // Save the full movie object for display in profile
      List<Movie> watchlistMovies = await _watchlistService.getWatchlistMovies();

      // Check if movie is already in the list to avoid duplicates
      if (!watchlistMovies.any((m) => m.id == widget.movie.id)) {
        watchlistMovies.add(_detailedMovie ?? widget.movie);
        await _watchlistService.saveWatchlistMovies(watchlistMovies);
      }
    }

    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked
            ? 'Added to watchlist'
            : 'Removed from watchlist'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _loadReviews() async {
    _currentUserId = await _reviewService.getCurrentUserId();
    _userReview = await _reviewService.getUserReview(widget.movie.id, _currentUserId!);

    List<Review> allReviews = await _reviewService.getReviews(widget.movie.id);

    setState(() {
      if (_userReview != null) {
        _reviews = [_userReview!];
        _reviews.addAll(allReviews.where((r) => r.userId != _currentUserId));
      } else {
        _reviews = allReviews;
      }
    });
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.amber, size: 28);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, color: Colors.amber, size: 28);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: 28);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = _detailedMovie ?? widget.movie;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.movie.title),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleWatchlist,
          ),
          IconButton(
            icon: Icon(Icons.grid_view),
            onPressed: () {
              // TODO: Implement grid view functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Poster and Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Movie Poster
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      movie.posterPath,
                      width: 140,
                      height: 210,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 16),

                  // Movie Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        if (movie.releaseDate != null)
                          Text(
                            movie.releaseDate!,
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                        SizedBox(height: 4),
                        if (movie.certification != null && movie.certification!.isNotEmpty)
                          Text(
                            movie.certification!,
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                        SizedBox(height: 4),
                        Text(
                          movie.getGenres(),
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 4),
                        Text(
                          movie.getFormattedRuntime(),
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 12),
                        // Add to Watchlist Button
                        ElevatedButton.icon(
                          onPressed: _toggleWatchlist,
                          icon: Icon(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            size: 18,
                          ),
                          label: Text('Add to WatchList'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Star Rating
              Row(
                children: [
                  _buildStarRating(movie.starRating),
                  SizedBox(width: 8),
                  Text(
                    '${movie.rating.toStringAsFixed(1)}/10',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Description Box
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.overview,
                      maxLines: _isDescriptionExpanded ? null : 3,
                      overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                    if (movie.overview.length > 150)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            _isDescriptionExpanded ? '...less' : '...more',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Director / Production House
              if (movie.director != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Director',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      movie.director!,
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 20),
                  ],
                ),

              // OTT Section
              Text(
                'OTT:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Streaming platforms information coming soon',
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
              ),

              SizedBox(height: 20),

              // Reviews Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showWriteReviewDialog(context);
                    },
                    icon: Icon(Icons.rate_review, size: 18),
                    label: Text(_userReview == null ? 'Write Review' : 'Edit Review'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Display Reviews
              if (_reviews.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No reviews yet. Be the first to review!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                Column(
                  children: _reviews.map((review) {
                    bool isUserReview = review.userId == _currentUserId;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _buildReviewCard(
                        review.userName,
                        review.rating,
                        review.comment,
                        isUserReview: isUserReview,
                        onDelete: isUserReview ? () => _deleteReview() : null,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(
      String userName,
      double rating,
      String comment, {
        bool isUserReview = false,
        VoidCallback? onDelete,
      }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isUserReview ? Colors.blue[300]! : Colors.grey[300]!,
          width: isUserReview ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isUserReview ? Colors.blue[50] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isUserReview)
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: onDelete,
                      padding: EdgeInsets.only(left: 8),
                      constraints: BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Review'),
        content: Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _reviewService.deleteReview(widget.movie.id, _currentUserId!);
      await _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review deleted')),
      );
    }
  }

  void _showWriteReviewDialog(BuildContext context) {
    double userRating = _userReview?.rating ?? 3.0;
    TextEditingController reviewController = TextEditingController(
      text: _userReview?.comment ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_userReview == null ? 'Write a Review' : 'Edit Your Review'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Your Rating:'),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < userRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              userRating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write your review here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (reviewController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please write a review')),
                      );
                      return;
                    }

                    Review newReview = Review(
                      userId: _currentUserId!,
                      userName: 'You',
                      rating: userRating,
                      comment: reviewController.text.trim(),
                      timestamp: DateTime.now(),
                    );

                    await _reviewService.addReview(widget.movie.id, newReview);

                    // Save the reviewed movie for profile display
                    await ReviewedMoviesService.saveReviewedMovie(_detailedMovie ?? widget.movie, _currentUserId!);

                    await _loadReviews();

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Review ${_userReview == null ? 'submitted' : 'updated'}!')),
                    );
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}