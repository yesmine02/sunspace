import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routing/app_routes.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final currentRoute = Get.currentRoute;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // 🔷 HEADER
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'SUNSPACE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 🔷 NAVIGATION - Basé sur le rôle DYNAMIQUE de Strapi
          Expanded(
            child: Obx(() {
              // 🔹 Si le rôle est en cours de chargement, on affiche un loader
              if (authController.isFetchingRole.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(height: 12),
                      Text(
                        'Chargement du rôle...',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              // 🔹 Rôle récupéré depuis Strapi
              final bool isAdmin = authController.isAdmin;
              final bool isInstructor = authController.isInstructor;
              final bool isStudent = authController.isStudent;
              final bool isPro = authController.isProfessional;
              final bool isAssoc = authController.isAssociation;
              final bool isSpaceManager = authController.isSpaceManager;
              final bool isAuthenticatedOnly = authController.isAuthenticatedOnly;

              // Badge du rôle courant (affiché dans le menu pour info)
              final String roleName = authController.currentRoleName;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // Indicateur de rôle courant
                  if (roleName.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 6),
                          Text(
                            roleName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- ACCÈS GÉNÉRAL (Dashboard toujours visible) ---
                  _buildMenuItem(
                    title: 'Tableau de bord',
                    icon: Icons.grid_view_rounded,
                    isActive: currentRoute == AppRoutes.DASHBOARD,
                    onTap: () => Get.offAllNamed(AppRoutes.DASHBOARD),
                  ),
                  
                  // --- ITEMS ACCESSIBLES POUR ADMIN, ENSEIGNANT, AUTHENTIFIÉ, GESTIONNAIRE, PROFESSIONNEL ET ASSOCIATION ---
                  if (isAdmin || isInstructor || isAuthenticatedOnly || isSpaceManager || isPro || isAssoc) ...[
                    _buildMenuItem(
                      title: 'Réserver un espace',
                      icon: Icons.location_on_outlined,
                      isActive: currentRoute == AppRoutes.BOOK_SPACE,
                      onTap: () => Get.offAllNamed(AppRoutes.BOOK_SPACE),
                    ),
                    _buildMenuItem(
                      title: 'Mes Réservations',
                      icon: Icons.event_available_outlined,
                      isActive: currentRoute == AppRoutes.MY_RESERVATIONS,
                      onTap: () => Get.offAllNamed(AppRoutes.MY_RESERVATIONS),
                    ),
                  ],

                  // --- ITEMS SPÉCIFIQUES GESTIONNAIRE D'ESPACE ET ADMIN ---
                  if (isAdmin || isSpaceManager) ...[
                    _buildMenuItem(
                      title: 'Espaces',
                      icon: Icons.apartment_outlined,
                      isActive: currentRoute == AppRoutes.SPACES,
                      onTap: () => Get.offAllNamed(AppRoutes.SPACES),
                    ),
                    _buildMenuItem(
                      title: 'Équipements',
                      icon: Icons.build_outlined,
                      isActive: currentRoute == AppRoutes.EQUIPMENTS,
                      onTap: () => Get.offAllNamed(AppRoutes.EQUIPMENTS),
                    ),
                    _buildMenuItem(
                      title: 'Réservations',
                      icon: Icons.assignment_outlined,
                      isActive: currentRoute == AppRoutes.RESERVATIONS,
                      onTap: () => Get.offAllNamed(AppRoutes.RESERVATIONS),
                    ),
                  ],

                  // --- ITEMS RÉSERVÉS UNIQUEMENT À L'ADMIN ---
                  if (isAdmin) ...[
                    _buildMenuItem(
                      title: 'Utilisateurs',
                      icon: Icons.people_outline,
                      isActive: currentRoute == AppRoutes.USERS,
                      onTap: () => Get.offAllNamed(AppRoutes.USERS),
                    ),
                    _buildMenuItem(
                      title: 'Associations',
                      icon: Icons.account_balance_outlined,
                      isActive: currentRoute == AppRoutes.ASSOC_LIST,
                      onTap: () => Get.offAllNamed(AppRoutes.ASSOC_LIST),
                    ),
                  ],

                  // --- SECTION ENSEIGNANT ---
                  if (isInstructor || isAdmin) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader('ENSEIGNANT'),
                    _buildMenuItem(
                      title: 'Mes formations',
                      icon: Icons.menu_book_rounded,
                      isActive: currentRoute == AppRoutes.COURSES,
                      onTap: () => Get.offAllNamed(AppRoutes.COURSES),
                    ),
                    _buildMenuItem(
                      title: 'Sessions',
                      icon: Icons.calendar_today_outlined,
                      isActive: currentRoute == AppRoutes.SESSIONS,
                      onTap: () => Get.offAllNamed(AppRoutes.SESSIONS),
                    ),
                    _buildMenuItem(
                      title: 'Étudiants',
                      icon: Icons.school_outlined,
                      isActive: currentRoute == AppRoutes.STUDENTS,
                      onTap: () => Get.offAllNamed(AppRoutes.STUDENTS),
                    ),
                    _buildMenuItem(
                      title: 'Devoirs',
                      icon: Icons.assignment_outlined,
                      isActive: currentRoute == AppRoutes.TASKS,
                      onTap: () => Get.offAllNamed(AppRoutes.TASKS),
                    ),
                    _buildMenuItem(
                      title: 'Communication',
                      icon: Icons.chat_bubble_outline_rounded,
                      isActive: currentRoute == AppRoutes.COMMUNICATION,
                      onTap: () => Get.offAllNamed(AppRoutes.COMMUNICATION),
                    ),
                  ],

                  // --- SECTION ÉTUDIANT ---
                  if (isStudent || isAdmin) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader('ÉTUDIANT'),
                    _buildMenuItem(
                      title: 'Mes cours',
                      icon: Icons.menu_book_rounded,
                      isActive: currentRoute == AppRoutes.MY_COURSES,
                      onTap: () => Get.offAllNamed(AppRoutes.MY_COURSES),
                    ),
                    _buildMenuItem(
                      title: 'Mes devoirs',
                      icon: Icons.assignment_outlined,
                      isActive: currentRoute == AppRoutes.TASKS,
                      onTap: () => Get.offAllNamed(AppRoutes.TASKS),
                    ),
                    _buildMenuItem(
                      title: 'Catalogue Cours',
                      icon: Icons.school_outlined,
                      isActive: currentRoute == AppRoutes.MY_COURSES,
                      onTap: () => Get.offAllNamed(AppRoutes.MY_COURSES),
                    ),
                    _buildMenuItem(
                      title: "Espaces d'étude",
                      icon: Icons.apartment_outlined,
                      isActive: currentRoute == AppRoutes.STUDY_SPACES,
                      onTap: () => Get.offAllNamed(AppRoutes.STUDY_SPACES),
                    ),
                    _buildMenuItem(
                      title: 'Sessions',
                      icon: Icons.calendar_today_outlined,
                      isActive: currentRoute == AppRoutes.TRAINING,
                      onTap: () => Get.offAllNamed(AppRoutes.TRAINING),
                    ),
                    _buildMenuItem(
                      title: 'Communication',
                      icon: Icons.people_outline_rounded,
                      isActive: currentRoute == AppRoutes.COMMUNICATION,
                      onTap: () => Get.offAllNamed(AppRoutes.COMMUNICATION),
                    ),
                  ],

                  // --- SECTION PROFESSIONNEL ---
                  if (isPro || isAdmin) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader('PROFESSIONNEL'),
                    _buildMenuItem(
                      title: 'Formations',
                      icon: Icons.school_outlined,
                      isActive: currentRoute == AppRoutes.TRAINING,
                      onTap: () => Get.offAllNamed(AppRoutes.TRAINING),
                    ),
                    _buildMenuItem(
                      title: 'Abonnements',
                      icon: Icons.calendar_month_outlined,
                      isActive: currentRoute == AppRoutes.SUBSCRIPTION_PAYMENT,
                      onTap: () => Get.offAllNamed(AppRoutes.SUBSCRIPTION_PAYMENT),
                    ),
                    _buildMenuItem(
                      title: 'Mon Profil',
                      icon: Icons.person_outline_rounded,
                      isActive: currentRoute == AppRoutes.PROFILE,
                      onTap: () => Get.offAllNamed(AppRoutes.PROFILE),
                    ),
                  ],

                  // --- SECTION ASSOCIATION ---
                  if (isAssoc || isAdmin) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader('ASSOCIATION'),
                    _buildMenuItem(
                      title: 'Formations',
                      icon: Icons.menu_book_rounded,
                      isActive: currentRoute == AppRoutes.ASSOC_TRAININGS,
                      onTap: () => Get.offAllNamed(AppRoutes.ASSOC_TRAININGS),
                    ),
                    _buildMenuItem(
                      title: 'Membres',
                      icon: Icons.people_outline,
                      isActive: currentRoute == AppRoutes.ASSOC_MEMBERS,
                      onTap: () => Get.offAllNamed(AppRoutes.ASSOC_MEMBERS),
                    ),
                    _buildMenuItem(
                      title: 'Budget & Utilisation',
                      icon: Icons.bar_chart_rounded,
                      isActive: currentRoute == AppRoutes.ASSOC_BUDGET,
                      onTap: () => Get.offAllNamed(AppRoutes.ASSOC_BUDGET),
                    ),
                  ],
                ],
              );
            }),
          ),

          // 🔷 FOOTER (USER & LOGOUT)
          _buildFooter(authController),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8), // Slate 400
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF007AFF) : Colors.transparent, // Vibrant blue from image
        borderRadius: BorderRadius.circular(10), // More modern radius
      ),
      child: ListTile(
        onTap: onTap ?? () {},
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFF1E293B), // Dark slate
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF1E293B),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15, // Matching image font size feel
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFooter(AuthController authController) {
    return Obx(() {
      final user = authController.currentUser.value;
      final email = user?['email'] ?? 'admin@sunspace.app';

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Utilisateur',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Get.defaultDialog(
                  title: "Déconnexion",
                  middleText: "Voulez-vous vraiment vous déconnecter ?",
                  textConfirm: "Oui",
                  textCancel: "Non",
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    authController.logout();
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(color: Colors.grey.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, size: 18, color: Colors.black87),
                  SizedBox(width: 8),
                  Text('Déconnexion', style: TextStyle(color: Colors.black87, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
//fonction privée (✅ “Cette fonctionnalité n’est pas encore prête”.)
  void _showNotImplemented(String feature) {
    Get.snackbar(
      'Information',
      '$feature sera disponible prochainement.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade50,
      colorText: Colors.blue.shade900,
      icon: const Icon(Icons.info_outline, color: Colors.blue),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}
