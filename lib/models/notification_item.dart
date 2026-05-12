//lib/models/notification_item.dart
//(model)👉 represente la structure de la notification
//📦 Stocker les notifications
//🔄 Convertir JSON → objet
//🧠 Gérer facilement les données dans ton app Flutter
class NotificationItem {
  final String? id; // Often in v5, id can come as string if documentId is used, or int
  final String? documentId;
  final String? type; //Type de notification (ex: message, commande, alerte)
  final String title;
  final String message; //Contenu de la notification
  bool read; //Statut de lecture (lu ou non lu)
  final DateTime? readAt;//Date de lecture
  final String? relatedType;
  final int? relatedId;
  final String? actionUrl;//Lien à ouvrir quand on clique sur la notification
  final DateTime date; //Date de creation

//Constructeur
//Sert à créer une notification manuellement.
  NotificationItem({
    this.id,
    this.documentId,
    this.type,
    required this.title,
    required this.message,
    this.read = false, //par defaut la notification est non lue
    this.readAt,
    this.relatedType,
    this.relatedId,
    this.actionUrl,
    required this.date,
  });
//convertir json en NotificationItem
  factory NotificationItem.fromJson(Map<String, dynamic> json) { 
    // Gérer la structure imbriquée "attributes" de Strapi si elle existe
    final Map<String, dynamic> data = (json['attributes'] != null) ? json['attributes'] : json;

    return NotificationItem(
      id: json['id']?.toString(),
      documentId: json['documentId'] ?? json['document_id'],
      type: data['type'],
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      read: data['read'] == true,
      readAt: data['read_at'] != null ? DateTime.tryParse(data['read_at']) : null,
      relatedType: data['related_type'],
      relatedId: data['related_id'] is int ? data['related_id'] : int.tryParse(data['related_id']?.toString() ?? ''),
      actionUrl: data['action_url'],
      date: data['createdAt'] != null 
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}
