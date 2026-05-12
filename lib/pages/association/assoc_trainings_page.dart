// ===============================================
// Page de Gestion des Formations (AssocTrainingsPage)
// Pour les Associations : Organiser des formations pour leurs membres
// Design responsive — adapté mobile et desktop
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sessions_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/associations_controller.dart';
import '../../data/models/training_session.dart';
import '../../data/models/association_model.dart';
import 'widgets/add_assoc_session_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class AssocTrainingsPage extends StatelessWidget {
  const AssocTrainingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SessionsController());
    final assocController = Get.find<AssociationsController>();
    final authController = Get.find<AuthController>();
    
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 32.0,
          vertical: isMobile ? 24.0 : 36.0,
        ),
        child: Obx(() {
          // 🔹 IDENTIFICATION DE L'ASSOCIATION ACTIVE VIA LE CONTROLLER
          final List<Association> myAssocs = assocController.myAssociations;
          Association? activeAssoc;
          
          if (myAssocs.isNotEmpty) {
            if (assocController.selectedAssocId.value == null) {
              assocController.selectedAssocId.value = myAssocs.first.id;
            }
            activeAssoc = myAssocs.firstWhereOrNull((a) => a.id == assocController.selectedAssocId.value);
            activeAssoc ??= myAssocs.first;
            assocController.selectedAssocId.value = activeAssoc.id;
          }
          
          final int? myId = int.tryParse(authController.currentUser.value?['id']?.toString() ?? '');
          final bool canManage = activeAssoc?.admin?.id == myId;
          final int? assocAdminId = activeAssoc?.admin?.id;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── EN-TÊTE ──────────────────────────────────
              _buildHeader(context, isMobile, canManage, activeAssoc, myAssocs),
              const SizedBox(height: 24),

              // ─── RECHERCHE ─────────────────────────────────
              _buildSearchBar(controller, isMobile),
              const SizedBox(height: 24),

              // ─── LISTE DES SESSIONS ───────────────────────
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // FILTRE : Seulement les formations créées par cette association (via son admin)
                final displaySessions = controller.sessions.where((s) {
                  if (assocAdminId == null) return false; // Ne rien afficher si l'admin n'est pas identifié
                  if (s.instructorId != assocAdminId) return false;
                  
                  // CRUCIAL: Si la session a un cours associé, c'est une session d'enseignant!
                  // Les sessions d'association n'ont jamais de cours.
                  if (s.courseId != null) return false;
                  
                  return true;
                }).where((s) {
                  // Filtre recherche local
                  final query = controller.searchQuery.value.toLowerCase();
                  if (query.isEmpty) return true;
                  return s.title.toLowerCase().contains(query) || 
                         (s.courseName?.toLowerCase().contains(query) ?? false);
                }).toList();

                if (displaySessions.isEmpty) {
                  return _buildEmptyState(context, canManage);
                }

                return isMobile
                    ? _buildTrainingsList(context, controller, canManage, displaySessions)
                    : _buildTrainingsTable(context, controller, canManage, displaySessions);
              }),
            ],
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EN-TÊTE : Titre + Bouton Nouveau Parcours
  // ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isMobile, bool canManage, Association? activeAssoc, List<Association> myAssocs) {
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formations : ${activeAssoc?.name ?? 'Association'}',
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        // 🔹 SELECTEUR SI PLUSIEURS ASSOCIATIONS
        if (myAssocs.length > 1) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: activeAssoc?.id,
                items: myAssocs.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Text(a.name ?? 'Sans nom', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: (newId) {
                  if (newId != null) {
                    Get.find<AssociationsController>().selectedAssocId.value = newId;
                  }
                },
              ),
            ),
          ),
        ],
        Text(
          canManage 
            ? 'Créez et gérez les parcours d\'apprentissage pour vos membres.'
            : 'Consultez les formations organisées par votre association.',
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
          if (canManage) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _buildAddButton(),
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        if (canManage) ...[
          const SizedBox(width: 24),
          _buildAddButton(),
        ],
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => Get.dialog(
        const AddAssocSessionDialog(),
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
  Widget _buildEmptyState(BuildContext context, bool canManage) {
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
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
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
          Text(
            canManage 
              ? 'Votre liste de formations est vide. Commencez par\nplanifier une nouvelle session pour vos membres.'
              : 'Votre association n\'a pas encore publié de formations.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: 28),
            // Bouton d'action
            ElevatedButton.icon(
              onPressed: () => Get.dialog(
                const AddAssocSessionDialog(),
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LISTE MOBILE des formations
  // ─────────────────────────────────────────────
  Widget _buildTrainingsList(BuildContext context, SessionsController controller, bool canManage, List<TrainingSession> displaySessions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displaySessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final session = displaySessions[index];
        final bool isOnline = session.type == SessionType.enLigne;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (session.courseName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            session.courseName!,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeBadge(session.typeLabel, isOnline),
                ],
              ),
              const SizedBox(height: 16),
              _infoRow(Icons.access_time_rounded, "Durée: ${session.formattedTimeRange}"),
              const SizedBox(height: 8),
              if (!isOnline && session.spaceName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        session.spaceName!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              _infoRow(Icons.people_alt_rounded, 'Participants: ${session.currentParticipants} / ${session.maxParticipants}'),
              const SizedBox(height: 20),
              
              if (isOnline && session.meetingLink != null && session.meetingLink!.isNotEmpty && !session.isExpired)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchURL(session.meetingLink!),
                      icon: const Icon(Icons.videocam_rounded, size: 20),
                      label: const Text('REJOINDRE LA SESSION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(session.status, session.isExpired),
                  if (canManage)
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          color: const Color(0xFF2563EB),
                          onTap: () => Get.dialog(AddAssocSessionDialog(session: session)),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFEF4444),
                          onTap: () => _confirmDelete(session, controller),
                        ),
                      ],
                    )
                  else if (!isOnline || session.meetingLink == null || session.meetingLink!.isEmpty)
                    const Text(
                      "Infos en présentiel",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
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
  Widget _buildTrainingsTable(BuildContext context, SessionsController controller, bool canManage, List<TrainingSession> displaySessions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 64,
          dataRowHeight: 80,
          horizontalMargin: 24,
          columnSpacing: 32,
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          columns: [
            const DataColumn(label: Text('FORMATION',     style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5))),
            const DataColumn(label: Text('TYPE',         style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5))),
            const DataColumn(label: Text('DÉBUT',         style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5))),
            const DataColumn(label: Text('FIN',           style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5))),
            const DataColumn(label: Text('STATUT',       style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5))),
            const DataColumn(label: Text('PARTICIPANTS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5))),
            const DataColumn(label: Text('ACCÈS',        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5))),
            if (canManage) const DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5))),
          ],
          rows: displaySessions.map((session) {
            final bool isOnline = session.type == SessionType.enLigne;
            return DataRow(cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 15)),
                    if (session.courseName != null)
                      Text(session.courseName!, style: TextStyle(color: Colors.blue.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              DataCell(_buildTypeBadge(session.typeLabel, isOnline)),
              DataCell(Text(session.formattedStartDate, style: const TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500))),
              DataCell(Text(session.formattedEndDate, style: const TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500))),
              DataCell(_buildStatusBadge(session.status, session.isExpired)),
              DataCell(
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Text('${session.currentParticipants} / ${session.maxParticipants}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  ],
                ),
              ),
              DataCell(
                isOnline && session.meetingLink != null && session.meetingLink!.isNotEmpty && !session.isExpired
                ? ElevatedButton(
                    onPressed: () => _launchURL(session.meetingLink!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Rejoindre', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  )
                : Text(
                    isOnline ? 'Lien non dispo' : 'Présentiel',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600),
                  )
              ),
              if (canManage)
                DataCell(Row(children: [
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF64748B),
                    onTap: () => Get.dialog(AddAssocSessionDialog(session: session)),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => _confirmDelete(session, controller),
                  ),
                ])),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BADGES
  // ─────────────────────────────────────────────
  Widget _buildTypeBadge(String type, bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isOnline ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOnline ? Icons.videocam_rounded : Icons.location_on_rounded, size: 12, color: isOnline ? const Color(0xFF4F46E5) : const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            type,
            style: TextStyle(color: isOnline ? const Color(0xFF4F46E5) : const Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SessionStatus status, bool isExpired) {
    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Terminée',
          style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, fontSize: 11),
        ),
      );
    }

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

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar(
          'Erreur',
          'Impossible d\'ouvrir le lien : $urlString',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFEE2E2),
          colorText: const Color(0xFF991B1B),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Format de lien invalide.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEE2E2),
        colorText: const Color(0xFF991B1B),
      );
    }
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
