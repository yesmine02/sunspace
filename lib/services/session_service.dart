import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart'; // 🔔 Refresh notifs au démarrage
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

        // # role  :On déclenche le rafraîchissement du rôle en tâche de fond 
        // pour être toujours à jour avec les permissions serveur
        auth.refreshRole();

        // 🔔 Charger les notifications dès que la session est restaurée
        // (l'utilisateur verra le badge correct dès l'ouverture de l'app)
        Future.microtask(() async {
          try {
            if (Get.isRegistered<NotificationController>()) {
              await Get.find<NotificationController>().fetchNotifications();
            }
          } catch (e) {
            // Erreur silencieuse - pas critique
          }
        });

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
