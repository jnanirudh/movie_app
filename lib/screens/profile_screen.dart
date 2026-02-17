import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    try {
      final user = FirebaseAuth.instance.currentUser;
      _userId = user?.uid;

      setState(() {
        if (user != null && user.email != null) {
          _userName = user.email!.split('@')[0];
        } else {
          _userName = 'Movie Enthusiast';
        }
      });

      // Load watchlist
      _watchlistMovies = await _watchlistService.getWatchlistMovies();

      // Load user reviews from Firestore
      await _loadUserReviews();
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserReviews() async {
    if (_userId == null) return;

    try {
      print('Loading reviews for user: $_userId');
      final reviewMaps = await _reviewService.getUserReviews(_userId!);
      print('Found ${reviewMaps.length} reviews');

      List<MovieReviewPair> pairs = [];

      final reviewedMovies =
      await ReviewedMoviesService.getReviewedMovies(_userId!);
      print('Reviewed movies tracked: ${reviewedMovies.length}');

      for (var reviewMap in reviewMaps) {
        try {
          int movieId = reviewMap['movieId'];
          Movie? movie = reviewedMovies[movieId];

          if (movie == null) {
            try {
              movie =
                  _watchlistMovies.firstWhere((m) => m.id == movieId);
            } catch (e) {
              print(
                  'Movie $movieId not found in watchlist or reviewed movies');
            }
          }

          if (movie != null) {
            final review = Review(
              userId: reviewMap['userId'] ?? '',
              userName: reviewMap['userName'] ?? 'Anonymous',
              rating: (reviewMap['rating'] as num).toDouble(),
              comment: reviewMap['comment'] ?? '',
              timestamp: reviewMap['timestamp'] != null
                  ? (reviewMap['timestamp'] as dynamic).toDate()
                  : DateTime.now(),
            );
            pairs.add(MovieReviewPair(movie: movie, review: review));
            print('Added review pair for: ${movie.title}');
          } else {
            print('Could not find movie data for movieId: $movieId');
          }
        } catch (e) {
          print('Error processing review: $e');
        }
      }

      setState(() {
        _userReviews = pairs;
      });
    } catch (e) {
      print('Error loading user reviews: $e');
    }
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
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
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
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue,
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
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