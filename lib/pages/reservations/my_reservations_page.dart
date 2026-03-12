// ============================================
// Page Mes Réservations (Professionnel)
// Liste les réservations passées et futures
// ============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/reservation.dart';

class MyReservationsPage extends StatelessWidget {
  const MyReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BookingController());
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    final String username = user != null ? (user['username'] ?? 'Utilisateur') : 'Utilisateur';
    
    // Charger au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchMyReservations();
    });

    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec Illustration et Bienvenue
            _buildHeader(context, username, isMobile, controller),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cartes de statistiques
                  _buildStatsCards(controller, isMobile),
                  const SizedBox(height: 48),

                  // Section Titre + Recherche
                  _buildSectionHeader(controller, isMobile),
                  const SizedBox(height: 24),

                  // Liste des réservations
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final filteredList = controller.filteredReservations;
                    if (filteredList.isEmpty) {
                      return _buildEmptyState(isMobile);
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final res = filteredList[index];
                        return _buildReservationCard(context, res, isMobile);
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String username, bool isMobile, BookingController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 40, 
        isMobile ? 40 : 60, 
        isMobile ? 16 : 40, 
        isMobile ? 24 : 40
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Illustration de fond (Calendrier discret)
          if (!isMobile)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.calendar_month_rounded, size: 200, color: Colors.blue.shade900),
              ),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Espace Personnel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF007AFF), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ESPACE PERSONNEL',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Message de Bienvenue
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 44,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                  ),
                  children: [
                    const TextSpan(text: 'Bienvenue, '),
                    TextSpan(
                      text: username,
                      style: const TextStyle(color: Color(0xFF007AFF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Retrouvez ici toutes vos réservations et gérez votre planning en toute simplicité.',
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: isMobile ? 14 : 18,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Boutons d'action
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => controller.fetchMyReservations(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Actualiser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.toNamed('/book-space'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Nouvelle Réservation', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BookingController controller, bool isMobile) {
    return Obx(() {
      final total = controller.reservations.length;
      final confirmes = controller.reservations.where((r) => r.status == ReservationStatus.confirmee).length;
      final enAttente = controller.reservations.where((r) => r.status == ReservationStatus.enAttente).length;

      return isMobile 
        ? Column(
            children: [
              _buildStatCard('TOTAL', total.toString(), Icons.calendar_today_rounded, const Color(0xFFF8FAFC), isMobile),
              const SizedBox(height: 12),
              _buildStatCard('CONFIRMÉES', confirmes.toString(), Icons.check_circle_outline_rounded, const Color(0xFFF0FDF4), isMobile),
              const SizedBox(height: 12),
              _buildStatCard('EN ATTENTE', enAttente.toString(), Icons.access_time_rounded, const Color(0xFFFFFBEB), isMobile),
            ],
          )
        : Row(
            children: [
              Expanded(child: _buildStatCard('TOTAL', total.toString(), Icons.calendar_today_rounded, const Color(0xFFF8FAFC), isMobile)),
              const SizedBox(width: 20),
              Expanded(child: _buildStatCard('CONFIRMÉES', confirmes.toString(), Icons.check_circle_outline_rounded, const Color(0xFFF0FDF4), isMobile)),
              const SizedBox(width: 20),
              Expanded(child: _buildStatCard('EN ATTENTE', enAttente.toString(), Icons.access_time_rounded, const Color(0xFFFFFBEB), isMobile)),
            ],
          );
    });
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BookingController controller, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(),
          const SizedBox(height: 16),
          _buildSearchBar(controller, isMobile),
        ],
      );
    }

    return Row(
      children: [
        _buildSectionTitle(),
        const SizedBox(width: 48),
        Expanded(child: _buildSearchBar(controller, isMobile)),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'MES RÉSERVATIONS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BookingController controller, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        onChanged: controller.updateSearchQuery,
        style: TextStyle(fontSize: isMobile ? 14 : 15),
        decoration: InputDecoration(
          hintText: "Rechercher un espace...",
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.search, color: Color(0xFF94A3B8), size: 22),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
        ),
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, Reservation res, bool isMobile) {
    final Color statusColor = _getStatusColor(res.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showReservationDetails(context, res),
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barre latérale de couleur selon le statut
              Container(width: 6, decoration: BoxDecoration(color: statusColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Icône selon type ou défaut
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF007AFF))),
                      const SizedBox(width: 16),
                      
                      // Infos principales
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(res.spaceName ?? "Espace", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            Text(res.formattedDate, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                            Text(res.formattedTime, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ],
                        ),
                      ),
                      
                      if (!isMobile) ...[
                        // Montant
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Montant total", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text("${res.totalAmount.toStringAsFixed(2)} TND", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(width: 32),
                      ],
                      
                      // Statut Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(res.statusString, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReservationDetails(BuildContext context, Reservation res) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Détails de la réservation", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 32),
              
              _detailRow(Icons.business_rounded, "Espace", res.spaceName ?? "Non spécifié"),
              _detailRow(Icons.calendar_today_rounded, "Date", res.formattedDate),
              _detailRow(Icons.access_time_rounded, "Horaire", res.formattedTime),
              _detailRow(Icons.info_outline_rounded, "Statut", res.statusString, color: _getStatusColor(res.status)),
              _detailRow(Icons.payment_rounded, "Montant total", "${res.totalAmount.toStringAsFixed(2)} TND", isBold: true),
              
              if (res.notes != null && res.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("Services & Notes :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Text(res.notes!, style: const TextStyle(fontSize: 14)),
                ),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Fermer", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text("$label : ", style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color ?? const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Aucune de vos prochaines sessions ne correspond à votre recherche.",
              style: TextStyle(
                fontSize: isMobile ? 14 : 16, 
                color: const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmee: return const Color(0xFF166534);
      case ReservationStatus.terminee: return const Color(0xFF1E293B);
      case ReservationStatus.annulee: return const Color(0xFF991B1B);
      case ReservationStatus.enAttente: return const Color(0xFF9A3412);
    }
  }
}
