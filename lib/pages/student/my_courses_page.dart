import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/courses_controller.dart';
import '../../data/models/course.dart';
import '../../routing/app_routes.dart';
import '../../widgets/notification_bell.dart';

class MyCoursesPage extends StatelessWidget {
  const MyCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CoursesController());
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. TOP NAV BAR
          _buildTopNavBar(context, isMobile),
          
          // 2. MAIN CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40, 
                vertical: isMobile ? 24 : 40
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER (Title + Subtitle)
                  _buildHeader(isMobile),
                  const SizedBox(height: 32),

                  // SEARCH BAR CARD
                  _buildSearchCard(controller, isMobile),
                  const SizedBox(height: 32),

                  // COURSE COUNT
                  Obx(() {
                    final enrolledCount = controller.courses.where((c) => controller.isEnrolled(c)).length;
                    return Text(
                      "$enrolledCount formations rejointes",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // GRID OF COURSES
                  Obx(() {
                    if (controller.isLoading.value && controller.courses.isEmpty) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)));
                    }

                    // Filtrer pour ne montrer que les cours inscrits
                    final enrolledCourses = controller.filteredCourses.where((c) {
                      return controller.isEnrolled(c);
                    }).toList();

                    if (enrolledCourses.isEmpty) {
                      return _buildEmptyState(isMobile);
                    }

                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: enrolledCourses.map<Widget>((course) => _buildCourseCard(course, isMobile)).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          const NotificationBell(),
          const SizedBox(width: 16),
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

  Widget _buildSearchCard(CoursesController controller, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
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
      child: TextField(
        onChanged: controller.updateSearch,
        decoration: const InputDecoration(
          hintText: "Rechercher une formation...",
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
          prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            const Icon(Icons.menu_book_rounded, color: Color(0xFF007AFF), size: 32),
            const SizedBox(width: 16),
            Text(
              "Mes Cours",
              style: TextStyle(
                fontSize: isMobile ? 28 : 36, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "Retrouvez ici toutes les formations auxquelles vous participez.",
          style: TextStyle(
            fontSize: isMobile ? 14 : 17, 
            color: const Color(0xFF64748B), 
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Course course, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.levelLabel.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 16),
                // TITLE
                Text(
                  course.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                // INFOS (Time, Modules)
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    const Text("0h", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    const Icon(Icons.play_circle_outline, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    const Text("0 Modules", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 24),
                // PROGRESSION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Progression", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
                    const Text("0%", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.05, // Just for the mockup look
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.toNamed(AppRoutes.COURSE_DETAILS, arguments: course),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("Accéder", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        SizedBox(width: 12),
                        Icon(Icons.chevron_right_rounded, size: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            "Aucun cours trouvé",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
