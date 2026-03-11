// ============================================
// Modèle Payment (Paiement et Facture)
// ============================================

import 'package:intl/intl.dart';

enum PaymentStatus { enAttente, paye, echoue, rembourse }

class Payment {
  final String id;
  final String? documentId;
  final double amount;
  final String paymentMethod;
  final PaymentStatus status;
  final String relatedType; // "Réservation", "Abonnement", etc.
  final String? transactionId;
  final String? paymentGateway;
  final DateTime? paidAt;
  final String? invoiceNumber;

  Payment({
    required this.id,
    this.documentId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.relatedType,
    this.transactionId,
    this.paymentGateway,
    this.paidAt,
    this.invoiceNumber,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      documentId: json['documentId']?.toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'Carte_en_ligne',
      status: _parseStatus(json['mystatus']),
      relatedType: json['related_type'] ?? 'Réservation',
      transactionId: json['transaction_id'],
      paymentGateway: json['payment_gateway'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']).toLocal() : null,
      invoiceNumber: json['invoice_number'],
    );
  }

  static PaymentStatus _parseStatus(String? status) {
    switch (status) {
      case 'Paye':
      case 'Payé':
        return PaymentStatus.paye;
      case 'Echoue':
      case 'Échoué':
        return PaymentStatus.echoue;
      case 'Rembourse':
      case 'Remboursé':
        return PaymentStatus.rembourse;
      case 'En_attente':
      default:
        return PaymentStatus.enAttente;
    }
  }

  String get statusString {
    switch (status) {
      case PaymentStatus.paye: return 'Payé';
      case PaymentStatus.echoue: return 'Échoué';
      case PaymentStatus.rembourse: return 'Remboursé';
      case PaymentStatus.enAttente: return 'En attente';
    }
  }

  String get formattedDate => paidAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(paidAt!) : 'Non payé';
}
