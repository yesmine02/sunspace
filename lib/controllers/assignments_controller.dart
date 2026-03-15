// ===============================================
// Contrôleur des Devoirs (AssignmentsController)
// CRUD complet vers Strapi v5
// ===============================================

import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../data/models/assignment.dart';
import 'auth_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssignmentsController extends GetxController {
  final String _baseUrl = 'http://193.111.250.244:3046/api/assignments';
  final AuthController _authController = Get.find<AuthController>();

  var assignments = <Assignment>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs; // Pour afficher les erreurs dans l'UI
  var originalAssignments = <Assignment>[]; // Pour la recherche locale
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAssignments();//Donc dès que la page s’ouvre →les données sont chargées automatiquement.
    
    // Écouter les changements de recherche
    ever(searchQuery, (_) => _filterAssignments());
  }

  // 1. Récupération des devoirs (GET)
  Future<void> fetchAssignments() async {
    try {
      isLoading(true);
      errorMessage.value = ''; // Reset error
      final token = await _authController.getToken();
      
      print("Fetching assignments from: $_baseUrl");
      
      final response = await http.get(
        Uri.parse('$_baseUrl?populate=*'),
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
          for (var item in jsonList) {
            try {
              loadedAssignments.add(Assignment.fromJson(item));
            } catch (e) {
              print("Erreur parsing assignment ${item['id']}: $e");
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
    if (searchQuery.value.isEmpty) { //On affiche tous les assignments.
      assignments.value = originalAssignments;
    } else {//Sinon on filtre.
      String query = searchQuery.value.toLowerCase();
      assignments.value = originalAssignments.where((assignment) {
        return assignment.title.toLowerCase().contains(query) || // On cherche dans le titre.
               (assignment.courseName?.toLowerCase().contains(query) ?? false);//ou dans le nom du cours.
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
