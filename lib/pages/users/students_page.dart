import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/students_controller.dart';
import '../../data/models/enrollment.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StudentsController());
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Fond bleu très clair comme les autres pages
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 20 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 HEADER
            Row(
              children: [
                Icon(Icons.people_alt_outlined, color: const Color(0xFF007AFF), size: isMobile ? 28 : 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mes Étudiants",
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Suivez la progression de vos apprenants",
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 🔹 TABLE CARD
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)));
                  }

                  if (controller.enrollments.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (isMobile) {
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: controller.enrollments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final enr = controller.enrollments[index];
                        return _buildStudentMobileCard(enr);
                      },
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 400),
                        child: DataTable(
                          columnSpacing: 32,
                          horizontalMargin: 0,
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
                          ),
                          columns: const [
                            DataColumn(label: Text('Nom')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Cours')),
                            DataColumn(label: Text('Progression')),
                            DataColumn(label: Text('Date d\'inscription')),
                          ],
                          rows: controller.enrollments.map((enr) => DataRow(
                            cells: [
                              DataCell(Text(enr.studentName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              DataCell(Text(enr.studentEmail, style: const TextStyle(color: Color(0xFF64748B)))),
                              DataCell(Text(enr.courseTitle, style: const TextStyle(color: Color(0xFF1E293B)))),
                              DataCell(Text("${enr.progressPercentage.toInt()}%", style: const TextStyle(color: Color(0xFF1E293B)))),
                              DataCell(Text(enr.enrollmentDate, style: const TextStyle(color: Color(0xFF64748B)))),
                            ],
                          )).toList(),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentMobileCard(StudentEnrollment enr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                enr.studentName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${enr.progressPercentage.toInt()}%",
                  style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.email_outlined, enr.studentEmail),
          const SizedBox(height: 8),
          _infoRow(Icons.book_outlined, enr.courseTitle),
          const SizedBox(height: 8),
          _infoRow(Icons.calendar_today_outlined, enr.enrollmentDate),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text(
            "Aucun étudiant inscrit pour le moment",
            style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
