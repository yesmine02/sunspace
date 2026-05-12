// ===============================================
// Modèle Assignment (Devoir)
// ===============================================

//stocker les infos/lire les données API/envoyer les données API
//formater la date/gérer description et fichier.
import 'package:intl/intl.dart';

class Assignment {
  final String id;
  final String? documentId;
  final String title; // Titre du devoir
  final String? courseId; // ID du cours
  final String? courseName; // Nom du cours associé
  final DateTime? dueDate; // Date d'échéance
  final List<dynamic>? submissions; // Soutenir les soumissions extraites
  final double maxPoints; // Points maximum
  final double passingScore; // Note de passage
  final bool allowLateSubmission; // Autoriser les retards
  final String description; // Instructions
  final String? courseDocumentId; // documentId du cours associé
  final Map<String, dynamic>? attachment; // Pièce jointe
//✅ Constructeur de la classe Assignment.
  Assignment({
    required this.id,
    this.documentId,
    required this.title,
    this.courseName,
    this.dueDate,
    this.maxPoints = 100,
    this.passingScore = 0,
    this.allowLateSubmission = false,
    this.description = '',
    this.attachment,
    this.courseId,
    this.courseDocumentId,
    this.submissions,
  });
//✅ Formate la date d'échéance en jj/MM/aaaa.
  String get formattedDueDate {
    if (dueDate == null) return '-';
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(dueDate!);
  }

  /// ✅ Retourne vrai si la date actuelle dépasse la date d'échéance.
  bool get isLate {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// ✅ Retourne vrai si l'étudiant spécifié a déjà soumis ce devoir.
  bool isSubmittedByUser(String? userId) {
    if (submissions == null || submissions!.isEmpty || userId == null) return false;
    return submissions!.any((s) {
      final subData = s is Map ? (s['attributes'] ?? s) : null;
      if (subData == null) return false;
      
      // Extraction de l'ID de l'étudiant dans la soumission
      String? subStudentId;
      final studentLink = subData['student'];
      if (studentLink != null) {
        if (studentLink is Map) {
          subStudentId = (studentLink['id'] ?? studentLink['data']?['id'])?.toString();
        } else if (studentLink is String || studentLink is int) {
          subStudentId = studentLink.toString();
        }
      }
      
      final status = subData['mystatus']?.toString() ?? 'Soumis';
      return subStudentId == userId && status == 'Soumis';
    });
  }

  /// Retourne true si l'utilisateur a soumis ce devoir
  bool get hasSubmitted => submissions != null && submissions!.isNotEmpty;

  /// ✅ Retourne la date de soumission pour un utilisateur donné
  String getFormattedSubmissionDateForUser(String? userId) {
    if (userId == null || submissions == null) return '-';
    try {
      final sub = submissions!.firstWhere((s) {
        final subData = s is Map ? (s['attributes'] ?? s) : null;
        final studentLink = subData?['student'];
        String? subStudentId;
        if (studentLink is Map) {
          subStudentId = (studentLink['id'] ?? studentLink['data']?['id'])?.toString();
        }
        return subStudentId == userId;
      });
      final subData = sub is Map ? (sub['attributes'] ?? sub) : null;
      final dateStr = subData?['submitted_at'] ?? subData?['createdAt'];
      if (dateStr == null) return '-';
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(DateTime.parse(dateStr));
    } catch (e) {
      return '-';
    }
  }
//✅ Méthode utilitaire pour gérer les valeurs nulles ou les listes.
  static String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) {
      // Gestion des Blocs Strapi (List of Maps with type: paragraph)
      try {
        return value.map((block) {
          if (block is Map && block['type'] == 'paragraph') {
            final children = block['children'];
            if (children is List) {
              return children.map((child) => child['text'] ?? '').join('');
            }
          }
          return block.toString();
        }).join('\n');
      } catch (e) {
        return value.join('\n');
      }
    }
    return value.toString();
  }
//✅ Crée une instance d'Assignment à partir d'un JSON.
  factory Assignment.fromJson(Map<String, dynamic> json) { 
    // Détection auto Strapi (si enveloppé dans 'attributes')
    final Map<String, dynamic> data = (json['attributes'] != null) ? json['attributes'] : json;
    
    final dateStr = data['due_date'];
    final idStr = json['id']?.toString() ?? data['id']?.toString() ?? '';

    // Extraction ultra-robuste du titre du cours et de l'ID (Strapi v4/v5/Flat/Nested)
    String courseTitle = '-';
    String? cId;
    String? cDocId;

    final dynamic cp = data['course'] ?? json['course'];
    if (cp != null) {
      if (cp is Map) {
        // Extraction ID/DocID
        cId = (cp['id'] ?? cp['data']?['id'] ?? cp['attributes']?['id'])?.toString();
        cDocId = (cp['documentId'] ?? cp['data']?['documentId'] ?? cp['attributes']?['documentId'])?.toString();
        
        // Recherche du titre dans tous les niveaux possibles (data -> attributes -> title)
        dynamic findTitle(dynamic obj) {
          if (obj == null) return null;
          if (obj is! Map) return null;
          if (obj['title'] != null) return obj['title'];
          if (obj['name'] != null) return obj['name'];
          if (obj['attributes'] != null) return findTitle(obj['attributes']);
          if (obj['data'] != null) return findTitle(obj['data']);
          return null;
        }
        
        final resTitle = findTitle(cp);
        if (resTitle != null) courseTitle = resTitle.toString();
      } else {
        // ID direct
        cId = cp.toString();
      }
    }

    return Assignment(
      id: idStr,
      documentId: json['documentId']?.toString() ?? data['documentId']?.toString(),
      title: _safeString(data['title'] ?? 'Sans titre'),
      courseName: courseTitle,
      dueDate: dateStr != null ? DateTime.parse(dateStr) : null,
      maxPoints: (data['max_points'] ?? 0).toDouble(),
      passingScore: (data['passing_score'] ?? 0).toDouble(),
      allowLateSubmission: data['allow_late_submission'] ?? false,
      description: _safeString(data['description']), 
      attachment: _extractFileData(data['attachment']),
      courseId: cId,
      courseDocumentId: cDocId,
      // Strapi v5 peut renvoyer directement la liste ou enveloppée dans 'data'
      submissions: data['submissions'] is List ? data['submissions'] : (data['submissions']?['data'] ?? []),
    );
  }

  static Map<String, dynamic>? _extractFileData(dynamic fileField) {
    if (fileField == null) return null;
    
    // Si c'est déjà le Map final
    if (fileField is Map && fileField['url'] != null) {
      return Map<String, dynamic>.from(fileField);
    }
    
    // Si c'est enveloppé dans data/attributes (Strapi standard)
    if (fileField is Map && fileField['data'] != null) {
      final inner = fileField['data'];
      if (inner is Map) {
        final Map<String, dynamic> attrs = inner['attributes'] ?? inner;
        return {
          'id': inner['id'],
          'name': attrs['name'],
          'url': attrs['url'],
          'ext': attrs['ext'],
        };
      }
    }
    
    return null;
  }

//✅ Convertit un Assignment en JSON pour l'API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'title': title,
      'courseName': courseName,
      'dueDate': dueDate?.toIso8601String(),
      'maxPoints': maxPoints,
      'passingScore': passingScore,
      'allowLateSubmission': allowLateSubmission,
      'description': description,
      'attachment': attachment,
    };
  }

  //transforme une description simple en format spécial Strapi RichText.
  static List<Map<String, dynamic>> _toBlocks(String text) {
    if (text.isEmpty) {
      return [
        {
          'type': 'paragraph',
          'children': [
            {'type': 'text', 'text': ''}
          ]
        }
      ];
    }
    return text.split('\n').map((line) {
      return {
        'type': 'paragraph',
        'children': [
          {'type': 'text', 'text': line}
        ]
      };
    }).toList();
  }

  // Pour l'envoi API — conforme au schéma Strapi
  Map<String, dynamic> toStrapiJson(dynamic courseId) { //Envoyer un devoir au serveur
    int? numericCourseId;
    if (courseId != null) {
      if (courseId is int) {
        numericCourseId = courseId;
      } else if (courseId is String) {
        numericCourseId = int.tryParse(courseId);
      }
    }

    return {
      'data': {
        'title': title,
        'description': _toBlocks(description), // Format Blocks (array)
        'due_date': dueDate?.toUtc().toIso8601String(),
        'max_points': maxPoints,
        'passing_score': passingScore,
        'allow_late_submission': allowLateSubmission,
        if (numericCourseId != null) 'course': {'connect': [numericCourseId]},
        'publishedAt': DateTime.now().toUtc().toIso8601String(), // Auto-publish for Strapi v4/v5
      }
    };
  }
}
