import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/auth_controller.dart';
import 'services/session_service.dart';
import 'routing/app_pages.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // Init AuthController
  Get.put(AuthController());

  // Init SessionService et vérifie token côté serveur
  final sessionService = Get.put(SessionService());
  final authController = Get.find<AuthController>();
  final valid = await sessionService.validateSession();
  if (!valid) {
    authController.isLoggedIn.value = false;
  }

  runApp(MyApp());
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
