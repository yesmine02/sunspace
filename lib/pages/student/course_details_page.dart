// ============================================
// Page Course Details (Détails du Cours)
// ============================================
//affiche les détails d’un cours (leçons, devoirs, etc.).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/course.dart';
import '../../data/models/assignment.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/assignments_controller.dart';
import '../../pages/assignments/widgets/submit_work_dialog.dart';
import '../../controllers/courses_controller.dart';

class CourseDetailsPage extends StatefulWidget {
  const CourseDetailsPage({super.key});

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthController _authController = Get.find<AuthController>();
  final AssignmentsController _assignmentsController = Get.put(AssignmentsController());
  final CoursesController _coursesController = Get.put(CoursesController());

  @override
  void initState() {
    super.initState();
    // Permet d'ouvrir directement un onglet spécifique (ex: Devoirs)
    final int initialIndex = Get.arguments is Map ? (Get.arguments['initialTab'] ?? 0) : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamic args = Get.arguments;
    Course? course;
    
    if (args is Course) {
      course = args;
    } else if (args is Map) {
      final dynamic courseArg = args['course'];
      if (courseArg is Course) {
        course = courseArg;
      } else if (courseArg is Assignment) {
        final String? cid = courseArg.courseId;
        if (cid != null) {
          course = _coursesController.courses.firstWhereOrNull((c) => c.id.toString() == cid);
        }
        course ??= Course(
          id: courseArg.courseId ?? '',
          title: courseArg.courseName ?? 'Formation',
          level: CourseLevel.debutant,
          price: 0,
        );
      }
    } else if (args is Assignment) {
      final String? cid = args.courseId;
      if (cid != null) {
        course = _coursesController.courses.firstWhereOrNull((c) => c.id.toString() == cid);
      }
      course ??= Course(
        id: args.courseId ?? '',
        title: args.courseName ?? 'Formation',
        level: CourseLevel.debutant,
        price: 0,
      );
    }

    final bool isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. TOP NAV BAR (Search + Icons)
          _buildTopNavBar(isMobile),
          
          // 2. COURSE HEADER (Back + Title + Instructor)
          _buildCourseHeader(course, isMobile),

          // 3. MAIN CONTENT (Tabs + Body + Sidebar)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT SIDE: TABS + CONTENT
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLessonsTab(isMobile),
                            _buildAssignmentsTab(isMobile),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // RIGHT SIDE: PROGRESSION SIDEBAR
                if (!isMobile)
                  Container(
                    width: 320,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8, 
                              height: 8, 
                              decoration: const BoxDecoration(color: Color(0xFF007AFF), shape: BoxShape.circle)
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "PROGRESSION",
                              style: TextStyle(
                                fontWeight: FontWeight.w900, 
                                fontSize: 13, 
                                letterSpacing: 1.2, 
                                color: Color(0xFF0F172A)
                              ),
                            ),
                          ],
                        ),
                        // Espace pour le contenu futur de la progression
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavBar(bool isMobile) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Search Bar
          if (!isMobile)
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Rechercher...",
                    prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          const Spacer(),
          // Notifications
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
          // User Profile
          Obx(() {
            final user = _authController.currentUser.value;
            final username = user?['username'] ?? 'User';
            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: const Icon(Icons.person_outline, size: 22, color: Color(0xFF2563EB)),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      username, 
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569), fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCourseHeader(Course? course, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.chevron_left, color: Color(0xFF1E293B)),
          ),
          const SizedBox(width: 12),
          // Course Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course?.title ?? "Formation",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text(
                      "SESSION ACTIVE",
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.w800, 
                        color: Color(0xFF64748B), 
                        letterSpacing: 0.5
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Instructor
          if (!isMobile) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  "INSTRUCTEUR", 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)
                ),
                Text(
                  course?.instructorName ?? "louay", 
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 14)
                ),
              ],
            ),
            const SizedBox(width: 32),
          ],
          // Level Badge
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDBEAFE)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                course?.levelLabel ?? "Intermédiaire",
                style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF0F172A),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF007AFF),
        indicatorWeight: 3,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        tabs: [
          const Tab(
            height: 65,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book_rounded, size: 20),
                const SizedBox(width: 12),
                const Text("Leçons"),
              ],
            ),
          ),
          Tab(
            height: 65,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_outlined, size: 20),
                const SizedBox(width: 12),
                const Text("Devoirs"),
                const SizedBox(width: 8),
                Flexible(
                  child: Obx(() {
                    final dynamic args = Get.arguments;
                    Course? course;
                    if (args is Course) {
                      course = args;
                    } else if (args is Map) {
                      final dynamic c = args['course'];
                      if (c is Course) course = c;
                      else if (c is Assignment) {
                        final String? cid = c.courseId;
                        if (cid != null) {
                          course = _coursesController.courses.firstWhereOrNull((course) => course.id.toString() == cid);
                        }
                        // Fallback temporaire si non trouvé dans la liste
                        course ??= Course(id: cid ?? '', title: c.courseName ?? '', level: CourseLevel.debutant, price: 0);
                      }
                    }

                    final count = _assignmentsController.assignments.where((a) {
                      final String cid = a.courseId ?? '';
                      final String currentCid = course?.id.toString() ?? '';
                      final String aTitle = a.courseName?.trim().toLowerCase() ?? '';
                      final String cTitle = course?.title?.trim().toLowerCase() ?? '';
                      return (cid != '' && cid == currentCid) || (aTitle != '' && aTitle == cTitle);
                    }).length;
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(), 
                        style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w900)
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab(bool isMobile) {
    return Container(
      color: const Color(0xFFF0F7FF).withOpacity(0.5),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isMobile ? 80 : 120,
                  height: isMobile ? 80 : 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30)],
                  ),
                  child: Icon(Icons.menu_book_rounded, size: isMobile ? 32 : 48, color: const Color(0xFFE2E8F0)),
                ),
                SizedBox(height: isMobile ? 24 : 40),
                Text(
                  "Prêt à apprendre ?",
                  style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 40),
                  child: Text(
                    "Sélectionnez votre première leçon dans le menu latéral pour débuter ce cours.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16, 
                      color: const Color(0xFF64748B), 
                      height: 1.6, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab(bool isMobile) {
    final dynamic args = Get.arguments;
    Course? course;
    if (args is Course) {
      course = args;
    } else if (args is Map) {
      final dynamic c = args['course'];
      if (c is Course) course = c;
      else if (c is Assignment) {
        final String? cid = c.courseId;
        if (cid != null) {
          course = _coursesController.courses.firstWhereOrNull((course) => course.id.toString() == cid);
        }
        course ??= Course(
          id: cid ?? '', 
          title: c.courseName ?? '', 
          level: CourseLevel.debutant, 
          price: 0
        );
      }
    } else if (args is Assignment) {
      course = Course(
        id: args.courseId ?? '', 
        title: args.courseName ?? '', 
        level: CourseLevel.debutant, 
        price: 0
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 40),
      color: const Color(0xFFF0F7FF).withOpacity(0.5),
      child: Obx(() {
        if (_assignmentsController.isLoading.value && _assignmentsController.assignments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = _assignmentsController.assignments.where((a) {
          final String cid = a.courseId ?? '';
          final String currentCid = course?.id.toString() ?? '';
          
          final String aTitle = a.courseName?.trim().toLowerCase() ?? '';
          final String cTitle = course?.title?.trim().toLowerCase() ?? '';

          final bool match = (cid != '' && cid == currentCid) || (aTitle != '' && aTitle == cTitle);
          return match;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment_outlined, size: 90, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 24),
                const Text("Aucun devoir pour le moment", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildAssignmentCard(filtered[index], isMobile),
        );
      }),
    );
  }

  Widget _buildAssignmentCard(dynamic assignment, bool isMobile) {
    // Sur mobile très étroit, on passe en colonne pour éviter l'overflow
    final bool useVerticalLayout = isMobile;

    Widget buildContent() {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.assignment_rounded, color: Color(0xFF007AFF), size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "À rendre le ${assignment.formattedDueDate}",
                              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              assignment.description,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${assignment.maxPoints.toInt()} Points Max",
                style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildButton() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ElevatedButton(
          onPressed: () => Get.dialog(SubmitWorkDialog(assignment: assignment)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            minimumSize: useVerticalLayout ? const Size(double.infinity, 56) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.send_rounded, size: 20),
              SizedBox(width: 12),
              Text("Soumettre", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: useVerticalLayout
          ? Column(
              children: [
                buildContent(),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                buildButton(),
              ],
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: buildContent()),
                  const SizedBox(width: 20),
                  SizedBox(width: 200, child: buildButton()),
                ],
              ),
            ),
    );
  }
}
