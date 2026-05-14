import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' | 'user' | 'company'
  final DateTime createdAt;

  // Student-specific profile fields
  final String fullName;
  final String headline;
  final String location;
  final List<String> skills;
  final String? resumeUrl;

  // Company-specific profile fields
  final String companyName;
  final String website;
  final String description;

  // Bookmarks (student only)
  final List<String> savedInternships;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    this.fullName = '',
    this.headline = '',
    this.location = '',
    this.skills = const [],
    this.resumeUrl,
    this.companyName = '',
    this.website = '',
    this.description = '',
    this.savedInternships = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    // Helper to safely convert to List<String>
    List<String> toStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return (value).whereType<String>().toList();
      }
      // If it's a single string, convert to a list with one element
      if (value is String) {
        return [value];
      }
      return [];
    }

    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fullName: map['fullName'] ?? '',
      headline: map['headline'] ?? '',
      location: map['location'] ?? '',
      skills: toStringList(map['skills']),
      resumeUrl: map['resumeUrl'] as String?,
      companyName: map['companyName'] ?? '',
      website: map['website'] ?? '',
      description: map['description'] ?? '',
      savedInternships: toStringList(map['savedInternships']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'fullName': fullName,
      'headline': headline,
      'location': location,
      'skills': skills,
      if (resumeUrl != null) 'resumeUrl': resumeUrl,
      'companyName': companyName,
      'website': website,
      'description': description,
      'savedInternships': savedInternships,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? headline,
    String? location,
    List<String>? skills,
    String? resumeUrl,
    String? companyName,
    String? website,
    String? description,
    List<String>? savedInternships,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      role: role,
      createdAt: createdAt,
      fullName: fullName ?? this.fullName,
      headline: headline ?? this.headline,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      companyName: companyName ?? this.companyName,
      website: website ?? this.website,
      description: description ?? this.description,
      savedInternships: savedInternships ?? this.savedInternships,
    );
  }
}
