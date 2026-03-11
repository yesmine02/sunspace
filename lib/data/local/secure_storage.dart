import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 🔐 Classe qui gère le stockage local des infos de connexion
/// (token + utilisateur) sur le téléphone
class SecureStorage {
  static const String _tokenKey = 'auth_token'; // Clé pour sauvegarder le token
  static const String _userKey = 'auth_user';   // Clé pour sauvegarder l'utilisateur

  /// 🔹 Récupérer le token enregistré
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// 🔹 Sauvegarder le token après login
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// 🔹 Supprimer le token (logout)
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// 🔹 Sauvegarder les infos utilisateur
  static Future<void> saveUser(dynamic user) async {
    final prefs = await SharedPreferences.getInstance();

    if (user != null) {
      if (user is String) {
        // Si déjà en format texte JSON
        await prefs.setString(_userKey, user);
      } else {
        // Sinon on transforme l'objet en JSON
        try {
          await prefs.setString(_userKey, jsonEncode(user));
        } catch (_) {}
      }
    }
  }
  
  /// 🔹 Récupérer les infos utilisateur
  static Future<dynamic> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString(_userKey);

    if (userStr != null) {
      try {
        return jsonDecode(userStr); 
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 🔹 Supprimer seulement les données de session (logout) sans effacer les données de l'application
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
