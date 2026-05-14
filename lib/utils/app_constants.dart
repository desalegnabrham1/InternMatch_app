/// Centralised application-wide constants.
/// Import this file instead of hard-coding strings throughout the app.
class AppConstants {
  AppConstants._();

  // ── App meta ────────────────────────────────────────────────────────────────
  static const String appName = 'InternMatch';
  static const String appTagline = 'Find your perfect internship';

  // ── Firestore collections ───────────────────────────────────────────────────
  static const String colUsers = 'users';
  static const String colInternships = 'internships';
  static const String colChats = 'chats';
  static const String colMessages = 'messages';
  static const String colResumes = 'resumes';

  // ── Firebase Storage paths ──────────────────────────────────────────────────
  static const String storageResumes = 'resumes';

  // ── User roles ──────────────────────────────────────────────────────────────
  static const String roleUser = 'user';
  static const String roleCompany = 'company';
  static const String roleAdmin = 'admin';
  static const List<String> adminEmails = [
    'admin2@gmail.com',
  ];

  // ── Validation ──────────────────────────────────────────────────────────────
  static const int minPasswordLength = 6;
  static const int maxDescriptionLength = 2000;

  // ── Regex patterns ──────────────────────────────────────────────────────────
  /// RFC-5322-inspired simple email regex.
  static final RegExp emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  /// Accepts international phone numbers (digits, spaces, +, -, parentheses).
  static final RegExp phoneRegex = RegExp(r'^[+\d][\d\s\-().]{6,19}$');

  /// Simple URL regex (http/https optional).
  static final RegExp urlRegex = RegExp(
      r'^(https?:\/\/)?(www\.)?[a-zA-Z0-9\-]+(\.[a-zA-Z]{2,})+(\/[^\s]*)?$');

  // ── Snackbar messages ────────────────────────────────────────────────────────
  static const String msgInternshipPosted = 'Internship posted successfully!';
  static const String msgInternshipUpdated = 'Internship updated successfully!';
  static const String msgInternshipDeleted = 'Internship deleted.';
  static const String msgFailedPost = 'Failed to post internship.';
  static const String msgFailedUpdate = 'Failed to update internship.';
  static const String msgFailedDelete = 'Failed to delete internship.';
  static const String msgUserDeleted = 'User record deleted.';
  static const String msgFailedDeleteUser = 'Failed to delete user.';
  static const String msgProfileUpdated = 'Profile updated successfully!';
  static const String msgFailedProfile = 'Failed to update profile.';
  static const String msgResumeUploaded = 'Resume uploaded successfully!';
  static const String msgFailedResume = 'Failed to upload resume.';
  static const String msgBookmarkAdded = 'Saved to bookmarks.';
  static const String msgBookmarkRemoved = 'Removed from bookmarks.';
  static const String msgCompanyNotFound = 'Company profile not found.';
  static const String msgNoEmailApp = 'Could not open email app.';
  static const String msgNoDialer = 'Could not open dialer.';

  // ── Validator messages ───────────────────────────────────────────────────────
  static const String valRequired = 'This field is required';
  static const String valEmail = 'Please enter a valid email address';
  static const String valEmailRequired = 'Please enter your email';
  static const String valPasswordRequired = 'Please enter your password';
  static const String valPasswordLength =
      'Password must be at least $minPasswordLength characters';
  static const String valPasswordMatch = 'Passwords do not match';
  static const String valPhone = 'Please enter a valid phone number';
  static const String valUrl = 'Please enter a valid URL (e.g. https://...)';
  static const String valDeadline = 'Please select a deadline';
  static const String valNameRequired = 'Please enter your full name';
  static const String valCompanyNameRequired = 'Please enter your company name';
  static const String valTitleRequired = 'Please enter a job title';
}
