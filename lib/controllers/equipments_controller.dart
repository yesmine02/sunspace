// ============================================
// Contrôleur des Équipements (EquipmentsController)
// Gère toutes les opérations CRUD (Créer, Lire, Modifier, Supprimer)
// Les données sont envoyées/reçues du serveur Strapi
// ============================================

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/equipment.dart';

import 'package:http/http.dart' as http;
import '../data/local/secure_storage.dart';
import 'auth_controller.dart';

class EquipmentsController extends GetxController {
  // Liste observable des équipements — quand elle change, l'UI se met à jour automatiquement
  final RxList<Equipment> equipments = <Equipment>[].obs;

  // Texte de recherche saisi par l'utilisateur
  final RxString searchQuery = ''.obs;

  // Filtre de statut sélectionné (par défaut : tous)
  final RxString selectedStatus = 'Tous les statuts'.obs;

  // Indicateur de chargement (true = en cours de chargement)
  final RxBool isLoading = false.obs;

  // URL de base de l'API Strapi pour les équipements
  static const String _baseUrl = 'http://193.111.250.244:3046/api/equipment-assets';

  // Clé utilisée pour sauvegarder les données en cache local
  static const String _storageKey = 'saved_equipments';

  // Appelé automatiquement quand le contrôleur est créé
  // Charge les équipements dès le démarrage
  @override
  void onInit() {
    super.onInit();
    loadEquipments();
  }

  // Récupère le token JWT d'authentification (nécessaire pour chaque requête API)
  Future<String?> _getToken() async {
    final auth = Get.find<AuthController>();
    return auth.token ?? await SecureStorage.getToken();
  }

  // En-têtes HTTP communs envoyés avec chaque requête API
  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ══════════════════════════════════════════════
  // CHARGER les équipements depuis le serveur (GET)
  // ══════════════════════════════════════════════
  Future<void> loadEquipments() async {
    isLoading.value = true; // Affiche un indicateur de chargement
    try {
      String? token = await _getToken();

      if (token != null) {
        // Envoie une requête GET au serveur pour récupérer tous les équipements
        final response = await http.get(
          Uri.parse('$_baseUrl?pagination[pageSize]=100'),
          headers: _headers(token),
        );

        if (response.statusCode == 200) {
          // Succès ! On décode le JSON reçu
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          // Strapi v5 met les données dans une clé "data"
          if (jsonResponse.containsKey('data')) {
            final List<dynamic> list = jsonResponse['data'];

            // Convertit chaque élément JSON en objet Equipment et met à jour la liste
            equipments.assignAll(list.map((item) => Equipment.fromJson(item)).toList());
            
            // Sauvegarde en cache local
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_storageKey, response.body);
            return;
          }
        } else {
           print('Erreur serveur equipments: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('Erreur réseau equipments: $e');
    } finally {
      isLoading.value = false;
    }

    // Si le serveur ne répond pas, on charge depuis le cache local
    _loadFromCache();
  }

  // ══════════════════════════════════════════════
  // CRÉER un équipement sur le serveur (POST)
  // ══════════════════════════════════════════════
  Future<void> addEquipment(Equipment equipment) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        _showError('Token non disponible. Veuillez vous reconnecter.');
        return;
      }

      // Envoie les données du nouvel équipement au serveur
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers(token),
        body: jsonEncode(equipment.toStrapiJson()), // Convertit en JSON format Strapi
      );

      // 200 ou 201 = création réussie
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Recharge la liste depuis le serveur pour avoir les vrais id/documentId
        await loadEquipments();
        Get.back(); // Ferme le dialogue d'ajout
        Get.snackbar(
          'Succès',
          'L\'équipement "${equipment.name}" a été créé avec succès.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFDCFCE7),
          colorText: Color(0xFF166534),
        );
      } else {
        String errorDetail = 'Erreur ${response.statusCode}';
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          if (errorData.containsKey('error') && errorData['error']['message'] != null) {
            errorDetail = errorData['error']['message'];
          }
        } catch (e) {
          errorDetail = response.body;
        }
        
        print('Erreur création équipement détaillée: $errorDetail');
        _showError('Erreur de création : $errorDetail');
      }
    } catch (e) {
      print('Erreur réseau création équipement: $e');
      _showError('Impossible de se connecter au serveur.');
    }
  }

  // ══════════════════════════════════════════════
  // MODIFIER un équipement sur le serveur (PUT)
  // ══════════════════════════════════════════════
  Future<void> updateEquipment(Equipment equipment) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        _showError('Token non disponible. Veuillez vous reconnecter.');
        return;
      }

      // Strapi v5 utilise le documentId (pas l'id numérique) pour modifier
      final String? docId = equipment.documentId;
      if (docId == null || docId.isEmpty) {
        _showError('Impossible de modifier : documentId manquant.');
        return;
      }

      // Envoie les nouvelles données via PUT /api/equipment-assets/{documentId}
      final response = await http.put(
        Uri.parse('$_baseUrl/$docId'),
        headers: _headers(token),
        body: jsonEncode(equipment.toStrapiJson()),
      );

      if (response.statusCode == 200) {
        // Recharge la liste depuis le serveur
        await loadEquipments();
        Get.back(); // Ferme le dialogue d'édition
        Get.snackbar(
          'Succès',
          'L\'équipement "${equipment.name}" a été mis à jour avec succès.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFDCFCE7),
          colorText: Color(0xFF166534),
        );
      } else {
        print('Erreur modification équipement: ${response.statusCode} - ${response.body}');
        _showError('Erreur lors de la modification (${response.statusCode})');
      }
    } catch (e) {
      print('Erreur réseau modification équipement: $e');
      _showError('Impossible de se connecter au serveur.');
    }
  }

  // ══════════════════════════════════════════════
  // SUPPRIMER un équipement sur le serveur (DELETE)
  // ══════════════════════════════════════════════
  Future<void> deleteEquipment(String id) async {
    // Cherche l'équipement dans la liste locale pour récupérer son documentId
    final equipment = equipments.firstWhereOrNull((e) => e.id == id);
    if (equipment == null) return;

    final String? docId = equipment.documentId;
    if (docId == null || docId.isEmpty) {
      _showError('Impossible de supprimer : documentId manquant.');
      return;
    }

    try {
      String? token = await _getToken();
      if (token == null) {
        _showError('Token non disponible. Veuillez vous reconnecter.');
        return;
      }

      // Envoie une requête DELETE via DELETE /api/equipment-assets/{documentId}
      final response = await http.delete(
        Uri.parse('$_baseUrl/$docId'),
        headers: _headers(token),
      );

      // 200 ou 204 = suppression réussie
      if (response.statusCode == 200 || response.statusCode == 204) {
        await loadEquipments();
        Get.snackbar(
          'Succès',
          'L\'équipement "${equipment.name}" a été supprimé.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFDCFCE7),
          colorText: Color(0xFF166534),
        );
      } else {
        print('Erreur suppression équipement: ${response.statusCode} - ${response.body}');
        _showError('Erreur lors de la suppression (${response.statusCode})');
      }
    } catch (e) {
      print('Erreur réseau suppression équipement: $e');
      _showError('Impossible de se connecter au serveur.');
    }
  }

  // ══════════════════════════════════════════════
  // UTILITAIRES
  // ══════════════════════════════════════════════

  // Affiche un message d'erreur rouge en bas de l'écran
  void _showError(String message) {
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFFEE2E2),
      colorText: Color(0xFF991B1B),
    );
  }

  // Charge les données depuis le cache local (utilisé si le serveur est indisponible)
  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString(_storageKey);
    if (cached != null) {
      try {
        final dynamic decoded = jsonDecode(cached);
        if (decoded is Map && decoded.containsKey('data')) {
           final List<dynamic> list = decoded['data'];
           equipments.assignAll(list.map((item) => Equipment.fromJson(item)).toList());
        } else if (decoded is List) {
           equipments.assignAll(decoded.map((item) => Equipment.fromJson(item)).toList());
        }
      } catch (e) {
        print('Erreur lecture cache équipements: $e');
      }
    }
  }

  // Retourne la liste des équipements filtrés par nom et statut
  List<Equipment> get filteredEquipments {
    return equipments.where((equipment) {
      final nameMatches = equipment.name.toLowerCase().startsWith(searchQuery.value.toLowerCase());
      final statusMatches = selectedStatus.value == 'Tous les statuts' ||
          equipment.statusString == selectedStatus.value;
      return nameMatches && statusMatches;
    }).toList();
  }

  // Statistiques — comptent les équipements par statut
  int get totalEquipments => equipments.length;
  int get availableEquipments => equipments.where((e) => e.status == EquipmentStatus.disponible).length;
  int get brokenEquipments => equipments.where((e) => e.status == EquipmentStatus.enPanne).length;
  int get maintenanceEquipments => equipments.where((e) => e.status == EquipmentStatus.enMaintenance).length;

  // Met à jour le texte de recherche
  void updateSearch(String query) {
    searchQuery.value = query;
  }

  // Met à jour le filtre de statut
  void updateStatus(String? status) {
    if (status != null) {
      selectedStatus.value = status;
    }
  }
}
