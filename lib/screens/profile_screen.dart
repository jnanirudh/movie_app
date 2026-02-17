import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../services/watchlist_service.dart';
import '../services/review_service.dart';
import '../services/reviewedMovie_service.dart';
import 'movieDetail_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final WatchlistService _watchlistService = WatchlistService();
  final ReviewService _reviewService = ReviewService();

  List<Movie> _watchlistMovies = [];
  List<MovieReviewPair> _userReviews = [];
  bool _isLoading = true;
  String _userName = 'Loading...';
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    // Get user ID
    _userId = await _reviewService.getCurrentUserId();

    setState(() {
      _userName = 'User_${_userId!.substring(_userId!.length - 8)}';
    });

    // Load watchlist
    _watchlistMovies = await _watchlistService.getWatchlistMovies();

    // Load user reviews
    await _loadUserReviews();

    setState(() => _isLoading = false);
  }

  Future<void> _loadUserReviews() async {
    _userReviews = [];

    // Get all reviewed movies from the service
    Map<int, Movie> reviewedMovies = await _getReviewedMovies();

    for (var entry in reviewedMovies.entries) {
      int movieId = entry.key;
      Movie movie = entry.value;

      Review? review = await _reviewService.getUserReview(movieId, _userId!);
      if (review != null) {
        _userReviews.add(MovieReviewPair(movie: movie, review: review));
      }
    }

    // Sort by most recent
    _userReviews.sort((a, b) => b.review.timestamp.compareTo(a.review.timestamp));
  }

  Future<Map<int, Movie>> _getReviewedMovies() async {
    return await ReviewedMoviesService.getReviewedMovies(_userId!);
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share Your Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              QrImageView(
                data: 'user_profile:$_userId',
                version: QrVersions.auto,
                size: 200.0,
              ),
              SizedBox(height: 20),
              Text(
                'Scan to view profile',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              // Navigate to settings screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );

              // If user logged out, reload profile data
              if (result == true) {
                _loadProfileData();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProfileData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section - User Identity
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // Profile Picture with QR Code button
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showQRCode,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 2),
                              ),
                              child: Icon(
                                Icons.qr_code,
                                size: 24,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Username
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID: ${_userId?.substring(0, 12)}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Watchlist Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Watchlist',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12),

              _watchlistMovies.isEmpty
                  ? Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No movies in watchlist yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
                  : Container(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _watchlistMovies.length,
                  itemBuilder: (context, index) {
                    final movie = _watchlistMovies[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(movie: movie),
                          ),
                        ).then((_) => _loadProfileData());
                      },
                      child: Container(
                        width: 130,
                        margin: EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                movie.posterPath,
                                width: 130,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 130,
                                    height: 180,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.movie, size: 50),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              movie.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 30),

              // Reviews Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12),

              _userReviews.isEmpty
                  ? Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: _userReviews.length,
                itemBuilder: (context, index) {
                  final pair = _userReviews[index];
                  return _buildReviewCard(pair);
                },
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(MovieReviewPair pair) {
    final movie = pair.movie;
    final review = pair.review;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(movie: movie),
          ),
        ).then((_) => _loadProfileData());
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                movie.posterPath,
                width: 80,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 120,
                    color: Colors.grey[300],
                    child: Icon(Icons.movie, size: 40),
                  );
                },
              ),
            ),
            SizedBox(width: 16),

            // Movie Info and Rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),

                  // Star Rating
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating.floor()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
                  ),
                  SizedBox(height: 8),

                  Text(
                    review.comment,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to pair movie with review
class MovieReviewPair {
  final Movie movie;
  final Review review;

  MovieReviewPair({required this.movie, required this.review});
}