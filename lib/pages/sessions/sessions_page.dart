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
    
    // Adaptabilité du design
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    final double horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Fond gris bleuté
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Titre + Sous-titre
            _buildHeaderTitle(isMobile),
            const SizedBox(height: 24),
            
            // Bouton Nouvelle Session
            _buildAddButton(isMobile),
            const SizedBox(height: 32),

            // Liste des sessions (Design Card Mobile ou DataTable Desktop)
            Obx(() {
              if (controller.isLoading.value && controller.sessions.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
              }

              if (controller.filteredSessions.isEmpty) {
                return _buildEmptyState();
              }

              if (isMobile) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.filteredSessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildSessionCard(context, controller.filteredSessions[index]),
                );
              }

              return _buildSessionsTableContainer(controller);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.groups_outlined, color: const Color(0xFF007AFF), size: isMobile ? 28 : 36),
            const SizedBox(width: 12),
            Text(
              'Mes Sessions',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32, 
                fontWeight: FontWeight.bold, 
                color: const Color(0xFF1E293B)
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Planifiez et gérez vos sessions de formation',
          style: TextStyle(
            color: Colors.grey[600], 
            fontSize: isMobile ? 14 : 16
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 220,
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

  // 🔹 CARTE MOBILE
  Widget _buildSessionCard(BuildContext context, TrainingSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                child: Text(
                  session.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildSessionStatusBadge(session.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            session.courseName ?? '-',
            style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DÉBUT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(session.formattedStartDate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('PARTICIPANTS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('${session.currentParticipants} / ${session.maxParticipants}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF007AFF))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.laptop_chromebook, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(session.typeLabel, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                onPressed: () => Get.dialog(AddEditSessionDialog(session: session)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                onPressed: () {
                  Get.defaultDialog(
                    title: "Supprimer",
                    middleText: "Supprimer la session '${session.title}' ?",
                    textConfirm: "Oui",
                    textCancel: "Non",
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.red,
                    onConfirm: () {
                      Get.find<SessionsController>().deleteSession(session.documentId!);
                      Get.back();
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStatusBadge(SessionStatus status) {
    bool isPublished = status == SessionStatus.publie;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPublished ? const Color(0xFFBBF7D0) : const Color(0xFFFEF08A)),
      ),
      child: Text(
        isPublished ? 'Publiée' : 'Brouillon',
        style: TextStyle(
          color: isPublished ? const Color(0xFF166534) : const Color(0xFF854D0E),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🔹 TABLEAU DESKTOP
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
          dividerColor: Colors.transparent,
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
              DataColumn(label: Text('Actions')),
            ],
            rows: controller.filteredSessions.map((session) {
              return DataRow(
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
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                        onPressed: () => Get.dialog(AddEditSessionDialog(session: session)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        onPressed: () {
                          Get.defaultDialog(
                            title: "Supprimer",
                            middleText: "Supprimer la session '${session.title}' ?",
                            textConfirm: "Oui",
                            textCancel: "Non",
                            confirmTextColor: Colors.white,
                            buttonColor: Colors.red,
                            onConfirm: () {
                              controller.deleteSession(session.documentId!);
                              Get.back();
                            },
                          );
                        },
                      ),
                    ],
                  )),
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
        color: isPublished ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
