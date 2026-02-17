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
      _currentUserName = user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous';
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
    try {
      final detailedMovie = await _tmdbService.fetchMovieDetails(widget.movie.id);
      if (!mounted) return;
      setState(() {
        _detailedMovie = detailedMovie;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailedMovie = widget.movie;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserReview() async {
    if (_currentUserId == null) return;
    try {
      final review = await _reviewService.getUserReview(widget.movie.id, _currentUserId!);
      if (mounted) setState(() => _userReview = review);
    } catch (e) {
      print('Error loading user review: $e');
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() => _reviewsLoading = true);
    try {
      final reviews = await _reviewService.getReviews(widget.movie.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _reviewsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _checkWatchlistStatus() async {
    try {
      bool inWatchlist = await _watchlistService.isInWatchlist(widget.movie.id);
      if (mounted) setState(() => _isBookmarked = inWatchlist);
    } catch (e) {
      print('Error checking watchlist: $e');
    }
  }

  Future<void> _toggleWatchlist() async {
    try {
      if (_isBookmarked) {
        await _watchlistService.removeFromWatchlist(widget.movie.id);
      } else {
        await _watchlistService.addToWatchlist(widget.movie.id);
      }
      if (mounted) {
        setState(() => _isBookmarked = !_isBookmarked);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isBookmarked ? 'Added to watchlist' : 'Removed from watchlist'), duration: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      print('Error toggling watchlist: $e');
    }
  }

  Future<bool> _showWriteReviewDialog() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to write a review')));
      return false;
    }

    double userRating = _userReview?.rating ?? 3.0;
    final TextEditingController reviewController = TextEditingController(text: _userReview?.comment ?? '');
    bool reviewSubmitted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_userReview == null ? 'Write a Review' : 'Edit Your Review'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Your Rating:'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(index < userRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                          onPressed: isSubmitting ? null : () => setDialogState(() => userRating = index + 1.0),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(hintText: 'Write your review here...', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (reviewController.text.trim().isEmpty) return;
                    setDialogState(() => isSubmitting = true);
                    try {
                      Review newReview = Review(
                        userId: _currentUserId!,
                        userName: _currentUserName!,
                        rating: userRating,
                        comment: reviewController.text.trim(),
                        timestamp: DateTime.now(),
                      );
                      await _reviewService.addReview(widget.movie.id, newReview);
                      await ReviewedMoviesService.saveReviewedMovie(_detailedMovie ?? widget.movie, _currentUserId!);
                      _userReview = newReview;
                      reviewSubmitted = true;
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
                    } catch (e) {
                      if (dialogContext.mounted) setDialogState(() => isSubmitting = false);
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit'),
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
      return Scaffold(appBar: AppBar(title: Text(widget.movie.title)), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(movie.title, overflow: TextOverflow.ellipsis)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(movie.posterPath, width: 140, height: 210, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(width: 140, height: 210, color: Colors.grey[300], child: const Icon(Icons.movie, size: 60))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(movie.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), maxLines: 3),
                        const SizedBox(height: 8),
                        if (movie.releaseDate != null) Text(movie.releaseDate!, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                        if (movie.certification != null && movie.certification!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                            child: Text(movie.certification!, style: const TextStyle(fontSize: 12)),
                          ),
                        Text(movie.getGenres(), style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                        Text(movie.getFormattedRuntime(), style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _toggleWatchlist,
                          icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border, size: 18),
                          label: Text(_isBookmarked ? 'In Watchlist' : 'Add to Watchlist'),
                          style: ElevatedButton.styleFrom(backgroundColor: _isBookmarked ? Colors.green : null, foregroundColor: _isBookmarked ? Colors.white : null),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(children: [_buildStarRating(movie.starRating), const SizedBox(width: 8), Text('${movie.rating.toStringAsFixed(1)}/10', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
              const SizedBox(height: 20),
              const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.overview, maxLines: _isDescriptionExpanded ? null : 3, overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 1.5)),
                    if (movie.overview.length > 150)
                      GestureDetector(
                        onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                        child: Padding(padding: const EdgeInsets.only(top: 8), child: Text(_isDescriptionExpanded ? '...less' : '...more', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (movie.director != null) ...[
                const Text('Director', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(movie.director!, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                const SizedBox(height: 20),
              ],
              const Text('OTT:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                  child: Text('Streaming platforms coming soon', style: TextStyle(fontSize: 15, color: Colors.grey[600]))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final submitted = await _showWriteReviewDialog();
                      if (submitted && mounted) {
                        setState(() {});
                        await _loadReviews();
                      }
                    },
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: Text(_userReview == null ? 'Write Review' : 'Edit Review'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _reviewsLoading ? const Center(child: CircularProgressIndicator()) : Column(children: _buildSortedReviews()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) return const Icon(Icons.star, color: Colors.amber, size: 28);
        if (index == fullStars && hasHalfStar) return const Icon(Icons.star_half, color: Colors.amber, size: 28);
        return const Icon(Icons.star_border, color: Colors.amber, size: 28);
      }),
    );
  }

  List<Widget> _buildSortedReviews() {
    final sorted = [..._reviews];
    sorted.sort((a, b) {
      if (a.userId == _currentUserId) return -1;
      if (b.userId == _currentUserId) return 1;
      return b.timestamp.compareTo(a.timestamp);
    });
    return sorted.map((review) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildReviewCard(review, isUserReview: review.userId == _currentUserId),
    )).toList();
  }

  Widget _buildReviewCard(Review review, {required bool isUserReview}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: isUserReview ? Colors.blue[300]! : Colors.grey[300]!, width: isUserReview ? 2 : 1),
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
                      child: Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'A', style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(review.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    if (isUserReview)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
                        child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(review.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (isUserReview)
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteReview()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text('${review.timestamp.day}/${review.timestamp.month}/${review.timestamp.year}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Future<void> _deleteReview() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _reviewService.deleteReview(widget.movie.id, _currentUserId!);
      await ReviewedMoviesService.deleteReviewedMovie(widget.movie.id, _currentUserId!);
      setState(() => _userReview = null);
      await _loadReviews();
    }
  }
}