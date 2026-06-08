import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'widgets/sidebar.dart';
import 'routing/app_routes.dart';
import 'controllers/auth_controller.dart';

/// 🔹 Layout principal utilisé pour toutes les pages du dashboard
/// Il contient : Sidebar (Desktop) ou Drawer (Mobile) + contenu de la page
class DashboardLayout extends StatelessWidget {
  final Widget
  child; // 👉 Contenu de la page actuelle (dashboard, settings, etc.)

  DashboardLayout({super.key, required this.child});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // 🔹 Détermine si on est sur un grand écran (Desktop / Tablette)
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;
    final AuthController authController = Get.find<AuthController>();

    // Masque l'onglet "Mes" pour le rôle Admin et le rôle Space Manager
    final bool shouldHideMes =
        authController.isAdmin || authController.isSpaceManager;

    /// 🔹 Détermine quel onglet de la BottomNavigationBar doit être actif
    int currentIndex = 0;
    String currentRoute = Get.currentRoute;

    if (shouldHideMes) {
      // Si l'onglet "Mes" doit être masqué, on n'a que 3 onglets (Dashboard, Réserver, Menu)
      if (currentRoute == AppRoutes.DASHBOARD) {
        currentIndex = 0;
      } else if (currentRoute == AppRoutes.BOOK_SPACE) {
        currentIndex = 1;
      } else {
        currentIndex = 2; // Menu Drawer
      }
    } else {
      // Si l'onglet "Mes" est visible, on a 4 onglets (Dashboard, Réserver, Mes, Menu)
      if (currentRoute == AppRoutes.DASHBOARD) {
        currentIndex = 0;
      } else if (currentRoute == AppRoutes.BOOK_SPACE) {
        currentIndex = 1;
      } else if (currentRoute == AppRoutes.MY_RESERVATIONS) {
        currentIndex = 2;
      } else {
        currentIndex = 3; // Menu Drawer
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),

      /// 🔹 Menu latéral (Drawer) pour mobile
      drawer: isDesktop ? null : const Drawer(child: Sidebar()),

      /// 🔹 Contenu principal
      body: Row(
        children: [
          // Sidebar persistante sur Desktop
          if (isDesktop) const Sidebar(),

          // Contenu de la page
          Expanded(child: child),
        ],
      ),
      // 🔹 Barre de navigation inférieure pour mobile
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                if (shouldHideMes) {
                  switch (index) {
                    case 0:
                      Get.offAllNamed(AppRoutes.DASHBOARD);
                      break;
                    case 1:
                      Get.offAllNamed(
                        AppRoutes.BOOK_SPACE,
                      ); // Redirige vers la page de réservation d'espace
                      break;
                    case 2:
                      _scaffoldKey.currentState
                          ?.openDrawer(); // Ouvre le menu Drawer
                      break;
                  }
                } else {
                  switch (index) {
                    case 0:
                      Get.offAllNamed(AppRoutes.DASHBOARD);
                      break;
                    case 1:
                      Get.offAllNamed(AppRoutes.BOOK_SPACE);
                      break;
                    case 2:
                      Get.offAllNamed(AppRoutes.MY_RESERVATIONS);
                      break;
                    case 3:
                      _scaffoldKey.currentState?.openDrawer();
                      break;
                  }
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(
                0xFF64748B,
              ), // Slate 500 pour correspondre à l'image
              unselectedItemColor: const Color(0xFF64748B),
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: [
                // Affiche ou masque l'onglet "Mes" en fonction du rôle de l'utilisateur
                const BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Tableau',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.location_on_outlined),
                  label: 'Réserver',
                ),
                if (!shouldHideMes) // Masque l'onglet "Mes" pour les rôles Admin et Space Manager
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.event_available_outlined),
                    label: 'Mes',
                  ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.menu_rounded),
                  label: 'Menu',
                ),
              ],
            ),
    );
  }
}
