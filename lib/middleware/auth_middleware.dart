import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/session_service.dart';
import '../routing/app_routes.dart';

//Vérifie si l’utilisateur est connecté avant de lui donner accès à une page.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 0;

  /// 🔹 Vérifie la session avant d'accéder à une page protégée
  @override
  RouteSettings? redirect(String? route) {
    // Vérifie si AuthController est déjà initialisé
    if (Get.isRegistered<AuthController>()) {
      final authController = Get.find<AuthController>();

      // 🔹 Si l'utilisateur n'est pas localement connecté → LOGIN
      if (!authController.isLoggedIn.value) {
        return const RouteSettings(name: AppRoutes.LOGIN);
      }

      // 🔹 Vérification serveur avec SessionService
      if (Get.isRegistered<SessionService>()) {
        final sessionService = Get.find<SessionService>();

        // ⚠️ On ne peut pas attendre async dans redirect, donc on lance un check
        sessionService.validateSession().then((isValid) {
          if (!isValid) {
            // 🔹 Si session invalide → renvoyer au login
            Get.offAllNamed(AppRoutes.LOGIN);
          }
        });
      }

      // Tout est OK → continuer vers la page demandée
      return null;
    }

    // Si AuthController non initialisé → LOGIN
    return const RouteSettings(name: AppRoutes.LOGIN);
  }
}
