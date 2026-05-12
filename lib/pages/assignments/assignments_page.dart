// ===============================================
// Page de Gestion des Devoirs (AssignmentsPage)
// Design Responsive : Tableau (desktop) + Cartes (mobile)
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/assignments_controller.dart';
import '../../data/models/assignment.dart';
import '../../controllers/courses_controller.dart';
import '../../routing/app_routes.dart';
import '../../widgets/notification_bell.dart';
import './widgets/add_edit_assignment_dialog.dart';
import './widgets/view_assignment_dialog.dart';
import './widgets/submit_work_dialog.dart';
import '../../controllers/auth_controller.dart';
import '../student/course_details_page.dart'; // Pour d'éventuels helpers si besoin

class AssignmentsPage extends StatelessWidget {
  const AssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(CoursesController()); // S'assurer que le catalogue est chargé
    final controller = Get.put(AssignmentsController());
    final authController = Get.find<AuthController>();

    // Déterminer le mode (Management vs Étudiant)
    final bool isManagementArg = Get.arguments is Map ? (Get.arguments['isManagement'] ?? false) : false;
    // Un instructeur est toujours en mode gestion. Un admin peut choisir via le menu.
    final bool isManagementMode = authController.isInstructor || (authController.isAdmin && isManagementArg);
    
    // Mettre à jour l'état du contrôleur pour l'API
    if (controller.isManagementMode.value != isManagementMode) {
      controller.isManagementMode.value = isManagementMode;
      controller.fetchAssignments(); // Re-charger avec les bons filtres
    }

    final String pageTitle = isManagementMode ? 'Gestion des Devoirs' : 'Mes Devoirs';
    final String pageSubtitle = isManagementMode 
        ? 'Gérez les devoirs et les évaluations de vos cours.' 
        : 'Gérez vos soumissions et consultez vos notes.';

    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final double horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. TOP NAV BAR (Search + Icons)
          _buildTopNavBar(context, isMobile),
          
          // 2. MAIN CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 24.0 : 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête : Titre + Bouton Nouveau Devoir
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double buttonWidth = isManagementMode ? (isMobile ? 110 : 200) : 0;
                      final double titleWidth = constraints.maxWidth - buttonWidth - (isManagementMode ? 16 : 0);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildHeaderTitle(isMobile, titleWidth, pageTitle, pageSubtitle),
                          if (isManagementMode)
                            _buildAddButton(isMobile),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Barre de recherche secondaire
                  _buildSearchBar(controller),
                  const SizedBox(height: 32),

                  // Liste des Devoirs
                  Obx(() {
                    if (controller.isLoading.value && controller.assignments.isEmpty) {
                      return const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))),
                      );
                    }

                    if (controller.assignments.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Le filtre par inscription est fait dans le contrôleur
                    List<Assignment> displayList = controller.assignments;

                    if (isManagementMode) {
                      // Vue Gestion : Tableau (Desktop) ou Cartes avec outils (Mobile)
                      if (!isMobile) {
                        return _buildAssignmentsTableContainer(controller);
                      } else {
                        return Column(
                          children: displayList.map<Widget>((assignment) {
                            return _buildAssignmentCard(context, controller, authController, assignment, isMobile, true);
                          }).toList(),
                        );
                      }
                    } else {
                      // Vue Étudiant : Cartes avec bouton Soumettre
                      return Column(
                        children: displayList.map<Widget>((assignment) {
                          return _buildAssignmentCard(context, controller, authController, assignment, isMobile, false);
                        }).toList(),
                      );
                    }
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // TOP NAV BAR (Mockup style)
  // =============================

  Widget _buildTopNavBar(BuildContext context, bool isMobile) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Global Search Bar
          if (!isMobile)
            Container(
              width: 400,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Rechercher...",
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          const Spacer(),
          // Notifications
          const NotificationBell(),
          const SizedBox(width: 16),
          // User Profile
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                const Text(
                  "intern", 
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569), fontSize: 15)
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // =============================
  // WIDGETS DE LA PAGE
  // =============================

  Widget _buildHeaderTitle(bool isMobile, double availableWidth, String title, String subtitle) {
    return Container(
      constraints: BoxConstraints(maxWidth: availableWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.assignment_rounded, color: Color(0xFF007AFF), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32, // Slightly smaller on mobile
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFF64748B), 
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AssignmentsController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        onChanged: (val) => controller.updateSearch(val),
        decoration: const InputDecoration(
          hintText: 'Rechercher un devoir...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildAddButton(bool isMobile) {
    return ElevatedButton.icon(
      onPressed: () => Get.dialog(
        const AddEditAssignmentDialog(), // BOUTON : Ouvrir le dialogue de création de devoir
        barrierDismissible: true,
      ),
      icon: const Icon(Icons.add, size: 20),
      label: Text(isMobile ? 'Nouveau' : 'Nouveau Devoir', style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
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
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucun devoir trouvé.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }


  Widget _buildAssignmentCard(BuildContext context, AssignmentsController controller, AuthController authController, Assignment assignment, bool isMobile, bool canManage) {
    final bool useVerticalLayout = isMobile;
    bool isLate = assignment.dueDate != null && assignment.dueDate!.isBefore(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: useVerticalLayout
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCardContent(assignment, isLate, canManage, authController),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildCardFooter(assignment, useVerticalLayout, canManage, controller),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Expanded(child: _buildCardContent(assignment, isLate, canManage, authController)),
                  const SizedBox(width: 24),
                  Container(
                    width: 200,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(child: _buildCardFooter(assignment, useVerticalLayout, canManage, controller)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCardContent(Assignment assignment, bool isLate, bool canManage, AuthController authController) {
    final coursesController = Get.find<CoursesController>();
    final course = coursesController.courses.firstWhereOrNull((c) => c.id.toString() == assignment.courseId);
    final String displayCourseName = course?.title ?? assignment.courseName ?? 'COURS';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges (Using Wrap to prevent overflow on mobile)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatusBadge(
                displayCourseName, 
                const Color(0xFFDBEAFE), 
                const Color(0xFF2563EB),
                Icons.menu_book_rounded
              ),
              _buildStatusBadge(
                !canManage && assignment.isSubmittedByUser(authController.currentUser.value?['id']?.toString()) ? 'Soumis' : (isLate ? 'En retard' : 'À faire'),
                !canManage && assignment.isSubmittedByUser(authController.currentUser.value?['id']?.toString()) ? const Color(0xFFDCFCE7) : (isLate ? const Color(0xFFFEE2E2) : const Color(0xFFFFF7ED)),
                !canManage && assignment.isSubmittedByUser(authController.currentUser.value?['id']?.toString()) ? const Color(0xFF16A34A) : (isLate ? const Color(0xFFDC2626) : const Color(0xFFEA580C)),
                !canManage && assignment.isSubmittedByUser(authController.currentUser.value?['id']?.toString()) ? Icons.check_circle_outline_rounded : Icons.access_time_rounded
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Late Warning Message (New)
          if (isLate && !assignment.isSubmittedByUser(authController.currentUser.value?['id']?.toString()) && !canManage)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: assignment.allowLateSubmission ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: assignment.allowLateSubmission ? const Color(0xFFFFEDD5) : const Color(0xFFFEE2E2)),
              ),
              child: Row(
                children: [
                  Icon(
                    assignment.allowLateSubmission ? Icons.history_rounded : Icons.lock_clock, 
                    color: assignment.allowLateSubmission ? const Color(0xFFEA580C) : const Color(0xFFDC2626), 
                    size: 20
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      assignment.allowLateSubmission 
                        ? "En retard : Vous pouvez encore soumettre, mais votre travail sera marqué comme tardif."
                        : "En retard : La soumission est maintenant fermée pour ce devoir.",
                      style: TextStyle(
                        color: assignment.allowLateSubmission ? const Color(0xFF9A3412) : const Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Title
          Text(
            assignment.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Details
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: const Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Text(
                    "Échéance: ${assignment.formattedDueDate}",
                    style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 18, color: const Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Text(
                    "${assignment.maxPoints.toInt()} Points",
                    style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardFooter(Assignment assignment, bool isMobile, bool canManage, AssignmentsController controller) {
    if (canManage) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: Colors.grey, size: 24),
            onPressed: () => Get.dialog(ViewAssignmentDialog(assignment: assignment)), // BOUTON : Voir les détails du devoir
            tooltip: 'Voir',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E293B), size: 24),
            onPressed: () => Get.dialog(AddEditAssignmentDialog(assignment: assignment)), // BOUTON : Modifier le contenu du devoir
            tooltip: 'Modifier',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
            onPressed: () => _confirmDelete(controller, assignment), // BOUTON : Supprimer définitivement le devoir
            tooltip: 'Supprimer',
          ),
        ],
      );
    } else {
      return _buildSubmitButton(assignment, isMobile);
    }
  }

  Widget _buildSubmitButton(Assignment assignment, bool isMobile) {
    final authController = Get.find<AuthController>();
    final bool isSubmitted = assignment.isSubmittedByUser(authController.currentUser.value?['id']?.toString());
    
    return ElevatedButton(
      onPressed: () {
        if (isSubmitted) {
          Get.toNamed(AppRoutes.COURSE_DETAILS, arguments: {
            'course': assignment,
            'initialTab': 1,
          });
          return;
        }

        // 🕑 Vérification de la date d'échéance avant de naviguer
        final dueDate = assignment.dueDate;
        final bool allowLate = assignment.allowLateSubmission;
        
        if (dueDate != null && DateTime.now().isAfter(dueDate) && !allowLate) {
          Get.snackbar(
            'Soumission impossible',
            'La date d\'\u00e9chéance est dépassée. Cet enseignant n\'autorise pas les soumissions en retard.',
            backgroundColor: const Color(0xFFDC2626),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            icon: const Icon(Icons.lock_clock, color: Colors.white),
            duration: const Duration(seconds: 4),
          );
          return;
        }

        Get.toNamed(AppRoutes.COURSE_DETAILS, arguments: {
          'course': assignment,
          'initialTab': 1,
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubmitted ? const Color(0xFFF1F5F9) : const Color(0xFF007AFF),
        foregroundColor: isSubmitted ? const Color(0xFF64748B) : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isSubmitted ? "Voir l'envoi" : "Soumettre", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(width: 12),
          Icon(isSubmitted ? Icons.visibility_outlined : Icons.chevron_right_rounded, size: 22),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 180), // Limit width to prevent extreme cases
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // VUE DESKTOP : TABLEAU
  // =============================

  Widget _buildAssignmentsTableContainer(AssignmentsController controller) {
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
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 24,
            columnSpacing: 40,
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
            dataTextStyle: const TextStyle(color: Color(0xFF334155), fontSize: 14),
            border: const TableBorder(horizontalInside: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            columns: const [
              DataColumn(label: Text('Titre')),
              DataColumn(label: Text('Cours')),
              DataColumn(label: Text('Échéance')),
              DataColumn(label: Text('Points')),
              DataColumn(label: Text('Actions')),
            ],
            rows: controller.assignments.map((assignment) {
              return DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        assignment.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(assignment.courseName ?? '-')),
                  DataCell(Text(assignment.formattedDueDate)),
                  DataCell(Text(assignment.maxPoints.toInt().toString())),
                  DataCell(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, color: Colors.grey, size: 20),
                          onPressed: () => Get.dialog(ViewAssignmentDialog(assignment: assignment)),
                          tooltip: 'Voir',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E293B), size: 20),
                          onPressed: () => Get.dialog(AddEditAssignmentDialog(assignment: assignment)),
                          tooltip: 'Modifier',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _confirmDelete(controller, assignment),
                          tooltip: 'Supprimer',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // =============================
  // DIALOGUE DE CONFIRMATION
  // =============================

  void _confirmDelete(AssignmentsController controller, Assignment assignment) {
    Get.defaultDialog(
      title: "Supprimer le devoir",
      middleText: "Voulez-vous vraiment supprimer '${assignment.title}' ?",
      textConfirm: "Supprimer",
      textCancel: "Annuler",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.black,
      onConfirm: () {
        if (assignment.documentId != null) {
          controller.deleteAssignment(assignment.documentId!);
        }
        Get.back();
      },
    );
  }
}
