import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routing/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/spaces_controller.dart';
import '../../controllers/notification_controller.dart';
import '../spaces/create_space_page.dart';
import '../../widgets/notification_bell.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // S'assure que les dépendances sont là
    if (!Get.isRegistered<SpacesController>()) Get.put(SpacesController());
    
    final NotificationController notifController = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());
        
    final AuthController authController = Get.find<AuthController>();

    debugPrint('🏠 DASHBOARD LOAD → Rôle détecté: ${authController.currentRoleType}');

    final String userEmail = authController.currentUser.value?['email'] ?? '';
    final bool isSpecialUser = userEmail.toLowerCase() == 'authenticated@sunevit.tn';

    Widget dashboard;
    if (authController.isInstructor) {
      dashboard = _InstructorDashboard(notifController: notifController);
    } else if (authController.isAuthenticatedOnly && !isSpecialUser) {
      dashboard = _AuthenticatedDashboard(notifController: notifController);
    } else if (authController.isStudent || authController.isProfessional || isSpecialUser) {
      dashboard = _ModernDashboard(notifController: notifController);
    } else {
      dashboard = _AdminDashboard(notifController: notifController);
    }

    // On retourne le dashboard directement sans Scaffold interne pour éviter les conflits avec DashboardLayout
    return Container(
      color: const Color(0xFFF8FAFC),
      child: dashboard,
    );
  }
}

// ============================================================
// TABLEAU DE BORD MODERNE (POUR PROS, ÉTUDIANTS & AUTHENTICATED)
// ============================================================
class _ModernDashboard extends StatelessWidget {
  final NotificationController notifController;
  const _ModernDashboard({required this.notifController});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(notifController),
          const SizedBox(height: 24),
          
          // Header "Bienvenue"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bienvenue sur SUNSPACE', 
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('Gérez votre espace de travail', 
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.grid_view_rounded, color: Color(0xFF3B82F6), size: 24),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne Gauche : Carte de navigation principale
                  Expanded(
                    flex: 3,
                    child: _buildMainNavigationCard(),
                  ),
                  const SizedBox(width: 24),
                  // Colonne Droite : CTA Bleu + Cours Populaires
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildOptimizeTimeCard(),
                        const SizedBox(height: 24),
                        _buildPopularCoursesCard(),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildMainNavigationCard(),
                  const SizedBox(height: 24),
                  _buildOptimizeTimeCard(),
                  const SizedBox(height: 24),
                  _buildPopularCoursesCard(),
                ],
              );
            }
          }),
          
          const SizedBox(height: 40),
          const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _buildCommonQuickActions(context),
        ],
      ),
    );
  }
}

Widget _buildMainNavigationCard() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFF1F5F9)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
    ),
    child: Column(
      children: [
        _buildActionItem(
          icon: Icons.grid_view_rounded, iconBg: const Color(0xFFEFF6FF), iconColor: const Color(0xFF3B82F6),
          title: 'Tableau de bord', subtitle: 'Vue d\'ensemble de votre activité',
          onTap: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(left: 60),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
        _buildActionItem(
          icon: Icons.calendar_today_rounded, iconBg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF22C55E),
          title: 'Réserver un espace', subtitle: 'Trouvez et réservez votre bureau',
          onTap: () => Get.toNamed(AppRoutes.BOOK_SPACE),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 60),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
        _buildActionItem(
          icon: Icons.person_outline_rounded, iconBg: const Color(0xFFF5F3FF), iconColor: const Color(0xFF8B5CF6),
          title: 'Mon Profil', subtitle: 'Gérez vos informations personnelles',
          onTap: () => Get.toNamed(AppRoutes.PROFILE),
        ),
      ],
    ),
  );
}

Widget _buildCommonQuickActions(BuildContext context) {
  final actions = [
    {'label': 'Tableau de bord', 'icon': Icons.grid_view_rounded, 'route': AppRoutes.DASHBOARD, 'active': true},
    {'label': 'Réserver', 'icon': Icons.calendar_today_rounded, 'route': AppRoutes.BOOK_SPACE, 'active': false},
    {'label': 'Paramètres', 'icon': Icons.settings_outlined, 'route': AppRoutes.SETTINGS, 'active': false},
    {'label': 'Mon Profil', 'icon': Icons.person_outline_rounded, 'route': AppRoutes.PROFILE, 'active': false},
  ];

  return Row(
    children: actions.map((a) {
      final isActive = a['active'] as bool;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () {
              if (a['route'] != AppRoutes.DASHBOARD) {
                Get.toNamed(a['route'] as String);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? const Color(0xFF3B82F6).withOpacity(0.2) : const Color(0xFFF1F5F9)),
                boxShadow: [
                  if (isActive) 
                    BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  else
                    BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Icon(a['icon'] as IconData, size: 24, color: isActive ? const Color(0xFF3B82F6) : Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(a['label'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500, 
                        color: isActive ? const Color(0xFF3B82F6) : Colors.grey[600]
                      )),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

// ============================================================
// TABLEAU DE BORD ENSEIGNANT
// ============================================================
class _InstructorDashboard extends StatelessWidget {
  final NotificationController notifController;
  const _InstructorDashboard({required this.notifController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(notifController),
          const SizedBox(height: 24),
          const Text('Tableau de bord', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Bienvenue dans votre espace pédagogique', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 28),
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildTeachingManagementCard()),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildOptimizeTimeCard(),
                        const SizedBox(height: 20),
                        _buildPopularCoursesCard(),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildTeachingManagementCard(),
                  const SizedBox(height: 20),
                  _buildOptimizeTimeCard(),
                  const SizedBox(height: 20),
                  _buildPopularCoursesCard(),
                ],
              );
            }
          }),
          const SizedBox(height: 28),
          const Text('Actions rapides', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildQuickActionsInstructor(),
        ],
      ),
    );
  }

  Widget _buildTeachingManagementCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
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
                    const Text('Gestion des Enseignements', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('Tâches pédagogiques en attente', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF3B82F6), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionItem(
            icon: Icons.menu_book_outlined, iconBg: const Color(0xFFEFF6FF), iconColor: const Color(0xFF3B82F6),
            title: 'Gérer mes formations', subtitle: 'Créez et modifiez vos cours',
            onTap: () => Get.toNamed(AppRoutes.COURSES),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildActionItem(
            icon: Icons.people_outline_rounded, iconBg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF22C55E),
            title: 'Suivi des étudiants', subtitle: 'Consultez les progrès de vos élèves',
            onTap: () => Get.toNamed(AppRoutes.STUDENTS),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildActionItem(
            icon: Icons.calendar_month_outlined, iconBg: const Color(0xFFFFF7ED), iconColor: const Color(0xFFF97316),
            title: 'Planifier une session', subtitle: 'Organisez une nouvelle session de formation',
            onTap: () => Get.toNamed(AppRoutes.SESSIONS),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsInstructor() {
    final actions = [
      {'label': 'Réserver', 'icon': Icons.calendar_today_rounded, 'route': AppRoutes.BOOK_SPACE, 'active': true},
      {'label': 'Mes Formations', 'icon': Icons.menu_book_outlined, 'route': AppRoutes.COURSES, 'active': false},
      {'label': 'Catalogue', 'icon': Icons.school_outlined, 'route': AppRoutes.COURSE_CATALOG, 'active': false},
      {'label': 'Mon Profil', 'icon': Icons.person_outline_rounded, 'route': AppRoutes.PROFILE, 'active': false},
    ];

    return Row(
      children: actions.map((a) {
        final isActive = a['active'] as bool;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => Get.toNamed(a['route'] as String),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isActive ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Icon(a['icon'] as IconData, size: 24, color: isActive ? const Color(0xFF2563EB) : Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(a['label'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? const Color(0xFF2563EB) : Colors.grey[700])),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// TABLEAU DE BORD ADMIN
// ============================================================
class _AdminDashboard extends StatelessWidget {
  final NotificationController notifController;
  const _AdminDashboard({required this.notifController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(notifController),
          const SizedBox(height: 20),
          _buildAdminHeader(context),
          const SizedBox(height: 30),
          _buildAdminStats(),
          const SizedBox(height: 30),
          _buildRecentReservations(context),
          const SizedBox(height: 30),
          _buildPopularCoursesAdmin(),
          const SizedBox(height: 30),
          _buildQuickActionsAdmin(context),
        ],
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20, runSpacing: 20,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tableau de bord', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('Bienvenue dans votre espace de gestion SUNSPACE', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog.fullscreen(child: const CreateSpacePage()));
          },
          icon: const Icon(Icons.add_business),
          label: const Text('Ajouter un espace'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminStats() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 800) {
        return Row(
          children: [
            Expanded(child: _buildStatCard('Espaces totaux', '24', Icons.business, Colors.blue, '+2 ce mois')),
            const SizedBox(width: 20),
            Expanded(child: _buildStatCard('Réservations actives', '156', Icons.calendar_today, Colors.orange, '+12% vs mois dernier')),
            const SizedBox(width: 20),
            Expanded(child: _buildStatCard('Cours publiés', '18', Icons.book, Colors.red, '+1 ajouté récemment')),
          ],
        );
      } else {
        return Column(
          children: [
            _buildStatCard('Espaces totaux', '24', Icons.business, Colors.blue, '+2 ce mois'),
            const SizedBox(height: 15),
            _buildStatCard('Réservations actives', '156', Icons.calendar_today, Colors.orange, '+12% vs mois dernier'),
            const SizedBox(height: 15),
            _buildStatCard('Cours publiés', '18', Icons.book, Colors.red, '+1 ajouté récemment'),
          ],
        );
      }
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500))),
            Icon(icon, color: color.withOpacity(0.8)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(children: [const Icon(Icons.trending_up, size: 16, color: Colors.green), const SizedBox(width: 5), Text(trend, style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
        ],
      ),
    );
  }

  Widget _buildRecentReservations(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Réservations récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('Activité de réservation en temps réel', style: TextStyle(color: Colors.grey[600], fontSize: 13))])),
            TextButton(onPressed: () {}, child: const Row(children: [Text('Voir tout'), Icon(Icons.arrow_forward, size: 16)])),
          ]),
          const SizedBox(height: 20),
          _buildReservationItem('Bureau Premium', 'Alice Martin', '2026-01-28 10:00 - 12:00', 'Confirmée', Colors.green),
          const Divider(height: 30),
          _buildReservationItem('Salle de Réunion', 'Bob Dupont', '2026-01-28 14:00 - 16:00', 'Confirmée', Colors.green),
        ],
      ),
    );
  }

  Widget _buildReservationItem(String space, String user, String time, String status, Color statusColor) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(space, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 4), Text('$user · $time', style: TextStyle(color: Colors.grey[600], fontSize: 13))])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold))),
    ]);
  }

  Widget _buildPopularCoursesAdmin() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Cours populaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('Les plus suivis', style: TextStyle(color: Colors.grey[600], fontSize: 13))])),
            IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_forward, size: 20)),
          ]),
          const SizedBox(height: 20),
          _buildCourseItem('Démarrage avec Next.js', '324 étudiants', '4.8', '#1'),
          const Divider(height: 30),
          _buildCourseItem('Design UX/UI', '412 étudiants', '4.9', '#2'),
          const Divider(height: 30),
          _buildCourseItem('Maîtriser TypeScript', '189 étudiants', '4.7', '#3'),
        ],
      ),
    );
  }

  Widget _buildCourseItem(String title, String students, String rating, String rank) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(students, style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(rank, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)), Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))])]),
    ]);
  }

  Widget _buildQuickActionsAdmin(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 15, crossAxisSpacing: 15,
              childAspectRatio: constraints.maxWidth > 600 ? 1.8 : 1.5,
              children: [
                _buildQuickActionItemAdmin('Nouvel espace', Icons.business_outlined, () {
                  showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog.fullscreen(child: const CreateSpacePage()));
                }),
                _buildQuickActionItemAdmin('Nouveau cours', Icons.menu_book_outlined, () => Get.toNamed(AppRoutes.COURSES)),
                _buildQuickActionItemAdmin('Utilisateurs', Icons.people_outline, () => Get.toNamed(AppRoutes.USERS)),
                _buildQuickActionItemAdmin('Analytiques', Icons.analytics_outlined, () => Get.toNamed(AppRoutes.ANALYTICS)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionItemAdmin(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.black87, size: 26), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))]),
      ),
    );
  }
}

// ============================================================
// WIDGETS COMMUNS MÉTIERS
// ============================================================

Widget _buildTopBar(NotificationController notifController) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      const NotificationBell(size: 28, iconColor: Colors.black87),
      const SizedBox(width: 16),
      InkWell(
        onTap: () => Get.toNamed(AppRoutes.PROFILE),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.person_outline, color: Colors.blue, size: 24),
        ),
      ),
    ],
  );
}

Widget _buildActionItem({required IconData icon, required Color iconBg, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF0F172A))), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500]))])),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
        ],
      ),
    ),
  );
}

Widget _buildOptimizeTimeCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Optimisez votre temps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        const Text("Réservez vos créneaux de formation à l'avance pour garantir votre place.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.BOOK_SPACE),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('Réserver maintenant', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPopularCoursesCard() {
  final courses = [
    {'title': 'Démarrage avec Next.js', 'students': '324', 'rating': '4.8'},
    {'title': 'Design UX/UI', 'students': '412', 'rating': '4.9'},
    {'title': 'Maîtriser TypeScript', 'students': '189', 'rating': '4.7'},
  ];
  final dotColors = [const Color(0xFF3B82F6), const Color(0xFF22C55E), const Color(0xFFF97316)];

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COURS POPULAIRES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ...courses.asMap().entries.map((e) {
          final c = e.value;
          return Column(
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColors[e.key], shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Row(children: [Icon(Icons.people_outline, size: 12, color: Colors.grey[400]), const SizedBox(width: 4), Text(c['students']!, style: TextStyle(fontSize: 11, color: Colors.grey[500])), const SizedBox(width: 10), const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24)), const SizedBox(width: 3), Text(c['rating']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]),
                      ],
                    ),
                  ),
                ],
              ),
              if (e.key < courses.length - 1) const Divider(height: 20, color: Color(0xFFF1F5F9)),
            ],
          );
        }),
      ],
    ),
  );
}
// ============================================================
// TABLEAU DE BORD AUTHENTICATED
// ============================================================
class _AuthenticatedDashboard extends StatelessWidget {
  final NotificationController notifController;
  const _AuthenticatedDashboard({required this.notifController});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final authController = Get.find<AuthController>();
    final username = authController.currentUser.value?['username'] ?? 'authenticated';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(notifController),
          const SizedBox(height: 24),
          
          Text('Tableau de bord', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Bienvenue $username', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          
          const SizedBox(height: 32),
          
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildAuthNavigationCard()),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildOptimizeTimeCard(),
                        const SizedBox(height: 24),
                        _buildPopularCoursesCard(),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildAuthNavigationCard(),
                  const SizedBox(height: 24),
                  _buildOptimizeTimeCard(),
                  const SizedBox(height: 24),
                  _buildPopularCoursesCard(),
                ],
              );
            }
          }),
          
          const SizedBox(height: 40),
          const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _buildCommonQuickActions(context),
        ],
      ),
    );
  }
}

Widget _buildAuthNavigationCard() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
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
                  const Text('Bienvenue sur SUNSPACE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text('Gérez votre espace de travail', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.grid_view_rounded, color: Color(0xFF3B82F6), size: 24),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildActionItem(
          icon: Icons.grid_view_rounded, iconBg: const Color(0xFFEFF6FF), iconColor: const Color(0xFF3B82F6),
          title: 'Tableau de bord', subtitle: 'Vue d\'ensemble de votre activité',
          onTap: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(left: 60),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
        _buildActionItem(
          icon: Icons.calendar_today_rounded, iconBg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF22C55E),
          title: 'Réserver un espace', subtitle: 'Trouvez et réservez votre bureau',
          onTap: () => Get.toNamed(AppRoutes.BOOK_SPACE),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 60),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
        _buildActionItem(
          icon: Icons.person_outline_rounded, iconBg: const Color(0xFFF5F3FF), iconColor: const Color(0xFF8B5CF6),
          title: 'Mon Profil', subtitle: 'Gérez vos informations personnelles',
          onTap: () => Get.toNamed(AppRoutes.PROFILE),
        ),
      ],
    ),
  );
}

