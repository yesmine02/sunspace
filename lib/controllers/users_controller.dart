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

  @override
  void onInit() {
    super.onInit();
    loadUsers();
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

  Future<void> addUser(User user) async {
    // Vérifier si l'email existe déjà dans la liste actuelle
    final bool emailExists = users.any(
      (u) => u.email?.toLowerCase() == user.email?.toLowerCase()
    );

    if (emailExists) {
      throw Exception("L'adresse email '${user.email}' est déjà utilisée.");
    }

    try {
      users.add(user);
      await saveUsers();
    } catch (e) {
      debugPrint("Error adding user: $e");
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();

      if (token != null) {
        // Dans Strapi, la suppression d'un utilisateur se fait généralement sur /api/users/:id
        // L'URL de base est http://193.111.250.244:3046/api/users
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
            'Le membre a été retiré avec succès.',
            backgroundColor: Color(0xFFDCFCE7),
            colorText: Color(0xFF166534),
          );
        } else {
          Get.snackbar(
            'Erreur',
            'Impossible de retirer le membre du serveur (Code: ${response.statusCode})',
            backgroundColor: Color(0xFFFEE2E2),
            colorText: Color(0xFF991B1B),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de la connexion au serveur.',
        backgroundColor: Color(0xFFFEE2E2),
        colorText: Color(0xFF991B1B),
      );
    }
  }

  void updateUser(User user) {
    int index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      users[index] = user;
      saveUsers();
    }
  }
}
