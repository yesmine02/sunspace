// ============================================
// Contrôleur des Espaces (SpacesController)
// Gère toutes les opérations CRUD (Créer, Lire, Modifier, Supprimer)
// Les données sont envoyées/reçues du serveur Strapi
// ============================================

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/space.dart';

import 'package:http/http.dart' as http;
import '../data/local/secure_storage.dart';
import 'auth_controller.dart';

class SpacesController extends GetxController {
  // Liste observable des espaces — quand elle change, l'UI se met à jour automatiquement
  final RxList<Space> spaces = <Space>[].obs;

  // Texte de recherche saisi par l'utilisateur
  final RxString searchQuery = ''.obs;

  // Filtre de statut sélectionné (par défaut : tous)
  final RxString selectedStatus = 'Tous les statuts'.obs;

  // Filtre de type sélectionné (par défaut : tout)
  final RxString selectedType = 'Tous les types'.obs;

  // Indicateur de chargement (true = en cours de chargement)
  final RxBool isLoading = false.obs;
  
  // URL de base de l'API Strapi pour les espaces
  static const String _baseUrl = 'http://193.111.250.244:3046/api/spaces';

  // Clé utilisée pour sauvegarder les données en cache local
  static const String _storageKey = 'saved_spaces';

  // Appelé automatiquement quand le contrôleur est créé
  // Charge les espaces dès le démarrage
  @override
  void onInit() {
    super.onInit();
    loadSpaces();
  }

  // Récupère le token JWT d'authentification (nécessaire pour chaque requête API)
  Future<String?> _getToken() async {
    final auth = Get.find<AuthController>();
    return auth.token ?? await SecureStorage.getToken();
  }

  // En-têtes HTTP communs envoyés avec chaque requête API
  // - Authorization : le token JWT pour prouver qu'on est connecté
  // - Content-Type : on envoie du JSON
  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ══════════════════════════════════════════════
  // CHARGER les espaces depuis le serveur (GET)
  // ══════════════════════════════════════════════
  Future<void> loadSpaces() async {
    isLoading.value = true; // Affiche un indicateur de chargement
    try {
      String? token = await _getToken();

      if (token != null) {
        // Envoie une requête GET au serveur pour récupérer tous les espaces
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

            // Convertit chaque élément JSON en objet Space et met à jour la liste
            try {
              final newSpaces = list.map((item) => Space.fromJson(item)).toList();
              spaces.assignAll(newSpaces);
            } catch (jsonError) {
              print('ERREUR de parsing Space.fromJson: $jsonError');
              rethrow;
            }
            
            // Sauvegarde en cache local (au cas où le serveur est indisponible plus tard)
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_storageKey, response.body);
            return;
          }
        } else {
           print('Erreur serveur spaces: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      // Erreur réseau (pas d'internet, serveur down, etc.)
      print('Erreur réseau spaces: $e');
    } finally {
      isLoading.value = false; // Cache l'indicateur de chargement
    }

    // Si le serveur ne répond pas, on charge depuis le cache local
    _loadFromCache();
  }

  // ══════════════════════════════════════════════
  // CRÉER un espace sur le serveur (POST)
  // ══════════════════════════════════════════════
  Future<void> addSpace(Space space) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        _showError('Token non disponible. Veuillez vous reconnecter.');
        return;
      }

      // Envoie les données du nouvel espace au serveur
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers(token),
        body: jsonEncode(space.toStrapiJson()), // Convertit l'espace en JSON format Strapi
      );

      // 200 ou 201 = création réussie
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Recharge la liste depuis le serveur pour avoir les vrais id/documentId
        await loadSpaces();
        Get.back(); // Ferme la page de création
        Get.snackbar(
          'Succès',
          'L\'espace "${space.name}" a été créé avec succès.',
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
        
        print('Erreur création espace détaillée: $errorDetail');
        _showError('Erreur de création : $errorDetail');
      }
    } catch (e) {
      print('Erreur réseau création espace: $e');
      _showError('Impossible de se connecter au serveur.');
    }
  }

  // ══════════════════════════════════════════════
  // MODIFIER un espace sur le serveur (PUT)
  // ══════════════════════════════════════════════
  Future<void> updateSpace(Space space) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        _showError('Token non disponible. Veuillez vous reconnecter.');
        return;
      }

      // Strapi v5 utilise le documentId (pas l'id numérique) pour modifier
      final String? docId = space.documentId;
      if (docId == null || docId.isEmpty) {
        _showError('Impossible de modifier : documentId manquant.');
        return;
      }

      // Envoie les nouvelles données au serveur via PUT /api/spaces/{documentId}
      final response = await http.put(
        Uri.parse('$_baseUrl/$docId'),
        headers: _headers(token),
        body: jsonEncode(space.toStrapiJson()),
      );

      if (response.statusCode == 200) {
        // Recharge la liste depuis le serveur pour refléter les modifications
        await loadSpaces();
        Get.back(); // Ferme la page d'édition
        Get.snackbar(
          'Succès',
          'L\'espace "${space.name}" a été mis à jour avec succès.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFDCFCE7),
          colorText: Color(0xFF166534),
        );
      } else {
        print('Erreur modification espace: ${response.statusCode} - ${response.body}');
        _showError('Erreur lors de la modification (${response.statusCode})');
      }
    } catch (e) {
      print('Erreur réseau modification espace: $e');
      _showError('Impossible de se connecter au serveur.');
    }
  }

  // ══════════════════════════════════════════════
  // SUPPRIMER un espace sur le serveur (DELETE)
  // ══════════════════════════════════════════════
  Future<void> deleteSpace(String id) async {
    // Cherche l'espace dans la liste locale pour récupérer son documentId
    final space = spaces.firstWhereOrNull((s) => s.id == id);
    if (space == null) return;

    // On a besoin du documentId pour dire au serveur quel espace supprimer
    final String? docId = space.documentId;
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

      // Envoie une requête DELETE au serveur via DELETE /api/spaces/{documentId}
      final response = await http.delete(
        Uri.parse('$_baseUrl/$docId'),
        headers: _headers(token),
      );

      // 200 ou 204 = suppression réussie
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Recharge la liste depuis le serveur
        await loadSpaces();
        Get.snackbar(
          'Succès',
          'L\'espace "${space.name}" a été supprimé.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFDCFCE7),
          colorText: Color(0xFF166534),
        );
      } else {
        print('Erreur suppression espace: ${response.statusCode} - ${response.body}');
        _showError('Erreur lors de la suppression (${response.statusCode})');
      }
    } catch (e) {
      print('Erreur réseau suppression espace: $e');
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

  // Charge les données depuis le cache local (SharedPreferences)
  // Utilisé quand le serveur est indisponible
  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString(_storageKey);
    if (cached != null) {
      try {
        final dynamic decoded = jsonDecode(cached);
        // Le cache peut avoir le format Strapi { "data": [...] } ou juste une liste [...]
        if (decoded is Map && decoded.containsKey('data')) {
           final List<dynamic> list = decoded['data'];
           spaces.assignAll(list.map((item) => Space.fromJson(item)).toList());
        } else if (decoded is List) {
           spaces.assignAll(decoded.map((item) => Space.fromJson(item)).toList());
        }
      } catch (e) {
        print('Erreur lecture cache: $e');
      }
    }
  }

  // Retourne la liste des espaces filtrés par nom, statut et type
  List<Space> get filteredSpaces {
    return spaces.where((space) {
      // Vérifie si le nom commence par le texte de recherche
      final nameMatches = space.name.toLowerCase().startsWith(searchQuery.value.toLowerCase());
      
      // Vérifie si le statut correspond au filtre sélectionné
      final statusMatches = selectedStatus.value == 'Tous les statuts' || 
          space.statusString == selectedStatus.value;
          
      // Vérifie si le type correspond au filtre sélectionné (Normalise le type pour Strapi)
      final typeMatches = selectedType.value == 'Tous les types' || 
          space.typeString == _mapUItoStrapiType(selectedType.value);

      return nameMatches && statusMatches && typeMatches;
    }).toList();
  }

  // Mappe les noms de l'interface vers les noms attendus par Strapi
  String _mapUItoStrapiType(String uiType) {
    // Les noms dans l'interface correspondent maintenant exactement aux Enums de Strapi
    return uiType;
  }

  // Statistiques — comptent les espaces par statut
  int get totalSpaces => spaces.length;
  int get availableSpaces => spaces.where((s) => s.status == SpaceStatus.disponible).length;
  int get brokenSpaces => spaces.where((s) => s.status == SpaceStatus.enPanne).length;
  int get maintenanceSpaces => spaces.where((s) => s.status == SpaceStatus.maintenance).length;

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

  // Met à jour le filtre de type
  void updateType(String? type) {
    if (type != null) {
      selectedType.value = type;
    }
  }
}
