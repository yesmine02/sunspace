import 'package:http/http.dart' as http;
import 'dart:convert';

/// Cette classe parle avec le SERVEUR pour récupérer les infos utilisateur
class AuthProvider {

  // Adresse de base de ton API backend
  final String baseUrl = 'http://193.111.250.244:3046/api';

  /// 🔹 Cette fonction demande au serveur : "Qui est l'utilisateur connecté ?"
  /// Elle utilise le TOKEN pour prouver que l'utilisateur est authentifié
  Future<dynamic> getCurrentUser(String token) async {

    // Création de l’URL complète → /users/me?populate=role
    final url = Uri.parse('$baseUrl/users/me?populate=role');

    // Envoi d'une requête GET au serveur avec le token dans le header
    final response = await http.get(
      url,
      headers: {
        // Le token est envoyé ici pour authentifier la requête
        'Authorization': 'Bearer $token',
      },
    );
    
    // Si le serveur répond "OK"
    if (response.statusCode == 200) {
      // On transforme la réponse JSON en objet Dart
      return jsonDecode(response.body);
    } else {
      // Sinon on déclenche une erreur
      throw Exception('Failed to load user: ${response.statusCode}');
    }
  }
}
