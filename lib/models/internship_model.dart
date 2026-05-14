import 'package:cloud_firestore/cloud_firestore.dart';

class InternshipModel {
  final String id;
  final String title;
  final String companyName;
  final String location;
  final String description;
  final String requirement;
  final String contactEmail;
  final String contactPhone;
  final String deadline;
  final String createdBy; // company UID
  final DateTime createdAt;

  InternshipModel({
    required this.id,
    required this.title,
    required this.companyName,
    required this.location,
    required this.description,
    required this.requirement,
    required this.contactEmail,
    required this.contactPhone,
    required this.deadline,
    required this.createdBy,
    required this.createdAt,
  });

  factory InternshipModel.fromMap(Map<String, dynamic> map, String id) {
    return InternshipModel(
      id: id,
      title: map['title'] ?? '',
      companyName: map['companyName'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      requirement: map['requirement'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      deadline: map['deadline'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'companyName': companyName,
      'location': location,
      'description': description,
      'requirement': requirement,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'deadline': deadline,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  InternshipModel copyWith({
    String? id,
    String? title,
    String? companyName,
    String? location,
    String? description,
    String? requirement,
    String? contactEmail,
    String? contactPhone,
    String? deadline,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return InternshipModel(
      id: id ?? this.id,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      description: description ?? this.description,
      requirement: requirement ?? this.requirement,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      deadline: deadline ?? this.deadline,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
