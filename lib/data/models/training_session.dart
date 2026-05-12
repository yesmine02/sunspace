// ============================================
// Modèle TrainingSession (Session de Formation)
// ============================================
//représenter une session de formation (titre, date, type, statut, participants…)
import 'package:intl/intl.dart';

enum SessionType { presentiel, hybride, enLigne }
enum SessionStatus { brouillon, publie }

class TrainingSession {
  final String id;
  final String? documentId;
  final String title;
  final String? courseName; // Nom du cours associé
  final String? courseId; // ID numérique ou documentId du cours
  final SessionType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final SessionStatus status;
  final int maxParticipants;
  final int currentParticipants;
  final String? meetingLink;
  final String? notes;
  final List<int> attendeeIds;
  final int? instructorId;
  final String? instructorName;

  TrainingSession({
    required this.id,
    this.documentId,
    required this.title,
    this.courseName,
    this.courseId,
    required this.type,
    this.startDate,
    this.endDate,
    this.status = SessionStatus.brouillon,
    this.maxParticipants = 10,
    this.currentParticipants = 0,
    this.meetingLink,
    this.notes,
    this.attendeeIds = const [],
    this.instructorId,
    this.instructorName,
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

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  String get formattedStartDate {
    if (startDate == null) return '-';
    return DateFormat('d MMMM à HH:mm', 'fr_FR').format(startDate!);
  }

  String get formattedEndDate {
    if (endDate == null) return '-';
    return DateFormat('d MMMM à HH:mm', 'fr_FR').format(endDate!);
  }

  String get formattedTimeRange {
    if (startDate == null || endDate == null) return '-';
    final date = DateFormat('d MMMM', 'fr_FR').format(startDate!);
    final start = DateFormat('HH:mm').format(startDate!);
    final end = DateFormat('HH:mm').format(endDate!);
    return "$date ($start - $end)";
  }

  /// Extrait le nom de l'espace depuis les notes (format: "📍 Espace: NOM\n...")
  String? get spaceName {
    if (notes == null) return null;
    if (notes!.startsWith("📍 Espace: ")) {
      return notes!.split("\n")[0].replaceFirst("📍 Espace: ", "").trim();
    }
    return null;
  }

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    // Détection auto Strapi v5 (si enveloppé dans 'attributes')
    final Map<String, dynamic> data = (json['attributes'] != null) ? json['attributes'] : json;

    // Le serveur Strapi utilise start_datetime et end_datetime
    final startStr = data['start_datetime'];
    final endStr = data['end_datetime'];

    return TrainingSession(
      id: json['id']?.toString() ?? data['id']?.toString() ?? '',
      documentId: json['documentId']?.toString() ?? data['documentId']?.toString(),
      title: data['title'] ?? 'Sans titre',
      courseName: data['course'] is Map 
          ? (data['course']['title'] ?? data['course']['data']?['attributes']?['title'] ?? data['course']['data']?['title'] ?? '-')
          : (data['courseName'] ?? '-'),
      courseId: data['course'] != null
          ? (data['course'] is Map
              ? (data['course']['id'] ?? data['course']['data']?['id'] ?? data['course']['documentId'] ?? data['course']['data']?['documentId'])?.toString()
              : data['course'].toString())
          : null,
      type: _parseType(data['type']),
      startDate: startStr != null ? DateTime.parse(startStr).toLocal() : null,
      endDate: endStr != null ? DateTime.parse(endStr).toLocal() : null,
      status: data['mystatus'] == 'Planifiée' ? SessionStatus.publie : SessionStatus.brouillon,
      maxParticipants: data['max_participants'] ?? 10,
      currentParticipants: (data['attendees'] as List?)?.length ?? data['currentParticipants'] ?? 0,
      attendeeIds: (data['attendees'] as List?)?.map((e) => (e['id'] as num).toInt()).toList() ?? [],
      meetingLink: data['meeting_url'] ?? data['recording_url'] ?? data['meetingLink'],
      notes: data['notes'],
      instructorId: data['instructor'] != null
          ? (data['instructor'] is Map
              ? int.tryParse((data['instructor']['id'] ?? data['instructor']['data']?['id'] ?? '').toString())
              : int.tryParse(data['instructor'].toString()))
          : null,
      instructorName: data['instructor'] != null && data['instructor'] is Map
          ? (data['instructor']['username'] ?? data['instructor']['data']?['attributes']?['username'] ?? data['instructor']['data']?['username'] ?? 'Instructeur')
          : null,
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
