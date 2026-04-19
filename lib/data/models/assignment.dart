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
  final double maxPoints; // Points maximum
  final double passingScore; // Note de passage
  final bool allowLateSubmission; // Autoriser les retards
  final String description; // Instructions
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
  });
//✅ Formate la date d'échéance en jj/MM/aaaa.
  String get formattedDueDate {
    if (dueDate == null) return '-';
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(dueDate!);
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

    // Extraction robuste du titre du cours (Strapi v5)
    String courseTitle = '-';
    // On cherche d'abord dans 'data' (le niveau actuel), puis dans les relations
    final coursePayload = data['course'];
    if (coursePayload != null) {
      if (coursePayload is Map) {
         if (coursePayload['title'] != null) {
           courseTitle = _safeString(coursePayload['title']);
         } else if (coursePayload['data'] != null && coursePayload['data'] is Map) {
           // Strapi v5 structure nested data
           final innerData = coursePayload['data'];
           if (innerData['attributes'] != null) {
             courseTitle = _safeString(innerData['attributes']['title']);
           } else {
             courseTitle = _safeString(innerData['title']);
           }
         }
      }
    }
    
    // Extraction robuste de l'ID du cours
    String? cId;
    if (coursePayload != null && coursePayload is Map) {
      if (coursePayload['id'] != null) {
        cId = coursePayload['id'].toString();
      } else if (coursePayload['data'] != null && coursePayload['data'] is Map) {
        cId = coursePayload['data']['id']?.toString();
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
      attachment: data['attachment'],
      courseId: cId,
    );
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
    return {
      'data': {
        'title': title,
        'description': _toBlocks(description), // Format Blocks (array)
        'due_date': dueDate?.toUtc().toIso8601String(),
        'max_points': maxPoints,
        'passing_score': passingScore,
        'allow_late_submission': allowLateSubmission,
        if (courseId != null) 'course': courseId.toString(), //associer le devoir au cours
      }
    };
  }
}
