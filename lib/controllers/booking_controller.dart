// ============================================
// BookingController — Contrôleur de Réservation
// Architecture : GetX, API REST Strapi v5 
//Gestion des réservations : ✅ Création ✅ Annulation ✅ Historique ✅ Filtres
// ============================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/auth_controller.dart';
import '../data/models/space.dart';
import '../data/models/reservation.dart';
import 'notification_controller.dart';

class BookingController extends GetxController {
  // ── Dépendances ──────────────────────────────────────────────
  final AuthController _auth = Get.find<AuthController>();
  static const String _baseUrl = 'http://193.111.250.244:3046/api/reservations';

  // ── États réactifs ───────────────────────────────────────────
  final RxList<Reservation> reservations = <Reservation>[].obs;
  final RxString selectedResFilter = 'Toutes'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isCheckingAvailability = false.obs; // État de vérification
  final RxBool isMonthly = true.obs;
  
  // Plage horaire de travail
  final List<String> timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30', 
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', 
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30', '18:00'
  ];

  final RxBool isAllDay = false.obs; // Réservation toute la journée
  final RxInt checkoutStep = 1.obs; // 1: Date/Heure, 2: Services, 3: Paiement
  final RxList<String> selectedServices = <String>[].obs;// Services additionnels

  // ── Champs de réservation ────────────────────────────────────
  final Rx<DateTime> startDateTime = DateTime.now().add(const Duration(hours: 1)).obs;// Date et heure de début
  final Rx<DateTime> endDateTime = DateTime.now().add(const Duration(hours: 2)).obs;// Date et heure de fin
  final RxDouble totalAmount = 0.0.obs;// Montant total

  // ── Catalogue des services additionnels ──────────────────────
  final Map<String, double> servicesCatalog = const {
    'Café illimité': 5.0,
    'Projecteur': 15.0,
    'Microphone': 10.0,
    'Imprimante pro': 8.0,
  };

  // ── Contrôleurs de formulaire ────────────────────────────────
  final cardNameController = TextEditingController();// Nom sur la carte
  final cardNumberController = TextEditingController();
  final cardExpiryController = TextEditingController();
  final cardCvcController = TextEditingController();

  @override
  void onClose() {
    cardNameController.dispose();
    cardNumberController.dispose();
    cardExpiryController.dispose();
    cardCvcController.dispose();
    super.onClose();
  }

  // ── Getters calculés ─────────────────────────────────────────
// Filtre les réservations selon le filtre sélectionné
  List<Reservation> get filteredReservations {
    final now = DateTime.now();// Date actuelle
    List<Reservation> list = List.from(reservations);// Liste des réservations


    // Filtre selon le filtre sélectionné
    //Prends toutes les réservations de la liste, 
    //et garde uniquement celles dont la date de début est dans le futur (après maintenant).
    // Mets le résultat dans list.
    switch (selectedResFilter.value) {
      case 'À venir':// Filtre les réservations à venir
        list = list.where((r) => r.startDateTime.isAfter(now)).toList(); 
        break;
      case 'Passées':
        list = list.where((r) => r.startDateTime.isBefore(now)).toList();
        break;
      case 'En attente':
        list = list.where((r) => r.status == ReservationStatus.enAttente).toList();
        break;
      case 'Confirmées':
        list = list.where((r) => r.status == ReservationStatus.confirmee).toList();
        break;
    }

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();// Met la recherche en minuscule
      // Prends toutes les réservations de la liste, 
      //et garde uniquement celles dont le nom de l'espace ou le nom de l'utilisateur contient la recherche.
      // Mets le résultat dans list.
      list = list.where((r) =>
        (r.spaceName ?? '').toLowerCase().contains(q) ||
        (r.user?.username ?? '').toLowerCase().contains(q)
      ).toList();
    }

    return list;
  }

// Compte le nombre de réservations à venir
  int get upcomingCount => reservations.where((r) => r.startDateTime.isAfter(DateTime.now())).length;
  // Compte le nombre de réservations passées
  int get pastCount => reservations.where((r) => r.startDateTime.isBefore(DateTime.now())).length;

  // ── Méthodes utilitaires ──────────────────────────────────────

  void updateResFilter(String filter) => selectedResFilter.value = filter;// Met à jour le filtre de réservation
  void updateSearchQuery(String query) => searchQuery.value = query;// Met à jour la recherche

  
  
  void toggleService(String name, double hourlyPrice, double monthlyPrice) {// Active ou désactive un service additionnel
    selectedServices.contains(name) ? selectedServices.remove(name) : selectedServices.add(name);// Ajoute ou retire le service de la liste
    _calculateTotal(hourlyPrice: hourlyPrice, monthlyPrice: monthlyPrice);// Met à jour le total
  }

  void updateDates(DateTime start, DateTime end, double hourlyPrice, double monthlyPrice) {
    startDateTime.value = start;
    endDateTime.value = end;
    _calculateTotal(hourlyPrice: hourlyPrice, monthlyPrice: monthlyPrice);
  }

  /// Alias public pour rester compatible avec checkout_page.dart
  void calculateTotal({required double hourlyPrice, required double monthlyPrice}) =>
      _calculateTotal(hourlyPrice: hourlyPrice, monthlyPrice: monthlyPrice);

  void _calculateTotal({required double hourlyPrice, required double monthlyPrice}) {
    double base = isMonthly.value
        ? monthlyPrice
        : () {
            double hours = endDateTime.value.difference(startDateTime.value).inMinutes / 60.0;
            return (hours < 1.0 ? 1.0 : hours) * hourlyPrice;
          }();

    final servicesCost = selectedServices.fold<double>(
      0.0, (sum, s) => sum + (servicesCatalog[s] ?? 0.0)
    );

    totalAmount.value = base + servicesCost;
  }

  /// Bascule entre réservation ponctuelle et toute la journée (09:00 - 18:00)
  void toggleAllDay(double hourlyPrice, double monthlyPrice) {
    isAllDay.value = !isAllDay.value;
    if (isAllDay.value) {
      isMonthly.value = false;
      final now = startDateTime.value;
      updateDates(
        DateTime(now.year, now.month, now.day, 9, 0),
        DateTime(now.year, now.month, now.day, 18, 0),
        hourlyPrice,
        monthlyPrice
      );
    }
  }

  /// Vérifie si les horaires sont valides (Heures de travail et pas dans le passé)
  bool validateBookingTimes() {
    final now = DateTime.now();
    final start = startDateTime.value;
    final end = endDateTime.value;

    // 1. Pas dans le passé (avec une petite marge de 5 min)
    if (start.isBefore(now.subtract(const Duration(minutes: 5)))) {
      _showError("Date invalide", "Vous ne pouvez pas réserver dans le passé.");
      return false;
    }

    // 2. Fin après début
    if (!end.isAfter(start)) {
      _showError("Horaire invalide", "L'heure de fin doit être après l'heure de début.");
      return false;
    }

    // 3. Heures de travail (09:00 - 18:00)
    if (start.hour < 9 || end.hour > 18 || (end.hour == 18 && end.minute > 0)) {
      _showError("Hors service", "Les réservations sont possibles de 09:00 à 18:00.");
      return false;
    }

    return true;
  }

  // ── Validation du formulaire de paiement ──────────────────────
// Valide le formulaire de paiement
  bool _validatePaymentForm() {
    if (cardNameController.text.trim().isEmpty ||// Vérifie si le nom sur la carte est vide
        cardNumberController.text.trim().isEmpty ||// Vérifie si le numéro de carte est vide
        cardExpiryController.text.trim().isEmpty ||// Vérifie si la date d'expiration est vide
        cardCvcController.text.trim().isEmpty) {// Vérifie si le code CVC est vide
      _showError('Champs incomplets', 'Veuillez remplir tous les champs de paiement.');
      return false;
    }
    if (cardNumberController.text.replaceAll(' ', '').length != 16) {// Vérifie si le numéro de carte contient 16 chiffres
      _showError('Carte invalide', 'Le numéro de carte doit contenir 16 chiffres.');
      return false;
    }

    // Validation logique de la date d'expiration (MM/YY)
    final expiryStr = cardExpiryController.text;
    if (!expiryStr.contains('/') || expiryStr.length != 5) {
      _showError('Date invalide', 'Le format doit être MM/YY.');
      return false;
    }

    final parts = expiryStr.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse(parts[1]) ?? 0;

    if (month < 1 || month > 12) {
      _showError('Mois invalide', 'Le mois doit être entre 01 et 12.');
      return false;
    }

    // Vérifier si la carte est expirée (On rajoute 2000 pour l'année YY -> YYYY)
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      _showError('Carte expirée', "La date d'expiration est dépassée.");
      return false;
    }

    return true;
  }

  // ── Vérification dynamique de disponibilité ───────────────────

  /// Contacte le serveur Strapi et retourne `true` si le créneau est libre.
  /// Lance une exception si le serveur est injoignable.
  Future<bool> _isSlotAvailable({
    required String spaceId,// ID de l'espace
    required String? token,// Token de l'utilisateur
  }) async {
    isCheckingAvailability.value = true;// Met à jour le statut de vérification
    // Vérifie si le créneau est disponible
    try {
      final url = Uri.parse(
        '$_baseUrl?filters[space][documentId][\$eq]=$spaceId&filters[mystatus][\$ne]=Annulee&populate=false'
      );// URL de l'API Strapi
// Envoie la requête à l'API Strapi
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));// Timeout de 10 secondes

      if (response.statusCode != 200) {
        debugPrint('[BookingController] Dispo check error: ${response.statusCode}');
        return true; // On laisse passer si le serveur n'arrive pas à répondre
      }
// Décode la réponse JSON
//on la convertit en liste d'objets lisibles par Dart. existing
//existing = toutes les réservations déjà enregistrées pour cet espace.
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> existing = data['data'] ?? [];// Liste des réservations existantes
//Ce sont les horaires que l'utilisateur actuel veut réserver.
      final newStart = startDateTime.value;// date de début de la réservation
      final newEnd = endDateTime.value;// date de fin de la réservation
// Parcourt toutes les réservations existantes
      for (final res in existing) {
// Si une réservation n'est pas confirmée, elle ne bloque pas le créneau
// L'utilisateur a demandé que seules les réservations confirmées bloquent le créneau
        final status = (res['mystatus'] ?? '').toString().toLowerCase();// Statut de la réservation
        if (!status.contains('confirm')) continue;// Si la réservation n'est pas confirmée, on laisse le créneau libre
//on lit les heures de la réservation 
//déjà en place dans la base de données et on les convertit en date locale
        final existStart = DateTime.parse(res['start_datetime']).toLocal();// Date de début de la réservation existante
        final existEnd = DateTime.parse(res['end_datetime']).toLocal();// Date de fin de la réservation existante

        // Algorithme de chevauchement standard :
        // Deux intervalles se chevauchent si : début_A < fin_B ET fin_A > début_B
        if (newStart.isBefore(existEnd) && newEnd.isAfter(existStart)) {
          return false; // ❌ Créneau occupé
        }
      }
      return true; // ✅ Créneau libre

    } finally {
      isCheckingAvailability.value = false;// Met fin à la vérification de disponibilité
    }
  }

  // ── CRÉATION DE LA RÉSERVATION (workflow complet) ─────────────

  Future<void> createReservation(Space space) async {
    // Étape 0 : Valider l'horaire (Business hours & Past hours)
    if (!validateBookingTimes()) return;

    // Étape 1 : Valider le formulaire côté client
    if (!_validatePaymentForm()) return;

    isLoading.value = true;

    try {
      final token = await _auth.getToken();// Récupère le token de l'utilisateur connecté
      final user = _auth.currentUser.value;// Récupère les infos de l'utilisateur connecté

      if (token == null || user == null) {// Si le token ou l'utilisateur est null
        _showError('Session expirée', 'Veuillez vous reconnecter et réessayer.');
        return;
      }

      // Étape 2 : Vérifier dynamiquement la disponibilité sur le serveur
      final spaceId = space.documentId ?? space.id;// Récupère l'ID de l'espace
      final slotFree = await _isSlotAvailable(spaceId: spaceId, token: token);// Vérifie si le créneau est disponible

      if (!slotFree) {// Si le créneau n'est pas disponible
        _showUnavailableDialog();// Affiche un message d'erreur
        return;
      }

      // Étape 3 : Envoyer la réservation au serveur
      final body = {
        "data": {
          "start_datetime": startDateTime.value.toUtc().toIso8601String(),
          "end_datetime": endDateTime.value.toUtc().toIso8601String(),
          "mystatus": "En_attente",
          "purpose": "Réservation via App",
          "payment_status": "En_attente",
          "payment_method": "Carte_en_ligne",
          "total_amount": totalAmount.value,
          "notes": selectedServices.isEmpty
              ? "Aucun service additionnel"
              : "Services : ${selectedServices.join(', ')}",
          "organizer_name": user['username'] ?? "Utilisateur",
          "organizer_phone": user['phone'] ?? "Non spécifié",
          "user": user['documentId'] ?? user['id'],
          "space": spaceId,
        }
      };

      debugPrint('[BookingController] POST $body');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      debugPrint('[BookingController] Response ${response.statusCode}: ${response.body}');

      // Étape 4 : Réagir à la réponse du serveur
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 📢 Notifier l'administrateur
        try {
          final notifCtrl = Get.find<NotificationController>();
          notifCtrl.notifyAdmins(
            title: 'Nouvelle réservation',
            message: 'Un utilisateur a réservé l\'espace ${space.name}. Veuillez valider ou refuser cette demande.',
          );
        } catch (e) {
          debugPrint('Erreur envoi notification admin: $e');
        }

        Get.back(); // Ferme le formulaire
        _showSuccessDialog(); // Affiche le succès
        fetchMyReservations(); // Rafraîchit la liste
      } else {
        final errBody = jsonDecode(response.body);// Récupère le corps de la réponse
        final msg = errBody['error']?['message'] ?? 'Erreur ${response.statusCode}';// Récupère le message d'erreur
        _showError('Réservation refusée', msg);// Affiche un message d'erreur
      }

    } on Exception catch (e) {
      _showError('Problème réseau', 'Impossible de joindre le serveur. Vérifiez votre connexion.\n($e)');
    } finally {
      isLoading.value = false;
    }
  }

  // ── CHARGEMENT DE TOUTES LES RÉSERVATIONS (Admin) ────────────

  Future<void> fetchAllReservations() async {
    isLoading.value = true;
    try {
      final token = await _auth.getToken();
      if (token == null) return;

      // Syntaxe simplifiée pour Strapi v5
      //populate=* : pour inclure les données des relations (user, space)
      //sort=createdAt:desc : pour trier par date de création (les plus récentes en premier)
      //pagination[pageSize]=100 : pour augmenter le nombre d'éléments récupérés
      final url = Uri.parse(
        '$_baseUrl?populate=*&sort=createdAt:desc&pagination[pageSize]=100'
      );

      debugPrint('[BookingController] Admin fetch URL: $url');//affiche l'URL de l'API

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('[BookingController] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('data')) {
          final List<dynamic> list = data['data'];
          debugPrint('[BookingController] Data received: ${list.length} items');
          
          if (list.isNotEmpty) {
            reservations.assignAll(list.map((item) => Reservation.fromJson(item)).toList());
          } else {
            reservations.clear();
            debugPrint('[BookingController] Server returned empty list');
          }
        }
      } else {
        debugPrint('[BookingController] fetchAll Error Body: ${response.body}');
        _showError('Erreur serveur', 'Code: ${response.statusCode}\nImpossible de charger les réservations.');
      }
    } on Exception catch (e) {
      debugPrint('[BookingController] fetchAll exception: $e');
      _showError('Erreur réseau', 'Erreur: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── CHARGEMENT DES RÉSERVATIONS DE L'UTILISATEUR CONNECTÉ ────

  Future<void> fetchMyReservations() async {
    isLoading.value = true;
    try {
      final token = await _auth.getToken();
      final user = _auth.currentUser.value;
      if (token == null || user == null) return;

      final userId = user['id'];
      final response = await http.get(
        Uri.parse('$_baseUrl?filters[user][id][\$eq]=$userId&populate=space'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('data')) {
          reservations.assignAll(
            (data['data'] as List).map((item) => Reservation.fromJson(item)).toList()
          );
        }
      }
    } on Exception catch (e) {
      debugPrint('[BookingController] fetchMine exception: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── MISE À JOUR DU STATUT (Admin) ────────────────────────────

  Future<void> updateReservationStatus(Reservation res, String status) async {
    isLoading.value = true;
    try {
      final token = await _auth.getToken();
      if (token == null) return;

      final id = res.documentId ?? res.id;
      
      // Fonction interne pour envoyer la requête
      Future<http.Response> sendUpdate(String statusValue) async {
        debugPrint('[updateStatus] Tentative : $statusValue sur $id');
        return await http.put(
          Uri.parse('$_baseUrl/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({"data": {"mystatus": statusValue}}),
        ).timeout(const Duration(seconds: 10));
      }

      // 1. Première tentative avec la valeur passée (ex: "Confirmee")
      var response = await sendUpdate(status);

      // 2. Si 400 et que c'est "Confirmee", tenter "Confirmée" (avec accent)
      if (response.statusCode == 400 && status == 'Confirmee') {
        debugPrint('[updateStatus] 400 détecté avec "Confirmee", tentative avec "Confirmée"...');
        response = await sendUpdate('Confirmée');
      }

      // 3. Gestion globale de la réponse
      if (response.statusCode == 200) {
        // Détection de la valeur finale acceptée
        final finalStatusStr = response.statusCode == 200 ? (status == 'Confirmee' ? (response.request?.toString().contains('Confirmée') ?? false ? 'Confirmée' : 'Confirmee') : status) : status;
        
        // Mise à jour LOCALE de l'item spécifique pour éviter de faire sauter toute la liste
        final idx = reservations.indexWhere((r) => r.id == res.id || (r.documentId != null && r.documentId == res.documentId));
        if (idx != -1) {
          final old = reservations[idx];
          reservations[idx] = Reservation(
            id: old.id,
            documentId: old.documentId,
            startDateTime: old.startDateTime,
            endDateTime: old.endDateTime,
            status: Reservation.parseStatusFromString(status == 'Confirmee' ? 'Confirmée' : status), // On force l'enum interne
            purpose: old.purpose,
            paymentStatus: old.paymentStatus,
            paymentMethod: old.paymentMethod,
            totalAmount: old.totalAmount,
            notes: old.notes,
            spaceName: old.spaceName,
            user: old.user,
          );
          reservations.refresh();
        }

        Get.snackbar(
          "Succès", 
          "La réservation de ${res.spaceName ?? 'l\'espace'} est maintenant validée.",
          backgroundColor: const Color(0xFFDCFCE7), 
          colorText: const Color(0xFF166534),
          icon: const Icon(Icons.check_circle, color: Color(0xFF166534)),
        );
      } else {
        final errBody = jsonDecode(response.body);
        final msg = errBody['error']?['message'] ?? 'Erreur ${response.statusCode}';
        _showError('Mise à jour refusée', 'Détail Strapi: $msg');
      }

    } on Exception catch (e) {
      debugPrint('[BookingController] updateStatus exception: $e');
      _showError('Erreur réseau', 'Impossible de joindre le serveur. $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── SUPPRESSION D'UNE RÉSERVATION (Admin) ────────────────────

  Future<void> deleteReservation(Reservation res) async {
    isLoading.value = true;
    try {
      final token = await _auth.getToken();
      if (token == null) return;

      final id = res.documentId ?? res.id;
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        reservations.remove(res);
        Get.snackbar("Supprimée", "La réservation a été supprimée.",
            backgroundColor: const Color(0xFFF3F4F6), colorText: Colors.black87);
      } else {
        _showError('Erreur', 'Suppression échouée (${response.statusCode})');
      }
    } on Exception catch (e) {
      debugPrint('[BookingController] delete exception: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Méthodes d'affichage (UI helpers) ────────────────────────

  void _showError(String title, String message) {
    Get.snackbar(
      title, message,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  void _showUnavailableDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_busy_rounded, color: Colors.orange, size: 64),
              ),
              const SizedBox(height: 20),
              const Text(
                "Créneau Indisponible",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              const Text(
                "Cet espace est déjà réservé par quelqu'un d'autre sur ce créneau horaire.\n\nVeuillez choisir un autre horaire ou une autre date.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Modifier l'horaire", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              ),
              const SizedBox(height: 24),
              const Text(
                "Réservation Confirmée !",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              const Text(
                "Votre réservation a été enregistrée avec succès.\nVous pouvez la retrouver dans votre planning.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Super !", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
