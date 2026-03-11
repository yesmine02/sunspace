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
