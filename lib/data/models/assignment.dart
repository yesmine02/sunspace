// ===============================================
// Modèle Assignment (Devoir)
// ===============================================

import 'package:intl/intl.dart';

class Assignment {
  final String id;
  final String? documentId;
  final String title; // Titre du devoir
  final String? courseName; // Nom du cours associé
  final DateTime? dueDate; // Date d'échéance
  final double maxPoints; // Points maximum
  final double passingScore; // Note de passage
  final bool allowLateSubmission; // Autoriser les retards
  final String description; // Instructions
  final Map<String, dynamic>? attachment; // Pièce jointe

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
  });

  String get formattedDueDate {
    if (dueDate == null) return '-';
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(dueDate!);
  }

  static String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) return value.join('\n'); // Tente de joindre les listes (ex: RichText)
    return value.toString();
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    // Lecture des clés snake_case de Strapi
    final dateStr = json['due_date'];

    String courseTitle = '-';
    if (json['course'] != null && json['course'] is Map) {
      courseTitle = _safeString(json['course']['title']);
    } else if (json['courseName'] != null) {
      courseTitle = _safeString(json['courseName']);
    }

    return Assignment(
      id: json['id']?.toString() ?? '',
      documentId: json['documentId']?.toString(),
      title: _safeString(json['title'] ?? 'Sans titre'),
      courseName: courseTitle,
      dueDate: dateStr != null ? DateTime.parse(dateStr) : null,
      maxPoints: (json['max_points'] ?? 0).toDouble(),
      passingScore: (json['passing_score'] ?? 0).toDouble(),
      allowLateSubmission: json['allow_late_submission'] ?? false,
      description: _safeString(json['description']), 
      attachment: json['attachment'],
    );
  }

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

  // Convertit une string en format Blocks (Strapi v5 Rich Text)
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
  Map<String, dynamic> toStrapiJson(dynamic courseId) {
    return {
      'data': {
        'title': title,
        'description': _toBlocks(description), // Format Blocks (array)
        'due_date': dueDate?.toUtc().toIso8601String(),
        'max_points': maxPoints,
        'passing_score': passingScore,
        'allow_late_submission': allowLateSubmission,
        if (courseId != null) 'course': courseId.toString(),
      }
    };
  }
}
