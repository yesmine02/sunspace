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
import 'package:intl/intl.dart';
import 'notification_controller.dart';
import 'equipments_controller.dart';
import '../data/models/equipment.dart';

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
  final RxList<Reservation> spaceReservationsOnDay = <Reservation>[].obs; // Réservations du jour pour l'espace sélectionné
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
  final RxInt numberOfPeople = 1.obs; // Demande actuelle

  // ── Champs de réservation ────────────────────────────────────
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rx<TimeOfDay> startTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))).obs;
  final Rx<TimeOfDay> endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2))).obs;
  
  final Rx<DateTime> startDateTime = DateTime.now().add(const Duration(hours: 1)).obs;
  final Rx<DateTime> endDateTime = DateTime.now().add(const Duration(hours: 2)).obs;
  final RxDouble totalAmount = 0.0.obs;

  // Contrôleurs de paiement
  final TextEditingController cardNameController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardExpiryController = TextEditingController();
  final TextEditingController cardCvcController = TextEditingController();

  // ── Catalogue des services additionnels (Dynamique) ─────────
  // Fusionne les services fixes et les équipements physiques
  Map<String, Map<String, dynamic>> get servicesCatalog {
    // 1. Initialisation du catalogue vide
    final Map<String, Map<String, dynamic>> catalog = {};

    // 2. Intégration des équipements physiques depuis EquipmentsController
    try {
      final EquipmentsController eqController = Get.find<EquipmentsController>();
      
      for (var eq in eqController.equipments) {
        final String name = eq.name;
        // On récupère le prix de l'équipement (strictement depuis le serveur)
        final double rentalPrice = eq.price ?? 0.0; 
        
        final bool isEqAvailable = eq.status == EquipmentStatus.disponible;

        if (catalog.containsKey(name)) {
          // Si on a déjà cet équipement, il est disponible si au moins un exemplaire l'est
          catalog[name]!['available'] = catalog[name]!['available'] || isEqAvailable;
          // On garde le prix de l'équipement (le dernier trouvé avec ce nom)
          catalog[name]!['price'] = rentalPrice;
        } else {
          catalog[name] = {
            'price': rentalPrice,
            'available': isEqAvailable,
            'type': eq.type,
          };
        }
      }
    } catch (e) {
      print("Erreur lors de la construction du catalogue dynamique: $e");
    }

    return catalog;
  }

  // ── Contrôleurs de formulaire ────────────────────────────────
  // Les contrôleurs de carte ont été supprimés car le paiement n'est plus requis.


  @override
  void onInit() {
    super.onInit();
    // Recalculer le total dès que la liste des équipements change (prix mis à jour, etc.)
    try {
      final EquipmentsController eqController = Get.find<EquipmentsController>();
      ever(eqController.equipments, (_) {
        // On récupère le prix de l'espace actuel pour recalculer
        // Note: On pourrait avoir besoin de passer les prix réels ici
        // Pour l'instant on se contente de rafraîchir si on a un espace sélectionné
        print("Equipements mis à jour, rafraîchissement du catalogue...");
      });
    } catch (e) {
      print("EquipmentsController non trouvé pour le listener: $e");
    }
  }

  @override
  void onClose() {
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

  
  
  void toggleService(String name, double hourlyPrice, double monthlyPrice) {
    // Vérifier la disponibilité avant de basculer
    final service = servicesCatalog[name];
    if (service != null && service['available'] == false) {
      Get.snackbar(
        "Indisponible", 
        "L'équipement '$name' est actuellement en maintenance.",
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
      return;
    }
    
    selectedServices.contains(name) ? selectedServices.remove(name) : selectedServices.add(name);
    _calculateTotal(hourlyPrice: hourlyPrice, monthlyPrice: monthlyPrice);
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
      0.0, (sum, s) => sum + ((servicesCatalog[s]?['price'] as double?) ?? 0.0)
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

  // ── Validation du formulaire de paiement (Supprimée car paiement désactivé) ──


  // ── Vérification dynamique de disponibilité ───────────────────

  /// Contacte le serveur Strapi et valide la capacité de l'espace.
  /// Algorithme : Places disponibles = (Capacité Max) - (Somme des places déjà Confirmées)
  Future<bool> _isSlotAvailable({
    required Space space,
    required String? token,
  }) async {
    isCheckingAvailability.value = true;
    final String spaceId = space.documentId ?? space.id;
    final int capacityMax = space.capacity;
    final int requested = numberOfPeople.value;

    try {
      final url = Uri.parse(
        '$_baseUrl?filters[space][documentId][\$eq]=$spaceId&filters[mystatus][\$eq]=Confirmée&populate=false'
      );
      
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return true;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> existing = data['data'] ?? [];
      
      final newStart = startDateTime.value;
      final newEnd = endDateTime.value;

      int occupiedSeats = 0;

      for (final res in existing) {
        // On ne compte que les réservations confirmées sur le même créneau
        final existStart = DateTime.parse(res['start_datetime']).toLocal();
        final existEnd = DateTime.parse(res['end_datetime']).toLocal();

        if (newStart.isBefore(existEnd) && newEnd.isAfter(existStart)) {
          // Chevauchement détecté, on cumule les personnes
          final int people = int.tryParse(res['attendees']?.toString() ?? '1') ?? 1;
          occupiedSeats += people;
        }
      }

      final int availableSeats = capacityMax - occupiedSeats;

      if (requested > availableSeats) {
        // BLOCAGE IMMÉDIAT
        _showCapacityError(availableSeats, requested);
        return false;
      }

      return true; // ✅ Capacité suffisante

    } finally {
      isCheckingAvailability.value = false;// Met fin à la vérification de disponibilité
    }
  }

  /// Récupère toutes les réservations d'un espace pour un jour spécifique
  Future<void> fetchSpaceReservationsOnDay(String spaceId, DateTime day) async {
    isLoading.value = true;
    try {
      final token = await _auth.getToken();
      if (token == null) return;

      // On filtre par espace, par statut (Uniquement confirmé pour l'affichage) et par date
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final url = Uri.parse(
        '$_baseUrl?filters[space][documentId][\$eq]=$spaceId'
        '&filters[mystatus][\$eq]=Confirmée'
        '&filters[start_datetime][\$contains]=$dateStr'
        '&populate=user'
      );

      debugPrint('[BookingController] Fetch day schedule URL: $url');

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> list = data['data'] ?? [];
        spaceReservationsOnDay.assignAll(list.map((item) => Reservation.fromJson(item)).toList());
        debugPrint('[BookingController] Day schedule: ${spaceReservationsOnDay.length} items found');
      }
    } catch (e) {
      debugPrint('[BookingController] Error fetching day schedule: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── CRÉATION DE LA RÉSERVATION (workflow complet) ─────────────

  Future<bool> createReservation(Space space) async {
    // Étape 0 : Valider l'horaire (Business hours & Past hours)
    if (!validateBookingTimes()) return false;

    isLoading.value = true;

    try {
      final token = await _auth.getToken();// Récupère le token de l'utilisateur connecté
      final user = _auth.currentUser.value;// Récupère les infos de l'utilisateur connecté

      if (token == null || user == null) {// Si le token ou l'utilisateur est null
        _showError('Session expirée', 'Veuillez vous reconnecter et réessayer.');
        return false;
      }

      // Étape 2 : Vérification Intelligente de la Capacité
      final slotAllowed = await _isSlotAvailable(space: space, token: token);

      if (!slotAllowed) {
        return false; // L'erreur de capacité est déjà gérée par _showCapacityError
      }

      // Étape 3 : Envoyer la réservation au serveur
      final body = {
        "data": {
          "start_datetime": startDateTime.value.toUtc().toIso8601String(),
          "end_datetime": endDateTime.value.toUtc().toIso8601String(),
          "is_all_day": isAllDay.value,
          "mystatus": "En_attente",
          "attendees": numberOfPeople.value,
          "purpose": "Réservation via App",
          "payment_status": "En_attente",
          "payment_method": "Carte_en_ligne",
          "total_amount": totalAmount.value,
          "turnstile_verified": true,
          "notes": selectedServices.isEmpty
              ? "Aucun service additionnel"
              : "Services : ${selectedServices.join(', ')}",
          "organizer_name": user['username'] ?? "Utilisateur",
          "organizer_phone": user['phone'] ?? "00000000",
          "space": space.documentId ?? space.id,
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
          final username = user['username'] ?? 'Un utilisateur';
          final spaceName = space.name ?? 'Espace inconnu';
          final dateFormat = DateFormat('dd/MM/yyyy');
          final timeFormat = DateFormat('HH:mm');
          final start = startDateTime.value;
          final end = endDateTime.value;
          
          final dateStr = dateFormat.format(start);
          final startTimeStr = timeFormat.format(start);
          final endTimeStr = timeFormat.format(end);

          notifCtrl.notifyAdmins(
            title: 'Nouvelle réservation — $spaceName',
            message: '$username a réservé "$spaceName" le $dateStr $startTimeStr -> $endTimeStr',
          );
        } catch (e) {
          debugPrint('Erreur envoi notification admin: $e');
        }

        Get.back(); // Ferme le formulaire
        _showSuccessDialog(); // Affiche le succès
        fetchMyReservations(); // Rafraîchit la liste
        return true;
      } else {
        final errBody = jsonDecode(response.body);// Récupère le corps de la réponse
        final msg = errBody['error']?['message'] ?? 'Erreur ${response.statusCode}';// Récupère le message d'erreur
        _showError('Réservation refusée', msg);// Affiche un message d'erreur
        return false;
      }

    } on Exception catch (e) {
      _showError('Problème réseau', 'Impossible de joindre le serveur. Vérifiez votre connexion.\n($e)');
      return false;
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
      if (token == null || user == null) {
        debugPrint('[BookingController] fetchMine: Token or User is null');
        return;
      }

      final username = Uri.encodeComponent(user['username'] ?? '');
      final url = '$_baseUrl?filters[organizer_name][\$eq]=$username&populate=space&sort=createdAt:desc&pagination[pageSize]=100';
      debugPrint('[BookingController] fetchMine URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('[BookingController] fetchMine Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('data')) {
          final List rawList = data['data'];
          debugPrint('[BookingController] fetchMine: Found ${rawList.length} items');
          
          try {
            final parsedList = rawList.map((item) => Reservation.fromJson(item)).toList();
            reservations.assignAll(parsedList);
            debugPrint('[BookingController] fetchMine: Successfully parsed all reservations');
          } catch (e) {
            debugPrint('[BookingController] fetchMine Parsing Error: $e');
          }
        }
      } else {
        debugPrint('[BookingController] fetchMine Error Body: ${response.body}');
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

      // ─── Normalisation du statut pour Strapi v5 (qui demande des accents) ───
      String statusToSend = status;
      if (status == 'Confirmee') statusToSend = 'Confirmée';
      if (status == 'Annulee') statusToSend = 'Annulée';
      if (status == 'Terminee') statusToSend = 'Terminée';

      var response = await sendUpdate(statusToSend);

      // 3. Gestion globale de la réponse
      if (response.statusCode == 200) {
        // Mise à jour LOCALE de l'item spécifique pour éviter de faire sauter toute la liste
        final idx = reservations.indexWhere((r) => r.id == res.id || (r.documentId != null && r.documentId == res.documentId));
        if (idx != -1) {
          final old = reservations[idx];
          reservations[idx] = Reservation(
            id: old.id,
            documentId: old.documentId,
            startDateTime: old.startDateTime,
            endDateTime: old.endDateTime,
            status: Reservation.parseStatusFromString(statusToSend),
            purpose: old.purpose,
            paymentStatus: old.paymentStatus,
            paymentMethod: old.paymentMethod,
            totalAmount: old.totalAmount,
            notes: old.notes,
            spaceName: old.spaceName,
            organizerName: old.organizerName, // FIX: On garde le nom !
            numberOfPeople: old.numberOfPeople, // FIX: On garde le nombre de personnes !
            user: old.user,
          );
          reservations.refresh();
        }

        // 📢 GESTION DES NOTIFICATIONS
        try {
          final notifCtrl = Get.find<NotificationController>();
          final spaceName = res.spaceName ?? 'Espace';
          final isAdminUser = _auth.isAdmin;
          final currentUser = _auth.currentUser.value;

          // 1. Notifier l'admin si un UTILISATEUR annule sa propre réservation
          if (statusToSend == 'Annulée' && !isAdminUser) {
            final username = currentUser?['username'] ?? 'Un utilisateur';
            final date = res.formattedDate;
            final time = res.formattedTime;
            
            notifCtrl.notifyAdmins(
              title: 'Réservation Annulée — $spaceName',
              message: '$username a annulé sa réservation pour "$spaceName" prévue le $date ($time).',
            );
          }

          // 2. Notifier l'utilisateur (seulement si l'ADMIN fait le changement)
          if (res.user?.id != null && isAdminUser) {
            final isConfirmed = statusToSend == 'Confirmée';
            final isRefused = statusToSend == 'Annulée';
            
            if (isConfirmed || isRefused) {
              final statusText = isConfirmed ? 'validée' : 'refusée';
              final titleText = isConfirmed ? 'Réservation confirmée !' : 'Réservation refusée !';
              final notifType = isConfirmed ? 'Confirmation_réservation' : 'Alerte';
              
              notifCtrl.sendNotification(
                targetUserId: res.user!.id!,
                title: titleText,
                message: 'Votre réservation pour "$spaceName" a été $statusText par l\'administration.',
                type: notifType,
              );
            }
          }
        } catch (e) {
          debugPrint('Erreur envoi notification statut: $e');
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

  void _showCapacityError(int available, int requested) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_flipped, color: Colors.red, size: 64),
              const SizedBox(height: 20),
              const Text(
                "Action impossible : Capacité insuffisante",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 16),
              Text(
                "Il ne reste que $available places pour ce créneau, alors que vous en demandez $requested.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                  child: const Text("Compris", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
