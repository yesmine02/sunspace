// ============================================
// Page Mes Sessions de Formation (Étudiant)
// ============================================
// Affiche uniquement les sessions liées aux cours auxquels l'étudiant est inscrit.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/sessions_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/courses_controller.dart';
import '../../data/models/training_session.dart';

class StudentTrainingPage extends StatefulWidget {
  const StudentTrainingPage({super.key});

  @override
  State<StudentTrainingPage> createState() => _StudentTrainingPageState();
}

class _StudentTrainingPageState extends State<StudentTrainingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SessionsController _sessionsController = Get.put(SessionsController());
  final CoursesController _coursesController = Get.put(CoursesController());
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // ✅ Recharger les inscriptions pour que le filtre soit toujours à jour
    _coursesController.fetchEnrollments();
    _sessionsController.loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final bool isVerySmall = MediaQuery.of(context).size.width < 400;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : (isMobile ? 20 : 40), vertical: isMobile ? 20 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER + STATS
              if (isMobile) ...[
                _buildHeader(isMobile),
                const SizedBox(height: 24),
                _buildStats(isMobile),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildHeader(isMobile)),
                    _buildStats(isMobile),
                  ],
                ),
              ],
              
              const SizedBox(height: 32),

              // 2. SEARCH BAR
              _buildSearchBar(isMobile),
              const SizedBox(height: 32),

              // 3. TABS
              _buildTabs(isMobile),
              const SizedBox(height: 32),

              // 4. CONTENT
              Obx(() {
                if (_sessionsController.isLoading.value || _coursesController.isLoading.value) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }
                
                return _buildSessionsList(
                  isAvailableOnly: _tabController.index == 0,
                  isMobile: isMobile,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "Mes Sessions",
                style: TextStyle(
                  fontSize: isMobile ? 28 : 36, 
                  fontWeight: FontWeight.w900, 
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          "Retrouvez ici les sessions de formation liées aux cours que vous suivez.",
          style: TextStyle(
            fontSize: 15, 
            color: Color(0xFF64748B), 
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(bool isMobile) {
    return Obx(() {
      final userId = _authController.currentUser.value?['id'];
      
      // Filtrer les sessions appartenant aux cours de l'étudiant
      final enrolledSessions = _sessionsController.sessions.where((s) {
        if (s.courseId == null) return false;
        return _coursesController.enrolledCourseIds.contains(int.tryParse(s.courseId!)) || 
               _coursesController.enrolledCourseDocumentIds.contains(s.courseId);
      }).toList();

      final availableCount = enrolledSessions.where((s) => userId != null && !s.attendeeIds.contains(userId)).length;
      final myInscriptionsCount = enrolledSessions.where((s) => userId != null && s.attendeeIds.contains(userId)).length;
      
      return Row(
        mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          _buildStatBox(myInscriptionsCount.toString(), "Mes sessions", const Color(0xFFEFF6FF), const Color(0xFF2563EB), isMobile),
          const SizedBox(width: 12),
          _buildStatBox(availableCount.toString(), "À rejoindre", Colors.white, const Color(0xFF1E293B), isMobile, hasBorder: true),
        ],
      );
    });
  }

  Widget _buildStatBox(String value, String label, Color bgColor, Color textColor, bool isMobile, {bool hasBorder = false}) {
    return Container(
      width: isMobile ? 105 : 120,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: hasBorder ? Border.all(color: const Color(0xFFE2E8F0)) : null,
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
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
        onChanged: _sessionsController.updateSearch,
        decoration: InputDecoration(
          hintText: "Rechercher une session parmi vos cours...",
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

  Widget _buildTabs(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildTabItem(0, "À rejoindre", isMobile)),
          Expanded(child: _buildTabItem(1, "Inscrit", isMobile)),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, bool isMobile) {
    final bool isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.index = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsList({required bool isAvailableOnly, required bool isMobile}) {
    return Obx(() {
      final userId = _authController.currentUser.value?['id'];
      
      // ✅ FILTRE STRICT : Uniquement les sessions des cours auxquels l'étudiant est DÉJÀ inscrit
      final studentSessions = _sessionsController.sessions.where((s) {
        if (s.courseId == null) return false; // Session sans cours => exclue
        return _coursesController.enrolledCourseIds.contains(int.tryParse(s.courseId!)) || 
               _coursesController.enrolledCourseDocumentIds.contains(s.courseId);
      }).toList();

      // Filtrer par recherche textuelle
      final searchFiltered = studentSessions.where((s) {
        final query = _sessionsController.searchQuery.value.toLowerCase();
        if (query.isEmpty) return true;
        return s.title.toLowerCase().contains(query) || 
               (s.courseName?.toLowerCase().contains(query) ?? false);
      }).toList();

      // Séparer selon l'onglet actif :
      // Onglet 0 ("À rejoindre") = sessions du cours inscrit, mais pas encore rejointes
      // Onglet 1 ("Inscrit")     = sessions du cours inscrit auxquelles l'étudiant participe
      final displaySessions = isAvailableOnly 
          ? searchFiltered.where((s) => userId != null && !s.attendeeIds.contains(userId)).toList()
          : searchFiltered.where((s) => userId != null && s.attendeeIds.contains(userId)).toList();

      if (displaySessions.isEmpty) {
        return _buildEmptyState(isAvailableOnly, isMobile);
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displaySessions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) => _buildSessionCard(displaySessions[index], showUnenroll: !isAvailableOnly, isMobile: isMobile),
      );
    });
  }

  Widget _buildEmptyState(bool isAvailableOnly, bool isMobile) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.event_note_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            isAvailableOnly ? "Aucune nouvelle session à rejoindre" : "Vous n'êtes inscrit à aucune session",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Seules les sessions de vos cours rejoints s'affichent ici.",
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TrainingSession session, {required bool showUnenroll, required bool isMobile}) {
    final bool isOnline = session.type == SessionType.enLigne || session.type == SessionType.hybride;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
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
                      session.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.courseName ?? "Cours Inconnu",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.typeLabel,
                  style: TextStyle(
                    color: isOnline ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildInfoItem(Icons.calendar_today_rounded, DateFormat('d MMM yyyy', 'fr_FR').format(session.startDate ?? DateTime.now())),
              _buildInfoItem(Icons.access_time_rounded, "${DateFormat('HH:mm').format(session.startDate ?? DateTime.now())}"),
              _buildInfoItem(Icons.people_alt_outlined, "${session.currentParticipants}/${session.maxParticipants}"),
              if (session.instructorName != null)
                _buildInfoItem(Icons.person_rounded, session.instructorName!),
            ],
          ),
          const SizedBox(height: 24),
          if (showUnenroll && isOnline && session.meetingLink != null) ...[
            TextButton.icon(
              onPressed: session.isExpired ? null : () async {
                if (session.meetingLink != null) {
                  final Uri url = Uri.parse(session.meetingLink!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    Get.snackbar("Erreur", "Impossible d'ouvrir le lien : ${session.meetingLink}");
                  }
                }
              },
              icon: const Icon(Icons.link, size: 18),
              label: Text(session.isExpired ? "Lien expiré" : "Rejoindre la réunion"),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: session.isExpired 
              ? const Text("SESSION TERMINÉE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))
              : (showUnenroll 
                  ? _buildActionButton("Se désinscrire", const Color(0xFFEF4444), () => _showUnenrollmentDialog(session))
                  : _buildActionButton(
                      session.currentParticipants >= session.maxParticipants ? "Complet" : "Participer", 
                      session.currentParticipants >= session.maxParticipants ? Colors.grey.shade400 : const Color(0xFF2563EB), 
                      session.currentParticipants >= session.maxParticipants ? null : () => _showEnrollmentDialog(session)
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        disabledBackgroundColor: Colors.grey.shade200,
      ),
      child: Text(
        label, 
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: onTap == null ? Colors.grey : Colors.white,
        )
      ),
    );
  }

  void _showEnrollmentDialog(TrainingSession session) {
    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Voulez-vous participer à la session '${session.title}' ?",
      textConfirm: "Oui",
      textCancel: "Annuler",
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF2563EB),
      onConfirm: () {
        Get.back();
        _sessionsController.enrollInSession(session.documentId!);
      },
    );
  }

  void _showUnenrollmentDialog(TrainingSession session) {
    Get.defaultDialog(
      title: "Désinscription",
      middleText: "Voulez-vous annuler votre participation ?",
      textConfirm: "Confirmer",
      textCancel: "Retour",
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFEF4444),
      onConfirm: () {
        Get.back();
        _sessionsController.unenrollFromSession(session.documentId!);
      },
    );
  }
}
