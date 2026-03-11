import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routing/app_routes.dart';
import '../../controllers/spaces_controller.dart';
import '../spaces/create_space_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    // S'assure que SpacesController est disponible pour CreateSpacePage
    Get.put(SpacesController());
    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Icons (Notification & Profile)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                // Notification Icon with Blue Dot
                InkWell(
                  onTap: () {
                    Get.snackbar('Notifications', 'Aucune nouvelle notification');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_outlined,
                        size: 28,
                        color: Colors.black87,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Profile Icon with Light Blue Circle
                InkWell(
                  onTap: () {
                    Get.toNamed(AppRoutes.PROFILE);
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Header Section
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 350),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableau de bord',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Bienvenue dans votre espace de gestion SUNSPACE',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Ouvre la page de création d'espace comme fenêtre modale plein écran
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => Dialog.fullscreen(
                      child: const CreateSpacePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_business),
                label: const Text('Ajouter un espace'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),

          SizedBox(height: 30),

          // Stats Cards
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid: 3 cards on wide screens, 1 column on small
              if (constraints.maxWidth > 800) {
                return Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Espaces totaux', '24', Icons.business, Colors.blue, '+2 ce mois')),
                    const SizedBox(width: 20),
                    Expanded(
                        child: _buildStatCard('Réservations actives', '156', Icons.calendar_today,
                            Colors.orange, '+12% vs mois dernier')),
                    const SizedBox(width: 20),
                    Expanded(
                        child: _buildStatCard('Cours publiés', '18', Icons.book, Colors.red,
                            '+1 ajouté récemment')),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildStatCard(
                        'Espaces totaux', '24', Icons.business, Colors.blue, '+2 ce mois'),
                    const SizedBox(height: 15),
                    _buildStatCard('Réservations actives', '156', Icons.calendar_today,
                        Colors.orange, '+12% vs mois dernier'),
                    const SizedBox(height: 15),
                    _buildStatCard(
                        'Cours publiés', '18', Icons.book, Colors.red, '+1 ajouté récemment'),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 30),

          // 1. Réservations récentes
          _buildRecentReservations(),

          const SizedBox(height: 30),

          // 2. Cours populaires
          _buildPopularCourses(),

          const SizedBox(height: 30),

          // 3. Actions rapides
          _buildQuickActions(),

          const SizedBox(height: 30),

          // 4. Statistiques secondaires (Taux d'occupation puis Revenu)
          _buildSecondaryStatsReordered(),
        ],
      ),
    );
  }

  Widget _buildSecondaryStatsReordered() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 700) {
        return Row(
          children: [
            Expanded(
                child: _buildDetailedStatCard('Taux d\'occupation', '87%', Icons.bar_chart,
                    Colors.blue, '+5% vs semaine dernière', Colors.green)),
            const SizedBox(width: 20),
            Expanded(
                child: _buildDetailedStatCard('Revenu ce mois', '\$8,432.50', Icons.attach_money,
                    Colors.blue, '+18% vs mois dernier', Colors.green)),
          ],
        );
      } else {
        return Column(
          children: [
            _buildDetailedStatCard('Taux d\'occupation', '87%', Icons.bar_chart, Colors.blue,
                '+5% vs semaine dernière', Colors.green),
            const SizedBox(height: 15),
            _buildDetailedStatCard('Revenu ce mois', '\$8,432.50', Icons.attach_money, Colors.blue,
                '+18% vs mois dernier', Colors.green),
          ],
        );
      }
    });
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            double width = constraints.maxWidth;
            int crossAxisCount = width > 600 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: width > 600 ? 1.8 : 1.5,
              children: [
                _buildQuickActionItem('Nouvel espace', Icons.business_outlined, () {
                  // Même action que le bouton principal
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => Dialog.fullscreen(
                      child: const CreateSpacePage(),
                    ),
                  );
                }),
                _buildQuickActionItem('Nouveau cours', Icons.menu_book_outlined, () {
                  Get.snackbar('Action', 'Ajouter un nouveau cours');
                }),
                _buildQuickActionItem('Utilisateurs', Icons.people_outline, () {
                  Get.snackbar('Action', 'Gérer les utilisateurs');
                }),
                _buildQuickActionItem('Analytiques', Icons.analytics_outlined, () {
                  Get.snackbar('Action', 'Voir les statistiques');
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatCard(String title, String value, IconData icon, Color iconColor,
      String trend, Color trendColor) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 10),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Text(trend,
                    style:
                        TextStyle(color: trendColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String trend) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Icon(icon, color: color.withValues(alpha: 0.8)),
            ],
          ),
          SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: Colors.green), // Mock trend icon
              SizedBox(width: 5),
              Text(trend, style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReservations() {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4))],
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
                    Text('Réservations récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Activité de réservation en temps réel', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              TextButton(onPressed: () {}, child: Row(children: [Text('Voir tout'), Icon(Icons.arrow_forward, size: 16)])),
            ],
          ),
          SizedBox(height: 20),
          _buildReservationItem('Bureau Premium', 'Alice Martin', '2026-01-28 10:00 - 12:00', 'Confirmée', Colors.green),
          Divider(height: 30),
          _buildReservationItem('Salle de Réunion', 'Bob Dupont', '2026-01-28 14:00 - 16:00', 'Confirmée', Colors.green),
        ],
      ),
    );
  }

  Widget _buildReservationItem(String space, String user, String time, String status, Color statusColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(space, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 4),
              Text('$user · $time', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPopularCourses() {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4))],
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
                    Text('Cours populaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Les plus suivis', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: Icon(Icons.arrow_forward, size: 20)),
            ],
          ),
          SizedBox(height: 20),
          _buildCourseItem('Démarrage avec Next.js', '324 étudiants', '4.8', '#1'),
          Divider(height: 30),
          _buildCourseItem('Design UX/UI', '412 étudiants', '4.9', '#2'),
          Divider(height: 30),
          _buildCourseItem('Maîtriser TypeScript', '189 étudiants', '4.7', '#3'),
        ],
      ),
    );
  }
  
  Widget _buildCourseItem(String title, String students, String rating, String rank) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 4),
              Text(students, style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
             Text(rank, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
             Row(
               children: [
                 Icon(Icons.star, color: Colors.amber, size: 14),
                 Text(rating, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
               ],
             )
          ],
        )
      ],
    );
  }
}
