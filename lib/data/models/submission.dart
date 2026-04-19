import 'dart:convert';

class Submission {
  final String? id;
  final String? documentId;
  final String assignmentId;
  final String studentId;
  final String? content;
  final String status;
  final double? grade;
  final String? feedback;
  final String? attachmentUrl;
  final DateTime? createdAt;

  Submission({
    this.id,
    this.documentId,
    required this.assignmentId,
    required this.studentId,
    this.content,
    this.status = 'En attente',
    this.grade,
    this.feedback,
    this.attachmentUrl,
    this.createdAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    // Détection auto Strapi (si enveloppé dans 'attributes')
    final Map<String, dynamic> data = (json['attributes'] != null) ? json['attributes'] : json;
    
    // Récupération de l'URL de l'attachement si présente
    String? url;
    if (data['attachment'] != null) {
      final attachment = data['attachment'];
      if (attachment is Map) {
        if (attachment['url'] != null) {
          url = attachment['url'];
        } else if (attachment['data'] != null && attachment['data'] is Map) {
          final inner = attachment['data'];
          if (inner['attributes'] != null) {
            url = inner['attributes']['url'];
          } else {
            url = inner['url'];
          }
        }
      }
    }

    return Submission(
      id: json['id']?.toString() ?? data['id']?.toString(),
      documentId: json['documentId']?.toString() ?? data['documentId']?.toString(),
      assignmentId: _extractId(data['assignment']),
      studentId: _extractId(data['student']),
      content: data['content'],
      status: data['status'] ?? 'En attente',
      grade: (data['grade'] ?? 0).toDouble(),
      feedback: data['feedback'],
      attachmentUrl: url,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
    );
  }

  static String _extractId(dynamic relation) {
    if (relation == null) return '';
    if (relation is Map) {
      if (relation['id'] != null) return relation['id'].toString();
      if (relation['data'] != null && relation['data'] is Map) {
        return relation['data']['id'].toString();
      }
    }
    return relation.toString();
  }

  Map<String, dynamic> toStrapiJson() {
    return {
      'data': {
        'assignment': assignmentId,
        'student': studentId,
        'content': content ?? '',
        'status': status,
      }
    };
  }
}
