import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/auth_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/associations_controller.dart';
import 'controllers/equipments_controller.dart';
import 'data/local/secure_storage.dart';
import 'services/session_service.dart';
import 'routing/app_pages.dart';
import 'theme.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 🌍 Format date
  await initializeDateFormatting('fr_FR', null);

  // 2. 🔐 Auth & Session
  Get.put(AuthController());
  final sessionService = Get.put(SessionService());
  final authController = Get.find<AuthController>();
  Get.put(NotificationController());
  Get.put(AssociationsController());
  Get.put(EquipmentsController());

  // --- DÉCONNEXION FORCÉE AU DÉMARRAGE (Demande de l'utilisateur) ---
  await SecureStorage.clearAll();
  
  // Vérifier la session avec un timeout de 3 secondes
  try {
    final valid = await sessionService.validateSession().timeout(
      const Duration(seconds: 3), 
      onTimeout: () => false
    );
    if (!valid) {
      authController.isLoggedIn.value = false;
    }
  } catch (e) {
    authController.isLoggedIn.value = false;
  }

  // 🚀 Lancement de l'application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Sunspace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}