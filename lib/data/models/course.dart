// ============================================
// Modèle Course (Formation) - Alignement Complet Strapi v5
// ============================================
//représenter une formation dans l’application (ses infos comme titre, prix, niveau…) 
//pour pouvoir les utiliser et les envoyer au serveur.
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
//✅ Vérifie si le cours est publié.
  bool get isPublished => status == CourseStatus.publie;
//✅ Convertit le niveau du cours en String.
  static CourseLevel _parseLevel(String? levelStr) {
    if (levelStr == null) return CourseLevel.debutant;
    if (levelStr == 'Intermédiaire') return CourseLevel.intermediaire;
    if (levelStr == 'Avancé') return CourseLevel.avance;
    return CourseLevel.debutant;
  }
//Elle vérifie si le cours est publié ou brouillon
  static CourseStatus _parseStatus(String? statusStr) {
    if (statusStr == 'Publié' || statusStr == 'publie') return CourseStatus.publie;
    return CourseStatus.brouillon;
  }
//✅ Crée une instance de Course à partir d'un JSON.
  factory Course.fromJson(Map<String, dynamic> json) {
    // Détection auto Strapi v5 (si enveloppé dans 'attributes')
    final Map<String, dynamic> data = (json['attributes'] != null) ? json['attributes'] : json;
    
    return Course(
      id: json['id']?.toString() ?? data['id']?.toString() ?? '',
      documentId: json['documentId']?.toString() ?? data['documentId']?.toString(),
      title: data['title'] ?? 'Sans titre',
      level: _parseLevel(data['level']),
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      status: _parseStatus(data['mystatus']),
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
      publishedAt: data['publishedAt'] != null ? DateTime.parse(data['publishedAt']) : null,
      instructorName: (data['instructor'] != null) 
          ? (data['instructor'] is Map ? (data['instructor']['username'] ?? data['instructor']['data']?['username'] ?? '') : '')
          : '',
    );
  }
//✅ Convertit un Course en JSON pour l'API.
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
//✅ Convertit un Course en JSON pour l'API.
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
//prend le niveau technique du cours le transforme en texte que l’utilisateur comprend.
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
