import 'dart:convert';

class Submission {
  final String? id;
  final String? documentId;
  final String assignmentId;
  final String studentId;
  final String? studentName;
  final String? content;
  final String status; // mystatus dans l'API
  final double? grade;
  final String? feedback;
  final String? attachmentUrl;
  final DateTime? createdAt;
  final DateTime? submittedAt;

  Submission({
    this.id,
    this.documentId,
    required this.assignmentId,
    required this.studentId,
    this.studentName,
    this.content,
    this.status = 'En attente',
    this.grade,
    this.feedback,
    this.attachmentUrl,
    this.createdAt,
    this.submittedAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    // Détection auto Strapi (si enveloppé dans 'attributes')
    final Map<String, dynamic> data = (json['attributes'] != null) ? json['attributes'] : json;
    
    // Extraction sécurisée de l'ID de fichier/URL (compatible Strapi v4/v5)
    String? url;
    if (data['file'] != null) {
      final fileData = data['file'];
      if (fileData is Map) {
        if (fileData['url'] != null) {
          url = fileData['url'];
        } else if (fileData['data'] != null) {
          final inner = fileData['data'];
          if (inner is Map) {
            final attrs = inner['attributes'] ?? inner;
            url = attrs['url'];
          }
        }
      }
    }

    return Submission(
      id: json['id']?.toString() ?? data['id']?.toString(),
      documentId: json['documentId']?.toString() ?? data['documentId']?.toString(),
      assignmentId: _extractId(data['assignment']),
      studentId: _extractId(data['student']),
      studentName: _extractStudentName(data['student']),
      content: data['content'],
      status: data['mystatus'] ?? data['status'] ?? 'En attente',
      grade: (data['grade'] ?? 0).toDouble(),
      feedback: data['feedback'],
      attachmentUrl: url,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
      submittedAt: data['submitted_at'] != null ? DateTime.parse(data['submitted_at']) : null,
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

  static String _extractStudentName(dynamic studentData) {
    if (studentData == null) return "Étudiant";
    Map? data;
    if (studentData is Map) {
      if (studentData['data'] != null && studentData['data'] is Map) {
        data = studentData['data']['attributes'] ?? studentData['data'];
      } else {
        data = studentData['attributes'] ?? studentData;
      }
    }
    if (data == null) return "Étudiant";
    return data['username'] ?? data['fullName'] ?? data['email'] ?? "Étudiant";
  }

  Map<String, dynamic> toStrapiJson() {
    return {
      'data': {
        'assignment': assignmentId,
        'student': studentId,
        'content': content ?? '',
        'mystatus': status,
      }
    };
  }
}
