// ============================================
// Modèle Reservation (Réservation d'espace)
// ============================================

import 'package:intl/intl.dart';

import 'user.dart';

enum ReservationStatus { enAttente, confirmee, terminee, annulee }

class Reservation {
  final String id;
  final String? documentId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final ReservationStatus status;
  final String? purpose;
  final String paymentStatus;
  final String paymentMethod;
  final double totalAmount;
  final String? notes;
  final String? spaceName;
  final User? user; // Objet User complet si peuplé

  Reservation({
    required this.id,
    this.documentId,
    required this.startDateTime,
    required this.endDateTime,
    required this.status,
    this.purpose,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.totalAmount,
    this.notes,
    this.spaceName,
    this.user,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    // Dans Strapi v5 avec populate, l'objet est souvent à la racine du JSON data ou dans attributes
    final attrs = json; 
    
    // Parse Space
    String? sName;
    if (attrs['space'] != null) {
      if (attrs['space'] is Map) {
        sName = attrs['space']['name'];
      } else {
        sName = "Espace #${attrs['space']}";
      }
    }

    // Parse User
    User? uObj;
    if (attrs['user'] != null && attrs['user'] is Map) {
      uObj = User.fromJson(attrs['user']);
    }

    return Reservation(
      id: json['id'].toString(),
      documentId: json['documentId']?.toString(),
      startDateTime: DateTime.parse(attrs['start_datetime']).toLocal(),
      endDateTime: DateTime.parse(attrs['end_datetime']).toLocal(),
      status: _parseStatus(attrs['mystatus']),
      purpose: attrs['purpose'],
      paymentStatus: attrs['payment_status'] ?? 'En_attente',
      paymentMethod: attrs['payment_method'] ?? 'Carte_en_ligne',
      totalAmount: (attrs['total_amount'] ?? 0).toDouble(),
      notes: attrs['notes'],
      spaceName: sName,
      user: uObj,
    );
  }

  static ReservationStatus _parseStatus(String? status) {
    switch (status) {
      case 'Confirmee':
      case 'Confirmée':
        return ReservationStatus.confirmee;
      case 'Terminee':
      case 'Terminée':
        return ReservationStatus.terminee;
      case 'Annulee':
      case 'Annulée':
        return ReservationStatus.annulee;
      case 'En_attente':
      default:
        return ReservationStatus.enAttente;
    }
  }

  String get statusString {
    switch (status) {
      case ReservationStatus.confirmee: return 'Confirmée';
      case ReservationStatus.terminee: return 'Terminée';
      case ReservationStatus.annulee: return 'Annulée';
      case ReservationStatus.enAttente: return 'En attente';
    }
  }

  String get formattedDate => DateFormat('dd/MM/yyyy').format(startDateTime);
  String get formattedTime => "${DateFormat('HH:mm').format(startDateTime)} - ${DateFormat('HH:mm').format(endDateTime)}";
}
