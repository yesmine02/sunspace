// ============================================
// Contrôleur des Sessions (SessionsController)
// Gère les sessions de formation (CRUD)
// ============================================

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/training_session.dart';
import '../data/local/secure_storage.dart';
import 'auth_controller.dart';

class SessionsController extends GetxController {
  final RxList<TrainingSession> sessions = <TrainingSession>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  static const String _baseUrl = 'http://193.111.250.244:3046/api/training-sessions';
  static const String _storageKey = 'saved_sessions';

  @override
  void onInit() {
    super.onInit();
    loadSessions();
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 🔹 CHARGER les sessions
  Future<void> loadSessions() async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token != null) {
        // On peuple 'course' pour avoir le nom de la formation
        final response = await http.get(
          Uri.parse('$_baseUrl?populate=*&pagination[pageSize]=100'),
          headers: _headers(token),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final List<dynamic> data = responseData['data'] ?? [];
          sessions.value = data.map((item) => TrainingSession.fromJson(item)).toList();
          await _saveToLocal();
        } else {
          print('Erreur loadSessions: ${response.statusCode} - ${response.body}');
          await _loadFromLocal();
        }
      }
    } catch (e) {
      print('Erreur Exception loadSessions: $e');
      await _loadFromLocal();
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 AJOUTER une session
  Future<void> addSession(TrainingSession session, dynamic courseId) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      int? instructorId = auth.currentUser.value?['id'];

      if (token != null) {
        final bodyData = session.toStrapiJson(instructorId, courseId);
        print('POST Training Session Body: ${jsonEncode(bodyData)}');
        
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: _headers(token),
          body: jsonEncode(bodyData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await loadSessions();
          Get.back();
          _showSnackbar('Succès', 'Session planifiée', Colors.green);
        } else {
          print('Erreur addSession (${response.statusCode}): ${response.body}');
          _showSnackbar('Erreur', 'Échec de la planification (${response.statusCode})', Colors.red);
        }
      }
    } catch (e) {
      print('Exception addSession: $e');
      _showSnackbar('Erreur', 'Connexion impossible', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 MODIFIER une session
  Future<void> updateSession(TrainingSession session, dynamic courseId) async {
    if (session.documentId == null) return;

    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      int? instructorId = auth.currentUser.value?['id'];

      if (token != null) {
        final bodyData = session.toStrapiJson(instructorId, courseId);
        print('PUT Training Session Body: ${jsonEncode(bodyData)}');

        final response = await http.put(
          Uri.parse('$_baseUrl/${session.documentId}'),
          headers: _headers(token),
          body: jsonEncode(bodyData),
        );

        if (response.statusCode == 200) {
          await loadSessions();
          Get.back();
          _showSnackbar('Succès', 'Session mise à jour', Colors.blue);
        } else {
          print('Erreur updateSession (${response.statusCode}): ${response.body}');
          _showSnackbar('Erreur', 'Échec de la modification (${response.statusCode})', Colors.red);
        }
      }
    } catch (e) {
      print('Exception updateSession: $e');
      _showSnackbar('Erreur', 'Connexion impossible', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 SUPPRIMER une session
  Future<void> deleteSession(String docId) async {
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
          await loadSessions();
          _showSnackbar('Supprimé', 'Session annulée', Colors.orange);
        }
      }
    } catch (e) {
      _showSnackbar('Erreur', 'Échec de la suppression', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 S'INSCRIRE à une session
  Future<void> enrollInSession(String sessionDocId) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      int? userId = auth.currentUser.value?['id'];

      if (token != null && userId != null) {
        final body = jsonEncode({
          'data': {
            'attendees': {
              'connect': [userId]
            }
          }
        });

        final response = await http.put(
          Uri.parse('$_baseUrl/$sessionDocId'),
          headers: _headers(token),
          body: body,
        );

        if (response.statusCode == 200) {
          await loadSessions();
          _showSnackbar('Succès', 'Votre inscription a été enregistrée', Colors.green);
        } else {
          _showSnackbar('Erreur', 'Impossible de s\'inscrire', Colors.red);
        }
      } else {
        _showSnackbar('Erreur', 'Vous devez être connecté pour vous inscrire', Colors.orange);
      }
    } catch (e) {
      _showSnackbar('Erreur', 'Une erreur est survenue lors de l\'inscription', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 SE DÉSINSCRIRE d'une session
  Future<void> unenrollFromSession(String sessionDocId) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      int? userId = auth.currentUser.value?['id'];

      if (token != null && userId != null) {
        // Dans Strapi v5, on utilise disconnect pour retirer une relation
        final body = jsonEncode({
          'data': {
            'attendees': {
              'disconnect': [userId]
            }
          }
        });

        final response = await http.put(
          Uri.parse('$_baseUrl/$sessionDocId'),
          headers: _headers(token),
          body: body,
        );

        if (response.statusCode == 200) {
          await loadSessions();
          _showSnackbar('Succès', 'Votre inscription a été annulée', Colors.orange);
        } else {
          _showSnackbar('Erreur', 'Impossible de se désinscrire', Colors.red);
        }
      }
    } catch (e) {
      _showSnackbar('Erreur', 'Une erreur est survenue', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String query) => searchQuery.value = query;

  List<TrainingSession> get filteredSessions {
    if (searchQuery.isEmpty) return sessions;
    return sessions.where((s) => s.title.toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
  }

  void _showSnackbar(String title, String msg, Color color) {
    Get.snackbar(title, msg, backgroundColor: color, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
    } catch (e) {
      print('Erreur _saveToLocal: $e');
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cached = prefs.getString(_storageKey);
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        sessions.value = decoded.map((item) => TrainingSession.fromJson(item)).toList();
      }
    } catch (e) {
      print('Erreur _loadFromLocal: $e');
    }
  }
}
