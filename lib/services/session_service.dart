import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../data/local/secure_storage.dart';
import '../data/providers/auth_provider.dart';
import '../data/repositories/auth_repository.dart';

/// Service GetX pour vérifier la session de l'utilisateur
class SessionService extends GetxService {
  
  /// Vérifie si l'utilisateur est connecté et si son token est valide côté serveur
  Future<bool> validateSession() async {
    try {
      // 1️⃣ Récupérer le token enregistré localement
      final token = await SecureStorage.getToken();

      // Si pas de token → session invalide
      if (token == null || token.isEmpty) return false;

      // 2️⃣ Créer le repository pour communiquer avec le serveur
      final repo = AuthRepository(authProvider: AuthProvider());

      // 3️⃣ Vérifier le token auprès du serveur pour obtenir l'utilisateur
      final user = await repo.fetchCurrentUser(token);

      // 4️⃣ Si le serveur renvoie un utilisateur → session valide
      if (user != null) {
        // Mettre à jour le AuthController avec les infos de l'utilisateur
        final auth = Get.find<AuthController>();
        auth.currentUser.value = user.toJson(); // Infos utilisateur
        auth.isLoggedIn.value = true;          // Connecté
        auth.token = token;                    // Enregistrer le token
        return true;                           // Session valide
      } else {
        // 5️⃣ Si le serveur ne renvoie rien → token invalide
        await SecureStorage.clearAll();        // Supprimer les données locales
        return false;                          // Session invalide
      }
    } catch (_) {
      // 6️⃣ En cas d'erreur réseau ou autre problème
      await SecureStorage.clearAll();          // Supprimer les données locales
      return false;                            // Session invalide
    }
  }
}
