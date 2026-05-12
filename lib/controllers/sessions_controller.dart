// ============================================
// Contrôleur des Sessions (SessionsController)
// Gère les sessions de formation (CRUD)
// ============================================

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/training_session.dart';
import '../data/local/secure_storage.dart';
import 'auth_controller.dart';
import 'notification_controller.dart';
import 'courses_controller.dart';
import 'spaces_controller.dart';
import 'booking_controller.dart';


class SessionsController extends GetxController {
  final RxList<TrainingSession> sessions = <TrainingSession>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  static const String _baseUrl = 'http://193.111.250.244:3046/api/training-sessions';
  static const String _storageKey = 'saved_sessions';

  @override
  void onInit() {
    super.onInit();
    loadSessions();
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<void> loadSessions() async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      if (token != null) {
        final response = await http.get(Uri.parse('$_baseUrl?populate=*&pagination[pageSize]=100'), headers: _headers(token));
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final List<dynamic> data = responseData['data'] ?? [];
          sessions.value = data.map((item) => TrainingSession.fromJson(item)).toList();
          await _saveToLocal();
        } else {
          await _loadFromLocal();
        }
      }
    } catch (e) {
      await _loadFromLocal();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSession(TrainingSession session, dynamic courseId) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      int? instructorId = auth.currentUser.value?['id'];
      if (token != null) {
        final bodyData = session.toStrapiJson(instructorId, courseId);
        final response = await http.post(Uri.parse(_baseUrl), headers: _headers(token), body: jsonEncode(bodyData));
        if (response.statusCode == 200 || response.statusCode == 201) {
          await loadSessions();
          Get.back();
          _showSnackbar('Succès', 'Session créée', Colors.green);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSessionWithReservation({required TrainingSession session, required dynamic courseId, required String spaceId, required double totalAmount}) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      final user = auth.currentUser.value;
      if (token == null || user == null) return;

      final bodyData = session.toStrapiJson(user['id'], courseId);
      final sessionResponse = await http.post(Uri.parse(_baseUrl), headers: _headers(token), body: jsonEncode(bodyData));

      if (sessionResponse.statusCode == 200 || sessionResponse.statusCode == 201) {
        const reservationUrl = 'http://193.111.250.244:3046/api/reservations';
        final resBody = {
          "data": {
            "start_datetime": session.startDate?.toUtc().toIso8601String(),
            "end_datetime": session.endDate?.toUtc().toIso8601String(),
            "mystatus": "En_attente",
            "attendees": session.maxParticipants,
            "purpose": "Session de cours : ${session.title}",
            "payment_status": "En_attente",
            "payment_method": "Carte_en_ligne",
            "total_amount": totalAmount,
            "turnstile_verified": true,
            "organizer_name": user['username'] ?? "Enseignant",
            "space": spaceId,
          }
        };
        await http.post(Uri.parse(reservationUrl), headers: _headers(token), body: jsonEncode(resBody));
        await loadSessions();
        Get.back();
        _showSnackbar('Succès', 'Session et réservation créées', Colors.green);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSession(TrainingSession session, dynamic courseId, {String? oldSessionTitle}) async {
    if (session.documentId == null) return;
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      final user = auth.currentUser.value;
      if (token != null) {
        if (oldSessionTitle != null && user != null) {
          await _deleteLinkedReservation(token: token, username: user['username'] ?? '', sessionTitle: oldSessionTitle);
        }
        final bodyData = session.toStrapiJson(user?['id'], courseId);
        final response = await http.put(Uri.parse('$_baseUrl/${session.documentId}'), headers: _headers(token), body: jsonEncode(bodyData));
        if (response.statusCode == 200) {
          await loadSessions();
          if (Get.isRegistered<BookingController>()) Get.find<BookingController>().fetchMyReservations();
          Get.back();
          _showSnackbar('Succès', 'Session mise à jour', Colors.blue);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSessionWithReservation({required TrainingSession session, required dynamic courseId, required String oldSessionTitle, required String spaceId, required double totalAmount}) async {
    if (session.documentId == null) return;
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      final user = auth.currentUser.value;
      if (token == null || user == null) return;

      final bodyData = session.toStrapiJson(user['id'], courseId);
      final sessionResponse = await http.put(Uri.parse('$_baseUrl/${session.documentId}'), headers: _headers(token), body: jsonEncode(bodyData));

      if (sessionResponse.statusCode == 200) {
        await _deleteLinkedReservation(token: token, username: user['username'] ?? '', sessionTitle: oldSessionTitle);
        const reservationUrl = 'http://193.111.250.244:3046/api/reservations';
        final resBody = {
          'data': {
            'start_datetime': session.startDate?.toUtc().toIso8601String(),
            'end_datetime': session.endDate?.toUtc().toIso8601String(),
            'mystatus': 'En_attente',
            'attendees': session.maxParticipants,
            'purpose': 'Session de cours : ${session.title}',
            'total_amount': totalAmount,
            'organizer_name': user['username'] ?? 'Enseignant',
            'space': spaceId,
          }
        };
        await http.post(Uri.parse(reservationUrl), headers: _headers(token), body: jsonEncode(resBody));
        await loadSessions();
        if (Get.isRegistered<BookingController>()) Get.find<BookingController>().fetchMyReservations();
        Get.back();
        _showSnackbar('Succès', 'Session mise à jour avec réservation', Colors.blue);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSession(String docId, {bool force = false}) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      final user = auth.currentUser.value;

      if (token != null) {
        final session = sessions.firstWhereOrNull((s) => s.documentId == docId);
        if (session == null) return;

        bool isConfirmed = false;

        // 1. Chercher le statut de la réservation liée (si présentiel/hybride)
        if (session.type != SessionType.enLigne) {
          isConfirmed = await _checkIfConfirmed(
            token: token, 
            username: user?['username'] ?? '', 
            session: session
          );
        }

        // --- BLOCAGE SI CONFIRMÉE ---
        if (isConfirmed && !force) {
          _showSnackbar(
            'Action impossible', 
            'Cette formation est déjà confirmée par l\'Admin. Contactez l\'administration pour toute annulation.', 
            Colors.red
          );
          return;
        }

        // --- SUPPRESSION DIRECTE ---
        if (session.type != SessionType.enLigne) {
          await _deleteLinkedReservation(
            token: token, 
            username: user?['username'] ?? '', 
            sessionTitle: session.title
          );
        }

        final response = await http.delete(
          Uri.parse('$_baseUrl/$docId'), 
          headers: _headers(token)
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          await loadSessions();
          if (Get.isRegistered<BookingController>()) {
            Get.find<BookingController>().fetchMyReservations();
          }
          _showSnackbar('Succès', 'Formation supprimée', Colors.orange);
        }
      }
    } catch (e) {
      _showSnackbar('Erreur', 'Échec de la suppression', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _checkIfConfirmed({required String token, required String username, required TrainingSession session}) async {
    try {
      if (session.startDate == null) return false;
      const baseUrl = 'http://193.111.250.244:3046/api/reservations';
      
      final String sTitle = session.title.trim().toLowerCase();
      final DateTime sDate = session.startDate!.toLocal();
      final String sDateStr = sDate.toIso8601String().split('T')[0];

      debugPrint('🚀 [ANALYS] Vérif profonde pour: "$sTitle" le $sDateStr à ${sDate.hour}:${sDate.minute}');

      // Étape 1: Recherche par UTILISATEUR + DATE (Le plus sûr pour Siwar)
      final encodedUser = Uri.encodeComponent(username.trim());
      final urlUser = '$baseUrl?filters[organizer_name][\$eqi]=$encodedUser&pagination[pageSize]=100';
      
      final responseUser = await http.get(Uri.parse(urlUser), headers: _headers(token));
      if (responseUser.statusCode == 200) {
        final List items = jsonDecode(responseUser.body)['data'] ?? [];
        for (var item in items) {
          final Map<String, dynamic> attr = (item['attributes'] != null) ? item['attributes'] : item;
          
          final String resDateStr = (attr['start_datetime'] ?? attr['start_date'] ?? '').toString();
          if (resDateStr.isEmpty) continue;

          try {
            final DateTime rDate = DateTime.parse(resDateStr).toLocal();
            
            // 1. Est-ce le même jour et la même HEURE ?
            final bool sameTime = rDate.year == sDate.year && 
                                 rDate.month == sDate.month && 
                                 rDate.day == sDate.day &&
                                 rDate.hour == sDate.hour;

            if (sameTime) {
              final String status = (attr['mystatus']?.toString() ?? '').toLowerCase();
              debugPrint('🎯 [ANALYS] Match trouvé par Heure/Utilisateur! Statut: $status');
              if (status.contains('confirm') || status.contains('accept')) return true;
            }
          } catch (_) {}
        }
      }

      // Étape 2: Recherche par TITRE (Si l'étape 1 n'a pas suffi)
      final encodedTitle = Uri.encodeComponent(session.title);
      final urlTitle = '$baseUrl?filters[purpose][\$contains]=$encodedTitle&pagination[pageSize]=100';
      final respTitle = await http.get(Uri.parse(urlTitle), headers: _headers(token));
      
      if (respTitle.statusCode == 200) {
        final List items = jsonDecode(respTitle.body)['data'] ?? [];
        for (var item in items) {
          final Map<String, dynamic> attr = (item['attributes'] != null) ? item['attributes'] : item;
          final String status = (attr['mystatus']?.toString() ?? '').toLowerCase();
          
          if (status.contains('confirm') || status.contains('accept')) {
             final String resDateStr = (attr['start_datetime'] ?? attr['start_date'] ?? '').toString();
             try {
               final rDate = DateTime.parse(resDateStr).toLocal();
               if (rDate.year == sDate.year && rDate.month == sDate.month && rDate.day == sDate.day) {
                 return true;
               }
             } catch (_) {}
          }
        }
      }

    } catch (e) { 
      debugPrint('❌ [ANALYS] Erreur critique: $e'); 
    }
    return false;
  }

  Future<void> deleteLinkedReservationOnly({required String token, required String username, required String sessionTitle}) async {
    return _deleteLinkedReservation(token: token, username: username, sessionTitle: sessionTitle);
  }

  Future<void> _deleteLinkedReservation({required String token, required String username, required String sessionTitle}) async {
    try {
      const reservationBaseUrl = 'http://193.111.250.244:3046/api/reservations';
      final encodedName = Uri.encodeComponent(username);
      final purposes = ['Session de cours : $sessionTitle', 'Réservation via App'];
      for (final p in purposes) {
        final encodedPurpose = Uri.encodeComponent(p);
        final searchUrl = '$reservationBaseUrl?filters[organizer_name][\$eq]=$encodedName&filters[purpose][\$eq]=$encodedPurpose&pagination[pageSize]=100';
        final searchRes = await http.get(Uri.parse(searchUrl), headers: _headers(token));
        if (searchRes.statusCode != 200) continue;
        final List items = jsonDecode(searchRes.body)['data'] ?? [];
        if (items.isNotEmpty) {
          await Future.wait(items.map((item) async {
            final resDocId = item['documentId']?.toString();
            if (resDocId != null) await http.delete(Uri.parse('$reservationBaseUrl/$resDocId'), headers: _headers(token));
          }));
        }
      }
    } catch (e) { debugPrint('Erreur suppression: $e'); }
  }

  Future<void> enrollInSession(String sessionDocId) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      int? userId = auth.currentUser.value?['id'];
      if (token != null && userId != null) {
        
        // 1. Vérification de la capacité maximale
        final session = sessions.firstWhereOrNull((s) => s.documentId == sessionDocId);
        if (session != null) {
          if (session.currentParticipants >= session.maxParticipants) {
            _showSnackbar('Complet', 'Cette formation est déjà complète (${session.maxParticipants}/${session.maxParticipants}).', Colors.orange);
            return;
          }
          
          // 2. Vérification des conflits d'horaires (Chevauchement)
          if (session.startDate != null && session.endDate != null) {
            final DateTime start = session.startDate!;
            final DateTime end = session.endDate!;
            
            final conflict = sessions.firstWhereOrNull((s) {
              // Vérifier si l'utilisateur est déjà inscrit à cette autre session
              bool isEnrolled = s.attendeeIds.contains(userId);
              if (!isEnrolled) return false;
              
              if (s.startDate == null || s.endDate == null) return false;
              
              // Algorithme de chevauchement : (Début1 < Fin2) ET (Fin1 > Début2)
              return start.isBefore(s.endDate!) && end.isAfter(s.startDate!);
            });

            if (conflict != null) {
              _showSnackbar(
                'Conflit d\'horaire', 
                'Vous êtes déjà inscrit à la session "${conflict.title}" sur ce créneau.', 
                Colors.red
              );
              return;
            }
          }
        }

        final response = await http.put(
          Uri.parse('$_baseUrl/$sessionDocId'), 
          headers: _headers(token), 
          body: jsonEncode({
            'data': {
              'attendees': {
                'connect': [userId]
              }
            }
          })
        );
        
        if (response.statusCode == 200) {
          await loadSessions();
          _showSnackbar('Succès', 'Votre inscription a été validée', Colors.green);
        } else {
          _showSnackbar('Erreur', 'Impossible de s\'inscrire pour le moment', Colors.red);
        }
      }
    } finally { isLoading.value = false; }
  }

  Future<void> unenrollFromSession(String sessionDocId) async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      String? token = auth.token ?? await SecureStorage.getToken();
      int? userId = auth.currentUser.value?['id'];
      if (token != null && userId != null) {
        final response = await http.put(Uri.parse('$_baseUrl/$sessionDocId'), headers: _headers(token), body: jsonEncode({'data': {'attendees': {'disconnect': [userId]}}}));
        if (response.statusCode == 200) {
          await loadSessions();
          _showSnackbar('Succès', 'Désinscription validée', Colors.orange);
        }
      }
    } finally { isLoading.value = false; }
  }

  void updateSearch(String query) => searchQuery.value = query;

  bool isSessionOverlapping({required int instructorId, required DateTime start, required DateTime end, required bool isAssociation, String? excludeDocumentId}) {
    for (final s in sessions) {
      if (s.instructorId.toString() != instructorId.toString()) continue;
      if (excludeDocumentId != null && s.documentId == excludeDocumentId) continue;
      if (s.startDate == null || s.endDate == null) continue;
      final bool sIsAssociation = (s.courseId == null || s.courseId.toString() == "null");
      if (isAssociation != sIsAssociation) continue;
      if (start.isBefore(s.endDate!) && end.isAfter(s.startDate!)) return true;
    }
    return false;
  }

  List<TrainingSession> get filteredSessions {
    final userId = Get.find<AuthController>().currentUser.value?['id'];
    List<TrainingSession> available = sessions.where((s) {
      if (userId == null) return true;
      return !s.attendeeIds.contains(userId);
    }).toList();
    if (searchQuery.isEmpty) return available;
    return available.where((s) => s.title.toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
  }

  void _showSnackbar(String title, String msg, Color color) {
    Get.snackbar(title, msg, backgroundColor: color, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_storageKey);
    if (cached != null) sessions.value = (jsonDecode(cached) as List).map((item) => TrainingSession.fromJson(item)).toList();
  }
}
