//lib/pages/notifications/notifications_page.dart
//📋 afficher les notifications
//✅ marquer comme lues AUTOMATIQUEMENT dès l'entrée dans la page
//🕒 afficher la date de chaque notification
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/notification_controller.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationController controller = Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    // ✅ Appelé UNE SEULE FOIS dès l'entrée dans la page
    _loadAndMarkAllRead();
  }

  Future<void> _loadAndMarkAllRead() async {
    // ÉTAPE 1 : Marquer les notifications DÉJÀ en mémoire comme lues → badge = 0 IMMÉDIATEMENT
    controller.markAllAsRead();

    // ÉTAPE 2 : Charger les nouvelles depuis le serveur (peut prendre 1-2 sec)
    await controller.fetchNotifications();

    // ÉTAPE 3 : Marquer aussi les nouvelles notifications récupérées comme lues
    controller.markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune notification',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.notifications.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            final dateStr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(notification.date);
            final isUnread = !notification.read;

            IconData iconData = Icons.notifications_active;
            Color iconColor = Colors.blue;

            if (notification.type == 'Alerte') {
              iconData = Icons.warning_amber_rounded;
              iconColor = Colors.red;
            } else if (notification.type == 'Confirmation_réservation') {
              iconData = Icons.check_circle_outline_rounded;
              iconColor = Colors.green;
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                // Fond bleu clair = non lue | Blanc = lue
                color: isUnread ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUnread ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                  width: isUnread ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isUnread ? 0.06 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icône
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    // Contenu
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 15,
                                    color: isUnread
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              // Point bleu si non lue
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread
                                  ? const Color(0xFF334155)
                                  : Colors.grey[500],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
