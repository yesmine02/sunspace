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

class CoursesController extends GetxController {
  final RxList<Course> courses = <Course>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  static const String _baseUrl = 'http://193.111.250.244:3046/api/courses';
  static const String _storageKey = 'saved_courses';

  @override
  void onInit() {
    super.onInit();
    loadCourses();
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 🔹 GET
  Future<void> loadCourses() async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token != null) {
        final response = await http.get(
          Uri.parse('$_baseUrl?populate=*&pagination[pageSize]=100'),
          headers: _headers(token),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final List<dynamic> data = responseData['data'] ?? [];
          courses.value = data.map((item) => Course.fromJson(item)).toList();
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
          await loadCourses();
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
