// ============================================
// Page Découverte des Formations (Professionnel)
// Redésignée selon les nouvelles maquettes
// ============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/sessions_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/associations_controller.dart';
import '../../data/models/training_session.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SessionsController _sessionsController = Get.put(SessionsController());
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Initialise le contrôleur d'onglets pour gérer les deux sections (Disponibles / Mes sessions)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // Libère les ressources du contrôleur d'onglets lors de la destruction du widget pour éviter les fuites de mémoire
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
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

              // 4. CONTENT - Utilisation de Column au lieu de TabBarView fixe pour le scroll
              Obx(() {
                if (_sessionsController.isLoading.value) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }
                
                // On affiche le contenu de l'onglet actif directement dans la list
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

  /// --- WIDGETS DE CONSTRUCTION ---

  /// Affiche le titre de la page et la description (En-tête)
  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Color(0xFF007AFF), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "Sessions de formation",
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
        Text(
          "Retrouvez ici toutes les sessions de formation disponibles et vos inscriptions.",
          style: TextStyle(
            fontSize: isMobile ? 14 : 17, 
            color: const Color(0xFF64748B), 
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Affiche les petits compteurs de statistiques (Mes inscriptions / Disponibles)
  Widget _buildStats(bool isMobile) {
    return Obx(() {
      final userId = _authController.currentUser.value?['id'];
      
      // Toutes les sessions disponibles (non encore rejointes par ce pro) et NON CRÉÉES par une association
      // (Les sessions d'association n'ont jamais de cours associé)
      final allSessions = _sessionsController.sessions.where((s) => s.courseId != null).toList();
      final availableCount = allSessions.where((s) => userId != null && !s.attendeeIds.contains(userId)).length;
      final myInscriptionsCount = allSessions.where((s) => userId != null && s.attendeeIds.contains(userId)).length;
      
      return Row(
        mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          _buildStatBox(myInscriptionsCount.toString(), "Mes inscriptions", const Color(0xFFEFF6FF), const Color(0xFF007AFF), isMobile),
          const SizedBox(width: 12),
          _buildStatBox(availableCount.toString(), "Disponibles", Colors.white, const Color(0xFF1E293B), isMobile, hasBorder: true),
        ],
      );
    });
  }

  /// Construit un petit rectangle de statistique individuel
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

  /// Construit la barre de recherche avec son icône loupe
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
        style: TextStyle(fontSize: isMobile ? 14 : 15),
        decoration: InputDecoration(
          hintText: isMobile ? "Rechercher..." : "Rechercher une formation, un cours, un formateur...",
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

  /// Construit la barre d'onglets (Tabs) pour switcher entre les vues
  Widget _buildTabs(bool isMobile) {
    return Obx(() {
      final userId = _authController.currentUser.value?['id'];
      final availableCount = _sessionsController.sessions.length;
      final myInscriptionsCount = _sessionsController.sessions.where((s) => userId != null && s.attendeeIds.contains(userId)).length;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(child: _buildTabItem(0, "Sessions disponibles", isMobile)),
            Expanded(child: _buildTabItem(1, "Mes sessions", isMobile)),
          ],
        ),
      );
    });
  }

  /// Construit un bouton d'onglet individuel (ex: "Sessions disponibles")
  Widget _buildTabItem(int index, String label, bool isMobile) {
    final bool isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        setState(() => _tabController.index = index);//change d'onglet
      },
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

  /// Affiche la liste des formations filtrées selon l'onglet actif
  Widget _buildSessionsList({required bool isAvailableOnly, required bool isMobile}) {
    return Obx(() {
      final userId = _authController.currentUser.value?['id'];
      
      // Toutes les sessions (créées par n'importe quel enseignant, mais pas par une association)
      // Filtre de recherche textuelle inclus
      final allSessions = _sessionsController.sessions.where((s) {
        // Exclure les sessions d'association (qui n'ont pas de cours)
        if (s.courseId == null) return false;
        
        final query = _sessionsController.searchQuery.value.toLowerCase();
        if (query.isEmpty) return true;
        return s.title.toLowerCase().contains(query) ||
               (s.courseName?.toLowerCase().contains(query) ?? false);
      }).toList();

      // Onglet 0 : sessions disponibles (le pro n'y est pas encore inscrit)
      // Onglet 1 : mes sessions (le pro y est inscrit)
      final sessions = isAvailableOnly 
          ? allSessions.where((s) => userId != null && !s.attendeeIds.contains(userId)).toList() 
          : allSessions.where((s) => userId != null && s.attendeeIds.contains(userId)).toList();

      if (sessions.isEmpty) {
        return _buildEmptyState(isAvailableOnly, isMobile);
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sessions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) => _buildSessionCard(sessions[index], showUnenroll: !isAvailableOnly, isMobile: isMobile),
      );
    });
  }

  /// Affiche un message et une image quand il n'y a rien à montrer
  Widget _buildEmptyState(bool isAvailableOnly, bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(isAvailableOnly ? Icons.event_note_rounded : Icons.school_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            isAvailableOnly ? "Aucune session disponible" : "Aucune formation inscrite",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
          ),
          if (!isAvailableOnly) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() => _tabController.index = 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Voir les formations disponibles", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  /// Construit la carte blanche détaillée pour une formation spécifique
  Widget _buildSessionCard(TrainingSession session, {required bool showUnenroll, required bool isMobile}) {
    final bool isOnline = session.type == SessionType.enLigne || session.type == SessionType.hybride;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.courseName ?? "FORMATION PROFESSIONNELLE",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.typeLabel,
                  style: TextStyle(
                    color: isOnline ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Row with stats
          // les infos de la session(dates,heures,participants)
          Wrap(
            spacing: 40,
            runSpacing: 16,
            children: [
              _buildInfoItem(Icons.calendar_today_rounded, DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(session.startDate ?? DateTime.now())),
              _buildInfoItem(Icons.access_time_rounded, "${DateFormat('HH:mm').format(session.startDate ?? DateTime.now())} - ${DateFormat('HH:mm').format(session.endDate ?? DateTime.now())}"),
              _buildInfoItem(Icons.people_outline_rounded, "${session.currentParticipants} / ${session.maxParticipants} participants"),
              if (session.instructorName != null)
                _buildInfoItem(Icons.person_rounded, session.instructorName!),
            ],
          ),
          
          if (showUnenroll && isOnline && session.meetingLink != null) ...[
            const SizedBox(height: 24),
            InkWell(
              onTap: session.isExpired ? null : () async {
                if (session.meetingLink != null) {
                  final Uri url = Uri.parse(session.meetingLink!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    Get.snackbar("Erreur", "Impossible d'ouvrir le lien : ${session.meetingLink}");
                  }
                }
              },
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 20, color: session.isExpired ? Colors.grey : const Color(0xFF007AFF)),
                  const SizedBox(width: 8),
                  Text(
                    session.isExpired ? "Session terminée (Lien désactivé)" : "Lien de la réunion",
                    style: TextStyle(
                      color: session.isExpired ? Colors.grey : const Color(0xFF007AFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: session.isExpired ? TextDecoration.none : TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          Align(
            alignment: Alignment.centerRight,
            child: session.isExpired 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "SESSION TERMINÉE",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  )
                : (showUnenroll 
                    ? _buildUnenrollButton(session)
                    : _buildEnrollButton(session)),
          ),
        ],
      ),
    );
  }

  /// Affiche une icône et un petit texte d'information (ex: Date, Heure)
  Widget _buildInfoItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B).withOpacity(0.7)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  /// Bouton bleu pour s'inscrire à une formation
  Widget _buildEnrollButton(TrainingSession session) {
    final bool isFull = session.currentParticipants >= session.maxParticipants;

    return ElevatedButton(
      onPressed: isFull ? null : () => _showEnrollmentDialog(session),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFull ? Colors.grey.shade300 : const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        minimumSize: const Size(120, 48),
        disabledBackgroundColor: Colors.grey.shade200,
      ),
      child: Text(
        isFull ? "Complet" : "S'inscrire",
        style: TextStyle(
          fontWeight: FontWeight.w900, 
          fontSize: 15,
          color: isFull ? Colors.grey : Colors.white,
        ),
      ),
    );
  }

  /// Bouton rouge pour annuler une inscription
  Widget _buildUnenrollButton(TrainingSession session) {
    return ElevatedButton(
      onPressed: () => _showUnenrollmentDialog(session),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        minimumSize: const Size(120, 48),
      ),
      child: const Text(
        "Se désinscrire",
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String text, bool isMobile) {
    return Row(
      children: [
        Icon(icon, size: isMobile ? 16 : 18, color: const Color(0xFF007AFF)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(color: const Color(0xFF1E293B), fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.w500)
          ),
        ),
      ],
    );
  }

  void _showEnrollmentDialog(TrainingSession session) {
    if (session.documentId == null) {
      Get.snackbar("Erreur", "Identifiant de session manquant", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Voulez-vous vous inscrire à la session '${session.title}' ?",
      textConfirm: "S'inscrire",
      textCancel: "Annuler",
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF007AFF),
      onConfirm: () {
        Get.back();
        _sessionsController.enrollInSession(session.documentId!);
      },
    );
  }

  void _showUnenrollmentDialog(TrainingSession session) {
    if (session.documentId == null) return;

    Get.defaultDialog(
      title: "Annuler l'inscription",
      middleText: "Voulez-vous vraiment annuler votre inscription à '${session.title}' ?",
      textConfirm: "Oui, annuler",
      textCancel: "Non",
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFEF4444),
      onConfirm: () {
        Get.back();
        _sessionsController.unenrollFromSession(session.documentId!);
      },
    );
  }
}
