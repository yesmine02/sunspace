// ===============================================
// Page Détails de l'Espace (ViewSpacePage)
// Affiche toutes les informations détaillées d'un espace sélectionné.
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/space.dart';
import '../../routing/app_routes.dart';

class ViewSpacePage extends StatelessWidget {
  const ViewSpacePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération de l'objet Space passé via Get.toNamed
    final Space space = Get.arguments as Space;
    
    // Détection du mode mobile
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Fond gris clair légèrement bleuté
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 40.0, 
          vertical: isMobile ? 24.0 : 32.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section En-tête : Nom, badges et bouton modifier
            _buildHeader(context, space, isMobile),
            const SizedBox(height: 32),

            isMobile 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGeneralInfo(space, isMobile),
                    const SizedBox(height: 24),
                    _buildPricingCard(space),
                    const SizedBox(height: 24),
                    _buildSystemInfoCard(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colonne de gauche : Informations générales et Description
                    Expanded(
                      flex: 2,
                      child: _buildGeneralInfo(space, false),
                    ),
                    const SizedBox(width: 24),
                    // Colonne de droite : Tarification & Infos Système
                    Expanded(
                      child: Column(
                        children: [
                          _buildPricingCard(space),
                          const SizedBox(height: 24),
                          _buildSystemInfoCard(),
                        ],
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  // Widget : En-tête de la page
  Widget _buildHeader(BuildContext context, Space space, bool isMobile) {
    return isMobile 
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () => Get.back(),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        space.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Type et Statut
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTypeBadge(space.typeString),
                          _buildStatusBadge(space.status),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bouton Modifier (icône seule sur mobile)
                ElevatedButton(
                  onPressed: () => Get.toNamed(AppRoutes.EDIT_SPACE, arguments: space),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.edit, size: 20),
                ),
              ],
            ),
          ],
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.grey),
                  onPressed: () => Get.back(),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeBadge(space.typeString),
                        const SizedBox(width: 8),
                        _buildStatusBadge(space.status),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Bouton Modifier
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.EDIT_SPACE, arguments: space),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Modifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        );
  }

  // Widget : Badge affichant le type d'espace
  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        type,
        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Widget : Badge affichant le statut (Disponible, Occupé, etc.)
  Widget _buildStatusBadge(SpaceStatus status) {
    Color bgColor;
    Color iconColor;
    String label;

    switch (status) {
      case SpaceStatus.disponible:
        bgColor = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF166534);
        label = 'Disponible';
        break;
      case SpaceStatus.occupe:
        bgColor = const Color(0xFFFEF9C3);
        iconColor = const Color(0xFF854D0E);
        label = 'Occupé';
        break;
      case SpaceStatus.maintenance:
        bgColor = const Color(0xFFFEF9C3);
        iconColor = const Color(0xFF854D0E);
        label = 'En maintenance';
        break;
      case SpaceStatus.enPanne:
        bgColor = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFF991B1B);
        label = 'En panne';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: iconColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Widget : Carte des infos générales (Localisation, Capacité)
  Widget _buildGeneralInfo(Space space, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations générales',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          isMobile 
            ? Column(
                children: [
                  _buildInfoSquare(
                    icon: Icons.location_on_outlined,
                    title: 'Localisation',
                    value: space.location,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSquare(
                    icon: Icons.people_outline,
                    title: 'Capacité',
                    value: '${space.capacity} personnes',
                    isMobile: isMobile,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildInfoSquare(
                      icon: Icons.location_on_outlined,
                      title: 'Localisation',
                      value: space.location,
                      isMobile: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoSquare(
                      icon: Icons.people_outline,
                      title: 'Capacité',
                      value: '${space.capacity} personnes',
                      isMobile: false,
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 32),
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            space.description.isNotEmpty 
                ? space.description 
                : 'Aucune description disponible pour cet espace.',
            style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // Widget : Petit carré d'information combinant une icône, un titre et une valeur
  Widget _buildInfoSquare({required IconData icon, required String title, required String value, required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue, size: isMobile ? 20 : 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget : Carte affichant les différents tarifs (Heure, Jour, Mois)
  Widget _buildPricingCard(Space space) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildPricingRow('Par Heure', space.hourlyPrice),
          const SizedBox(height: 12),
          _buildPricingRow('Par Jour', space.dailyPrice),
          const SizedBox(height: 12),
          _buildPricingRow('Par Mois', space.monthlyPrice),
        ],
      ),
    );
  }

  // Widget : Ligne pour un tarif spécifique (label + prix en TND)
  Widget _buildPricingRow(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.blueGrey, fontWeight: FontWeight.w500),
          ),
          Text(
            '${amount.toInt()} TND',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  // Widget : Carte d'informations système (Dates de création/mise à jour)
  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations système',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSystemRow(Icons.calendar_today_outlined, 'Créé le 11/02/2026'),
          const SizedBox(height: 16),
          _buildSystemRow(Icons.history, 'Mis à jour le 11/02/2026'),
        ],
      ),
    );
  }

  // Widget : Ligne générique pour info système (icône + texte)
  Widget _buildSystemRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }
}
