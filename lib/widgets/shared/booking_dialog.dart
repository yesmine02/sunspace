import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/space.dart';

class BookingDialog extends StatelessWidget {
  final Space space;
  final bool isMobile;
  final bool showPayment;
  final int? initialParticipants;

  const BookingDialog({
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
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
      final end = DateTime(now.year, now.month, now.day, now.hour + 3, 0);
      
      controller.updateDates(
        start, 
        end, 
        space.hourlyPrice,
        space.monthlyPrice
      );
      controller.numberOfPeople.value = initialParticipants ?? 1;
    });

    return Dialog(
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
              _buildDateTimePicker(context, controller),
              const SizedBox(height: 16),

              // 1b. Nombre de personnes
              const Text("Nombre de participants", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildParticipantsSelector(controller),
              const SizedBox(height: 24),

              // 2. Services additionnels
              const Text("Services additionnels", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildServicesSelector(controller),
              const SizedBox(height: 24),

              // 3. Paiement (si activé et si pas étudiant)
              if (showPayment && !isStudent) ...[
                _buildPaymentFields(controller),
                const Divider(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total à payer :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Obx(() => Text(
                      "${controller.totalAmount.value.toStringAsFixed(2)} TND",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    )),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Bouton final
              Obx(() {
                // 1. Vérification Capacité Max
                final bool capacityExceeded = controller.numberOfPeople.value > space.capacity;
                
                // 2. Vérification Chevauchements (Places restantes sur le créneau)
                int occupied = 0;
                final start = controller.startDateTime.value;
                final end = controller.endDateTime.value;
                
                for (var res in controller.spaceReservationsOnDay) {
                  if (start.isBefore(res.endDateTime) && end.isAfter(res.startDateTime)) {
                    occupied += res.numberOfPeople;
                  }
                }
                
                final int remaining = space.capacity - occupied;
                final bool slotFull = controller.numberOfPeople.value > remaining;

                return Column(
                  children: [
                    if (capacityExceeded || slotFull)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  capacityExceeded 
                                    ? "Capacité max dépassée (${space.capacity} places)."
                                    : "Salle complète sur ce créneau (Il reste $remaining places).",
                                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (controller.isLoading.value || capacityExceeded || slotFull) ? null : () async {
                          bool success = await controller.createReservation(space);
                          if (success) {
                            Get.back(result: true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF), 
                          padding: const EdgeInsets.symmetric(vertical: 16), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Confirmer la réservation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

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
          const Text("Participants", style: TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          IconButton(
            onPressed: () { if (controller.numberOfPeople.value > 1) controller.numberOfPeople.value--; },
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          ),
          Obx(() => Text(
            "${controller.numberOfPeople.value}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )),
          IconButton(
            onPressed: () { if (controller.numberOfPeople.value < space.capacity) controller.numberOfPeople.value++; },
            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSelector(BookingController controller) {
    return Obx(() => Wrap(
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
            : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF007AFF) : (isAvailable ? const Color(0xFFDCFCE7) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? const Color(0xFF007AFF) : (isAvailable ? const Color(0xFFBBF7D0) : Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$name (${price.toInt()}TND/j)",
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isAvailable ? const Color(0xFF166534) : Colors.grey.shade500),
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
    ));
  }

  Widget _buildDateTimePicker(BuildContext context, BookingController controller) {
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
              DateTime? date = await showDatePicker(context: context, initialDate: start, firstDate: DateTime.now(), lastDate: DateTime(2030));
              if (date != null) {
                final newStart = DateTime(date.year, date.month, date.day, start.hour, start.minute);
                controller.updateDates(newStart, newStart.add(end.difference(start)), space.hourlyPrice, space.monthlyPrice);
              }
            },
            child: _buildInfoRow(Icons.calendar_today, "Date : $dateStr"),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTimeDropdown(controller, "Début", startTimeStr, isAllDay, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeDropdown(controller, "Fin", endTimeStr, isAllDay, false)),
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
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12), color: Colors.white),
      child: Row(children: [Icon(icon, size: 18, color: Colors.blue), const SizedBox(width: 12), Text(text, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), const Icon(Icons.keyboard_arrow_down, color: Colors.grey)]),
    );
  }

  Widget _buildTimeDropdown(BookingController controller, String label, String value, bool isDisabled, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.timeSlots.contains(value) ? value : null,
              isExpanded: true,
              onChanged: isDisabled ? null : (val) {
                if (val != null) {
                  final parts = val.split(':');
                  if (isStart) {
                    final newStart = DateTime(controller.startDateTime.value.year, controller.startDateTime.value.month, controller.startDateTime.value.day, int.parse(parts[0]), int.parse(parts[1]));
                    // Force la date de fin sur le même jour que le début
                    final newEnd = DateTime(newStart.year, newStart.month, newStart.day, controller.endDateTime.value.hour, controller.endDateTime.value.minute);
                    controller.updateDates(newStart, newEnd, space.hourlyPrice, space.monthlyPrice);
                  } else {
                    // Force l'heure de fin sur le même jour que l'heure de début
                    final newEnd = DateTime(controller.startDateTime.value.year, controller.startDateTime.value.month, controller.startDateTime.value.day, int.parse(parts[0]), int.parse(parts[1]));
                    controller.updateDates(controller.startDateTime.value, newEnd, space.hourlyPrice, space.monthlyPrice);
                  }
                }
              },
              items: controller.timeSlots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentFields(BookingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Paiement par carte", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(controller: controller.cardNameController, decoration: _inputDecoration("Nom complet", Icons.person)),
        const SizedBox(height: 12),
        TextField(controller: controller.cardNumberController, decoration: _inputDecoration("Numéro de carte", Icons.credit_card)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: controller.cardExpiryController, decoration: _inputDecoration("MM/AA", Icons.event))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: controller.cardCvcController, decoration: _inputDecoration("CVC", Icons.lock))),
        ]),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint, prefixIcon: Icon(icon, size: 20),
      filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }
}
