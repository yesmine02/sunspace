// ===============================================
// Modèle StudentEnrollment (Inscription)
// ===============================================
//représenter une inscription dans l’application (ses infos comme nom, email, progression…)
// pour pouvoir les utiliser et les envoyer au serveur.
class StudentEnrollment {
  final String id;
  final String studentName;
  final String studentEmail;
  final String courseTitle;
  final double progressPercentage;
  final String enrollmentDate;

  StudentEnrollment({
    required this.id,
    required this.studentName,
    required this.studentEmail,
    required this.courseTitle,
    this.progressPercentage = 0,
    required this.enrollmentDate,
  });
//✅ Crée une instance de StudentEnrollment à partir d'un JSON.
  factory StudentEnrollment.fromJson(Map<String, dynamic> json) {
    final student = json['student'] ?? {};
    final course = json['course'] ?? {};

    return StudentEnrollment(
      id: json['id']?.toString() ?? '',
      studentName: student['username'] ?? 'Inconnu',
      studentEmail: student['email'] ?? '-',
      courseTitle: course['title'] ?? 'Cours inconnu',
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
      enrollmentDate: json['enrolled_at'] != null ? json['enrolled_at'] : '-',
    );
  }
}
