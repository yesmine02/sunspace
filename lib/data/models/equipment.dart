// ============================================
// Modèle Equipment (Équipement)
// Ce fichier définit la structure d'un équipement
// et comment convertir les données du serveur Strapi
// ============================================

// Les statuts possibles d'un équipement
enum EquipmentStatus { disponible, enMaintenance, enPanne }

class Equipment {
  final String id;              // Identifiant unique (numérique converti en String)
  final String? documentId;     // Identifiant Strapi utilisé pour modifier/supprimer
  final String name;            // Nom de l'équipement
  final String type;            // Type (ex: "Imprimante", "Écran", etc.)
  final String serialNumber;    // Numéro de série
  final EquipmentStatus status; // Statut actuel
  final String? spaceName;      // Nom de l'espace où se trouve l'équipement (optionnel)
  final String? description;    // Description détaillée (optionnel)
  final DateTime? purchaseDate; // Date d'achat (optionnel)
  final double? price;          // Prix d'achat (optionnel)
  final DateTime? warrantyExpiry; // Date d'expiration de la garantie (optionnel)
  final String? notes;          // Notes additionnelles (optionnel)

  // Constructeur — les champs "required" sont obligatoires
  Equipment({
    required this.id,
    this.documentId,
    required this.name,
    required this.type,
    required this.serialNumber,
    required this.status,
    this.spaceName,
    this.description,
    this.purchaseDate,
    this.price,
    this.warrantyExpiry,
    this.notes,
  });

  // Convertit le texte du statut reçu du serveur Strapi en enum EquipmentStatus
  // Exemple : "En maintenance" → EquipmentStatus.enMaintenance
  static EquipmentStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return EquipmentStatus.disponible;
    switch (statusStr) {
      case 'Disponible':
        return EquipmentStatus.disponible;
      case 'En maintenance':
      case 'En_maintenance':
        return EquipmentStatus.enMaintenance;
      case 'En panne':
      case 'En_panne':
        return EquipmentStatus.enPanne;
      default:
        return EquipmentStatus.disponible;
    }
  }

  // Crée un objet Equipment à partir du JSON reçu du serveur
  // Les noms de champs du serveur sont différents de ceux du modèle :
  //   - "serial_number" sur le serveur → "serialNumber" dans le modèle
  //   - "mystatus" sur le serveur → "status" dans le modèle
  //   - "purchase_price" sur le serveur → "price" dans le modèle
  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'].toString(),                    // Le serveur envoie un int, on le convertit en String
      documentId: json['documentId']?.toString(),   // Utilisé pour PUT/DELETE sur Strapi
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      serialNumber: (json['serial_number'] ?? json['serialNumber'] ?? '').toString(),  // serial_number = nom Strapi
      status: _parseStatus(json['mystatus'] ?? json['status']),  // mystatus = nom Strapi
      spaceName: json['spaceName']?.toString(),
      description: json['description']?.toString(),
      purchaseDate: _parseDate(json['purchase_date'] ?? json['purchaseDate']),    // purchase_date = nom Strapi
      price: (json['purchase_price'] ?? json['price'])?.toDouble(),              // purchase_price = nom Strapi
      warrantyExpiry: _parseDate(json['warranty_expiry'] ?? json['warrantyExpiry']),  // warranty_expiry = nom Strapi
      notes: json['notes']?.toString(),
    );
  }

  // Convertit une valeur en DateTime de manière sécurisée
  // Retourne null si la valeur est invalide ou absente
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  // Convertit l'objet Equipment en JSON (pour le cache local)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'name': name,
      'type': type,
      'serial_number': serialNumber,
      'mystatus': statusString,
      'spaceName': spaceName,
      'description': description,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': price,
      'warranty_expiry': warrantyExpiry?.toIso8601String(),
      'notes': notes,
    };
  }

  // Convertit l'objet en JSON pour envoyer vers le serveur Strapi (POST ou PUT)
  // Le serveur attend le format : { "data": { ... } }
  // On n'envoie PAS id et documentId car le serveur les gère lui-même
  Map<String, dynamic> toStrapiJson() {
    return {
      'data': {
        'name': name,
        'type': type,
        'serial_number': serialNumber,
        'mystatus': statusString,
        'description': description,
        'purchase_date': purchaseDate?.toIso8601String(),
        'purchase_price': price,
        'warranty_expiry': warrantyExpiry?.toIso8601String(),
        'notes': notes ?? '',
      }
    };
  }

  // Convertit l'enum EquipmentStatus en texte lisible (pour l'affichage et le serveur)
  String get statusString {
    switch (status) {
      case EquipmentStatus.disponible:
        return 'Disponible';
      case EquipmentStatus.enMaintenance:
        return 'En_maintenance';
      case EquipmentStatus.enPanne:
        return 'En_panne';
    }
  }
}
