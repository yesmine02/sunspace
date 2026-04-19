// ===============================================
// Page de Liste des Équipements (EquipmentsPage)
// Affiche tous les équipements sous forme de tableau sur desktop
// et sous forme de cartes sur mobile.
// Permet d'ajouter, modifier ou supprimer des équipements.
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/equipments_controller.dart';
import '../../data/models/equipment.dart';
import './widgets/add_equipment_dialog.dart';
import './widgets/edit_equipment_dialog.dart';

class EquipmentsPage extends StatelessWidget {
  const EquipmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialisation du contrôleur
    final controller = Get.put(EquipmentsController());
    
    // Adaptabilité du design
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    final double horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Titre et bouton d'ajout
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

            // Barre de recherche et Filtre de statut
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

            // Tableau des équipements (DataTable sur Desktop, Cards sur Mobile)
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()));
              }

              if (controller.filteredEquipments.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(50), child: Text('Aucun équipement trouvé')));
              }

              if (isMobile) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.filteredEquipments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildEquipmentCard(context, controller.filteredEquipments[index], controller),
                );
              }

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.grey[100],
                      ),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(const Color(0xFFFDFDFD)),
                        dataRowHeight: 72,
                        horizontalMargin: 16,
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Numéro de série', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Espaces', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: controller.filteredEquipments.map((equipment) {
                          return DataRow(cells: [
                            DataCell(Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(equipment.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                if (equipment.description != null && equipment.description!.isNotEmpty)
                                  Text(equipment.description!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            )),
                            DataCell(Text(equipment.type, style: TextStyle(color: Colors.grey[700]))),
                            DataCell(Text(equipment.serialNumber, style: TextStyle(color: Colors.grey[700]))),
                            DataCell(_buildStatusBadge(equipment.status)),
                            DataCell(Text(equipment.spaceName ?? '-', style: TextStyle(color: Colors.grey[700]))),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                                  onPressed: () => Get.dialog(EditEquipmentDialog(equipment: equipment)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    Get.defaultDialog(
                                      title: "Supprimer l'équipement",
                                      middleText: "Êtes-vous sûr de vouloir supprimer l'équipement '${equipment.name}' ?",
                                      textConfirm: "Supprimer",
                                      textCancel: "Annuler",
                                      confirmTextColor: Colors.white,
                                      buttonColor: Colors.red,
                                      onConfirm: () {
                                        controller.deleteEquipment(equipment.id);
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
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),

            // Cartes de statistiques (Total, Dispo, etc.)
            _buildResponsiveStatistics(context, controller),
          ],
        ),
      ),
    );
  }

  // Widget : Carte d'équipement pour mobile
  Widget _buildEquipmentCard(BuildContext context, Equipment equipment, EquipmentsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      equipment.type,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(equipment.status),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('S/N', style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(equipment.serialNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('ESPACE', style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(equipment.spaceName ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          if (equipment.description != null && equipment.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              equipment.description!,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => Get.dialog(EditEquipmentDialog(equipment: equipment)),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  Get.defaultDialog(
                    title: "Supprimer",
                    middleText: "Supprimer l'équipement '${equipment.name}' ?",
                    textConfirm: "Oui",
                    textCancel: "Non",
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.red,
                    onConfirm: () {
                      controller.deleteEquipment(equipment.id);
                      Get.back();
                    },
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Supprimer'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget : Titre de la page
  Widget _buildHeaderTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 28, color: Colors.blue),
            const SizedBox(width: 12),
            Text(
              'Gestion des Équipements',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Gérez tous les équipements de vos espaces',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  // Widget : Bouton d'ajout d'équipement
  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => Get.dialog(
        const AddEquipmentDialog(),
        barrierDismissible: true,
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Ajouter un équipement'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Widget : Champ de recherche par texte
  Widget _buildSearchField(EquipmentsController controller) {
    return TextField(
      onChanged: controller.updateSearch,
      decoration: InputDecoration(
        hintText: 'Rechercher un équipement...',
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

  // Widget : Filtre par statut
  Widget _buildStatusFilter(EquipmentsController controller) {
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
          items: ['Tous les statuts', 'Disponible', 'En maintenance', 'En panne']
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

  // Widget : Statistiques globales
  Widget _buildResponsiveStatistics(BuildContext context, EquipmentsController controller) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    
    return Obx(() {
      final total = controller.equipments.length;
      final available = controller.availableEquipments;
      final broken = controller.brokenEquipments;
      final maintenance = controller.maintenanceEquipments;

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

  // Widget : Carte statistique individuelle
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

  // Widget : Badge de statut pour un équipement
  Widget _buildStatusBadge(EquipmentStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case EquipmentStatus.disponible:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        label = 'Disponible';
        break;
      case EquipmentStatus.enMaintenance:
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFF854D0E);
        label = 'En maintenance';
        break;
      case EquipmentStatus.enPanne:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        label = 'En panne';
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
