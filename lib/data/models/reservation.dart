// ============================================
// Modèle Reservation (Réservation d'espace)
// ============================================
//représenter une réservation (ses infos comme date, espace, statut, paiement…)
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

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
  final int numberOfPeople;
  final String? organizerName;
  final User? user; // Objet User complet si peuplé
  final int? userId; // ID utilisateur extrait de manière robuste

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
    this.numberOfPeople = 1,
    this.organizerName,
    this.user,
    this.userId,
  });
//convertit le JSON de Strapi en objet Reservation
  factory Reservation.fromJson(Map<String, dynamic> json) {
    try {
      // Dans Strapi v5 avec populate, l'objet est souvent à la racine du JSON data ou dans attributes
      final attrs = json; 
      
      // Parse Space
      String? sName;
      if (attrs['space'] != null) { //si l’espace existe
        if (attrs['space'] is Map) { //Si space est un objet complet
          sName = attrs['space']['name']; //prend le nom de l’espace
        } else {
          sName = "Espace #${attrs['space']}"; //sinon affiche juste Espace + ID
        }
      }

      // Parse User de manière robuste
      User? uObj;
      int? uId;
      if (attrs['user'] != null) {
        if (attrs['user'] is Map) {
          final userMap = attrs['user'] as Map<String, dynamic>;
          // Support du format Strapi v4 imbriqué { data: { id: ..., attributes: ... } }
          if (userMap.containsKey('data') && userMap['data'] != null) {
            final dataMap = userMap['data'];
            if (dataMap is Map) {
              final idValue = dataMap['id'];
              uId = int.tryParse(idValue.toString());
              final attrsMap = dataMap['attributes'];
              if (attrsMap is Map) {
                final fullMap = <String, dynamic>{
                  'id': uId,
                  ...Map<String, dynamic>.from(attrsMap)
                };
                uObj = User.fromJson(fullMap);
              } else {
                uObj = User.fromJson(Map<String, dynamic>.from(dataMap));
              }
            }
          } else {
            // Format Strapi v5 à plat
            uObj = User.fromJson(userMap);
            uId = uObj.id;
          }
        } else {
          // Format non-peuplé (juste l'ID numérique de l'utilisateur)
          uId = int.tryParse(attrs['user'].toString());
        }
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
        organizerName: attrs['organizer_name'],
        numberOfPeople: int.tryParse(attrs['attendees']?.toString() ?? '1') ?? 1,
        user: uObj,
        userId: uId ?? uObj?.id,
      );
    } catch (e) {
      debugPrint('❌ Reservation.fromJson error: $e | JSON: $json');
      rethrow;
    }
  }
//convertit le statut texte du JSON en statut que l’application comprend.
  static ReservationStatus _parseStatus(String? status) => parseStatusFromString(status);

  static ReservationStatus parseStatusFromString(String? status) {
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
//prend le statut de l’objet Reservation et le transforme en texte lisible.
  String get statusString {
    switch (status) {
      case ReservationStatus.confirmee: return 'Confirmée';
      case ReservationStatus.terminee: return 'Terminée';
      case ReservationStatus.annulee: return 'Refusée';
      case ReservationStatus.enAttente: return 'En attente';
    }
  }

  String get formattedDate => DateFormat('dd/MM/yyyy').format(startDateTime);
  String get formattedTime => "${DateFormat('HH:mm').format(startDateTime)} - ${DateFormat('HH:mm').format(endDateTime)}";

  bool get isSessionReservation => purpose?.startsWith('Session de cours') ?? false;
}
