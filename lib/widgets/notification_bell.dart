import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../routing/app_routes.dart';

class NotificationBell extends StatelessWidget {
  final Color iconColor;
  final double size;

  const NotificationBell({
    super.key,
    this.iconColor = const Color(0xFF1E293B),
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    final notifCtrl = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.NOTIFICATIONS),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 🔔 Icône clochette
            Icon(Icons.notifications_none_rounded, color: iconColor, size: size),

            // 🔴 Badge rouge avec le nombre (comme l'image)
            Obx(() {
              final count = notifCtrl.unreadCount;
              if (count == 0) return const SizedBox.shrink();

              // Texte affiché : "+1", "+2", "+9", "+99" max
              final label = count > 99 ? '+99' : '+$count';

              return Positioned(
                right: -10,
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    // Rose-rouge comme dans l'image de référence
                    color: const Color(0xFFE91E6B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E6B).withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
