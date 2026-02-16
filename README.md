# 🎬 Movie Browser App

A feature-rich Flutter mobile application for browsing movies, managing watchlists, and writing reviews. Built with TMDB API integration.

## ✨ Features
### 🏠 Home Screen
- Browse popular movies with infinite scroll
- Display movie posters, titles, genres, languages, and ratings
- Tap any movie card to view detailed information

### 🔍 Search Screen
- Real-time movie search powered by TMDB API
- Search results with poster thumbnails and key information
- Direct navigation to movie details from search results

### 🎥 Movie Detail Screen
- Comprehensive movie information including:
    - Large poster image
    - Title, release date, age rating, genre, and runtime
    - Star rating (converted to 5-star scale)
    - Expandable movie description
    - Director information
    - Streaming platform availability (OTT section)
- **Watchlist Management**: Add/remove movies from your personal watchlist
- **User Reviews**:
    - Write and edit your own reviews with star ratings
    - View reviews from other users

### 👤 Profile Screen
- User profile with avatar and QR code for profile sharing
- **Watchlist Section**: Horizontally scrollable list of saved movies
- **Reviews Section**: View all your movie reviews in one place
- Tap any movie or review to navigate to detailed view
- Settings icon for future configurations

## 🛠️ Technologies Used

- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **TMDB API** - Movie database and information
- **SharedPreferences** - Local data persistence
- **QR Flutter** - QR code generation for profile sharing

## 📦 Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  qr_flutter: ^4.1.0
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code with Flutter extensions
- TMDB API Key

### Installation

1. **Clone the repository**
```bash
   git clone https://github.com/yourusername/movie-browser-app.git
   cd movie-browser-app
```

2. **Install dependencies**
```bash
   flutter pub get
```

3. **Get your TMDB API Key**
    - Visit [TMDB API](https://www.themoviedb.org/settings/api)
    - Create an account and request an API key
    - Copy your API key

4. **Configure API Key**

   Create/update `lib/services/tmdb_service.dart`:
```dart
   class TmdbService {
     final String _apiKey = 'YOUR_API_KEY_HERE';
     final String _baseUrl = 'https://api.themoviedb.org/3';
     // ... rest of the code
   }
```

5. **Run the app**
```bash
   flutter run
```

## 📁 Project Structure
```
lib/
├── models/
│   ├── movie.dart           # Movie data model
│   └── review.dart          # Review data model
├── services/
│   ├── tmdb_service.dart    # TMDB API integration
│   ├── review_service.dart  # Review management
│   └── watchlist_service.dart # Watchlist management
├── screens/
│   ├── main_screen.dart     # Bottom navigation wrapper
│   ├── home_screen.dart     # Movie browsing
│   ├── search_screen.dart   # Movie search
│   ├── movieDetail_screen.dart # Movie details
│   └── profile_screen.dart  # User profile
└── main.dart                # App entry point
```

## 🎯 Key Features Explained

### Movie Model
The app uses a custom `Movie` model that maps TMDB API responses to Dart objects:
- ID, title, poster path, overview, rating
- Release date, runtime, certification
- Genre IDs with helper methods for display
- Language codes with readable names
- Director information from credits

### Data Persistence
- **SharedPreferences** for local storage:
    - User watchlist (movie IDs and full movie objects)
    - User reviews (ratings and comments)
    - User ID generation for review attribution

### Review System
- Users can write one review per movie
- Reviews include 1-5 star rating and text comment
- User's own review always appears first
- Edit and delete functionality for own reviews
- Reviews persist locally and display on profile

### Watchlist System
- Add/remove movies with bookmark button
- Synced across Movie Detail and Profile screens
- Visual feedback with SnackBar notifications
- Horizontal scrollable display in profile

## 🔮 Future Enhancements

- Social features (follow users, share reviews)
- Advanced filtering and sorting options on home screen
- Trailer playback integration
- Movie release notifications
- Dark mode support
- Multiple language support

## 📱 Screenshots



## 🙏 Acknowledgments

- [TMDB](https://www.themoviedb.org/) for providing the movie database API
- [Flutter](https://flutter.dev/) team for the amazing framework
- All contributors and testers

## 📧 Contact

Anirudh Jain - jn.anirudh@gmail.com
