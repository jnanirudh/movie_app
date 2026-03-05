import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import 'movieDetail_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Movie> _watchlistMovies = [];
  List<MovieReviewPair> _userReviews = [];
  bool _isLoading = true;
  String _displayName = 'Movie Enthusiast';
  String _subTitle = ''; // shows email or phone under the name
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Returns the best single-character avatar initial.
  String get _avatarInitial =>
      _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U';

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.getCurrentUser();
      if (user != null) {
        _userId = user['id'];

        // Best display name: display_name → email prefix → phone → fallback
        _displayName = user['display_name'] ??
            (user['email'] != null
                ? (user['email'] as String).split('@')[0]
                : null) ??
            user['phone'] ??
            'Movie Enthusiast';

        // Subtitle: show email if available, otherwise phone, otherwise nothing
        _subTitle = user['email'] ?? user['phone'] ?? '';
      }

      _watchlistMovies = await ApiService.getWatchlistMovies();
      await _loadUserReviews();
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserReviews() async {
    try {
      final reviewMaps = await ApiService.getMyReviews();
      List<MovieReviewPair> pairs = [];

      for (var r in reviewMaps) {
        final movieData = r['movie'];
        if (movieData == null) continue;

        final movie = Movie.fromJson(movieData);
        final review = Review(
          userId: r['user_id'] ?? '',
          userName: _displayName,
          rating: (r['rating'] as num).toDouble(),
          comment: r['comment'] ?? '',
          timestamp: DateTime.parse(r['created_at']),
        );
        pairs.add(MovieReviewPair(movie: movie, review: review));
      }

      if (mounted) setState(() => _userReviews = pairs);
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Share Your Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            QrImageView(
                data: 'user_profile:$_userId',
                version: QrVersions.auto,
                size: 200),
            const SizedBox(height: 20),
            Text('Scan to view profile',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              if (result == true) _loadProfileData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProfileData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(children: [
                    Stack(children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue,
                        child: Text(_avatarInitial,
                            style: const TextStyle(
                                fontSize: 48,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showQRCode,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.blue, width: 2)),
                            child: const Icon(Icons.qr_code,
                                size: 24, color: Colors.blue),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Text(_displayName,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    if (_subTitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(_subTitle,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600])),
                    ],
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Watchlist ────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Watchlist',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                _watchlistMovies.isEmpty
                    ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: Text('No movies in watchlist yet',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey))))
                    : SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    itemCount: _watchlistMovies.length,
                    itemBuilder: (context, index) {
                      final movie = _watchlistMovies[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    MovieDetailScreen(
                                        movie: movie)))
                            .then((_) => _loadProfileData()),
                        child: Container(
                          width: 130,
                          margin:
                          const EdgeInsets.only(right: 16),
                          child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  child: Image.network(
                                      movie.posterPath,
                                      width: 130,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                              width: 130,
                                              height: 180,
                                              color:
                                              Colors.grey[300],
                                              child: const Icon(
                                                  Icons.movie,
                                                  size: 50))),
                                ),
                                const SizedBox(height: 8),
                                Text(movie.title,
                                    maxLines: 2,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                        FontWeight.w500)),
                              ]),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // ── Reviews ──────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Reviews',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                _userReviews.isEmpty
                    ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: Text('No reviews yet',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey))))
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  itemCount: _userReviews.length,
                  itemBuilder: (context, index) =>
                      _buildReviewCard(_userReviews[index]),
                ),
                const SizedBox(height: 20),
              ]),
        ),
      ),
    );
  }

  Widget _buildReviewCard(MovieReviewPair pair) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => MovieDetailScreen(movie: pair.movie)))
          .then((_) => _loadProfileData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(pair.movie.posterPath,
                width: 80,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, size: 40))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pair.movie.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                      children: List.generate(
                          5,
                              (i) => Icon(
                              i < pair.review.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 24))),
                  const SizedBox(height: 8),
                  Text(pair.review.comment,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                      TextStyle(fontSize: 14, color: Colors.grey[700])),
                ]),
          ),
        ]),
      ),
    );
  }
}

class MovieReviewPair {
  final Movie movie;
  final Review review;
  MovieReviewPair({required this.movie, required this.review});
}