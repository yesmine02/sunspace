import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/models/association_model.dart';
import '../data/local/secure_storage.dart';
import 'auth_controller.dart';

class AssociationsController extends GetxController {
  final RxList<Association> associations = <Association>[].obs;
  final RxBool isLoading = false.obs;
  
  final String apiUrl = 'http://193.111.250.244:3046/api/associations';

  @override
  void onInit() {
    super.onInit();
    loadAssociations();
  }

  Future<void> loadAssociations() async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token != null) {
        final response = await http.get(
          Uri.parse('$apiUrl?populate=*'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          final List<dynamic> data = body['data'] ?? [];
          associations.assignAll(data.map((item) => Association.fromJson(item)).toList());
        }
      } else {
        // Mock data if no token (for development)
        _loadMockData();
      }
    } catch (e) {
      print('Erreur loadAssociations: $e');
      _loadMockData();
    } finally {
      isLoading.value = false;
    }
  }

  void _loadMockData() {
    associations.assignAll([
      Association(
        id: 1,
        name: 'Test Association',
        email: 'Association@Association.com',
        budget: 68.0,
        isVerified: true,
        admin: AssociationAdmin(username: 'intern', email: 'intern@sunevit.tn'),
        members: [1],
      ),
    ]);
  }

  Future<bool> addMemberToAssociation(String associationDocId, int userId) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token == null) return false;

      // 1. On récupère l'association actuelle via son documentId
      final responseGet = await http.get(
        Uri.parse('$apiUrl/$associationDocId?populate=members'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (responseGet.statusCode == 200) {
        final body = jsonDecode(responseGet.body);
        final data = body['data'];
        
        // Extraire les IDs des membres actuels (Strapi v5 structure)
        List<int> memberIds = [];
        if (data != null && data['members'] != null) {
          for (var m in data['members']) {
            memberIds.add(m['id']);
          }
        }

        // 2. On ajoute le nouvel ID s'il n'est pas déjà présent
        if (!memberIds.contains(userId)) {
          memberIds.add(userId);
        }

        // 3. On met à jour l'association via son documentId
        final responsePut = await http.put(
          Uri.parse('$apiUrl/$associationDocId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'data': {
              'members': memberIds,
            }
          }),
        );

        if (responsePut.statusCode == 200) {
          await loadAssociations(); // Recharger les données locales
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erreur addMemberToAssociation: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createAssociation(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token == null) return false;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': data
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadAssociations(); // Rafraîchir la liste
        Get.snackbar(
          'Succès',
          'L\'association a été créée avec succès.',
          backgroundColor: Color(0xFFDCFCE7),
          colorText: Color(0xFF166534),
        );
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        print('Erreur Create: $errorBody');
        Get.snackbar(
          'Erreur',
          'Impossible de créer l\'association (Code: ${response.statusCode})',
          backgroundColor: Color(0xFFFEE2E2),
          colorText: Color(0xFF991B1B),
        );
        return false;
      }
    } catch (e) {
      print('Erreur createAssociation: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateAssociation(String documentId, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$apiUrl/$documentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': data
        }),
      );

      if (response.statusCode == 200) {
        await loadAssociations(); // Rafraîchir la liste
        Get.snackbar(
          'Succès',
          'L\'association a été mise à jour.',
          backgroundColor: Color(0xFFDCFCE7),
          colorText: Color(0xFF166534),
        );
        return true;
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de mettre à jour (Code: ${response.statusCode})',
          backgroundColor: Color(0xFFFEE2E2),
          colorText: Color(0xFF991B1B),
        );
        return false;
      }
    } catch (e) {
      print('Erreur updateAssociation: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteAssociation(String documentId) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$apiUrl/$documentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // En Strapi v5, DELETE retourne souvent 204 No Content
        await loadAssociations(); // Rafraîchir la liste
        Get.snackbar(
          'Succès',
          'L\'association a été supprimée.',
          backgroundColor: Color(0xFFDCFCE7),
          colorText: Color(0xFF166534),
        );
        return true;
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de supprimer (Code: ${response.statusCode})',
          backgroundColor: Color(0xFFFEE2E2),
          colorText: Color(0xFF991B1B),
        );
        return false;
      }
    } catch (e) {
      print('Erreur deleteAssociation: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
