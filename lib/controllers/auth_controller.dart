import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../data/local/secure_storage.dart';

class AuthController extends GetxController {
  final String baseUrl = 'http://193.111.250.244:3046/api';

  var isLoggedIn = false.obs;
  var isLoading = false.obs;
  String? token;
  final currentUser = Rxn<Map<String, dynamic>>();

  // 🔹 REGISTER
  Future<bool> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/local/register');
    
    // On ajoute un suffixe au username pour garantir l'unicité côté serveur,
    // car l'utilisateur veut que la contrainte ne porte que sur l'email.
    final uniqueUsername = "${username.trim()}_${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}";

    final body = {
      'username': uniqueUsername,
      'email': email.trim(),
      'password': password,
    };

    isLoading.value = true;
    try {
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
          if (data['user'] != null) {
            currentUser.value = data['user'];
            await SecureStorage.saveUser(data['user']);
          }
        }

        Get.snackbar('Succès', 'Compte créé avec succès');
        return true;
      } else {
        String message = 'Échec de l\'enregistrement';
        bool emailExiste = false;

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
    final url = Uri.parse('$baseUrl/auth/local');
    final body = {
      'identifier': email.trim(),
      'password': password,
    };

    isLoading.value = true;
    try {
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
          if (data['user'] != null) {
            currentUser.value = data['user'];
            await SecureStorage.saveUser(data['user']);
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
