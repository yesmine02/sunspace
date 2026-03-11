import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/models/enrollment.dart';
import '../data/local/secure_storage.dart';
import 'auth_controller.dart';
import 'package:intl/intl.dart';

class StudentsController extends GetxController {
  final RxList<StudentEnrollment> enrollments = <StudentEnrollment>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadStudents();
  }

  Future<void> loadStudents() async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      final userId = auth.currentUser.value?['id'];

      if (token == null || userId == null) return;

      // Filter enrollments by current instructor's ID
      final String url = 'http://193.111.250.244:3046/api/enrollments?filters[course][instructor][id][\$eq]=$userId&populate=student&populate=course';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> enrollmentsList = responseData['data'] ?? [];
        
        List<StudentEnrollment> fetched = [];

        for (var item in enrollmentsList) {
          final studentData = item['student'] ?? {};
          final courseData = item['course'] ?? {};
          final String dateStr = item['enrolled_at'] ?? '';
          String formattedDate = '-';

          if (dateStr.isNotEmpty) {
            try {
              DateTime dt = DateTime.parse(dateStr);
              formattedDate = DateFormat('dd/MM/yyyy').format(dt);
            } catch (e) {}
          }

          fetched.add(StudentEnrollment(
            id: item['id']?.toString() ?? '',
            studentName: studentData['username'] ?? 'Inconnu',
            studentEmail: studentData['email'] ?? '-',
            courseTitle: courseData['title'] ?? 'Cours inconnu',
            progressPercentage: (item['progress_percentage'] ?? 0).toDouble(),
            enrollmentDate: formattedDate,
          ));
        }

        enrollments.assignAll(fetched);
      }
    } catch (e) {
      print('Erreur loadStudents: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
