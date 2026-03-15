// ============================================
// Page Study Spaces (Espaces d'étude)
// ============================================
//affiche les espaces disponibles pour la réservation.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/spaces_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/space.dart';
import '../../routing/app_routes.dart';

class StudySpacesPage extends StatelessWidget {
  const StudySpacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialise le contrôleur s'il n'existe pas déjà
    final SpacesController controller = Get.put(SpacesController());
    final AuthController authController = Get.find<AuthController>();
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOP NAV BAR (Search + Icons) - Similaire à Training Page pour cohérence
            _buildTopNavBar(authController, isMobile),

            // 2. HERO BANNER
            _buildHeroBanner(isMobile),

            // 3. SEARCH BAR RECHERCHE ESPACE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: _SpaceSearchBar(),
            ),

            // 4. GRID OF SPACES
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final spacesList = controller.filteredSpaces;
                if (spacesList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("Aucun espace trouvé."),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : (MediaQuery.of(context).size.width < 1400 ? 2 : 3),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    mainAxisExtent: 520, // Hauteur fixe pour les cartes
                  ),
                  itemCount: spacesList.length,
                  itemBuilder: (context, index) {
                    return _buildSpaceCard(spacesList[index], isMobile);
                  },
                );
              }),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar(AuthController authController, bool isMobile) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (!isMobile)
            Container(
              width: 350,
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
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 16),
          Obx(() {
            final user = authController.currentUser.value;
            final username = user?['username'] ?? 'User';
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: const Icon(Icons.person_outline, size: 20, color: Color(0xFF2563EB)),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Text(username, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(bool isMobile) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(isMobile ? 12 : 24),
      padding: EdgeInsets.all(isMobile ? 24 : 64),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "COWORKING & STUDY",
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: isMobile ? 28 : 48,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                height: 1.1,
              ),
              children: [
                const TextSpan(text: "Trouvez "),
                const TextSpan(text: "l'espace idéal ", style: TextStyle(color: Color(0xFF3B82F6))),
                TextSpan(text: isMobile ? "pour vos études" : "pour vos\nétudes"),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Réservez des bureaux premium, des salles de réunion ou des postes de travail équipés.",
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceCard(Space space, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section (Icon + Badges)
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.business_outlined, size: 64, color: Color(0xFFCBD5E1)),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Row(
                    children: [
                      _buildMiniBadge(space.typeString, Colors.white, const Color(0xFF475569)),
                      const SizedBox(width: 8),
                      _buildMiniBadge("Abonnement", const Color(0xFF007AFF), Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  space.name,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Location
                Row(
                  children: const [
                    Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF3B82F6)),
                    SizedBox(width: 6),
                    Text(
                      "XXXX",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Info Boxes
                Row(
                  children: [
                    Expanded(child: _buildInfoBox("CAPACITÉ", "${space.capacity} pers.")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfoBox("PAR MOIS", "${space.monthlyPrice.toInt()} DT", isHighlight: true)),
                  ],
                ),
                const SizedBox(height: 24),

                // Bottom Row (Price + Button)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                          children: [
                            TextSpan(text: "${space.hourlyPrice.toInt()} DT"),
                            TextSpan(
                              text: " / h",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Get.toNamed(AppRoutes.CHECKOUT, arguments: space),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Réserver", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isHighlight) ...[
                const Text("DT ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
              ] else ...[
                const Icon(Icons.people_outline, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isHighlight ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isHighlight ? const Color(0xFF3B82F6) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceSearchBar extends StatelessWidget {
  const _SpaceSearchBar();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SpacesController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF94A3B8), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              onChanged: controller.updateSearch,
              decoration: const InputDecoration(
                hintText: "Rechercher un espace (nom, type, étage...)",
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
