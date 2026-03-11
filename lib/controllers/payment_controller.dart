// ============================================
// Controller Payment (Gestion des paiements et abonnements)
// ============================================

import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/auth_controller.dart';
import '../data/models/payment.dart';

class PaymentController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  static const String _baseUrl = 'http://193.111.250.244:3046/api/payments';

  // États réactifs
  final RxList<Payment> payments = <Payment>[].obs;
  final RxBool isLoading = false.obs;
  
  // Abonnement (Simulation pour l'instant via le profil utilisateur ou variable)
  final RxString currentPlan = 'Ponctuel'.obs; // 'Ponctuel' ou 'Mensuel'

  @override
  void onInit() {
    super.onInit();
    fetchMyPayments();
  }

  // 🔹 CHARGEMENT DE L'HISTORIQUE DES PAIEMENTS
  Future<void> fetchMyPayments() async {
    isLoading.value = true;
    final client = http.Client();
    try {
      final token = await _authController.getToken();
      final user = _authController.currentUser.value;
      
      if (token == null || user == null) return;

      final userId = user['id'];
      // Strapi v5 filter: filters[user][id][$eq]=userId
      final url = Uri.parse('$_baseUrl?filters[user][id][\$eq]=$userId&sort=paid_at:desc');

      final response = await client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('data')) {
          final List<dynamic> list = data['data'];
          payments.assignAll(list.map((item) => Payment.fromJson(item)).toList());
        }
      }
    } catch (e) {
      print("Erreur fetch payments: $e");
    } finally {
      client.close();
      isLoading.value = false;
    }
  }

  // 🔹 CHANGER DE PLAN (Simulation)
  void updatePlan(String plan) {
    currentPlan.value = plan;
    Get.snackbar(
      'Plan mis à jour',
      'Vous êtes désormais sur le plan $plan.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
