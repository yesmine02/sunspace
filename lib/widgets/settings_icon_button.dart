import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routing/app_routes.dart';

/// 🔹 Icône Paramètres (engrenage) — visible pour tous les rôles
/// À placer AVANT le NotificationBell dans les AppBar des pages
class SettingsIconButton extends StatelessWidget {
  final Color iconColor;
  final double size;

  const SettingsIconButton({
    super.key,
    this.iconColor = const Color(0xFF1E293B),
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.SETTINGS),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.settings_outlined,
          color: iconColor,
          size: size,
        ),
      ),
    );
  }
}
