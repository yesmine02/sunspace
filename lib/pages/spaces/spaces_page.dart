// ===============================================
// Page de Liste des Espaces (SpacesPage)
// Affiche tous les espaces sous forme de tableau.
// Comprend des filtres de recherche et des statistiques.
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/spaces_controller.dart';
import '../../data/models/space.dart';
import '../../routing/app_routes.dart';

class SpacesPage extends StatelessWidget {
  const SpacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialisation/Récupération du contrôleur
    final controller = Get.put(SpacesController());
    
    // Détection du mode mobile pour le design adaptatif
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    final double horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section En-tête : Titre et Bouton "Nouvel Espace"
            isMobile 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderTitle(context),
                    const SizedBox(height: 16),
                    _buildAddButton(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderTitle(context),
                    _buildAddButton(),
                  ],
                ),
            const SizedBox(height: 32),

            // Section Recherche et Filtrage par statut
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: isMobile 
                ? Column(
                    children: [
                      _buildSearchField(controller),
                      const SizedBox(height: 12),
                      _buildStatusFilter(controller),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 3, child: _buildSearchField(controller)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatusFilter(controller)),
                    ],
                  ),
            ),
            const SizedBox(height: 24),

            // Section Tableau des Espaces
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Permet le défilement horizontal sur mobile
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.grey[100],
                    ),
                    child: Obx(() => DataTable(
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFFDFDFD)),
                          dataRowHeight: 64,
                          horizontalMargin: 16,
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: Text('Espace', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Localisation', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Capacité', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Tarif/h', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Réservations', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: controller.filteredSpaces.map((space) {
                            return DataRow(cells: [
                              DataCell(Text(space.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(space.typeString, style: TextStyle(color: Colors.grey[600]))),
                              DataCell(Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(space.location, style: TextStyle(color: Colors.grey[600])),
                                ],
                              )),
                              DataCell(Row(
                                children: [
                                  const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${space.capacity}', style: TextStyle(color: Colors.grey[600])),
                                ],
                              )),
                              DataCell(Row(
                                children: [
                                  const Text('TND ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  Text(space.hourlyPrice > 0 ? '${space.hourlyPrice.toInt()}' : '', style: const TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              )),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Text('${space.reservations}', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                              )),
                              DataCell(_buildStatusBadge(space.status)),
                              DataCell(Row(
                                children: [
                                  // Visualiser
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.grey),
                                    onPressed: () => Get.toNamed(AppRoutes.VIEW_SPACE, arguments: space),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  // Modifier
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                                    onPressed: () => Get.toNamed(AppRoutes.EDIT_SPACE, arguments: space),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  // Supprimer
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                    onPressed: () {
                                      Get.defaultDialog(
                                        title: "Supprimer l'espace",
                                        middleText: "Êtes-vous sûr de vouloir supprimer l'espace '${space.name}' ?",
                                        textConfirm: "Supprimer",
                                        textCancel: "Annuler",
                                        confirmTextColor: Colors.white,
                                        buttonColor: Colors.red,
                                        onConfirm: () {
                                          controller.deleteSpace(space.id);
                                          Get.back();
                                        },
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        )),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Section Cartes de Statistiques
            _buildResponsiveStatistics(context, controller),
          ],
        ),
      ),
    );
  }

  // Widget : Titre principal de la page
  Widget _buildHeaderTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.business_rounded, color: Colors.blue, size: 32),
            const SizedBox(width: 12),
            Text(
              'Gestion des espaces',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Gérez vos espaces de coworking',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      ],
    );
  }

  // Widget : Bouton pour ajouter un espace
  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => Get.toNamed(AppRoutes.CREATE_SPACE),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Nouvel espace'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Widget : Champ de recherche par nom
  Widget _buildSearchField(SpacesController controller) {
    return TextField(
      onChanged: controller.updateSearch,
      decoration: InputDecoration(
        hintText: 'Rechercher un espace...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  // Widget : Filtre de statut (DropDown)
  Widget _buildStatusFilter(SpacesController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedStatus.value,
          isExpanded: true,
          items: ['Tous les statuts', 'Disponible', 'Occupé', 'En_maintenance', 'En_panne']
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
              .toList(),
          onChanged: controller.updateStatus,
        ),
      ),
    ));
  }

  // Widget : Grille de statistiques (Total, Dispo, Maintenance, etc.)
  Widget _buildResponsiveStatistics(BuildContext context, SpacesController controller) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    
    return Obx(() {
      final total = controller.spaces.length;
      final available = controller.availableSpaces;
      final broken = controller.brokenSpaces;
      final maintenance = controller.maintenanceSpaces;

      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          _buildStatCard('Total', '$total', Colors.black, isMobile),
          _buildStatCard('Disponible', '$available', const Color(0xFF166534), isMobile),
          _buildStatCard('En panne', '$broken', const Color(0xFF991B1B), isMobile),
          _buildStatCard('En maintenance', '$maintenance', const Color(0xFF854D0E), isMobile),
        ],
      );
    });
  }

  // Widget : Carte individuelle pour un chiffre statistique
  Widget _buildStatCard(String label, String value, Color valueColor, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // Widget : Badge de statut colore (Disponible, Occupé, etc.)
  Widget _buildStatusBadge(SpaceStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case SpaceStatus.disponible:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        label = 'Disponible';
        break;
      case SpaceStatus.occupe:
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFF854D0E);
        label = 'Occupé';
        break;
      case SpaceStatus.maintenance:
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFF854D0E);
        label = 'En_maintenance';
        break;
      case SpaceStatus.enPanne:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        label = 'En_panne';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
