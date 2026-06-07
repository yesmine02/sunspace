import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/space.dart';

class BookingDialog extends StatelessWidget {
  final Space space;
  final bool isMobile;
  final bool showPayment;
  final int? initialParticipants;

  const BookingDialog({
    super.key,
    required this.space,
    required this.isMobile,
    this.showPayment = true,
    this.initialParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final AuthController authController = Get.find<AuthController>();
    final bool isStudent = authController.isStudent;

    // Initialisation des données par défaut
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetToDefaults(
        hourlyPrice: space.hourlyPrice,
        monthlyPrice: space.monthlyPrice,
      );
      controller.numberOfPeople.value = initialParticipants ?? 1;
      controller.hasChosenStartTime.value = false;
      controller.hasChosenEndTime.value = false;

      // Charger l'emploi du temps initial
      controller.fetchSpaceReservationsOnDay(
        space.documentId ?? space.id.toString(),
        controller.startDateTime.value,
      );
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: Container(
        width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 500,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Réserver : ${space.name}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // 1. Date et Heure
              const Text(
                "Date et Heure",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDateTimePicker(context, controller),
              const SizedBox(height: 16),

              // Emploi du temps
              _buildScheduleView(controller),
              const SizedBox(height: 24),

              // 2. Nombre de participants
              const Text(
                "Nombre de participants",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildParticipantsSelector(controller),
              const SizedBox(height: 24),

              // 3. Services additionnels
              const Text(
                "Services additionnels",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildServicesSelector(controller),
              const SizedBox(height: 24),

              const Divider(height: 32),

              // 4. Récapitulatif
              const Text(
                "Récapitulatif",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Obx(() {
                  final hours =
                      controller.endDateTime.value
                          .difference(controller.startDateTime.value)
                          .inMinutes /
                      60.0;
                  final displayHours = hours < 1.0 ? 1.0 : hours;
                  final int participants = controller.numberOfPeople.value;

                  return Column(
                    children: [
                      if (controller.isMonthly.value)
                        _buildPriceRow(
                          "Espace (${space.monthlyPrice.toInt()} TND/mois x $participants pers)",
                          "${(space.monthlyPrice * participants).toInt()} TND",
                        )
                      else
                        _buildPriceRow(
                          "Espace (${space.hourlyPrice.toInt()} TND/h x ${displayHours.toStringAsFixed(displayHours == displayHours.toInt() ? 0 : 1)}h x $participants pers)",
                          "${(displayHours * space.hourlyPrice * participants).toInt()} TND",
                        ),

                      if (controller.selectedServices.isNotEmpty)
                        _buildPriceRow(
                          "Services extra",
                          "${controller.selectedServices.fold<double>(0.0, (sum, s) => sum + ((controller.servicesCatalog[s]?['price'] as double?) ?? 0.0)).toInt()} TND",
                        ),
                      const Divider(height: 24),
                      _buildPriceRow(
                        "Total estimé",
                        "${controller.totalAmount.value.toInt()} TND",
                        isTotal: true,
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 24),

              // 5. Champs de paiement (si activé et pas étudiant)
              if (showPayment && !isStudent) ...[
                _buildPaymentFields(controller),
                const SizedBox(height: 24),
              ],

              // 6. Bouton Réserver
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            // Vérification capacité max
                            if (controller.numberOfPeople.value >
                                space.capacity) {
                              Get.dialog(
                                AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.people_alt_rounded,
                                        color: Colors.red.shade600,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text("Capacité dépassée"),
                                    ],
                                  ),
                                  content: Text(
                                    "Le nombre de participants dépasse la capacité maximale de la salle (${space.capacity} places).",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: const Text(
                                        "D'accord",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            // Vérification chevauchement / places restantes
                            int occupied = 0;
                            final start = controller.startDateTime.value;
                            final end = controller.endDateTime.value;
                            for (var res in controller.spaceReservationsOnDay) {
                              if (start.isBefore(res.endDateTime) &&
                                  end.isAfter(res.startDateTime)) {
                                occupied += res.numberOfPeople;
                              }
                            }
                            final int remaining = space.capacity - occupied;
                            if (controller.numberOfPeople.value > remaining) {
                              Get.dialog(
                                AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.event_busy_rounded,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text("Créneau complet"),
                                    ],
                                  ),
                                  content: Text(
                                    "La salle est complète sur ce créneau. Il reste $remaining place(s) disponible(s).",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: const Text(
                                        "D'accord",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            // Validation des champs de paiement si affichés
                            if (showPayment && !isStudent) {
                              if (controller.cardNameController.text
                                      .trim()
                                      .isEmpty ||
                                  controller.cardNumberController.text
                                      .trim()
                                      .isEmpty ||
                                  controller.cardExpiryController.text
                                      .trim()
                                      .isEmpty ||
                                  controller.cardCvcController.text
                                      .trim()
                                      .isEmpty) {
                                Get.dialog(
                                  AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(
                                          Icons.credit_card_off_rounded,
                                          color: Colors.red.shade600,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text("Paiement incomplet"),
                                      ],
                                    ),
                                    content: const Text(
                                      "Veuillez remplir toutes les informations de paiement par carte.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Get.back(),
                                        child: const Text(
                                          "D'accord",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                            }

                            bool success =
                                await controller.createReservation(space);
                            if (success) {
                              Get.back(result: true);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Réserver",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Emploi du temps ──────────────────────────────────────────────────────
  Widget _buildScheduleView(BookingController controller) {
    return Obx(() {
      final reservations = controller.spaceReservationsOnDay;
      final now = DateTime.now();
      final selected = controller.startDateTime.value;
      final isToday = selected.year == now.year &&
          selected.month == now.month &&
          selected.day == now.day;
      final dateLabel = isToday
          ? "Aujourd'hui"
          : DateFormat('dd/MM', 'fr').format(selected);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Emploi du temps du $dateLabel",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
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
                      final start =
                          DateFormat('HH:mm').format(res.startDateTime);
                      final end = DateFormat('HH:mm').format(res.endDateTime);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: Text(
                          "$start - $end",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      );
    });
  }

  // ─── Sélecteur participants ───────────────────────────────────────────────
  Widget _buildParticipantsSelector(BookingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          const Text(
            "Participants",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              if (controller.numberOfPeople.value > 1) {
                controller.numberOfPeople.value--;
                controller.calculateTotal(
                  hourlyPrice: space.hourlyPrice,
                  monthlyPrice: space.monthlyPrice,
                );
              }
            },
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          ),
          Obx(
            () => Text(
              "${controller.numberOfPeople.value}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () {
              if (controller.numberOfPeople.value < space.capacity) {
                controller.numberOfPeople.value++;
                controller.calculateTotal(
                  hourlyPrice: space.hourlyPrice,
                  monthlyPrice: space.monthlyPrice,
                );
              }
            },
            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          ),
        ],
      ),
    );
  }

  // ─── Services ────────────────────────────────────────────────────────────
  Widget _buildServicesSelector(BookingController controller) {
    return Obx(
      () => Wrap(
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
                ? () => controller.toggleService(
                    name,
                    space.hourlyPrice,
                    space.monthlyPrice,
                  )
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : (isAvailable
                          ? const Color(0xFFDCFCE7)
                          : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF007AFF)
                      : (isAvailable
                            ? const Color(0xFFBBF7D0)
                            : Colors.grey.shade300),
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
                          : (isAvailable
                                ? const Color(0xFF166534)
                                : Colors.grey.shade500),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Date/Heure picker ────────────────────────────────────────────────────
  Widget _buildDateTimePicker(
    BuildContext context,
    BookingController controller,
  ) {
    return Obx(() {
      final start = controller.startDateTime.value;
      final end = controller.endDateTime.value;
      final isAllDay = controller.isAllDay.value;
      final dateStr = DateFormat('dd MMMM yyyy', 'fr').format(start);
      final startTimeStr = DateFormat('HH:mm').format(start);
      final endTimeStr = DateFormat('HH:mm').format(end);

      return Column(
        children: [
          InkWell(
            onTap: () async {
              DateTime? date = await showDatePicker(
                context: context,
                initialDate: start,
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                final newStart = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  start.hour,
                  start.minute,
                );
                controller.updateDates(
                  newStart,
                  newStart.add(end.difference(start)),
                  space.hourlyPrice,
                  space.monthlyPrice,
                );
                // Rafraîchir l'emploi du temps pour la nouvelle date
                controller.fetchSpaceReservationsOnDay(
                  space.documentId ?? space.id.toString(),
                  newStart,
                );
              }
            },
            child: _buildInfoRow(Icons.calendar_today, "Date : $dateStr"),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeDropdown(
                  controller,
                  "Début",
                  controller.hasChosenStartTime.value ? startTimeStr : "",
                  isAllDay,
                  true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeDropdown(
                  controller,
                  "Fin",
                  controller.hasChosenEndTime.value ? endTimeStr : "",
                  isAllDay,
                  false,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTimeDropdown(
    BookingController controller,
    String label,
    String value,
    bool isDisabled,
    bool isStart,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.timeSlots.contains(value) ? value : null,
              isExpanded: true,
              onChanged: isDisabled
                  ? null
                  : (val) {
                      if (val != null) {
                        final parts = val.split(':');
                        if (isStart) {
                          controller.hasChosenStartTime.value = true;
                          final newStart = DateTime(
                            controller.startDateTime.value.year,
                            controller.startDateTime.value.month,
                            controller.startDateTime.value.day,
                            int.parse(parts[0]),
                            int.parse(parts[1]),
                          );
                          final newEnd = DateTime(
                            newStart.year,
                            newStart.month,
                            newStart.day,
                            controller.endDateTime.value.hour,
                            controller.endDateTime.value.minute,
                          );
                          controller.updateDates(
                            newStart,
                            newEnd,
                            space.hourlyPrice,
                            space.monthlyPrice,
                          );
                        } else {
                          controller.hasChosenEndTime.value = true;
                          final newEnd = DateTime(
                            controller.startDateTime.value.year,
                            controller.startDateTime.value.month,
                            controller.startDateTime.value.day,
                            int.parse(parts[0]),
                            int.parse(parts[1]),
                          );
                          controller.updateDates(
                            controller.startDateTime.value,
                            newEnd,
                            space.hourlyPrice,
                            space.monthlyPrice,
                          );
                        }
                      }
                    },
              items: controller.timeSlots
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Paiement ─────────────────────────────────────────────────────────────
  Widget _buildPaymentFields(BookingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Paiement par carte",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.cardNameController,
          decoration: _inputDecoration("Nom complet", Icons.person),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.cardNumberController,
          decoration: _inputDecoration("Numéro de carte", Icons.credit_card),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.cardExpiryController,
                decoration: _inputDecoration("MM/AA", Icons.event),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller.cardCvcController,
                decoration: _inputDecoration("CVC", Icons.lock),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  // ─── Ligne de prix ────────────────────────────────────────────────────────
  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF1E40AF),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }
}
