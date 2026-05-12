// ============================================
// Contrôleur des Formations (CoursesController)
// ============================================

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/course.dart';
import '../data/local/secure_storage.dart';
import 'auth_controller.dart';
import 'notification_controller.dart';
import 'assignments_controller.dart'; // Ajout de l'import manquant

class CoursesController extends GetxController {
  final RxList<Course> courses = <Course>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxList<int> enrolledCourseIds = <int>[].obs;
  final RxList<String> enrolledCourseDocumentIds = <String>[].obs;

  static const String _baseUrl = 'http://193.111.250.244:3046/api/courses';
  static const String _storageKey = 'saved_courses';

  @override
  void onInit() {
    super.onInit();
    loadCourses();
    fetchEnrollments();
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
//✅ Récupère les formations depuis Strapi.
  // 🔹 GET
  Future<void> loadCourses() async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
//✅ Vérifie que l'utilisateur est connecté.
      if (token != null) {
        final response = await http.get(
          Uri.parse('$_baseUrl?populate=*&pagination[pageSize]=100'),
          headers: _headers(token),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final List<dynamic> data = responseData['data'] ?? [];
          if (data.isNotEmpty) {
            print("DEBUG: First Course raw JSON: ${data[0]}");
          }
          final List<Course> loaded = [];
          for (var item in data) {
            try {
              loaded.add(Course.fromJson(item));
            } catch (e, stack) {
              print("❌ ERROR parsing course: $e");
              print("ITEM: $item");
              print(stack);
            }
          }
          courses.value = loaded;
          await _saveToLocal();
        }
      }
    } catch (e) {
      print('Erreur loadCourses: $e');
      await _loadFromLocal();
    } finally {
      isLoading.value = false;
    }
  }
//✅ Ajoute une nouvelle formation.
  // 🔹 POST (ADD)
  Future<void> addCourse(Course course) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      int? instructorId = auth.currentUser.value?['id'];

      if (token != null) {
        final body = jsonEncode(course.toStrapiJson(instructorId));
        print('DEBUG - Ajout Corp: $body');

        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: _headers(token),
          body: body,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Extraire l'ID du cours créé
          dynamic newCourseId;
          try {
            final respData = jsonDecode(response.body);
            newCourseId = respData['data']?['id'] ?? respData['data']?['documentId'];
          } catch (e) {
            debugPrint('Erreur parsing ID cours: $e');
          }

          await loadCourses();
          
          // 📢 Notifier tous les étudiants de la nouvelle formation
          try {
            debugPrint('📣 Tentative d\'envoi de notification aux étudiants...');
            final instructorName = auth.currentUser.value?['username'] ?? 'Un enseignant';
            final notifCtrl = Get.find<NotificationController>();
            notifCtrl.notifyMembers(
              title: 'Nouveau cours disponible !',
              message: '$instructorName a publié un nouveau cours : "${course.title}"',
              type: 'Info', // Indispensable pour éviter l'erreur 400
              relatedType: 'course',
              relatedId: newCourseId,
              actionUrl: '/dashboard/student/catalog',
            );
          } catch (e) {
            debugPrint('Erreur notification étudiants: $e');
          }

          Get.back();
          _showSnackbar('Succès', 'Formation créée', Colors.green);
        } else {
          print('DEBUG - Erreur Ajout: ${response.body}');
          _showSnackbar('Erreur 400', 'Champ obligatoire manquant ou invalide', Colors.red);
        }
      }
    } catch (e) {
      _showSnackbar('Erreur', 'Impossible de contacter le serveur', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 PUT (UPDATE)
  Future<void> updateCourse(Course course) async {
    final String? docId = course.documentId;
    if (docId == null) return;

    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      int? instructorId = auth.currentUser.value?['id'];

      if (token != null) {
        final body = jsonEncode(course.toStrapiJson(instructorId));
        final response = await http.put(
          Uri.parse('$_baseUrl/$docId'),
          headers: _headers(token),
          body: body,
        );

        if (response.statusCode == 200) {
          await loadCourses();
          Get.back();
          _showSnackbar('Succès', 'Formation mise à jour', Colors.blue);
        } else {
          print('DEBUG - Erreur Modif: ${response.body}');
          _showSnackbar('Erreur', 'Échec de la modification', Colors.red);
        }
      }
    } catch (e) {
      _showSnackbar('Erreur', 'Impossible de contacter le serveur', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 DELETE
  Future<void> deleteCourse(String docId) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token != null) {
        final response = await http.delete(
          Uri.parse('$_baseUrl/$docId'),
          headers: _headers(token),
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          await loadCourses();
          _showSnackbar('Supprimé', 'Formation retirée', Colors.orange);
        }
      }
    } catch (e) {
      _showSnackbar('Erreur', 'Échec de la suppression', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 ENROLL IN COURSE (Inscription)
  Future<bool> enrollInCourse(Course course) async {
    try {
      final auth = Get.find<AuthController>();
      final userId = auth.currentUser.value?['id'];
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token == null || userId == null) return false;

      final url = 'http://193.111.250.244:3046/api/enrollments';
      
      // Strapi v5 Format Robuste
      final body = jsonEncode({
        'data': {
          'student': userId,
          'course': { 'connect': [int.tryParse(course.id) ?? course.id] },
          'enrolled_at': DateTime.now().toUtc().toIso8601String(),
          'publishedAt': DateTime.now().toUtc().toIso8601String(),
          'mystatus': 'Active', // Correction : 'Active' avec un 'e'
          'progress_percentage': 0,
          'certificate_issued': false,
          'final_grade': 0,
        }
      });

      final response = await http.post(
        Uri.parse(url),
        headers: _headers(token),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("DEBUG: Inscription réussie pour le cours ${course.title}");
        await fetchEnrollments(); // Recharger les IDs d'inscription
        await loadCourses();      // Recharger le catalogue pour l'état des boutons
        
        // Optionnel : Rafraîchir les devoirs si le contrôleur existe
        if (Get.isRegistered<AssignmentsController>()) {
          Get.find<AssignmentsController>().fetchAssignments();
        }

        // 🔔 Envoyer une notification à l'enseignant du cours
        if (course.instructorId != null) {
          try {
            final studentName = auth.currentUser.value?['username'] ?? 'Un étudiant';
            final notifCtrl = Get.find<NotificationController>();
            
            await notifCtrl.sendNotification(
              targetUserId: course.instructorId!,
              title: 'Nouvelle inscription !',
              message: '$studentName s\'est inscrit à votre cours "${course.title}".',
              type: 'Info',
              relatedType: 'course',
              relatedId: course.id,
              actionUrl: '/dashboard/instructor/courses',
            );
          } catch (e) {
            print('Erreur lors de l\'envoi de la notification à l\'enseignant: $e');
          }
        }
        
        return true;
      } else {
        print("DEBUG: Erreur inscription: ${response.body}");
        return false;
      }
    } catch (e) {
      print('Erreur enrollInCourse: $e');
      return false;
    }
  }

  // 🔹 GET ENROLLMENTS
  Future<void> fetchEnrollments() async {
    try {
      final auth = Get.find<AuthController>();
      final userId = auth.currentUser.value?['id'];
      final token = auth.token ?? await SecureStorage.getToken();
      if (token == null || userId == null) return;

      // URL simple - confirmée fonctionnelle
      final url = 'http://193.111.250.244:3046/api/enrollments'
          '?filters[student][id][\$eq]=$userId'
          '&populate=course'
          '&pagination[pageSize]=100';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'] ?? [];
        final List<int> ids = [];
        final List<String> docIds = [];

        for (var item in data) {
          // Strapi v5 flat: course directement dans item
          // Strapi v4: dans item['attributes']['course']['data']
          dynamic courseInfo = item['course'] ?? item['attributes']?['course'];
          if (courseInfo == null) continue;

          final courseData = courseInfo['data'] ?? courseInfo;
          final id = int.tryParse((courseData['id'] ?? '').toString());
          final docId = (courseData['documentId'] ?? courseData['attributes']?['documentId'] ?? '').toString();

          if (id != null) ids.add(id);
          if (docId.isNotEmpty) docIds.add(docId);
        }

        enrolledCourseIds.value = ids;
        enrolledCourseDocumentIds.value = docIds;
        debugPrint('🎓 Enrollments chargés : IDs=$ids | DocIDs=$docIds');
      } else {
        debugPrint('⚠️ fetchEnrollments HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur fetchEnrollments: $e');
    }
  }

  bool isEnrolled(Course course) {
    final numId = int.tryParse(course.id.toString());
    if (numId != null && enrolledCourseIds.contains(numId)) return true;
    if (course.documentId != null && enrolledCourseDocumentIds.contains(course.documentId)) return true;
    return false;
  }

  void updateSearch(String query) => searchQuery.value = query;

  List<Course> get filteredCourses {
    if (searchQuery.isEmpty) return courses;
    return courses.where((c) => c.title.toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
  }

  void _showSnackbar(String title, String msg, Color color) {
    Get.snackbar(title, msg, backgroundColor: color, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(courses.map((c) => c.toJson()).toList()));
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString(_storageKey);
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      courses.value = decoded.map((item) => Course.fromJson(item)).toList();
    }
  }
}
