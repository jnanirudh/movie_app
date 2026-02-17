import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';
import '../models/review.dart';
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
  bool _reviewsLoading = true;
  Review? _userReview;
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _currentUserName = user.displayName ??
          user.email?.split('@')[0] ??
          'Anonymous';
    }

    if (!mounted) return;
    await _loadMovieDetails();

    if (!mounted) return;
    await _checkWatchlistStatus();

    if (!mounted) return;
    await _loadUserReview();

    if (!mounted) return;
    await _loadReviews();
  }

  Future<void> _loadMovieDetails() async {
    if (!mounted) return;
    try {
      final detailedMovie =
      await _tmdbService.fetchMovieDetails(widget.movie.id);
      if (!mounted) return;
      setState(() {
        _detailedMovie = detailedMovie;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading movie details: $e');
      if (!mounted) return;
      setState(() {
        _detailedMovie = widget.movie;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserReview() async {
    if (!mounted) return;
    if (_currentUserId == null) return;
    try {
      final review = await _reviewService.getUserReview(
          widget.movie.id, _currentUserId!);
      if (!mounted) return;
      setState(() {
        _userReview = review;
      });
    } catch (e) {
      print('Error loading user review: $e');
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() => _reviewsLoading = true);
    try {
      print('🔍 Loading reviews for movieId: ${widget.movie.id}');
      final reviews =
      await _reviewService.getReviews(widget.movie.id);
      print('✅ Got ${reviews.length} reviews');
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _reviewsLoading = false;
      });
    } catch (e) {
      print('❌ Error loading reviews: $e');
      if (!mounted) return;
      setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _checkWatchlistStatus() async {
    if (!mounted) return;
    try {
      bool inWatchlist =
      await _watchlistService.isInWatchlist(widget.movie.id);
      if (!mounted) return;
      setState(() {
        _isBookmarked = inWatchlist;
      });
    } catch (e) {
      print('Error checking watchlist: $e');
    }
  }

  Future<void> _toggleWatchlist() async {
    try {
      if (_isBookmarked) {
        await _watchlistService.removeFromWatchlist(widget.movie.id);
        List<Movie> watchlistMovies =
        await _watchlistService.getWatchlistMovies();
        watchlistMovies.removeWhere((m) => m.id == widget.movie.id);
        await _watchlistService.saveWatchlistMovies(watchlistMovies);
      } else {
        await _watchlistService.addToWatchlist(widget.movie.id);
        List<Movie> watchlistMovies =
        await _watchlistService.getWatchlistMovies();
        if (!watchlistMovies.any((m) => m.id == widget.movie.id)) {
          watchlistMovies.add(_detailedMovie ?? widget.movie);
          await _watchlistService.saveWatchlistMovies(watchlistMovies);
        }
      }

      if (mounted) {
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
    } catch (e) {
      print('Error toggling watchlist: $e');
    }
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

  Future<bool> _showWriteReviewDialog() async {
    // ✅ Check user is logged in before opening dialog
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to write a review')),
      );
      return false;
    }

    double userRating = _userReview?.rating ?? 3.0;
    final TextEditingController reviewController = TextEditingController(
      text: _userReview?.comment ?? '',
    );
    bool reviewSubmitted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            bool isSubmitting = false;

            return AlertDialog(
              title: Text(_userReview == null
                  ? 'Write a Review'
                  : 'Edit Your Review'),
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
                            index < userRating
                                ? Icons.star
                                : Icons.star_border,
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
                  onPressed:
                  isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    print('🔘 Submit pressed');
                    print('👤 userId: $_currentUserId');
                    print('👤 userName: $_currentUserName');
                    print('⭐ rating: $userRating');
                    print('💬 comment: ${reviewController.text}');

                    if (reviewController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text('Please write a review')),
                      );
                      return;
                    }

                    setDialogState(() => isSubmitting = true);

                    try {
                      Review newReview = Review(
                        userId: _currentUserId!,
                        userName: _currentUserName!,
                        rating: userRating,
                        comment: reviewController.text.trim(),
                        timestamp: DateTime.now(),
                      );

                      print('📝 Calling addReview...');
                      await _reviewService.addReview(
                          widget.movie.id, newReview);
                      print('✅ addReview successful');

                      await ReviewedMoviesService.saveReviewedMovie(
                        _detailedMovie ?? widget.movie,
                        _currentUserId!,
                      );
                      print('✅ saveReviewedMovie successful');

                      _userReview = newReview;
                      reviewSubmitted = true;

                      Navigator.of(dialogContext).pop();
                    } catch (e) {
                      print('❌ Submit error: $e');
                      setDialogState(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Failed to submit: $e')),
                      );
                    }
                  },
                  child: isSubmitting
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    reviewController.dispose();
    return reviewSubmitted;
  }

  @override
  Widget build(BuildContext context) {
    final movie = _detailedMovie ?? widget.movie;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.movie.title)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          movie.title,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      movie.posterPath,
                      width: 140,
                      height: 210,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 140,
                          height: 210,
                          color: Colors.grey[300],
                          child: Icon(Icons.movie, size: 60),
                        );
                      },
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        if (movie.releaseDate != null)
                          Text(
                            movie.releaseDate!,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700]),
                          ),
                        SizedBox(height: 4),
                        if (movie.certification != null &&
                            movie.certification!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              movie.certification!,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        SizedBox(height: 4),
                        Text(
                          movie.getGenres(),
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 4),
                        Text(
                          movie.getFormattedRuntime(),
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _toggleWatchlist,
                          icon: Icon(
                            _isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 18,
                          ),
                          label: Text(_isBookmarked
                              ? 'In Watchlist'
                              : 'Add to Watchlist'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            backgroundColor:
                            _isBookmarked ? Colors.green : null,
                            foregroundColor:
                            _isBookmarked ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // TMDB Rating
              Row(
                children: [
                  _buildStarRating(movie.starRating),
                  SizedBox(width: 8),
                  Text(
                    '${movie.rating.toStringAsFixed(1)}/10',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Description
              Text('Description',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
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
                      overflow: _isDescriptionExpanded
                          ? null
                          : TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                    if (movie.overview.length > 150)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded =
                            !_isDescriptionExpanded;
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            _isDescriptionExpanded
                                ? '...less'
                                : '...more',
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Director
              if (movie.director != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Director',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(movie.director!,
                        style: TextStyle(
                            fontSize: 15, color: Colors.grey[700])),
                    SizedBox(height: 20),
                  ],
                ),

              // OTT
              Text('OTT:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Streaming platforms coming soon',
                  style:
                  TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
              ),

              SizedBox(height: 20),

              // Reviews Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reviews',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final submitted =
                      await _showWriteReviewDialog();
                      if (submitted && mounted) {
                        await _loadReviews();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Review submitted!')),
                        );
                      }
                    },
                    icon: Icon(Icons.rate_review, size: 18),
                    label: Text(_userReview == null ? 'Write Review' : 'Edit Review'),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Reviews List
              _reviewsLoading ? Center(child: CircularProgressIndicator()) :
              _reviews.isEmpty ? Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style:
                    TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
                  : Column(
                children: _buildSortedReviews(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Extracted to separate method for clarity
  List<Widget> _buildSortedReviews() {
    final sorted = [..._reviews];
    sorted.sort((a, b) {
      if (a.userId == _currentUserId) return -1;
      if (b.userId == _currentUserId) return 1;
      return b.timestamp.compareTo(a.timestamp);
    });

    return sorted.map((review) {
      bool isUserReview = review.userId == _currentUserId;
      return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _buildReviewCard(
          review,
          isUserReview: isUserReview,
          onDelete: isUserReview ? () => _deleteReview() : null,
        ),
      );
    }).toList();
  }

  Widget _buildReviewCard(
      Review review, {
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
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isUserReview ? Colors.blue : Colors.grey[400],
                      child: Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'A',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        review.userName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
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
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (onDelete != null)
                    IconButton(icon: Icon(Icons.delete,
                          color: Colors.red, size: 20),
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
            review.comment,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          SizedBox(height: 4),
          Text('${review.timestamp.day}/${review.timestamp.month}/${review.timestamp.year}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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

    if (confirm == true && mounted) {
      await _reviewService.deleteReview(widget.movie.id, _currentUserId!);
      await ReviewedMoviesService.deleteReviewedMovie(widget.movie.id, _currentUserId!);

      setState(() => _userReview = null);
      await _loadReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review deleted')),
      );
    }
  }
}