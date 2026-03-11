// ===============================================
// Page de Gestion des Sessions (SessionsPage)
// Design Responsive (Mobile & Desktop)
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sessions_controller.dart';
import '../../data/models/training_session.dart';
import './widgets/add_edit_session_dialog.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialisation du contrôleur
    final controller = Get.put(SessionsController());
    
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Fond gris bleuté
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Titre + Sous-titre
            _buildHeaderTitle(),
            const SizedBox(height: 24),
            
            // Bouton Nouvelle Session (aligné à gauche)
            _buildAddButton(),
            const SizedBox(height: 32),

            // Tableau des sessions (Design Card unique)
            Obx(() {
              if (controller.isLoading.value && controller.sessions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredSessions.isEmpty) {
                return _buildEmptyState();
              }

              return _buildSessionsTableContainer(controller);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_outlined, color: Color(0xFF007AFF), size: 36),
            const SizedBox(width: 12),
            const Text(
              'Mes Sessions',
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1E293B)
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Planifiez et gérez vos sessions de formation',
          style: TextStyle(
            color: Colors.grey[600], 
            fontSize: 16
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: 200, // Largeur fixe ou adaptée
      child: ElevatedButton.icon(
        onPressed: () => Get.dialog(
          const AddEditSessionDialog(),
          barrierDismissible: true,
        ),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nouvelle Session', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucune session trouvée.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // 🔹 TABLEAU (Style Card Desktop/Mobile unifié avec scroll)
  Widget _buildSessionsTableContainer(SessionsController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Theme(
        data: Theme.of(Get.context!).copyWith(
          dividerColor: Colors.transparent, // Supprimer les lignes de séparation par défaut si souhaité
          dataTableTheme: DataTableThemeData(
            headingRowColor: MaterialStateProperty.all(Colors.white),
            dataRowColor: MaterialStateProperty.all(Colors.white),
          )
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 24,
            columnSpacing: 30,
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
            dataTextStyle: const TextStyle(color: Color(0xFF334155), fontSize: 14),
            border: const TableBorder(horizontalInside: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            columns: const [
              DataColumn(label: Text('Titre')),
              DataColumn(label: Text('Cours')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Date de début')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Participants')),
            ],
            rows: controller.filteredSessions.map((session) {
              return DataRow(
                // onSelectChanged: null, // Désactive la sélection/clic
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        session.title, 
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        session.courseName ?? '-', 
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ),
                  DataCell(Text(session.typeLabel)),
                  DataCell(Text(session.formattedStartDate)),
                  DataCell(_buildStatusIndicator(session.status)),
                  DataCell(Text('${session.currentParticipants} / ${session.maxParticipants}')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(SessionStatus status) {
    bool isPublished = status == SessionStatus.publie;
    return Container(
      width: 24,
      height: 4,
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFFEE2E2) : const Color(0xFFFEE2E2), // Couleur rosée comme sur l'image
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
