// ============================================
// Contrôleur de Réservation (BookingController)
// Gère la logique de réservation d'espaces
// ============================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/auth_controller.dart';
import '../data/models/space.dart';
import '../data/models/reservation.dart';

class BookingController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  static const String _baseUrl = 'http://193.111.250.244:3046/api/reservations';

  // États réactifs
  final RxList<Reservation> reservations = <Reservation>[].obs;
  final RxString selectedResFilter = 'Toutes'.obs; // 'Toutes', 'À venir', 'Passées'
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxList<String> selectedServices = <String>[].obs;//✅ Liste des services sélectionnés.
  
  // États spécialisés Checkout Étudiant
  final RxBool isMonthly = true.obs;
  final RxInt checkoutStep = 1.obs; //Étape actuelle du processus de paiement.
  
  // Controllers pour le formulaire de paiement
  final cardNameController = TextEditingController();
  final cardNumberController = TextEditingController();
  final cardExpiryController = TextEditingController();
  final cardCvcController = TextEditingController();
//supprime les champs de texte quand on n’en a plus besoin
  @override
  void onClose() {
    cardNameController.dispose();
    cardNumberController.dispose();
    cardExpiryController.dispose();
    cardCvcController.dispose();
    super.onClose();
  }
//✅ Vérifie que les champs de paiement sont remplis.
  bool validatePayment() {
    if (cardNameController.text.isEmpty ||
        cardNumberController.text.isEmpty ||
        cardExpiryController.text.isEmpty ||
        cardCvcController.text.isEmpty) {
      Get.snackbar(
        'Erreur', 
        'Veuillez remplir tous les champs de paiement.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    
    // Validation du numéro de carte (16 chiffres + espaces = 19 caractères normalement)
    if (cardNumberController.text.replaceAll(' ', '').length != 16) {
      Get.snackbar('Erreur', 'Numéro de carte invalide (16 chiffres requis).', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    return true;
  }

  // Liste des réservations filtrées
  List<Reservation> get filteredReservations {
    final now = DateTime.now();
    List<Reservation> list = List.from(reservations);

    // Filtre de Statut / Chronologique
    if (selectedResFilter.value == 'À venir') {
      list = list.where((r) => r.startDateTime.isAfter(now)).toList();
    } else if (selectedResFilter.value == 'Passées') {
      list = list.where((r) => r.startDateTime.isBefore(now)).toList();
    } else if (selectedResFilter.value == 'En attente') {
      list = list.where((r) => r.status == ReservationStatus.enAttente).toList();
    } else if (selectedResFilter.value == 'Confirmées') {
      list = list.where((r) => r.status == ReservationStatus.confirmee).toList();
    }

    // Filtre de Recherche (Espace ou Utilisateur)
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list.where((r) {
        final spaceMatch = (r.spaceName ?? '').toLowerCase().contains(query);
        final userMatch = (r.user?.username ?? '').toLowerCase().contains(query);
        return spaceMatch || userMatch;
      }).toList();
    }

    return list;
  }

  // Comptages pour les filtres
  int get upcomingCount => reservations.where((r) => r.startDateTime.isAfter(DateTime.now())).length;
  int get pastCount => reservations.where((r) => r.startDateTime.isBefore(DateTime.now())).length;

  void updateResFilter(String filter) {
    selectedResFilter.value = filter;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  
  // Dates par défaut : maintenant + 1h -> maintenant + 2h (1h de durée)
  final Rx<DateTime> startDateTime = DateTime.now().add(const Duration(hours: 1)).obs;
  final Rx<DateTime> endDateTime = DateTime.now().add(const Duration(hours: 2)).obs;
  
  final RxDouble totalAmount = 0.0.obs;

  // Services disponibles et leur coût
  final Map<String, double> servicesCatalog = {
    'Café illimité': 5.0,
    'Projecteur': 15.0,
    'Microphone': 10.0,
    'Imprimante pro': 8.0,
  };

  // Bascule un service (ajout/retrait)
  void toggleService(String serviceName, double hourlyPrice, double monthlyPrice) {
    if (selectedServices.contains(serviceName)) {
      selectedServices.remove(serviceName);
    } else {
      selectedServices.add(serviceName);
    }
    calculateTotal(hourlyPrice: hourlyPrice, monthlyPrice: monthlyPrice);
  }

  // Met à jour les dates
  void updateDates(DateTime start, DateTime end, double hourlyPrice, double monthlyPrice) {
    startDateTime.value = start;
    endDateTime.value = end;
    calculateTotal(hourlyPrice: hourlyPrice, monthlyPrice: monthlyPrice);
  }

  // Calcule le montant total
  void calculateTotal({required double hourlyPrice, required double monthlyPrice}) {
    double basePrice = 0.0;
    
    if (isMonthly.value) {
      basePrice = monthlyPrice;
    } else {
      // Durée en heures (minimum 1h pour ponctuelle)
      final difference = endDateTime.value.difference(startDateTime.value);
      double hours = difference.inMinutes / 60.0;
      if (hours < 1.0) hours = 1.0;
      basePrice = hours * hourlyPrice;
    }
    
    // Ajout du coût des services sélectionnés
    double servicesCost = 0.0;
    for (var service in selectedServices) {
      servicesCost += servicesCatalog[service] ?? 0.0;
    }

    totalAmount.value = basePrice + servicesCost;
  }

  // 🔹 CRÉATION DE LA RÉSERVATION (POST)
  Future<void> createReservation(Space space) async {
    if (!validatePayment()) return;
    
    isLoading.value = true;
    final client = http.Client();

    try {
      final token = await _authController.getToken();
      final user = _authController.currentUser.value;
      
      if (token == null || user == null) {
        Get.snackbar('Erreur', 'Vous devez être connecté.', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final url = Uri.parse(_baseUrl);

      // Préparation du body JSON selon le format demandé
      final Map<String, dynamic> requestBody = {
        "data": {
          "start_datetime": startDateTime.value.toUtc().toIso8601String(),
          "end_datetime": endDateTime.value.toUtc().toIso8601String(),
          "mystatus": "En_attente",
          "purpose": "Réservation professionnelle via App",
          "payment_status": "En_attente",
          "payment_method": "Carte_en_ligne",
          "total_amount": totalAmount.value,
          "notes": "Services inclus: ${selectedServices.join(', ')}",
          
          // Nouveaux champs requis par le serveur
          "organizer_name": user['username'] ?? "Étudiant",
          "organizer_phone": user['phone'] ?? "Non spécifié",
          
          // Relations (Strapi v5 documentId ou ID numérique)
          "user": user['documentId'] ?? user['id'], 
          "space": space.documentId ?? space.id,
        }
      };

      print("=== RÉSERVATION (POST) ===");
      print("URL: $url");
      print("Body: ${jsonEncode(requestBody)}");

      final response = await client.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Succès', 
          'Votre réservation est confirmée !',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Get.back(); // Retour à la liste
      } else {
        print("Erreur réservation: ${response.body}");
        Get.snackbar('Erreur', 'Échec de la réservation (${response.statusCode})', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print("Exception réservation: $e");
      Get.snackbar('Erreur', 'Problème de connexion: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      client.close();
      isLoading.value = false;
    }
  }

  // 🔹 CHARGEMENT DE TOUTES LES RÉSERVATIONS (GET) - Pour Admin
  Future<void> fetchAllReservations() async {
    isLoading.value = true;
    final client = http.Client();
    try {
      final token = await _authController.getToken();
      if (token == null) return;

      // Simplification maximale pour trouver la source du 400
      // Parfois le 'sort' ou le double populate pose souci sur certaines conf Strapi
      final url = Uri.parse('$_baseUrl?populate=*');

      final response = await client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("=== ALL RESERVATIONS ===");
      print("URL: $url");
      print("Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('data')) {
          final List<dynamic> list = data['data'];
          reservations.assignAll(list.map((item) => Reservation.fromJson(item)).toList());
        }
      } else {
        print("Erreur body: ${response.body}");
      }
    } catch (e) {
      print("Erreur fetch all reservations: $e");
    } finally {
      client.close();
      isLoading.value = false;
    }
  }

  // 🔹 MISE À JOUR DU STATUT (v5 utilise documentId)
  Future<void> updateReservationStatus(Reservation res, String status) async {
    isLoading.value = true;
    try {
      final token = await _authController.getToken();
      if (token == null) return;

      // Strapi v5: on utilise le documentId dans l'URL
      final identifer = res.documentId ?? res.id;
      final url = Uri.parse('$_baseUrl/$identifer');

      print("UPDATING STATUS: $status for $identifer");

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "data": {"mystatus": status}
        }),
      );

      if (response.statusCode == 200) {
        Get.snackbar("Succès", "Statut mis à jour : $status", 
            backgroundColor: Color(0xFFDCFCE7), colorText: Color(0xFF166534));
        fetchAllReservations(); // Recharger la liste
      } else {
        print("Update Error Body: ${response.body}");
        Get.snackbar("Erreur", "Impossible de mettre à jour (${response.statusCode})");
      }
    } catch (e) {
      print("Erreur update status: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 SUPPRESSION D'UNE RÉSERVATION (v5 utilise documentId)
  Future<void> deleteReservation(Reservation res) async {
    isLoading.value = true;
    try {
      final token = await _authController.getToken();
      if (token == null) return;

      final identifer = res.documentId ?? res.id;
      final url = Uri.parse('$_baseUrl/$identifer');

      print("DELETING RESERVATION: $identifer");

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        Get.snackbar("Succès", "Réservation supprimée", 
            backgroundColor: Color(0xFFF3F4F6), colorText: Colors.black);
        fetchAllReservations();
      } else {
        Get.snackbar("Erreur", "Suppression échouée (${response.statusCode})");
      }
    } catch (e) {
      print("Erreur delete reservation: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 CHARGEMENT DES RÉSERVATIONS DE L'UTILISATEUR CONNECTÉ (GET)
  Future<void> fetchMyReservations() async {
    isLoading.value = true;
    final client = http.Client();
    try {
      final token = await _authController.getToken();
      final user = _authController.currentUser.value;
      
      if (token == null || user == null) return;

      final userId = user['id'];
      final url = Uri.parse('$_baseUrl?filters[user][id][\$eq]=$userId&populate=space');

      final response = await client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('data')) {
          final List<dynamic> list = data['data'];
          reservations.assignAll(list.map((item) => Reservation.fromJson(item)).toList());
        }
      }
    } catch (e) {
      print("Erreur fetch my reservations: $e");
    } finally {
      client.close();
      isLoading.value = false;
    }
  }
}
