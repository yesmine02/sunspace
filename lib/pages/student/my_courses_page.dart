import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/courses_controller.dart';
import '../../data/models/course.dart';
import '../../routing/app_routes.dart';

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
                  Obx(() => Text(
                    "${controller.filteredCourses.length} cours disponibles",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  )),
                  const SizedBox(height: 24),

                  // GRID OF COURSES
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)));
                    }

                    final courses = controller.filteredCourses;

                    if (courses.isEmpty) {
                      return _buildEmptyState(isMobile);
                    }

                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: courses.map<Widget>((course) => _buildCourseCard(course, isMobile)).toList(),
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
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 26),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    border: Border.all(color: Colors.white, width: 1.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
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
            const Icon(Icons.school_rounded, color: Color(0xFF007AFF), size: 32),
            const SizedBox(width: 16),
            Text(
              "Catalogue de Cours",
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
          "Explorez notre vaste sélection de formations pour booster vos compétences.",
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
      width: isMobile ? double.infinity : 350,
      height: 220,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            course.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),

          // Action Button (Green as requested)
          ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.COURSE_DETAILS, arguments: course),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text("Accéder", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 20),
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
