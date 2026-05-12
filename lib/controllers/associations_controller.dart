import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/models/association_model.dart';
import '../data/local/secure_storage.dart';
import 'auth_controller.dart';
import 'notification_controller.dart';

class AssociationsController extends GetxController {
  final RxList<Association> associations = <Association>[].obs;
  final RxBool isLoading = false.obs;
  
  /// ID de l'association sélectionnée par l'utilisateur (si multi-association)
  final RxnInt selectedAssocId = RxnInt();

  /// Liste des associations liées à l'utilisateur actuel (Admin ou Membre)
  List<Association> get myAssociations {
    final auth = Get.find<AuthController>();
    final myId = int.tryParse(auth.currentUser.value?['id']?.toString() ?? '');
    if (myId == null) return [];
    
    return associations.where((a) {
      if (a.admin?.id == myId) return true;
      return (a.members ?? []).any((m) => (m is Map ? m['id'] : m) == myId);
    }).toList();
  }

  final String apiUrl = 'http://193.111.250.244:3046/api/associations';

  /// Vérifie si l'utilisateur actuel est l'admin d'au moins une association
  bool get isCurrentUserAssocAdmin {
    final auth = Get.find<AuthController>();
    final myId = auth.currentUser.value?['id'];
    if (myId == null) return false;
    return associations.any((a) => a.admin?.id == myId);
  }

  /// Vérifie si l'utilisateur actuel est membre d'au moins une association
  bool get isCurrentUserAssocMember {
    final auth = Get.find<AuthController>();
    final myId = auth.currentUser.value?['id'];
    if (myId == null) return false;
    return associations.any((a) {
      if (a.members == null) return false;
      return a.members!.any((m) {
        if (m is Map) return m['id'] == myId;
        return m == myId;
      });
    });
  }
//✅ On charge les associations au démarrage.
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

  Future<bool> addMemberToAssociation(String associationDocId, int userId, {String? newMemberUsername, String? associationName}) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();//✅ On récupère le token.

      if (token == null) return false;

      // 1. On récupère l'association actuelle via son documentId (avec admin ET membres)
      final responseGet = await http.get(
        Uri.parse('$apiUrl/$associationDocId?populate[0]=members&populate[1]=admin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('🔎 GET Association status: ${responseGet.statusCode}');
      if (responseGet.statusCode != 200) {
        debugPrint('❌ GET failed: ${responseGet.body}');
      }

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

        debugPrint('🔎 PUT Association status: ${responsePut.statusCode}');
        if (responsePut.statusCode != 200) {
          debugPrint('❌ PUT failed: ${responsePut.body}');
        }

        if (responsePut.statusCode == 200) {
          // 📢 Notifier l'admin de l'association
          try {
            final adminId = data?['admin']?['id'];
            final assocName = associationName ?? data?['name'] ?? 'votre association';
            final memberName = newMemberUsername ?? 'Un utilisateur';

            debugPrint('🔎 Admin data: ${data?['admin']}');
            debugPrint('🔎 Admin ID trouvé: $adminId');

            if (adminId != null) {
              final notifCtrl = Get.find<NotificationController>();
              notifCtrl.sendNotification(
                targetUserId: adminId,
                title: 'Nouveau membre ajouté',
                message: '$memberName a rejoint votre association : $assocName',
                type: 'Info',
              );
              debugPrint('✅ Notification envoyée à l\'admin $adminId');
            } else {
              debugPrint('⚠️ adminId est null, notification non envoyée');
            }
          } catch (e) {
            debugPrint('Erreur envoi notification nouveau membre: $e');
          }

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

  /// Retire un membre d'une association via son documentId
  Future<bool> removeMemberFromAssociation(String associationDocId, int userId) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      if (token == null) return false;

      // 1. Récupérer la liste actuelle des membres
      final responseGet = await http.get(
        Uri.parse('$apiUrl/$associationDocId?populate[0]=members'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (responseGet.statusCode != 200) {
        debugPrint('❌ GET failed (remove): ${responseGet.body}');
        return false;
      }

      final body = jsonDecode(responseGet.body);
      final data = body['data'];

      // 2. Filtrer l'ID à retirer
      List<int> memberIds = [];
      if (data != null && data['members'] != null) {
        for (var m in data['members']) {
          final id = m['id'];
          if (id != null && id != userId) memberIds.add(id);
        }
      }

      // 3. Mettre à jour l'association sans ce membre
      final responsePut = await http.put(
        Uri.parse('$apiUrl/$associationDocId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'data': {'members': memberIds}}),
      );

      if (responsePut.statusCode == 200) {
        await loadAssociations();
        return true;
      }
      debugPrint('❌ PUT failed (remove): ${responsePut.body}');
      return false;
    } catch (e) {
      debugPrint('Erreur removeMemberFromAssociation: $e');
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
