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
import '../../widgets/notification_bell.dart';
import 'package:intl/intl.dart';
import '../../controllers/booking_controller.dart';

class StudySpacesPage extends StatelessWidget {
  const StudySpacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialise le contrôleur s'il n'existe pas déjà
    final SpacesController controller = Get.put(SpacesController());
    final BookingController bookingController = Get.put(BookingController());
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
                    return _buildSpaceCard(context, spacesList[index], isMobile, bookingController);
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
          const NotificationBell(iconColor: Color(0xFF475569)),
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

  Widget _buildSpaceCard(BuildContext context, Space space, bool isMobile, BookingController bookingController) {
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
                    Expanded(child: _buildInfoBox("CAPACITÉ", "${space.capacity} personnes")),
                  ],
                ),
                const SizedBox(height: 24),

                // Bottom Row (Price + Button)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleReservationClick(context, space, bookingController),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Réserver", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
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

  /// Gère le clic sur le bouton de réservation en fonction du statut.
  void _handleReservationClick(BuildContext context, Space space, BookingController controller) {
    if (space.status == SpaceStatus.disponible) {
      _showBookingDialog(context, space, controller);
    } else if (space.status == SpaceStatus.occupe) {
      _showStatusDialog(
        context,
        title: "Espace Occupé",
        message: "Cet espace est actuellement occupé. Veuillez choisir un autre créneau ou un autre espace.",
        icon: Icons.person_off_rounded,
        color: Colors.orange,
      );
    } else if (space.status == SpaceStatus.maintenance) {
      _showStatusDialog(
        context,
        title: "En Maintenance",
        message: "Cet espace est actuellement en maintenance pour améliorer nos services. Merci de votre compréhension.",
        icon: Icons.construction_rounded,
        color: Colors.blueGrey,
      );
    }
  }

  /// Affiche une boîte de dialogue d'information sur le statut.
  void _showStatusDialog(BuildContext context, {required String title, required String message, required IconData icon, required Color color}) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("D'accord", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  /// Ouvre le dialogue de réservation (le même que sur le plan 3D).
  void _showBookingDialog(BuildContext context, Space space, BookingController controller) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final AuthController authController = Get.find<AuthController>();
    final bool isStudent = authController.isStudent;

    // Réinitialisation des données pour une nouvelle session de réservation.
    controller.selectedServices.clear();
    controller.isMonthly.value = false;
    
    // Détermination des dates par défaut (J+1h à J+3h).
    controller.updateDates(
      DateTime.now().add(const Duration(hours: 1)), 
      DateTime.now().add(const Duration(hours: 3)), 
      space.hourlyPrice,
      space.monthlyPrice
    );

    // Charger l'emploi du temps initial
    controller.fetchSpaceReservationsOnDay(space.documentId ?? space.id.toString(), controller.startDateTime.value);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
        child: Container(
          width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 500,
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text("Réserver : ${space.name}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // 1. Durée et Heures
                const Text("Date et Heure", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildDateTimePicker(context, controller, space.hourlyPrice, space.monthlyPrice, space.documentId ?? space.id.toString()),
                const SizedBox(height: 16),

                // Emploi du temps (Schedule)
                _buildScheduleView(controller),
                            // 2. Services extra (Café, Projecteur, etc.)
                const Text("Services additionnels", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.servicesCatalog.entries.map((entry) {
                    final String name = entry.key;
                    final Map<String, dynamic> info = entry.value;
                    final bool isAvailable = info['available'] ?? true;
                    final isSelected = controller.selectedServices.contains(name);
                    final double price = info['price'] ?? 0.0;

                    return GestureDetector(
                      onTap: isAvailable 
                        ? () => controller.toggleService(name, space.hourlyPrice, space.monthlyPrice)
                        : () => Get.snackbar(
                            "Indisponible", 
                            "L'équipement '$name' est actuellement en maintenance.",
                            backgroundColor: Colors.orange.shade800,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFF007AFF) 
                              : (isAvailable ? const Color(0xFFDCFCE7) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF007AFF) : (isAvailable ? const Color(0xFFBBF7D0) : Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$name (${price.toInt()}TND/j)",
                              style: TextStyle(
                                color: isSelected 
                                    ? Colors.white 
                                    : (isAvailable ? const Color(0xFF166534) : Colors.grey.shade500),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check_circle, size: 14, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )),
                const SizedBox(height: 32),

                const SizedBox(height: 24),

                // Bouton final de confirmation
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : () => controller.createReservation(space),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF), 
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: controller.isLoading.value 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Confirmer la réservation", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget de sélection de date/heure.
  Widget _buildDateTimePicker(BuildContext context, BookingController controller, double hourlyPrice, double monthlyPrice, String spaceId) {
    return Obx(() {
      final start = controller.startDateTime.value;
      final end = controller.endDateTime.value;
      final isAllDay = controller.isAllDay.value;
      final dateStr = DateFormat('dd MMMM yyyy', 'fr').format(start);
      final startTimeStr = DateFormat('HH:mm').format(start);
      final endTimeStr = DateFormat('HH:mm').format(end);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              DateTime? date = await showDatePicker(context: context, initialDate: start, firstDate: DateTime.now(), lastDate: DateTime(2030));
              if (date != null) {
                final newStart = DateTime(date.year, date.month, date.day, start.hour, start.minute);
                final duration = end.difference(start);
                controller.updateDates(newStart, newStart.add(duration), hourlyPrice, monthlyPrice);
                controller.fetchSpaceReservationsOnDay(spaceId, newStart);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text("Date : $dateStr", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeDropdown(
                  context,
                  controller,
                  "Heure de début",
                  startTimeStr,
                  isAllDay,
                  (String? newValue) {
                    if (newValue != null) {
                      final parts = newValue.split(':');
                      final newStart = DateTime(start.year, start.month, start.day, int.parse(parts[0]), int.parse(parts[1]));
                      controller.updateDates(newStart, end, hourlyPrice, monthlyPrice);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeDropdown(
                  context,
                  controller,
                  "Heure de fin",
                  endTimeStr,
                  isAllDay,
                  (String? newValue) {
                    if (newValue != null) {
                      final parts = newValue.split(':');
                      final newEnd = DateTime(end.year, end.month, end.day, int.parse(parts[0]), int.parse(parts[1]));
                      controller.updateDates(start, newEnd, hourlyPrice, monthlyPrice);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildTimeDropdown(BuildContext context, BookingController controller, String label, String value, bool isDisabled, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDisabled ? Colors.grey.shade100 : const Color(0xFF10B981), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.timeSlots.contains(value) ? value : null,
              hint: const Text("Choisir", style: TextStyle(fontSize: 13)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              onChanged: isDisabled ? null : onChanged,
              items: controller.timeSlots.map((String slot) {
                return DropdownMenuItem<String>(
                  value: slot,
                  child: Text(slot, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleView(BookingController controller) {
    return Obx(() {
      final reservations = controller.spaceReservationsOnDay;
      final dateLabel = DateFormat("Aujourd'hui", 'fr').format(controller.startDateTime.value) == DateFormat("Aujourd'hui", 'fr').format(DateTime.now())
          ? "Aujourd'hui"
          : DateFormat('dd/MM', 'fr').format(controller.startDateTime.value);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Emploi du temps du $dateLabel", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: reservations.isEmpty
                ? const Center(
                    child: Text(
                      "Aucune réservation pour cette date",
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reservations.map((res) {
                      final start = DateFormat('HH:mm').format(res.startDateTime);
                      final end = DateFormat('HH:mm').format(res.endDateTime);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: Text(
                          "$start - $end",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      );
    });
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
