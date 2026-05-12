// ============================================
// Modèle Space (Espace)
// Ce fichier définit la structure d'un espace
// et comment convertir les données du serveur Strapi
// ============================================

// Les statuts possibles d'un espace
enum SpaceStatus { disponible, occupe, maintenance }

// Les types possibles d'un espace
// Les types possibles d'un espace (mis à jour selon Strapi)
enum SpaceType { 
  espaceDeTravail, 
  salleDeReunion, 
  salleDeFormation, 
  espaceCreatif, 
  espaceCollaboratif, 
  bureauPrive, 
  salleDeConference, 
  laboratoire, 
  espaceDetente, 
  cuisine, 
  securite, 
  accueil, 
  sanitaires,
  autre 
}

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
  static SpaceType _parseType(String? typeStr) {
    if (typeStr == null) return SpaceType.autre;
    switch (typeStr) {
      case 'Espace de Travail': return SpaceType.espaceDeTravail;
      case 'Salle de Réunion': return SpaceType.salleDeReunion;
      case 'Salle de Formation': return SpaceType.salleDeFormation;
      case 'Espace Créatif': return SpaceType.espaceCreatif;
      case 'Espace Collaboratif': return SpaceType.espaceCollaboratif;
      case 'Bureau Privé': return SpaceType.bureauPrive;
      case 'Salle de Conférence': return SpaceType.salleDeConference;
      case 'Laboratoire': return SpaceType.laboratoire;
      case 'Espace Détente': return SpaceType.espaceDetente;
      case 'Cuisine': return SpaceType.cuisine;
      case 'Sécurité': return SpaceType.securite;
      case 'Accueil': return SpaceType.accueil;
      case 'Sanitaires': return SpaceType.sanitaires;
      default: return SpaceType.autre;
    }
  }

  // Convertit le texte du statut reçu du serveur Strapi en enum SpaceStatus
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
      default:
        return SpaceStatus.disponible;
    }
  }

  // Crée un objet Space à partir du JSON reçu du serveur
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

  // Convertit l'enum SpaceType en texte lisible (exactement comme Strapi l'attend)
  String get typeString {
    switch (type) {
      case SpaceType.espaceDeTravail: return 'Espace de Travail';
      case SpaceType.salleDeReunion: return 'Salle de Réunion';
      case SpaceType.salleDeFormation: return 'Salle de Formation';
      case SpaceType.espaceCreatif: return 'Espace Créatif';
      case SpaceType.espaceCollaboratif: return 'Espace Collaboratif';
      case SpaceType.bureauPrive: return 'Bureau Privé';
      case SpaceType.salleDeConference: return 'Salle de Conférence';
      case SpaceType.laboratoire: return 'Laboratoire';
      case SpaceType.espaceDetente: return 'Espace Détente';
      case SpaceType.cuisine: return 'Cuisine';
      case SpaceType.securite: return 'Sécurité';
      case SpaceType.accueil: return 'Accueil';
      case SpaceType.sanitaires: return 'Sanitaires';
      case SpaceType.autre: return 'Autre';
    }
  }

  // Convertit l'enum SpaceStatus en texte lisible
  String get statusString {
    switch (status) {
      case SpaceStatus.disponible:
        return 'Disponible';
      case SpaceStatus.occupe:
        return 'Occupé';
      case SpaceStatus.maintenance:
        return 'En_maintenance';
    }
  }
}
