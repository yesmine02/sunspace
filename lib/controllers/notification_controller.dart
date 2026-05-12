//lib/controllers/notification_controller.dart
//(controller)👉 gère la logique des notifications
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/notification_item.dart';
import 'auth_controller.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationItem>[].obs; //Liste des notifications
  var isLoading = false.obs;//Indique si les notifications sont en cours de chargement
  Timer? _refreshTimer; // ⏱️ Timer pour le refresh automatique

//Compte combien de notifications ne sont pas lues
  int get unreadCount => notifications.where((n) => !n.read).length; 

  @override
  void onInit() {//Initialise le contrôleur
    super.onInit();
    // Premier chargement
    fetchNotifications();
    // 🔄 Refresh automatique toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final auth = Get.find<AuthController>();
      if (auth.isLoggedIn.value) {
        fetchNotifications();
      }
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel(); // Arrêter le timer quand le contrôleur est détruit
    super.onClose();
  }

//Charger les notifications (API)
  Future<void> fetchNotifications() async {
    final authController = Get.find<AuthController>();//Récupère le contrôleur d'authentification
    final jwt = await authController.getToken();
    final user = authController.currentUser.value;

    if (jwt == null || user == null) return;//Si pas de token ou d'utilisateur, on arrête

    isLoading.value = true;
    try {
      final url = Uri.parse('${authController.baseUrl}/notifications?filters[user][id][\$eq]=${user['id']}&sort=createdAt:desc');
      debugPrint('🔍 Fetch Notifications URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📦 Fetch Notifications Response: $data');
        if (data['data'] != null) {
          final List list = data['data'];
          debugPrint('📦 Fetch Notifications: Found ${list.length} items');
          notifications.value = list.map((json) => NotificationItem.fromJson(json)).toList();
        }
      } else {
        debugPrint('❌ Erreur fetchNotifications: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Exception fetchNotifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

//Ajoute une notification localement (utile pour le premier plan)
  void addNotification(String title, String body) {
    notifications.insert(0, NotificationItem(
      title: title,
      message: body,
      date: DateTime.now(),
      read: false,
    ));
    notifications.refresh();//met à jour la liste
  }

//Marque toutes les notifications comme lues
  void markAllAsRead() async {
    bool hasUnread = false;//Indique si il y a des notifications non lues
    for (var n in notifications) {
      if (!n.read) {//si la notification n'est pas lue
        n.read = true;//marque comme lue
        hasUnread = true;//il y a des notifications non lues
        if (n.documentId != null) {//si l'id de la notification est valide
          _updateServerReadStatus(n.documentId!);//met à jour le statut de la notification
        }
      }
    }
    if (hasUnread) {//si il y a des notifications non lues
      notifications.refresh();//met à jour la liste
    }
  }
//Marque une notification spécifique comme lue
  void markAsRead(int index) async {
    if (!notifications[index].read) {//si la notification n'est pas lue
      notifications[index].read = true;//marque comme lue
      notifications.refresh();//met à jour la liste
      final docId = notifications[index].documentId;//recupere l'id de la notification
      if (docId != null) {//si l'id de la notification est valide
        _updateServerReadStatus(docId);//met à jour le statut de la notification
      }
    }
  }
//Met à jour le statut de la notification sur le serveur
  Future<void> _updateServerReadStatus(String documentId) async {
    final authController = Get.find<AuthController>();
    final jwt = await authController.getToken();
    if (jwt == null) return;

    try {
      final url = Uri.parse('${authController.baseUrl}/notifications/$documentId');
      await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'read': true,
          }
        }),
      );
    } catch (e) {
      debugPrint('Erreur mise à jour notification: $e');
    }
  }

  /// 📤 Créer une notification pour un utilisateur spécifique dans Strapi
  Future<bool> sendNotification({
    required int targetUserId,
    String? targetDocumentId,
    required String title,
    required String message,
    String type = "Info",
    String? relatedType,
    dynamic relatedId,
    String? actionUrl,
  }) async {
    final authController = Get.find<AuthController>();
    final jwt = await authController.getToken();
    if (jwt == null) return false;

    try {
      final url = Uri.parse('${authController.baseUrl}/notifications');
      
      final Map<String, dynamic> data = {
        'type': type,
        'title': title,
        'message': message, 
        'read': false,
        'user': targetDocumentId ?? targetUserId, 
        'publishedAt': DateTime.now().toUtc().toIso8601String(),
      };

      if (relatedType != null) data['related_type'] = relatedType;
      if (relatedId != null) data['related_id'] = relatedId.toString();
      if (actionUrl != null) data['action_url'] = actionUrl;

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'data': data}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Notification envoyée à l\'utilisateur $targetUserId');
        return true;
      } else {
        debugPrint('❌ Échec envoi notification: ${response.statusCode}');
        debugPrint('Détails erreur Strapi: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception envoi notification: $e');
      return false;
    }
  }

  /// 📢 Notifier tous les administrateurs et gestionnaires (via Strapi uniquement)
  Future<void> notifyAdmins({
    required String title, 
    required String message,
    String type = 'Alerte',
  }) async {
    final authController = Get.find<AuthController>();
    final jwt = await authController.getToken();
    if (jwt == null) return;

    try {
      final url = Uri.parse('${authController.baseUrl}/users?populate=*');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (response.statusCode != 200) {
        print('❌ notifyAdmins - Erreur récupération users: ${response.statusCode}');
        return;
      }

      final List users = jsonDecode(response.body);
      int adminCount = 0;

      for (var user in users) {
        final role = user['role'];
        final roleName = (role is Map) ? (role['name'] ?? '') : (role?.toString() ?? '');
        
        final isAdmin = roleName.trim().toLowerCase() == 'admin' || 
                       roleName.trim().toLowerCase() == "gestionnaire d'espace" || 
                       roleName.trim().toLowerCase() == "administrator";
        
        if (!isAdmin) continue;
        
        adminCount++;
        debugPrint('🔔 Envoi notif à Admin: ${user['username']} (ID: ${user['id']})');

        // Sauvegarder dans la table notifications Strapi
        await sendNotification(
          targetUserId: user['id'],
          title: title,
          message: message,
          type: type,
        );
      }
      debugPrint('📢 notifyAdmins terminé. Administrateurs notifiés : $adminCount');
    } catch (e) {
      debugPrint('❌ Erreur notifyAdmins: $e');
    }
  }

  /// 🎓 Notifier tous les membres (Étudiants et Professionnels) via Strapi
  Future<void> notifyMembers({
    required String title, 
    required String message,
    String type = 'Info',
    String? relatedType,
    dynamic relatedId,
    String? actionUrl,
  }) async {
    debugPrint('📣 DEBUT notifyMembers : $title');
    final authController = Get.find<AuthController>();
    final jwt = await authController.getToken();
    if (jwt == null) {
      debugPrint('❌ notifyMembers : JWT non trouvé');
      return;
    }

    try {
      final url = Uri.parse('${authController.baseUrl}/users?populate=role');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('❌ notifyMembers - Erreur Strapi ${response.statusCode}: ${response.body}');
        return;
      }

      final List users = jsonDecode(response.body);
      int memberCount = 0;

      for (var user in users) {
        final role = user['role'];
        final roleName = (role is Map) ? (role['name'] ?? '') : (role?.toString() ?? '');
        final roleLower = roleName.trim().toLowerCase();
        
        final isMember = roleLower == 'student' || 
                         roleLower == 'étudiant' ||
                         roleLower == 'etudiant' ||
                         roleLower == 'authenticated' ||
                         roleLower == 'professionnel' ||
                         roleLower == 'professional';
        
        if (!isMember) continue;
        
        final userId = int.tryParse(user['id'].toString());
        if (userId == null) continue;

        memberCount++;
        await sendNotification(
          targetUserId: userId,
          targetDocumentId: user['documentId'],
          title: title,
          message: message,
          type: type,
          relatedType: relatedType,
          relatedId: relatedId,
          actionUrl: actionUrl,
        );
      }
      debugPrint('📢 notifyMembers terminé. Membres notifiés : $memberCount');
    } catch (e) {
      debugPrint('❌ Erreur notifyMembers: $e');
    }
  }
}
