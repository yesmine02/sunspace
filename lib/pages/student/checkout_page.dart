// ============================================
// Page Checkout (Paiement)
// ============================================
//gère le processus de paiement et de réservation.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/space.dart';
import '../../widgets/notification_bell.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BookingController controller = Get.put(BookingController());
    final AuthController authController = Get.find<AuthController>();
    final Space? space = Get.arguments as Space?;
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    if (space != null) {
      // Initialiser le total au chargement (Abonnement par défaut)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.calculateTotal(
          hourlyPrice: space.hourlyPrice, 
          monthlyPrice: space.monthlyPrice
        );
        // Charger l'emploi du temps initial
        controller.fetchSpaceReservationsOnDay(space.documentId ?? space.id.toString(), controller.startDateTime.value);
      });

    }

    if (space == null) {
      return const Scaffold(body: Center(child: Text("Erreur: Espace non trouvé")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: Column(
        children: [
          _buildTopNavBar(authController, isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 64, 
                vertical: 40
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(space, isMobile),
                  const SizedBox(height: 48),

                  // Stepper
                  _buildStepper(controller),
                  const SizedBox(height: 48),

                  // Main Content Layout
                  Obx(() {
                    if (controller.checkoutStep.value == 1) {
                      return isMobile 
                        ? Column(
                            children: [
                              if (!authController.isStudent) _buildFormulaCard(context, controller, space),
                              const SizedBox(height: 24),
                              _buildSummaryCard(space),
                              const SizedBox(height: 24),
                              _buildInfoCard(),
                              if (authController.isStudent) ...[
                                const SizedBox(height: 24),
                                _buildStudentScheduleSelection(context, controller, space),
                              ],
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2, 
                                child: authController.isStudent 
                                  ? _buildStudentScheduleSelection(context, controller, space)
                                  : _buildFormulaCard(context, controller, space)
                              ),
                              const SizedBox(width: 48),
                              Expanded(
                                flex: 1, 
                                child: Column(
                                  children: [
                                    _buildSummaryCard(space),
                                    const SizedBox(height: 24),
                                    _buildInfoCard(),
                                    if (!authController.isStudent) ...[
                                      const SizedBox(height: 24),
                                      _buildBillingDetailsCard(context, controller, space),
                                    ],
                                  ],
                                )
                              ),
                            ],
                          );
                    } else {
                      return const Center(child: Text("Réservation en cours..."));
                    }
                  }),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildHeader(Space space, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Finaliser votre réservation",
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "Espace : ${space.name}",
                  style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepper(BookingController controller) {
    final bool isMobile = Get.context != null && MediaQuery.of(Get.context!).size.width < 1100;
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, controller.checkoutStep.value == 1, controller.checkoutStep.value > 1),
        _buildStepDivider(controller.checkoutStep.value > 1, isMobile),
        _buildStepCircle(2, controller.checkoutStep.value == 2, false),
      ],
    ));
  }

  Widget _buildStepCircle(int step, bool isActive, bool isCompleted) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (isActive || isCompleted) ? const Color(0xFF007AFF) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: (isActive || isCompleted) ? const Color(0xFF007AFF) : const Color(0xFFE2E8F0), 
          width: 2
        ),
        boxShadow: (isActive || isCompleted) 
          ? [BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] 
          : [],
      ),
      child: Center(
        child: isCompleted 
          ? const Icon(Icons.check, color: Colors.white, size: 20)
          : Text(
              "$step",
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Widget _buildStepDivider(bool isActive, bool isMobile) {
    return Container(
      width: isMobile ? 30 : 60,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isActive ? const Color(0xFF007AFF) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildFormulaCard(BuildContext context, BookingController controller, Space space) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choisissez votre formule", style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text("Sélectionnez l'option qui correspond le mieux à vos besoins d'étude.", style: TextStyle(fontSize: isMobile ? 14 : 16, color: const Color(0xFF64748B))),
          const SizedBox(height: 32),

          // Option 1: Monthly
          Obx(() => _buildOptionCard(
            title: "Abonnement Mensuel",
            subtitle: "Accès illimité pendant 30 jours",
            price: "${space.monthlyPrice.toInt()} DT",
            unit: "/ mois",
            icon: Icons.calendar_today_outlined,
            isSelected: controller.isMonthly.value,
            onTap: () {
              // Étape 1 : Validation locale des dates
              if (!controller.validateBookingTimes()) return;

              controller.isMonthly.value = true;
              controller.calculateTotal(
                hourlyPrice: space.hourlyPrice, 
                monthlyPrice: space.monthlyPrice
              );
            },
          )),
          const SizedBox(height: 20),

          // Option 2: Hourly
          Obx(() => _buildOptionCard(
            title: "Réservation Ponctuelle",
            subtitle: "Payer à l'heure selon l'usage",
            price: "${space.hourlyPrice.toInt()} DT",
            unit: "/ heure",
            icon: Icons.access_time_rounded,
            isSelected: !controller.isMonthly.value,
            onTap: () {
              controller.isMonthly.value = false;
              controller.calculateTotal(
                hourlyPrice: space.hourlyPrice, 
                monthlyPrice: space.monthlyPrice
              );
            },
          )),
          const SizedBox(height: 40),

          // Date & Time pickers
          Obx(() {
            final start = controller.startDateTime.value;
            final end = controller.endDateTime.value;
            final dateStr = DateFormat('dd/MM/yyyy').format(start);
            final startTimeStr = DateFormat('HH:mm').format(start);
            final endTimeStr = DateFormat('HH:mm').format(end);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: Color(0xFF0F172A)),
                    const SizedBox(width: 8),
                    const Text(
                      "Sélectionner l'horaire",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // All Day Checkbox
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: controller.isAllDay.value,
                        onChanged: (val) => controller.toggleAllDay(space.hourlyPrice, space.monthlyPrice),
                        activeColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Réserver toute la journée (09:00 - 18:00)",
                      style: TextStyle(color: Color(0xFF475569), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Dropdowns Side by Side
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeDropdown(
                        context,
                        controller,
                        "Heure de début",
                        startTimeStr,
                        controller.isAllDay.value || controller.isMonthly.value,
                        (String? newValue) {
                          if (newValue != null) {
                            final parts = newValue.split(':');
                            final newStart = DateTime(start.year, start.month, start.day, int.parse(parts[0]), int.parse(parts[1]));
                            controller.updateDates(newStart, end, space.hourlyPrice, space.monthlyPrice);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeDropdown(
                        context,
                        controller,
                        "Heure de fin",
                        endTimeStr,
                        controller.isAllDay.value || controller.isMonthly.value,
                        (String? newValue) {
                          if (newValue != null) {
                            final parts = newValue.split(':');
                            final newEnd = DateTime(end.year, end.month, end.day, int.parse(parts[0]), int.parse(parts[1]));
                            controller.updateDates(start, newEnd, space.hourlyPrice, space.monthlyPrice);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Date Picker
                _buildPickerField(
                  context,
                  "DATE",
                  dateStr,
                  Icons.calendar_today_outlined,
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: start,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final newStart = DateTime(date.year, date.month, date.day, start.hour, start.minute);
                      final newEnd = DateTime(date.year, date.month, date.day, end.hour, end.minute);
                      controller.updateDates(newStart, newEnd, space.hourlyPrice, space.monthlyPrice);

                      // Rafraîchir l'emploi du temps pour la nouvelle date
                      controller.fetchSpaceReservationsOnDay(space.documentId ?? space.id.toString(), newStart);
                    }
                  },

                ),
                const SizedBox(height: 24),
                _buildScheduleView(controller),
              ],
            );
          }),

          const SizedBox(height: 48),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value 
                ? null 
                : () {
                    if (!controller.validateBookingTimes()) return;
                    controller.calculateTotal(hourlyPrice: space.hourlyPrice, monthlyPrice: space.monthlyPrice);
                    controller.createReservation(space);
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: controller.isLoading.value 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text("Confirmer la réservation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(width: 12),
                      Icon(Icons.check_circle_outline),
                    ],
                  ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required String price,
    required String unit,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isMobile = Get.context != null && MediaQuery.of(Get.context!).size.width < 1100;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE2E8F0), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF007AFF), size: isMobile ? 20 : 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Text(subtitle, style: TextStyle(fontSize: isMobile ? 12 : 14, color: const Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.w900, color: const Color(0xFF007AFF))),
                Text(unit, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDropdown(BuildContext context, BookingController controller, String label, String value, bool isDisabled, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDisabled ? Colors.grey.shade200 : const Color(0xFF10B981), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.timeSlots.contains(value) ? value : null,
              hint: const Text("Sélectionnez l'heure", style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
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

  Widget _buildPickerField(BuildContext context, String label, String value, IconData icon, {VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                Icon(icon, size: 20, color: const Color(0xFF0F172A)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Space space) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Résumé de l'espace", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 32),
          _buildSummaryItem(Icons.business_outlined, space.name, space.typeString),
          const SizedBox(height: 24),
          _buildSummaryItem(Icons.location_on_outlined, "xxxx", null),
          const SizedBox(height: 24),
          _buildSummaryItem(Icons.people_outline, "Jusqu'à ${space.capacity} personnes", null),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String title, String? subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            if (subtitle != null)
              Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "L'abonnement mensuel vous permet d'accéder à l'espace 7j/7 de 8h à 20h. Annulation gratuite jusqu'à 24h avant le début.",
              style: TextStyle(fontSize: 14, color: const Color(0xFF92400E), height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: PAYMENT ---

/*
  Widget _buildPaymentCard(BuildContext context, BookingController controller, Space space) {
    ... (contenu commenté)
  }
*/


  Widget _buildBillingDetailsCard(BuildContext context, BookingController controller, Space space) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DÉTAILS FACTURATION", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
          const SizedBox(height: 32),
          Obx(() => _buildBillingItem("Offre :", controller.isMonthly.value ? "Abonnement Mensuel" : "Accès Ponctuel")),
          Obx(() => _buildBillingItem("Durée :", controller.isMonthly.value ? "30 Jours" : "${controller.endDateTime.value.difference(controller.startDateTime.value).inHours} Heures")),
          Obx(() => _buildBillingItem("Début :", DateFormat('dd MMMM yyyy', 'fr').format(controller.startDateTime.value))),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Obx(() => Text("${controller.totalAmount.value.toInt()} DT", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    String hint, {
    IconData? icon, 
    TextEditingController? controller,
    List<TextInputFormatter>? formatters,
    TextInputType keyboardType = TextInputType.text,
    int? limit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          inputFormatters: formatters,
          keyboardType: keyboardType,
          maxLength: limit,
          decoration: InputDecoration(
            counterText: "",
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF94A3B8)) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  /// Version simplifiée de la sélection d'horaire pour l'étudiant (sans prix).
  Widget _buildStudentScheduleSelection(BuildContext context, BookingController controller, Space space) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Plannifier votre session", style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text("Choisissez la date et l'heure pour votre réservation.", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          
          Obx(() {
            final start = controller.startDateTime.value;
            final end = controller.endDateTime.value;
            final dateStr = DateFormat('dd/MM/yyyy').format(start);
            final startTimeStr = DateFormat('HH:mm').format(start);
            final endTimeStr = DateFormat('HH:mm').format(end);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPickerField(
                  context,
                  "DATE DE RÉSERVATION",
                  dateStr,
                  Icons.calendar_today_outlined,
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: start,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final newStart = DateTime(date.year, date.month, date.day, start.hour, start.minute);
                      final newEnd = DateTime(date.year, date.month, date.day, end.hour, end.minute);
                      controller.updateDates(newStart, newEnd, space.hourlyPrice, space.monthlyPrice);
                      controller.fetchSpaceReservationsOnDay(space.documentId ?? space.id.toString(), newStart);
                    }
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeDropdown(
                        context,
                        controller,
                        "Heure de début",
                        startTimeStr,
                        false,
                        (String? newValue) {
                          if (newValue != null) {
                            final parts = newValue.split(':');
                            final newStart = DateTime(start.year, start.month, start.day, int.parse(parts[0]), int.parse(parts[1]));
                            controller.updateDates(newStart, end, space.hourlyPrice, space.monthlyPrice);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeDropdown(
                        context,
                        controller,
                        "Heure de fin",
                        endTimeStr,
                        false,
                        (String? newValue) {
                          if (newValue != null) {
                            final parts = newValue.split(':');
                            final newEnd = DateTime(end.year, end.month, end.day, int.parse(parts[0]), int.parse(parts[1]));
                            controller.updateDates(start, newEnd, space.hourlyPrice, space.monthlyPrice);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildScheduleView(controller),
              ],
            );
          }),
          
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value 
                ? null 
                : () {
                    if (!controller.validateBookingTimes()) return;
                    controller.createReservation(space);
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: controller.isLoading.value 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text("Confirmer la réservation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(width: 12),
                      Icon(Icons.check_circle_outline),
                    ],
                  ),
            )),
          ),
        ],
      ),
    );
  }

  /// Affiche l'emploi du temps (réservations existantes) pour le jour sélectionné.
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
              border: Border.all(color: const Color(0xFFE2E8F0)),
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

// Formatters commentés...
/*
class CardNumberFormatter ...
class CardExpiryFormatter ...
*/

