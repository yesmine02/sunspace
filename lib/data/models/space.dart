// ============================================
// Modèle Space (Espace)
// Ce fichier définit la structure d'un espace
// et comment convertir les données du serveur Strapi
// ============================================

// Les statuts possibles d'un espace
enum SpaceStatus { disponible, occupe, enPanne, maintenance }

// Les types possibles d'un espace
enum SpaceType { bureau, posteBureautique, salleDeReunion, cafe, projecteur, micro, autre }

class Space {
  final String id;             // Identifiant unique (numérique converti en String)
  final String? documentId;    // Identifiant Strapi utilisé pour modifier/supprimer
  final String name;           // Nom de l'espace
  final String slug;           // Slug pour le plan interactif (ex: "espace1")
  final SpaceType type;        // Type de l'espace (bureau, salle, etc.)
  final String location;       // Localisation (ex: "Étage 2")
  final int capacity;          // Nombre de personnes max
  final double hourlyPrice;    // Tarif par heure (en TND)
  final double dailyPrice;     // Tarif par jour (en TND)
  final double monthlyPrice;   // Tarif par mois (en TND)
  final int reservations;      // Nombre de réservations
  final SpaceStatus status;    // Statut actuel de l'espace
  final String description;    // Description détaillée

  // Constructeur — les champs "required" sont obligatoires
  Space({
    required this.id,
    this.documentId,
    required this.name,
    required this.slug,
    required this.type,
    required this.location,
    required this.capacity,
    required this.hourlyPrice,
    required this.dailyPrice,
    required this.monthlyPrice,
    this.reservations = 0,
    required this.status,
    this.description = '',
  });

  // Convertit le texte du type reçu du serveur Strapi en enum SpaceType
  // Exemple : "Bureau" → SpaceType.bureau
  static SpaceType _parseType(String? typeStr) {
    if (typeStr == null) return SpaceType.autre;
    switch (typeStr) {
      case 'Bureau':
        return SpaceType.bureau;
      case 'Poste_bureatique':
        return SpaceType.posteBureautique;
      case 'Salle_reunion':
        return SpaceType.salleDeReunion;
      case 'Cafe':
        return SpaceType.cafe;
      case 'Projecteur':
        return SpaceType.projecteur;
      case 'Micro':
        return SpaceType.micro;
      default:
        return SpaceType.autre;
    }
  }

  // Convertit le texte du statut reçu du serveur Strapi en enum SpaceStatus
  // Exemple : "Disponible" → SpaceStatus.disponible
  static SpaceStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return SpaceStatus.disponible;
    switch (statusStr) {
      case 'Disponible':
        return SpaceStatus.disponible;
      case 'Occupé':
      case 'Occupe':
        return SpaceStatus.occupe;
      case 'En_maintenance':
        return SpaceStatus.maintenance;
      case 'En_panne':
        return SpaceStatus.enPanne;
      default:
        return SpaceStatus.disponible;
    }
  }

  // Crée un objet Space à partir du JSON reçu du serveur
  // Les noms de champs du serveur (snake_case) sont différents de ceux du modèle (camelCase)
  // Exemple : "hourly_rate" sur le serveur → "hourlyPrice" dans le modèle
  factory Space.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'].toString();
      final docId = json['documentId']?.toString();
      final name = json['name']?.toString() ?? '';
      final slug = json['slug']?.toString() ?? name.toLowerCase().replaceAll(' ', '');
      final typeStr = json['type']?.toString();
      final location = json['location']?.toString() ?? '';
      
      final capacityValue = json['capacity'];
      final capacity = capacityValue is int ? capacityValue : int.tryParse(capacityValue?.toString() ?? '0') ?? 0;
      
      final hPrice = (json['hourly_rate'] ?? json['hourlyPrice'] ?? 0).toDouble();
      final dPrice = (json['daily_rate'] ?? json['dailyPrice'] ?? 0).toDouble();
      final mPrice = (json['monthly_rate'] ?? json['monthlyPrice'] ?? 0).toDouble();
      
      final resValue = json['reservations'];
      final res = resValue is int ? resValue : int.tryParse(resValue?.toString() ?? '0') ?? 0;
      
      final statusStr = (json['availability_status'] ?? json['status'])?.toString();
      final desc = json['description']?.toString() ?? '';

      return Space(
        id: id,
        documentId: docId,
        name: name,
        slug: slug,
        type: _parseType(typeStr),
        location: location,
        capacity: capacity,
        hourlyPrice: hPrice,
        dailyPrice: dPrice,
        monthlyPrice: mPrice,
        reservations: res,
        status: _parseStatus(statusStr),
        description: desc,
      );
    } catch (e) {
      print("Erreur fatale dans Space.fromJson: $e sur le JSON: $json");
      rethrow;
    }
  }

  // Convertit l'objet Space en JSON (pour le cache local)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'name': name,
      'slug': slug,
      'type': typeString,
      'location': location,
      'capacity': capacity,
      'hourly_rate': hourlyPrice,
      'daily_rate': dailyPrice,
      'monthly_rate': monthlyPrice,
      'reservations': reservations,
      'availability_status': statusString,
      'description': description,
    };
  }

  // Convertit l'objet en JSON pour envoyer vers le serveur Strapi (POST ou PUT)
  // Le serveur attend le format : { "data": { ... } }
  // On n'envoie PAS id et documentId car le serveur les gère lui-même
  Map<String, dynamic> toStrapiJson() {
    return {
      'data': {
        'name': name,
        'slug': slug,
        'type': typeString,
        'location': location,
        'capacity': capacity,
        'hourly_rate': hourlyPrice,
        'daily_rate': dailyPrice,
        'monthly_rate': monthlyPrice,
        'availability_status': statusString,
        'description': description,
      }
    };
  }

  // Convertit l'enum SpaceType en texte lisible (pour l'affichage et le serveur)
  String get typeString {
    switch (type) {
      case SpaceType.bureau:
        return 'Bureau';
      case SpaceType.posteBureautique:
        return 'Poste_bureatique';
      case SpaceType.salleDeReunion:
        return 'Salle_reunion';
      case SpaceType.cafe:
        return 'Cafe';
      case SpaceType.projecteur:
        return 'Projecteur';
      case SpaceType.micro:
        return 'Micro';
      case SpaceType.autre:
        return 'Autre';
    }
  }

  // Convertit l'enum SpaceStatus en texte lisible (pour l'affichage et le serveur)
  String get statusString {
    switch (status) {
      case SpaceStatus.disponible:
        return 'Disponible';
      case SpaceStatus.occupe:
        return 'Occupé';
      case SpaceStatus.maintenance:
        return 'En_maintenance';
      case SpaceStatus.enPanne:
        return 'En_panne';
    }
  }
}
