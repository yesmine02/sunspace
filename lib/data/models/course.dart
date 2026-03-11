// ============================================
// Modèle Course (Formation) - Alignement Complet Strapi v5
// ============================================

import 'package:get/get.dart';

enum CourseLevel { debutant, intermediaire, avance }
enum CourseStatus { brouillon, publie }

class Course {
  final String id;
  final String? documentId;
  final String title;
  final CourseLevel level;
  final double price;
  final String description;
  final CourseStatus status; // Correspond au champ 'mystatus' sur Strapi
  final DateTime? createdAt;
  final DateTime? publishedAt;
  final String? instructorName;

  Course({
    required this.id,
    this.documentId,
    required this.title,
    required this.level,
    required this.price,
    this.description = '',
    this.status = CourseStatus.brouillon,
    this.createdAt,
    this.publishedAt,
    this.instructorName,
  });

  bool get isPublished => status == CourseStatus.publie;

  static CourseLevel _parseLevel(String? levelStr) {
    if (levelStr == null) return CourseLevel.debutant;
    if (levelStr == 'Intermédiaire') return CourseLevel.intermediaire;
    if (levelStr == 'Avancé') return CourseLevel.avance;
    return CourseLevel.debutant;
  }

  static CourseStatus _parseStatus(String? statusStr) {
    if (statusStr == 'Publié' || statusStr == 'publie') return CourseStatus.publie;
    return CourseStatus.brouillon;
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'].toString(),
      documentId: json['documentId']?.toString(),
      title: json['title'] ?? 'Sans titre',
      level: _parseLevel(json['level']),
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      status: _parseStatus(json['mystatus']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt']) : null,
      instructorName: json['instructor']?['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'title': title,
      'level': levelString,
      'price': price,
      'description': description,
      'mystatus': statusString,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toStrapiJson(int? instructorId) {
    return {
      'data': {
        'title': title,
        'level': levelString,
        'price': price.toInt(),
        'description': description,
        'mystatus': statusString, // Envoie 'Brouillon' ou 'Publié'
        if (instructorId != null) 'instructor': instructorId,
      }
    };
  }

  String get levelString {
    switch (level) {
      case CourseLevel.intermediaire: return 'Intermédiaire';
      case CourseLevel.avance: return 'Avancé';
      case CourseLevel.debutant: return 'Débutant';
    }
  }

  String get statusString {
    return status == CourseStatus.publie ? 'Publié' : 'Brouillon';
  }

  String get levelLabel => levelString;
}
