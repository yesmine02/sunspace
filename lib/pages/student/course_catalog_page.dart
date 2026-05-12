import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/courses_controller.dart';
import '../../data/models/course.dart';
import '../../routing/app_routes.dart';


class CourseCatalogPage extends StatelessWidget {
  const CourseCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CoursesController());
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 40, 
            vertical: isMobile ? 30 : 60
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔷 HEADER
              _buildHeader(isMobile),
              const SizedBox(height: 48),

              // 🔷 SEARCH & FILTERS
              _buildSearchSection(controller, isMobile),
              const SizedBox(height: 32),

              // 🔷 COURSE COUNT
              Obx(() => Text(
                "${controller.filteredCourses.length} cours disponibles",
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w600, 
                  color: Color(0xFF64748B)
                ),
              )),
              const SizedBox(height: 24),

              // 🔷 GRID OF COURSES
              Obx(() {
                if (controller.isLoading.value && controller.courses.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(100.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                if (controller.filteredCourses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(100.0),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text("Aucun cours trouvé", style: TextStyle(color: Colors.grey, fontSize: 18)),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.filteredCourses.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : (MediaQuery.of(context).size.width > 1600 ? 5 : 4), 
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isMobile ? 1.2 : 1.1, // Beaucoup plus compact (plus large que haut)
                  ),
                  itemBuilder: (context, index) => _buildCourseCard(context, controller.filteredCourses[index], isMobile),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)], // Dégradé très doux bleu SunSpace
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFDBFE).withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Catalogue de Cours",
                  style: TextStyle(
                    fontSize: isMobile ? 26 : 36,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E3A8A), // Bleu très foncé
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Explorez notre vaste sélection de formations animées par des experts pour booster vos compétences.",
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF3B82F6), // Bleu intermédiaire
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
      ),
      child: Icon(icon, color: isActive ? const Color(0xFF007AFF) : const Color(0xFF94A3B8), size: 20),
    );
  }

  Widget _buildSearchSection(CoursesController controller, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: controller.updateSearch,
              decoration: InputDecoration(
                hintText: "Rechercher une formation...",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, bool isMobile) {
    final isFree = course.price == 0;
    
    // Assignation d'une couleur d'accent en fonction du niveau
    Color badgeColor;
    Color badgeBgColor;
    switch(course.level) {
      case CourseLevel.debutant:
        badgeColor = const Color(0xFF10B981);
        badgeBgColor = const Color(0xFFDCFCE7);
        break;
      case CourseLevel.intermediaire:
        badgeColor = const Color(0xFFF59E0B);
        badgeBgColor = const Color(0xFFFEF3C7);
        break;
      case CourseLevel.avance:
        badgeColor = const Color(0xFFEF4444);
        badgeBgColor = const Color(0xFFFEE2E2);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Légèrement plus foncé que le blanc pur
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5), // Bordure un peu plus marquée
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── EN-TÊTE DE LA CARTE ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Encore plus réduit
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9), 
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.levelString,
                    style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        course.createdAt != null 
                          ? "${course.createdAt!.day.toString().padLeft(2, '0')}/${course.createdAt!.month.toString().padLeft(2, '0')}/${course.createdAt!.year}"
                          : "Non défini",
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── CONTENU DE LA CARTE ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12), // Encore plus réduit
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15, // Un peu plus petit
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Détails : Enseignant
                  if (course.instructorName != null && course.instructorName!.isNotEmpty) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                          child: Text(
                            course.instructorName![0].toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            course.instructorName!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Détails : Description
                  if (course.description.isNotEmpty)
                    Text(
                      course.description,
                      maxLines: 1, // Réduit à 1 ligne pour gagner de l'espace
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.3),
                    ),
                    
                  const SizedBox(height: 12), // Remplacé Spacer par un petit espace
                  _buildActionButton(context, course),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Course course) {
    final controller = Get.find<CoursesController>();

    return Obx(() {
      final bool isAlreadyEnrolled = controller.isEnrolled(course);
      final bool isLoadingEnroll = controller.isLoading.value;

      if (isAlreadyEnrolled) {
        return ElevatedButton.icon(
          onPressed: () => Get.toNamed(
            AppRoutes.COURSE_DETAILS, 
            arguments: course
          ),
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          label: const Text("Accéder"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEFF6FF), // Light Blue
            foregroundColor: const Color(0xFF2563EB),
            minimumSize: const Size(double.infinity, 40), // Réduit de 48 à 40
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        );
      }

      return ElevatedButton(
        onPressed: isLoadingEnroll ? null : () async {
          Get.showOverlay(
            asyncFunction: () => controller.enrollInCourse(course),
            loadingWidget: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ).then((success) {
            if (success == true) {
              Get.snackbar(
                "Succès", 
                "Vous êtes maintenant inscrit à ce cours.",
                backgroundColor: const Color(0xFFDCFCE7),
                colorText: const Color(0xFF166534),
                icon: const Icon(Icons.check_circle, color: Color(0xFF166534)),
              );
            } else {
              Get.snackbar(
                "Erreur", 
                "L'inscription a échoué. Veuillez réessayer.",
                backgroundColor: const Color(0xFFFEE2E2),
                colorText: const Color(0xFF991B1B),
                icon: const Icon(Icons.error, color: Color(0xFF991B1B)),
              );
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A), // Dark Slate
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 40), // Réduit de 48 à 40
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          "S'inscrire - Gratuit",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      );
    });
  }
}
