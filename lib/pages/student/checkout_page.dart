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
                              _buildFormulaCard(context, controller, space),
                              const SizedBox(height: 24),
                              _buildSummaryCard(space),
                              const SizedBox(height: 24),
                              _buildInfoCard(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildFormulaCard(context, controller, space)),
                              const SizedBox(width: 48),
                              Expanded(
                                flex: 1, 
                                child: Column(
                                  children: [
                                    _buildSummaryCard(space),
                                    const SizedBox(height: 24),
                                    _buildInfoCard(),
                                  ],
                                )
                              ),
                            ],
                          );
                    } else if (controller.checkoutStep.value == 2) {
                      return isMobile 
                        ? Column(
                            children: [
                              _buildPaymentCard(context, controller, space),
                              const SizedBox(height: 24),
                              _buildBillingDetailsCard(context, controller, space),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildPaymentCard(context, controller, space)),
                              const SizedBox(width: 48),
                              Expanded(
                                flex: 1, 
                                child: _buildBillingDetailsCard(context, controller, space),
                              ),
                            ],
                          );
                    } else {
                      return const Center(child: Text("Confirmation Page (Step 3)"));
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569))),
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
        _buildStepCircle(2, controller.checkoutStep.value == 2, controller.checkoutStep.value > 2),
        _buildStepDivider(controller.checkoutStep.value > 2, isMobile),
        _buildStepCircle(3, controller.checkoutStep.value == 3, false),
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
            final dateStr = DateFormat('dd/MM/yyyy').format(start);
            final timeStr = DateFormat('HH:mm').format(start);

            return Row(
              children: [
                Expanded(
                  child: _buildPickerField(
                    context,
                    "DATE DE DÉBUT",
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
                        controller.updateDates(newStart, newStart.add(const Duration(hours: 1)), space.hourlyPrice, space.monthlyPrice);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildPickerField(
                    context,
                    "HEURE DE DÉBUT",
                    timeStr,
                    Icons.access_time_rounded,
                    onTap: () async {
                      TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(start),
                      );
                      if (time != null) {
                        final newStart = DateTime(start.year, start.month, start.day, time.hour, time.minute);
                        controller.updateDates(newStart, newStart.add(const Duration(hours: 2)), space.hourlyPrice, space.monthlyPrice);
                      }
                    },
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          // Duration picker for Ponctuelle
          Obx(() {
            if (controller.isMonthly.value) return const SizedBox.shrink();
            
            final durationHours = controller.endDateTime.value.difference(controller.startDateTime.value).inHours;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DURÉE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: durationHours > 0 ? durationHours : 1,
                      isExpanded: true,
                      items: List.generate(12, (index) => index + 1).map((h) => DropdownMenuItem(
                        value: h,
                        child: Text("$h heure${h > 1 ? 's' : ''}"),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.updateDates(
                            controller.startDateTime.value, 
                            controller.startDateTime.value.add(Duration(hours: val)), 
                            space.hourlyPrice, 
                            space.monthlyPrice
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 48),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Calcule le total avant de passer au paiement
                controller.calculateTotal(hourlyPrice: space.hourlyPrice, monthlyPrice: space.monthlyPrice);
                controller.checkoutStep.value = 2;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("Continuer vers le paiement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(width: 12),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
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

  Widget _buildPickerField(BuildContext context, String label, String value, IconData icon, {required VoidCallback onTap}) {
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

  Widget _buildPaymentCard(BuildContext context, BookingController controller, Space space) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Securisé
          Container(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("PAIEMENT SÉCURISÉ", style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                      Text("Données cryptées.", style: TextStyle(fontSize: isMobile ? 14 : 16, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Icon(Icons.shield_outlined, size: isMobile ? 32 : 48, color: const Color(0xFF3B82F6)),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField("Nom sur la carte", "Ex: Jean Dupont", controller: controller.cardNameController),
                const SizedBox(height: 24),
                _buildTextField(
                  "Numéro de carte", 
                  "0000 0000 0000 0000", 
                  icon: Icons.credit_card_outlined,
                  controller: controller.cardNumberController,
                  formatters: [CardNumberFormatter()],
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTextField(
                      "Date d'expiration", 
                      "MM/AA",
                      controller: controller.cardExpiryController,
                      formatters: [CardExpiryFormatter()],
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(
                      "CVC", 
                      "***",
                      controller: controller.cardCvcController,
                      keyboardType: TextInputType.number,
                      limit: 3,
                    )),
                  ],
                ),
                const SizedBox(height: 32),

                // Logos Paiement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      const Text("Visa", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      if (!isMobile) ...[
                        const Spacer(),
                        const Text("PAIEMENT CRYPTÉ SSL 256 BITS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Buttons
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        controller.checkoutStep.value = 1;
                      },
                      child: const Text("Modifier l'offre", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value ? null : () => controller.createReservation(space),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: controller.isLoading.value 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                        : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.payment, size: 18),
                            const SizedBox(width: 8),
                            Obx(() => Text("Payer ${controller.totalAmount.value.toInt()} DT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18))),
                          ],
                        ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
}

// ============================================
// Formatters pour le Paiement
// ============================================

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) text = text.substring(0, 16);
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
        buffer.write(text[i]);
        var nonZeroIndex = i + 1;
        if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
            buffer.write(' ');
        }
    }
    
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}

class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '').replaceAll(' ', '');
    if (text.length > 4) text = text.substring(0, 4);
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
        buffer.write(text[i]);
        if (i == 1 && text.length > 2) {
            buffer.write(' / ');
        }
    }
    
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}
