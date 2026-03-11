import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class AuthRepository {
  // 🔹 Instance du provider qui fait les appels au serveur
  final AuthProvider authProvider;

  // 🔹 Constructeur, on doit fournir un AuthProvider
  AuthRepository({required this.authProvider});

  /// 🔹 Récupère l'utilisateur connecté depuis le serveur
  /// 🔹 Utilise le token pour authentifier la requête
  Future<User?> fetchCurrentUser(String token) async {
    try {
      // Appel au provider pour obtenir les données utilisateur
      final data = await authProvider.getCurrentUser(token);

      // Si les données sont présentes, on les convertit en objet User
      if (data != null) {
        return User.fromJson(data);
      }

      // Si pas de données, retourne null
      return null;
    } catch (e) {
      // Affiche l'erreur dans la console si quelque chose échoue
      debugPrint("Error fetching current user: $e");
      return null; // On retourne null pour indiquer qu'on n'a pas pu récupérer l'utilisateur
    }
  }
}
