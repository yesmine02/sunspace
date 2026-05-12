import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../data/models/user.dart';
import '../data/local/secure_storage.dart';
import 'auth_controller.dart';

class UsersController extends GetxController {
  final RxList<User> users = <User>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  
  final String apiUrl = 'http://193.111.250.244:3046/api/users?populate=*';
  static const String _storageKey = 'saved_users';

  /// Mapping dynamique des noms de rôles vers leurs IDs
  final RxMap<String, int> roleMapping = <String, int>{
    'Admin': 3, // Valeur par défaut probable
    'Authenticated': 1,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  /// 🔹 Extrait les IDs de rôles depuis les utilisateurs chargés
  void _updateRoleMapping() {
    for (var user in users) {
      if (user.role is Map && user.role['id'] != null) {
        final name = user.roleName;
        final id = user.role['id'] as int;
        if (name.isNotEmpty) {
          roleMapping[name] = id;
        }
      }
    }
    debugPrint('🎭 Role Mapping updated: $roleMapping');
  }

  /// 🔹 CHARGER depuis le serveur (Rétablissement de la connexion pour Users)
  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      try {
        final auth = Get.find<AuthController>();
        String? token = auth.token ?? await SecureStorage.getToken();

        if (token != null) {
          final response = await http.get(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            try {
              File('c:\\Dev_mobile\\sunspace\\users.json').writeAsStringSync(response.body);
            } catch(e) {}
            final List<dynamic> list = jsonDecode(response.body);
            
            try {
              final f = await SharedPreferences.getInstance();
              await f.setString('debug_users_dump', response.body);
            } catch(e){}

            users.assignAll(list.map((item) => User.fromJson(item)).toList());
            _updateRoleMapping();
            
            // Sauvegarde en cache local
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_storageKey, response.body);
            return;
          }
        }
      } catch (e) {
        print('Erreur réseau utilisateurs: $e');
      }
      
      // Fallback cache local si le serveur ne répond pas
      final prefs = await SharedPreferences.getInstance();
      final String? cached = prefs.getString(_storageKey);
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        users.assignAll(decoded.map((item) => User.fromJson(item)).toList());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  List<User> get filteredUsers {
    if (searchQuery.value.isEmpty) return users;
    return users.where((user) {
      final usernameMatches = (user.username ?? '').toLowerCase().contains(searchQuery.value.toLowerCase());
      final emailMatches = (user.email ?? '').toLowerCase().contains(searchQuery.value.toLowerCase());
      return usernameMatches || emailMatches;
    }).toList();
  }

  void updateSearch(String query) => searchQuery.value = query;

  Future<void> addUser(User user, String password) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token == null) throw Exception("Non authentifié");

      final response = await http.post(
        Uri.parse('http://193.111.250.244:3046/api/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': user.username,
          'email': user.email,
          'password': password,
          'confirmed': user.confirmed,
          'blocked': user.blocked,
          'role': roleMapping[user.roleName] ?? (user.role is Map ? user.role['id'] : 1),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadUsers(); // Recharger depuis le serveur
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? "Erreur ${response.statusCode}");
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUser(User user, {String? password}) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token == null) return;

      final url = 'http://193.111.250.244:3046/api/users/${user.id}';
      
      // Préparation du body
      final Map<String, dynamic> body = {
        'username': user.username,
        'email': user.email,
        'confirmed': user.confirmed,
        'blocked': user.blocked,
      };

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      // Gestion du rôle : On utilise l'ID mappé si disponible, sinon l'ID actuel
      final int? roleId = roleMapping[user.roleName] ?? (user.role is Map ? user.role['id'] : null);
      if (roleId != null) {
        body['role'] = roleId;
      } else {
        // Fallback sur le nom si on n'a vraiment pas d'ID (peu probable avec loadUsers)
        body['role'] = user.roleName;
      }

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        await loadUsers();
        Get.snackbar('Succès', 'Utilisateur mis à jour sur le serveur');
      } else {
        Get.snackbar('Erreur', 'Échec de la mise à jour (Code: ${response.statusCode})');
      }
    } catch (e) {
      print('Erreur updateUser: $e');
      Get.snackbar('Erreur', 'Erreur de connexion au serveur');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token != null) {
        final url = 'http://193.111.250.244:3046/api/users/$id';
        
        final response = await http.delete(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          users.removeWhere((u) => u.id == id);
          saveUsers();
          Get.snackbar(
            'Succès',
            'L\'utilisateur a été supprimé avec succès.',
            backgroundColor: Color(0xFFDCFCE7),
            colorText: Color(0xFF166534),
          );
        } else {
          Get.snackbar(
            'Erreur',
            'Impossible de supprimer l\'utilisateur (Code: ${response.statusCode})',
            backgroundColor: Color(0xFFFEE2E2),
            colorText: Color(0xFF991B1B),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la suppression: $e');
    }
  }
}
