// ============================================
// Modèle TrainingSession (Session de Formation)
// ============================================

import 'package:intl/intl.dart';

enum SessionType { presentiel, hybride, enLigne }
enum SessionStatus { brouillon, publie }

class TrainingSession {
  final String id;
  final String? documentId;
  final String title;
  final String? courseName; // Nom du cours associé
  final SessionType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final SessionStatus status;
  final int maxParticipants;
  final int currentParticipants;
  final String? meetingLink;
  final String? notes;
  final List<int> attendeeIds;

  TrainingSession({
    required this.id,
    this.documentId,
    required this.title,
    this.courseName,
    required this.type,
    this.startDate,
    this.endDate,
    this.status = SessionStatus.brouillon,
    this.maxParticipants = 10,
    this.currentParticipants = 0,
    this.meetingLink,
    this.notes,
    this.attendeeIds = const [],
  });

  // Libellés pour l'UI
  String get typeLabel {
    switch (type) {
      case SessionType.presentiel: return 'Présentiel';
      case SessionType.hybride: return 'Hybride';
      case SessionType.enLigne: return 'En ligne';
    }
  }

  // Valeurs pour le serveur Strapi
  String get typeStrapiValue {
    switch (type) {
      case SessionType.presentiel: return 'Présentiel';
      case SessionType.hybride: return 'Hybride';
      case SessionType.enLigne: return 'En_ligne';
    }
  }
  
  String get statusString {
    return status == SessionStatus.publie ? 'Planifiée' : 'Brouillon';
  }

  String get formattedStartDate {
    if (startDate == null) return '-';
    return DateFormat('d MMMM à HH:mm', 'fr_FR').format(startDate!);
  }

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    // Le serveur Strapi utilise start_datetime et end_datetime
    final startStr = json['start_datetime'];
    final endStr = json['end_datetime'];

    return TrainingSession(
      id: json['id']?.toString() ?? '',
      documentId: json['documentId']?.toString(),
      title: json['title'] ?? 'Sans titre',
      courseName: json['course']?['title'] ?? json['courseName'] ?? '-',
      type: _parseType(json['type']),
      startDate: startStr != null ? DateTime.parse(startStr) : null,
      endDate: endStr != null ? DateTime.parse(endStr) : null,
      status: json['mystatus'] == 'Planifiée' ? SessionStatus.publie : SessionStatus.brouillon,
      maxParticipants: json['max_participants'] ?? 10,
      currentParticipants: (json['attendees'] as List?)?.length ?? json['currentParticipants'] ?? 0,
      attendeeIds: (json['attendees'] as List?)?.map((e) => (e['id'] as num).toInt()).toList() ?? [],
      meetingLink: json['meeting_url'] ?? json['recording_url'] ?? json['meetingLink'],
      notes: json['notes'],
    );
  }

  static SessionType _parseType(String? typeStr) {
    if (typeStr == null) return SessionType.enLigne;
    if (typeStr == 'En_ligne') return SessionType.enLigne;
    if (typeStr == 'Presentiel') return SessionType.presentiel;
    if (typeStr == 'Hybride') return SessionType.hybride;
    
    // Fallbacks
    String t = typeStr.toLowerCase();
    if (t.contains('présentiel') || t.contains('presentiel')) return SessionType.presentiel;
    if (t.contains('hybride')) return SessionType.hybride;
    return SessionType.enLigne;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'title': title,
      'courseName': courseName,
      'type': type.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.name,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'attendeeIds': attendeeIds,
      'meetingLink': meetingLink,
      'notes': notes,
    };
  }

  // 🔹 Format STRICT pour Strapi v5 basé sur le JSON fourni
  Map<String, dynamic> toStrapiJson(int? instructorId, dynamic courseId) {
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
        'type': typeStrapiValue, // "En_ligne", "Presentiel", "Hybride"
        'start_datetime': startDate?.toUtc().toIso8601String(),
        'end_datetime': endDate?.toUtc().toIso8601String(),
        'max_participants': maxParticipants,
        'meeting_url': (meetingLink != null && meetingLink!.isNotEmpty) ? meetingLink : null,
        'notes': (notes != null && notes!.isNotEmpty) ? notes : null,
        'mystatus': statusString, // "Planifiée"
        if (instructorId != null) 'instructor': instructorId,
        if (numericCourseId != null) 'course': numericCourseId,
      }
    };
  }
}
