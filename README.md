# InternMatch - Internship Finder

A mobile application that connects students with internship opportunities. Built with Flutter and Firebase.

## Features

- **Multi-Role Authentication**: Student, Company, and Admin dashboards
- **Job Listings**: Browse and search internship opportunities
- **Application Management**: Track applications and statuses
- **Company Profiles**: Companies can post and manage internships
- **File Upload**: Resume and portfolio uploads via Firebase Storage
- **Google Sign-In**: Easy authentication with Google accounts
- **Real-time Data**: Firestore integration for live updates

## Tech Stack

- **Frontend**: Flutter 3.0+
- **Backend**: Firebase (Auth, Firestore, Cloud Storage, Cloud Functions)
- **Authentication**: Firebase Auth + Google Sign-In
- **Database**: Cloud Firestore
- **Additional**: Font Awesome icons, URL launcher, File picker

## Installation

1. **Prerequisites**:
   - Flutter SDK 3.0 or higher
   - Android SDK / Xcode (for iOS)
   - Firebase project with config files

2. **Clone & Setup**:
   ```bash
   flutter pub get
   flutter run
   ```

3. **Firebase Configuration**:
   - Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are configured
   - Update Firebase rules in `firestore.rules`

## Project Structure

- `lib/` - Source code
  - `screens/` - UI screens (admin, company, user)
  - `services/` - Firebase and business logic
  - `models/` - Data models
  - `widgets/` - Reusable UI components
  - `utils/` - Constants, themes, helpers

## Development

- Run: `flutter run`
- Build Android: `flutter build apk`
- Build iOS: `flutter build ios`

## License

This project is private.
