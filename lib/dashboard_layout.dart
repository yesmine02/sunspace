import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'widgets/sidebar.dart';
import 'routing/app_routes.dart';

/// 🔹 Layout principal utilisé pour toutes les pages du dashboard
/// Il contient : Sidebar (Desktop) ou Drawer (Mobile) + contenu de la page
class DashboardLayout extends StatelessWidget {
  final Widget child; // 👉 Contenu de la page actuelle (dashboard, settings, etc.)

  DashboardLayout({super.key, required this.child});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // 🔹 Détermine si on est sur un grand écran (Desktop / Tablette)
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    /// 🔹 Détermine quel onglet de la BottomNavigationBar doit être actif
    int currentIndex = 0;
    String currentRoute = Get.currentRoute;

    if (currentRoute == AppRoutes.DASHBOARD) {
      currentIndex = 0;
    } else if (currentRoute == AppRoutes.BOOK_SPACE) {
      currentIndex = 1;
    } else if (currentRoute == AppRoutes.MY_RESERVATIONS) {
      currentIndex = 2;
    } else {
      currentIndex = 3;
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
          Expanded(
            child: child,
          ),
        ],
      ),

      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
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
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF64748B), // Slate 500 pour correspondre à l'image
              unselectedItemColor: const Color(0xFF64748B),
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Tableau',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.location_on_outlined),
                  label: 'Réserver',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event_available_outlined),
                  label: 'Mes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_rounded),
                  label: 'Menu',
                ),
              ],
            ),
    );
  }
}
