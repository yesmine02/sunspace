// ===============================================
// Contrôleur des Devoirs (AssignmentsController)
// CRUD complet vers Strapi v5
// ===============================================

import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/models/assignment.dart';
import 'auth_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'courses_controller.dart';

class AssignmentsController extends GetxController {
  final String _baseUrl = 'http://193.111.250.244:3046/api/assignments';
  final AuthController _authController = Get.find<AuthController>();

  var assignments = <Assignment>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs; // Pour afficher les erreurs dans l'UI
  var originalAssignments = <Assignment>[]; // Pour la recherche locale
  var searchQuery = ''.obs;
  var isManagementMode = false.obs; // ✅ Nouveau : Mode gestion pour Enseignant/Admin

  @override
  void onInit() {
    super.onInit();
    fetchAssignments();
    ever(searchQuery, (_) => _filterAssignments());
  }

  Future<void> fetchAssignments() async {
    try {
      isLoading(true);
      errorMessage.value = '';
      final token = await _authController.getToken();
      final user = _authController.currentUser.value;

      String url;

      if (isManagementMode.value && _authController.isAdmin) {
        // Admin en mode gestion : Voit TOUT
        url = '$_baseUrl?populate=course&populate=submissions&populate=attachment';
      } else if (_authController.isInstructor && user != null) {
        // Enseignant : récupère ses devoirs
        url = '$_baseUrl?populate=course&populate=submissions&populate=attachment&filters[course][instructor][id][\$eq]=${user['id']}';
      } else if ((_authController.isStudent || _authController.isAdmin) && user != null) {
        // Étudiant ou Admin en vue "Mes Devoirs" : filtrer par inscriptions
        final coursesController = Get.find<CoursesController>();
        if (coursesController.enrolledCourseIds.isEmpty) {
          await coursesController.fetchEnrollments();
        }
        final ids = coursesController.enrolledCourseIds;
        if (ids.isEmpty) {
          assignments.value = [];
          originalAssignments = [];
          isLoading(false);
          return;
        }
        final idFilters = ids.asMap().entries.map((e) =>
          'filters[course][id][\$in][${e.key}]=${e.value}'
        ).join('&');
        url = '$_baseUrl?populate=course&populate=attachment&$idFilters';
      } else {
        // Autres cas
        url = '$_baseUrl?populate=course&populate=submissions&populate=attachment';
      }

      print("Fetching assignments from: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Response status: ${response.statusCode}");
      // print("Response body: ${response.body}"); // Uncomment for deep debug

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        if (data['data'] is List) { //On vérifie que :👉 le serveur a envoyé une liste.
          final List<dynamic> jsonList = data['data']; //On met la liste JSON dans une variable
          print("Found ${jsonList.length} assignments.");

          final List<Assignment> loadedAssignments = [];
          if (jsonList.isNotEmpty) {
            print("DEBUG: First item raw JSON: ${jsonList[0]}");
          }
          for (var item in jsonList) {
            try {
              final assignment = Assignment.fromJson(item);
              loadedAssignments.add(assignment);
            } catch (e, stack) {
              print("❌ ERROR parsing assignment: $e");
              print("ITEM: $item");
              print(stack);
            }
          }

          assignments.value = loadedAssignments;//On met à jour la liste reactive affichée dans UI.
          originalAssignments = loadedAssignments;//On garde une copie originale.👉 utile pour :recherche,filtres,reset.
          
          if (assignments.isEmpty && jsonList.isNotEmpty) {
             errorMessage.value = "Erreur de lecture des données (Parsing).";
          }
          
          _filterAssignments();
          _saveToCache(data); 
        } else {
           print("Format inattendu: data['data'] n'est pas une liste.");
           errorMessage.value = "Format de réponse inattendu (pas une liste).";
        }

      } else {
        print("Erreur chargement: ${response.statusCode} - ${response.body}");
        errorMessage.value = "Erreur serveur: ${response.statusCode}";
        _loadFromCache();
      }
    } catch (e) {
      print("Exception chargement devoirs: $e");
      errorMessage.value = "Erreur de connexion: $e";
      _loadFromCache();
    } finally {
      isLoading(false);
    }
  }

  // 2. Recherche locale
  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void _filterAssignments() {
    if (searchQuery.value.isEmpty) {
      assignments.value = originalAssignments;
    } else {
      String query = searchQuery.value.toLowerCase();
      assignments.value = originalAssignments.where((assignment) {
        return assignment.title.toLowerCase().contains(query) ||
               (assignment.courseName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  // 3. Ajout d'un devoir (POST) — pattern identique à addSession
  Future<void> addAssignment(Assignment assignment, dynamic courseId, {PlatformFile? file}) async {
    try {
      final token = await _authController.getToken();
      final url = Uri.parse(_baseUrl);
      
      final Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Construire le body
      final body = json.encode(assignment.toStrapiJson(courseId));
      
      print("=== ENVOI CRÉATION DEVOIR ===");
      print("URL: $url");
      print("Body: $body");

      final response = await http.post(url, headers: headers, body: body);

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Si un fichier est fourni, on l'upload séparément via Strapi Upload API
        if (file != null) {
          final createdData = json.decode(response.body);
          final createdId = createdData['data']?['id']; //On récupère l’ID du devoir créé.
          if (createdId != null) {
            await _uploadAttachment(createdId, file, token);
          }
        }
        Get.snackbar('Succès', 'Devoir créé avec succès');
        fetchAssignments();
      } else {
        print("Erreur création: ${response.body}");
        Get.snackbar('Erreur', 'Échec de la création (${response.statusCode})');
      }
    } catch (e) {
      print("Exception création: $e");
      Get.snackbar('Erreur', 'Problème de connexion: $e');
    }
  }

  // Upload du fichier séparément via l'API Upload de Strapi
  Future<void> _uploadAttachment(dynamic entryId, PlatformFile file, String? token) async {
    try {
      final uploadUrl = Uri.parse('http://193.111.250.244:3046/api/upload');
      var request = http.MultipartRequest('POST', uploadUrl);//car on envoie un fichier
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['ref'] = 'api::assignment.assignment';
      request.fields['refId'] = entryId.toString();
      request.fields['field'] = 'attachment';
//Ajouter le fichier
      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'files', file.bytes!, filename: file.name,
        ));
      } else if (file.path != null) {
        request.files.add(await http.MultipartFile.fromPath('files', file.path!));
      }

      print("Upload fichier: ${file.name} pour entry $entryId");
      //Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print("Upload response: ${response.statusCode} - ${response.body}");
    } catch (e) {
      print("Erreur upload fichier: $e");
    }
  }

  // 4. Modification d'un devoir (PUT)
  Future<void> updateAssignment(Assignment assignment, dynamic courseId) async {
    //On vérifie que l’ID du devoir n’est pas nul.
    if (assignment.documentId == null) {
      Get.snackbar('Erreur', 'Impossible de modifier : ID manquant');
      return;
    }
//✅ On crée un client HTTP pour envoyer la requête.
    final client = http.Client();
    try {
      final token = await _authController.getToken();
      final url = Uri.parse('$_baseUrl/${assignment.documentId}');
//✅ On prépare les headers avec le token.
      final Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
//✅ On convertit le devoir en JSON.
      final body = json.encode(assignment.toStrapiJson(courseId));

      print("=== MODIFICATION DEVOIR (PUT) ===");
      print("URL: $url");
      // print("Body: $body"); // Décommenter pour debug

      final response = await client.put(url, headers: headers, body: body);

      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        Get.snackbar('Succès', 'Devoir modifié avec succès');
        fetchAssignments();
      } else {
        print("Erreur modification: ${response.body}");
        Get.snackbar('Erreur', 'Échec de la modification (${response.statusCode})');
      }
    } catch (e) {
      print("Exception modification: $e");
      Get.snackbar('Erreur', 'Problème de connexion: $e');
    } finally {
      client.close();
    }
  }

  // 5. Suppression (DELETE)
  Future<void> deleteAssignment(String documentId) async {
    try {
      final token = await _authController.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$documentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        assignments.removeWhere((a) => a.documentId == documentId);
        originalAssignments.removeWhere((a) => a.documentId == documentId);
        Get.snackbar('Succès', 'Devoir supprimé');
      } else {
        Get.snackbar('Erreur', 'Impossible de supprimer (${response.statusCode})');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau');
    }
  }

  // 6. Soumission d'un devoir (Student)
  Future<bool> submitAssignment(String assignmentId, {String? content, PlatformFile? file}) async {
    try {
      isLoading(true);
      final token = await _authController.getToken();
      final user = _authController.currentUser.value;
      if (user == null || token == null) return false;

      final userId = user['id'].toString();
      final url = Uri.parse('http://193.111.250.244:3046/api/submissions');
      
      final body = json.encode({
        'data': {
          'assignment': assignmentId,
          'student': userId,
          'content': content ?? '',
          'status': 'En attente',
          'submitted_at': DateTime.now().toIso8601String(),
        }
      });

      print("=== SOUMISSION DEVOIR ===");
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("Submit response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final submissionId = data['data']?['id'];

        if (file != null && submissionId != null) {
          await _uploadSubmissionFile(submissionId, file, token);
        }

        Get.snackbar('Succès', 'Votre travail a été soumis !', backgroundColor: const Color(0xFF10B981), colorText: Colors.white);
        return true;
      } else {
        Get.snackbar('Erreur', 'Échec de la soumission (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print("Exception soumission: $e");
      Get.snackbar('Erreur', 'Problème de connexion');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> _uploadSubmissionFile(dynamic entryId, PlatformFile file, String token) async {
    try {
      final uploadUrl = Uri.parse('http://193.111.250.244:3046/api/upload');
      var request = http.MultipartRequest('POST', uploadUrl);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['ref'] = 'api::submission.submission';
      request.fields['refId'] = entryId.toString();
      request.fields['field'] = 'attachment';

      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('files', file.bytes!, filename: file.name));
      } else if (file.path != null) {
        request.files.add(await http.MultipartFile.fromPath('files', file.path!));
      }

      final response = await http.Response.fromStream(await request.send());
      print("Upload submission file: ${response.statusCode}");
    } catch (e) {
      print("Erreur upload submission file: $e");
    }
  }

  // 5. Cache local (SharedPreferences)
  Future<void> _saveToCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_assignments', json.encode(data));
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('cached_assignments')) {
      final data = json.decode(prefs.getString('cached_assignments')!);
      final List<dynamic> jsonList = data['data'];
      assignments.value = jsonList.map((item) => Assignment.fromJson(item)).toList();
      originalAssignments = assignments.toList();
    }
  }
}
