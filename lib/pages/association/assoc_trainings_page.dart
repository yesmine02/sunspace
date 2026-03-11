// ===============================================
// Page de Gestion des Formations (AssocTrainingsPage)
// Pour les Associations : Organiser des formations pour leurs membres
// Design responsive — adapté mobile et desktop
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sessions_controller.dart';
import '../../data/models/training_session.dart';
import '../sessions/widgets/add_edit_session_dialog.dart';

class AssocTrainingsPage extends StatelessWidget {
  const AssocTrainingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SessionsController());
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 32.0,
          vertical: isMobile ? 24.0 : 36.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── EN-TÊTE ──────────────────────────────────
            _buildHeader(context, isMobile),
            const SizedBox(height: 24),

            // ─── RECHERCHE ─────────────────────────────────
            _buildSearchBar(controller, isMobile),
            const SizedBox(height: 24),

            // ─── CONTENU : liste ou état vide ──────────────
            Obx(() {
              if (controller.isLoading.value && controller.sessions.isEmpty) {
                return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                );
              }

              if (controller.filteredSessions.isEmpty) {
                return _buildEmptyState(context);
              }

              return isMobile
                  ? _buildTrainingsList(context, controller)
                  : _buildTrainingsTable(context, controller);
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EN-TÊTE : Titre + Bouton Nouveau Parcours
  // ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isMobile) {
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organiser des Formations',
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Créez des parcours d\'apprentissage personnalisés pour les membres de votre association.',
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: isMobile ? 13 : 15,
            height: 1.5,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _buildAddButton(),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 24),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => Get.dialog(
        const AddEditSessionDialog(),
        barrierDismissible: true,
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text(
        'Nouveau Parcours',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BARRE DE RECHERCHE
  // ─────────────────────────────────────────────
  Widget _buildSearchBar(SessionsController controller, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.updateSearch,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher une formation...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          icon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ÉTAT VIDE (aucune formation)
  // ─────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône dans un cercle bleu clair
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF2563EB),
              size: 36,
            ),
          ),
          const SizedBox(height: 24),

          // Titre
          const Text(
            'Aucun parcours en cours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          // Sous-titre
          const Text(
            'Votre liste de formations est vide. Commencez par\nplanifier une nouvelle session pour vos membres.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

          // Bouton d'action
          ElevatedButton.icon(
            onPressed: () => Get.dialog(
              const AddEditSessionDialog(),
              barrierDismissible: true,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Planifier mon premier parcours',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LISTE MOBILE des formations
  // ─────────────────────────────────────────────
  Widget _buildTrainingsList(BuildContext context, SessionsController controller) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.filteredSessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final session = controller.filteredSessions[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeBadge(session.typeLabel),
                ],
              ),
              const SizedBox(height: 10),
              _infoRow(Icons.calendar_today_rounded, session.formattedStartDate),
              const SizedBox(height: 6),
              _infoRow(Icons.people_outline_rounded, '${session.currentParticipants} / ${session.maxParticipants} participants'),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(session.status),
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 20),
                        onPressed: () => Get.dialog(AddEditSessionDialog(session: session)),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        onPressed: () => _confirmDelete(session, controller),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // TABLEAU DESKTOP des formations
  // ─────────────────────────────────────────────
  Widget _buildTrainingsTable(BuildContext context, SessionsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 56,
          dataRowHeight: 68,
          horizontalMargin: 24,
          columnSpacing: 32,
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('TITRE',        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF64748B)))),
            DataColumn(label: Text('TYPE',         style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF64748B)))),
            DataColumn(label: Text('DATE',         style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF64748B)))),
            DataColumn(label: Text('STATUT',       style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF64748B)))),
            DataColumn(label: Text('PARTICIPANTS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF64748B)))),
            DataColumn(label: Text('ACTIONS',     style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF64748B)))),
          ],
          rows: controller.filteredSessions.map((session) {
            return DataRow(cells: [
              DataCell(Text(session.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
              DataCell(_buildTypeBadge(session.typeLabel)),
              DataCell(Text(session.formattedStartDate, style: const TextStyle(color: Color(0xFF475569), fontSize: 13))),
              DataCell(_buildStatusBadge(session.status)),
              DataCell(Text('${session.currentParticipants} / ${session.maxParticipants}', style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Row(children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 18),
                  onPressed: () => Get.dialog(AddEditSessionDialog(session: session)),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                  onPressed: () => _confirmDelete(session, controller),
                  tooltip: 'Supprimer',
                ),
              ])),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BADGES
  // ─────────────────────────────────────────────
  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  Widget _buildStatusBadge(SessionStatus status) {
    final bool isPublished = status == SessionStatus.publie;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPublished ? 'Planifiée' : 'Brouillon',
        style: TextStyle(
          color: isPublished ? const Color(0xFF166534) : const Color(0xFF854D0E),
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SUPPRESSION : Confirmation
  // ─────────────────────────────────────────────
  void _confirmDelete(TrainingSession session, SessionsController controller) {
    if (session.documentId == null) return;

    Get.defaultDialog(
      title: 'Supprimer la formation',
      middleText: 'Voulez-vous vraiment supprimer "${session.title}" ? Cette action est irréversible.',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFEF4444),
      onConfirm: () {
        controller.deleteSession(session.documentId!);
        Get.back();
      },
    );
  }
}
