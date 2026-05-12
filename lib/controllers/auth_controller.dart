import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../data/local/secure_storage.dart';
import 'notification_controller.dart'; // 🔔 Pour rafraîchir les notifs après login
//C’est le cerveau de l’authentification Il gère :✅ login✅ register✅ logout✅ rôle
//✅ update profil✅ password✅ delete account
class AuthController extends GetxController {
  final String baseUrl = 'http://193.111.250.244:3046/api';

  var isLoggedIn = false.obs;
  var isLoading = false.obs;
  String? token;
  final currentUser = Rxn<Map<String, dynamic>>();
  var isFetchingRole = false.obs;

  // ─────────────────────────────────────────────────────────────────────────
  // 🔹 HELPERS - Rôle
  // ─────────────────────────────────────────────────────────────────────────

  /// Retourne le type du rôle en minuscules (ex: "admin", "authenticated", "enseignant")
  String get currentRoleType {
    final user = currentUser.value; // les infos de l'utilisateur connecté
    if (user == null) return '';// Si aucun utilisateur connecté retourner vide.
    final role = user['role'];// les infos du rôle
    if (role == null) return ''; //Si utilisateur n’a pas de rôle retourner vide.
    String roleType = '';// On initialise une variable pour stocker le type du rôle.
    if (role is Map) {
      roleType = (role['type'] ?? role['name'] ?? '').toString().toLowerCase();// On met en minuscule pour faciliter la comparaison.
    } else {
      roleType = role.toString().toLowerCase();// Si le rôle n’est pas un Map, on le convertit directement en texte et on met en minuscule.
    }
    // 🔍 Debug : affiche le rôle complet dans la console pour détecter le bon type
    debugPrint('🎭 ROLE DEBUG → type: "$roleType" | full role: $role');
    debugPrint('🎭 ROLE DEBUG → name: "$currentRoleName"');
    return roleType;
  }

  /// Retourne le nom affiché du rôle (ex: "Admin", "Authenticated")
  String get currentRoleName {
    final user = currentUser.value; //les infos de l’utilisateur connecté
    if (user == null) return ''; //Si aucun utilisateur connecté retourner vide.
    final role = user['role'];
    if (role == null) return ''; //Si utilisateur n’a pas de rôle retourner vide.
    if (role is Map) return (role['name'] ?? role['type'] ?? '').toString();
    return role.toString(); //Si rôle n’est pas Map on le transforme directement en texte.
  }
//✅ Admin
  bool get isAdmin => currentRoleType == 'admin' || currentRoleType == 'administrator';
// ✅enseignant
  bool get isInstructor => currentRoleType == 'enseignant' || currentRoleType == 'instructor';
// ✅etudiant
  bool get isStudent {
    final role = currentRoleType.toLowerCase();
    final name = currentRoleName.toLowerCase();
    final res = role.contains('student') || role.contains('etudiant') || role.contains('étudiant') ||
                name.contains('student') || name.contains('etudiant') || name.contains('étudiant');
    debugPrint('🎓 CHECK IS_STUDENT: $res (RoleType: $role, RoleName: $name)');
    return res;
  }
  // ✅ Professionnel
  bool get isProfessional {
    final role = currentRoleType.toLowerCase();
    final name = currentRoleName.toLowerCase();
    return role.contains('professionnel') || role.contains('professional') ||
           name.contains('professionnel') || name.contains('professional');
  }
  //✅ Association
  bool get isAssociation => currentRoleType == 'association' || currentRoleType == 'association_member';
  //✅ Gestionnaire d'espace
  bool get isSpaceManager =>
      currentRoleType == 'space_manager' ||
      currentRoleType == 'gestionnaire' ||
      currentRoleType == 'gestionnairedespace' ||
      currentRoleType == 'gestionnaire_espace' ||
      currentRoleType == 'gestionnaire d\'espace' ||
      currentRoleType.contains('gestionnaire');
  //✅ Utilisateur authentifié (utilisateur connecté normal.)
  bool get isAuthenticatedOnly => currentRoleType == 'authenticated';


  // 🔹 REGISTER
  //Envoie les données d’inscription au serveur.
  Future<bool> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/local/register');
    
    // On ajoute un suffixe au username pour garantir l'unicité côté serveur,
    // car l'utilisateur veut que la contrainte ne porte que sur l'email.
    final uniqueUsername = "${username.trim()}_${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}";
//Prépare le corps de la requête POST à envoyer au serveur.
    final body = {
      'username': uniqueUsername,
      'email': email.trim(),
      'password': password,
    };

    isLoading.value = true;
    try {
      //Envoie une requête POST au serveur.
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        String? jwt = data['jwt'];

        if (jwt != null) {
          await _saveToken(jwt);
          //Si le serveur renvoie les infos de l’utilisateur, on les enregistre en mémoire et localement.
          if (data['user'] != null) {
            currentUser.value = data['user'];
            await SecureStorage.saveUser(data['user']);
          }
          // Fetch the exact role from the server
          try {
            await _fetchAndUpdateRole(jwt);
          } catch (e) {
            debugPrint('⚠️ Alerte : Login réussi mais impossible de charger le rôle : $e');
          }
        }

        Get.snackbar('Succès', 'Compte créé avec succès');
        return true;
      } else {
        String message = 'Échec de l\'enregistrement';
        bool emailExiste = false; //On va vérifier si l’erreur est “email déjà utilisé”.

        try {
          final data = jsonDecode(response.body);
          if (data['error'] != null && data['error']['message'] != null) {
            message = data['error']['message'];

            if (message.toLowerCase().contains('email') &&
                message.toLowerCase().contains('taken')) {
              emailExiste = true;
            }
          }
        } catch (_) {}

        if (emailExiste) {
          Get.snackbar('Compte existant',
              'Cet email est déjà enregistré, veuillez vous connecter');
        } else {
          // On n'affiche l'erreur que si ce n'est pas lié au username (normalement réglé par le suffixe)
          Get.snackbar('Erreur', message);
        }

        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de se connecter au serveur: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 LOGIN
  Future<bool> login(String email, String password) async {
    //Prépare URL et body pour Strapi.
    final url = Uri.parse('$baseUrl/auth/local');
    final body = {
      'identifier': email.trim(),
      'password': password,
    };

    isLoading.value = true;
    try {
      //Requête POST login
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? jwt = data['jwt'];

        if (jwt != null) {
          await _saveToken(jwt);
          if (data['user'] != null) {  //si les infos utilisateur sont présente
            currentUser.value = data['user'];//met à jour l’utilisateur actuel dans l’application.
            await SecureStorage.saveUser(data['user']);
          }
          // Fetch the exact role from the server
          try {
            await _fetchAndUpdateRole(jwt);
          } catch (e) {
            debugPrint('⚠️ Alerte : Connexion réussie mais impossible de charger le rôle : $e');
          }
          // 🔔 Charger les notifications du serveur maintenant qu'on est connectés
          try {
            if (Get.isRegistered<NotificationController>()) {
              await Get.find<NotificationController>().fetchNotifications();
            }
          } catch (e) {
            debugPrint('⚠️ Impossible de charger les notifications: $e');
          }
        }

        Get.snackbar('Succès', 'Connexion réussie');
        return true;
      } else {
        Get.snackbar('Erreur', 'Email ou mot de passe incorrect');
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de se connecter au serveur: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveToken(String jwt) async {
    await SecureStorage.saveToken(jwt);
    token = jwt;
    isLoggedIn.value = true;
  }

//se lance en arrière-plan à la seconde où l'utilisateur se connecte (login ou register).
//➡️ Va au serveur
//➡️ Récupère rôle
//➡️ Met à jour utilisateur
//➡️ Sauvegarde
  Future<void> _fetchAndUpdateRole(String jwt) async {
    print('🔵 DEBUT _fetchAndUpdateRole');
    isFetchingRole.value = true;
    try {
      // On utilise populate=* pour être plus universel sur Strapi v5
      final url = Uri.parse('$baseUrl/users/me?populate=*');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // 🔍 Synchronisation avec le champ 'avatar'
        if (userData['avatar'] != null) {
          debugPrint('🖼️ Avatar chargé avec succès');
        }

        final merged = <String, dynamic>{
          ...?currentUser.value,
          ...userData,
        };
        currentUser.value = merged;
        await SecureStorage.saveUser(merged);
        print('✅ Compte chargé avec succès');
      } else {
        print('⚠️ ÉCHEC CHARGEMENT (Code ${response.statusCode})');
        print('🚫 RÉPONSE SERVEUR: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement du rôle: $e');
    } finally {
      isFetchingRole.value = false;
    }
  }

  /// 🔹 Expose publiquement le refresh du rôle (utilisable depuis SessionService)
  //recharger le rôle quand tu veux Exemple :au démarrage app ou après modification permissions
  Future<void> refreshRole() async {
    final jwt = await getToken();
    //Si l’utilisateur est connecté
    if (jwt != null) {
      try {
        await _fetchAndUpdateRole(jwt);
      } catch (e) {
        // Silently fail if refreshing role fails on startup
      }
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    token = null;
    isLoggedIn.value = false;
    currentUser.value = null;
    Get.offAllNamed('/login');
  }

  // 🔹 UPDATE PROFILE
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final user = currentUser.value;
    final jwt = await getToken();
    if (user == null || jwt == null) return false;

    final url = Uri.parse('$baseUrl/users/${user['id']}');

    isLoading.value = true;
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final updatedUser = jsonDecode(response.body);
        currentUser.value = updatedUser;
        await SecureStorage.saveUser(updatedUser);
        Get.snackbar('Succès', 'Profil mis à jour avec succès');
        return true;
      } else {
        Get.snackbar('Erreur', 'Échec de la mise à jour du profil');
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur serveur: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 UPLOAD PROFILE IMAGE (Strapi v5)
  Future<bool> uploadProfilePicture(dynamic imageFile) async {
    final jwt = await getToken();
    final user = currentUser.value;
    if (jwt == null || user == null) return false;

    isLoading.value = true;
    try {
      // 1. Envoyer le fichier au dossier /api/upload de Strapi
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.headers['Authorization'] = 'Bearer $jwt';
      
      // imageFile est un XFile (issu de image_picker)
      request.files.add(await http.MultipartFile.fromPath('files', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> uploadData = jsonDecode(response.body);
        final fileId = uploadData[0]['id'];

        // 2. Lier ce fichier à l'utilisateur (champ 'avatar' confirmé par les logs)
        final updateResponse = await http.put(
          Uri.parse('$baseUrl/users/${user['id']}'),
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "avatar": fileId // On utilise 'avatar'
          }),
        );

        if (updateResponse.statusCode == 200) {
          await refreshRole(); // Recharge l'utilisateur avec son nouveau lien image via fetchAndUpdateRole
          Get.snackbar('Succès', 'Photo de profil mise à jour', backgroundColor: Colors.green, colorText: Colors.white);
          return true;
        } else {
          debugPrint('❌ Update User Image Error: ${updateResponse.body}');
          Get.snackbar('Erreur Lien', 'ID: ${fileId} - Statut: ${updateResponse.statusCode}', backgroundColor: Colors.orange, colorText: Colors.white);
        }
      } else {
        debugPrint('❌ Upload Request Error (${response.statusCode}): ${response.body}');
        // Extraire l'erreur Strapi
        String strapiError = response.body;
        try {
          final errJson = jsonDecode(response.body);
          strapiError = errJson['error']?['message'] ?? response.body;
        } catch(_) {}
        
        Get.snackbar('Échec Upload', 'Statut ${response.statusCode}: $strapiError', backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 5));
      }
      return false;
    } catch (e) {
      debugPrint('❌ Upload Error Exception: $e');
      Get.snackbar('Erreur', 'Erreur lors du téléchargement: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 REMOVE PROFILE PICTURE
  Future<bool> removeProfilePicture() async {
    final jwt = await getToken();
    final user = currentUser.value;
    if (jwt == null || user == null) return false;

    isLoading.value = true;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user['id']}'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "avatar": null // Supprime le lien média
        }),
      );

      if (response.statusCode == 200) {
        await refreshRole();
        Get.snackbar('Succès', 'Photo de profil supprimée', backgroundColor: Colors.blueGrey, colorText: Colors.white);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Remove Photo Error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 CHANGE PASSWORD
  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    final jwt = await getToken();
    if (jwt == null) return false;

    final url = Uri.parse('$baseUrl/auth/change-password');
    final body = {
      'currentPassword': currentPassword,
      'password': newPassword,
      'passwordConfirmation': confirmPassword,
    };

    isLoading.value = true;
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['jwt'] != null) {
          await _saveToken(data['jwt']);
        }
        Get.snackbar('Succès', 'Mot de passe mis à jour avec succès', 
            backgroundColor: const Color(0xFF10B981), colorText: Colors.white);
        return true;
      } else {
        String errorMsg = 'Échec de la mise à jour';
        try {
          final data = jsonDecode(response.body);
          if (data['error'] != null && data['error']['message'] != null) {
            errorMsg = data['error']['message'];
          }
        } catch (_) {}
        Get.snackbar('Erreur', errorMsg, backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur serveur: $e', backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 DELETE ACCOUNT
  Future<bool> deleteAccount() async {
    final user = currentUser.value;
    final jwt = await getToken();
    if (user == null || jwt == null) return false;

    final url = Uri.parse('$baseUrl/users/${user['id']}');

    isLoading.value = true;
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        Get.snackbar('Succès', 'Votre compte a été supprimé');
        await logout();
        return true;
      } else {
        Get.snackbar('Erreur', 'Impossible de supprimer le compte');
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur serveur: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getToken() async {
    if (token != null) return token;
    token = await SecureStorage.getToken();
    return token;
  }
}
