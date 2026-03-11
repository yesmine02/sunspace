import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/spaces_controller.dart';
import '../../data/models/space.dart';
import 'widgets/floor_plan_widget.dart';

/// Page principale de réservation d'espaces pour les professionnels.
/// Permet de basculer entre une vue Plan interactif et une vue Liste classique.
class BookSpacePage extends StatefulWidget {
  const BookSpacePage({super.key});

  @override
  State<BookSpacePage> createState() => _BookSpacePageState();
}

class _BookSpacePageState extends State<BookSpacePage> {
  bool showFloorPlan = true; // Contrôle l'affichage (Plan vs Liste)
  Space? selectedSpaceForTooltip; // Stocke l'espace cliqué sur le plan pour afficher sa fiche d'info

  @override
  Widget build(BuildContext context) {
    // Initialisation des contrôleurs GetX
    final spacesController = Get.put(SpacesController());
    final bookingController = Get.put(BookingController());
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8.0 : 24.0,
          vertical: isMobile ? 8.0 : 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile), // Titre et icône
            SizedBox(height: isMobile ? 10 : 20),

            // Sélecteur de vue (Boutons Plan / Liste)
            _buildViewToggle(),
            SizedBox(height: isMobile ? 10 : 20),

            // Filtres de recherche (uniquement visibles en mode Liste)
            if (!showFloorPlan) ...[
               _buildFilters(spacesController, isMobile),
               const SizedBox(height: 10),
            ],

            // Contenu principal (Plan ou Grille d'espaces)
            Expanded(
              child: showFloorPlan 
                ? _buildFloorPlanView(spacesController, bookingController)
                : _buildListView(spacesController, bookingController, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le sélecteur de mode d'affichage (Toggle).
  Widget _buildViewToggle() {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      width: isMobile ? double.infinity : 400,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _toggleButton(isMobile ? "Plan" : "Plan Interactif", showFloorPlan, () => setState(() => showFloorPlan = true))),
          Expanded(child: _toggleButton(isMobile ? "Liste" : "Liste des Espaces", !showFloorPlan, () => setState(() => showFloorPlan = false))),
        ],
      ),
    );
  }

  /// Petit bouton utilitaire pour le toggle.
  Widget _toggleButton(String label, bool active, VoidCallback onTap) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.blue : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  /// Construit la vue du plan interactif avec sa fiche d'information flottante (Tooltip).
  Widget _buildFloorPlanView(SpacesController spacesController, BookingController bookingController) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Appuyez sur un espace pour le réserver", 
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  // Le Widget du plan gère le zoom et le dessin proprement dit.
                  Center(
                    child: FloorPlanWidget(
                      onAreaSelected: (slug) {
                        if (slug.isEmpty) {
                          setState(() => selectedSpaceForTooltip = null);
                          return;
                        }
                        // Recherche de l'objet Space correspondant au slug cliqué.
                        final space = spacesController.spaces.firstWhereOrNull((s) => s.slug == slug);
                        setState(() {
                          selectedSpaceForTooltip = space;
                        });
                        if (space == null) {
                           Get.snackbar("Info", "Espace '$slug' (données serveur manquantes)");
                        }
                      },
                    ),
                  ),
                  
                  // Fiche d'info qui apparaît quand un espace est sélectionné sur le plan.
                  Positioned(
                    bottom: isMobile ? 12 : 30,
                    left: isMobile ? 12 : 30,
                    right: isMobile ? 12 : 30,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => 
                        FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                      child: (selectedSpaceForTooltip != null)
                        ? _buildSpaceTooltip(selectedSpaceForTooltip!, bookingController)
                        : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la vue en liste (grille de cartes).
  Widget _buildListView(SpacesController spacesController, BookingController bookingController, bool isMobile) {
    return Obx(() {
      if (spacesController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (spacesController.filteredSpaces.isEmpty) {
        return _buildEmptyState();
      }

      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile ? 1 : 2,
          childAspectRatio: isMobile ? 0.88 : 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: spacesController.filteredSpaces.length,
        itemBuilder: (context, index) {
          final space = spacesController.filteredSpaces[index];
          return _buildSpaceCard(context, space, bookingController, isMobile);
        },
      );
    });
  }

  /// Titre de la page.
  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.apartment_rounded, color: const Color(0xFF007AFF), size: isMobile ? 24 : 32),
            const SizedBox(width: 8),
            Text(
              'Espaces',
              style: TextStyle(
                fontSize: isMobile ? 20 : 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        if (!isMobile) ...[
          const SizedBox(height: 8),
          Text(
            'Trouvez le bureau ou la salle idéale pour votre travail.',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ],
    );
  }

  /// Barre de recherche et filtres de catégorie.
  Widget _buildFilters(SpacesController controller, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile 
        ? Column(children: [_buildSearchField(controller), const SizedBox(height: 12), _buildTypeFilter(controller)])
        : Row(
            children: [
              Expanded(child: _buildSearchField(controller)),
              const SizedBox(width: 16),
              Expanded(child: _buildTypeFilter(controller)),
            ],
          ),
    );
  }

  Widget _buildSearchField(SpacesController controller) {
    return TextField(
      onChanged: controller.updateSearch,
      decoration: InputDecoration(
        hintText: 'Rechercher (ex: Salle Apollo)...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _buildTypeFilter(SpacesController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedType.value, 
          hint: const Text("Filtrer par type"),
          isExpanded: true,
          items: ['Tous les types', 'Bureau', 'Salle de réunion', 'Open Space'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (val) {
             controller.updateType(val);
          }, 
        ),
      ),
    ));
  }

  /// Carte individuelle pour chaque bureau ou salle dans la vue Liste.
  Widget _buildSpaceCard(BuildContext context, Space space, BookingController bookingController, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Partie haute : Image (Placeholder), Badge 3D et Prix.
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Icon(Icons.desk, size: 64, color: Colors.blue.shade200),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: InkWell(
                    onTap: () => _show3DView(context, space),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.view_in_ar, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Vue 3D', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text('${space.hourlyPrice.toInt()} TND / h', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007AFF))),
                  ),
                ),
              ],
            ),
          ),
          
          // Partie basse : Nom, Type, Capacité et bouton de réservation.
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(space.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1),
                      Text(space.typeString, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text('${space.capacity} pers.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showBookingDialog(context, space, bookingController),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Réserver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucun espace trouvé.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// Construit la petite carte qui apparaît au-dessus du plan interactif.
  Widget _buildSpaceTooltip(Space space, BookingController bookingController) {
    return Container(
      key: Key(space.id),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(space.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => selectedSpaceForTooltip = null)),
                    ],
                  ),
                  Text(space.typeString.replaceAll('_', ' '), style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSmallInfo(Icons.people_outline, "${space.capacity} pers."),
                      Text('${space.hourlyPrice.toInt()} TND/hr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF166534))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => selectedSpaceForTooltip = null);
                        _showBookingDialog(context, space, bookingController);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Réserver maintenant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
      ],
    );
  }

  // --- ACTIONS ---

  /// Simule la vue 3D (actuellement un placeholder commenté pour l'implémentation future).
  void _show3DView(BuildContext context, Space space) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 800,
          height: isMobile ? MediaQuery.of(context).size.height * 0.6 : 500,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.view_in_ar, size: 100, color: Colors.white24),
                    const SizedBox(height: 20),
                    Text('Visualisation 3D : ${space.name}', style: const TextStyle(color: Colors.white, fontSize: 24)),
                    const Text('(Ici sera intégré le widget ModelViewer ou Unity)', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              Positioned(top: 16, right: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Get.back())),
            ],
          ),
        ),
      ),
    );
  }

  /// Ouvre le dialogue complet pour configurer et payer une réservation.
  void _showBookingDialog(BuildContext context, Space space, BookingController controller) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    
    // Réinitialisation des données pour une nouvelle session de réservation.
    controller.selectedServices.clear();
    controller.isMonthly.value = false;
    controller.cardNameController.clear();
    controller.cardNumberController.clear();
    controller.cardExpiryController.clear();
    controller.cardCvcController.clear();
    
    // Détermination des dates par défaut (J+1h à J+3h).
    controller.updateDates(
      DateTime.now().add(const Duration(hours: 1)), 
      DateTime.now().add(const Duration(hours: 3)), 
      space.hourlyPrice,
      space.monthlyPrice
    );

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
                _buildDateTimePicker(context, controller, space.hourlyPrice, space.monthlyPrice),
                const SizedBox(height: 24),

                // 2. Services extra (Café, Projecteur, etc.)
                const Text("Services additionnels", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Obx(() => Column(
                  children: controller.servicesCatalog.entries.map((entry) {
                    final isSelected = controller.selectedServices.contains(entry.key);
                    return CheckboxListTile(
                      title: Text(entry.key), subtitle: Text('+${entry.value} TND'),
                      value: isSelected,
                      onChanged: (val) => controller.toggleService(entry.key, space.hourlyPrice, space.monthlyPrice),
                      dense: true, activeColor: const Color(0xFF007AFF), contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                )),
                const SizedBox(height: 24),

                // 3. Paiement Sécurisé
                _buildPaymentFields(controller),
                const Divider(height: 48),

                // 4. Sommaire du prix total calculé en temps réel
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

                // Bouton final de confirmation serveur
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : () => controller.createReservation(space),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: controller.isLoading.value 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Confirmer et Payer", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget de sélection de date/heure avec retour immédiat sur le prix total.
  Widget _buildDateTimePicker(BuildContext context, BookingController controller, double hourlyPrice, double monthlyPrice) {
    return Obx(() {
      final start = controller.startDateTime.value;
      final end = controller.endDateTime.value;
      final format = DateFormat('dd/MM HH:mm');

      return Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                DateTime? date = await showDatePicker(context: context, initialDate: start, firstDate: DateTime.now(), lastDate: DateTime(2030));
                if (date != null) {
                  TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(start));
                  if (time != null) {
                    final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    final duration = end.difference(start);
                    controller.updateDates(newStart, newStart.add(duration), hourlyPrice, monthlyPrice);
                  }
                }
              },
              child: _dateTimeCard("Début", format.format(start)),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey)),
          Expanded(
            child: InkWell(
              onTap: () async {
                 TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(end));
                 if (time != null) {
                   final newEnd = DateTime(end.year, end.month, end.day, time.hour, time.minute);
                   if (newEnd.isAfter(start)) {
                      controller.updateDates(start, newEnd, hourlyPrice, monthlyPrice);
                   } else {
                     Get.snackbar("Erreur", "La fin doit être après le début");
                   }
                 }
              },
              child: _dateTimeCard("Fin", format.format(end)),
            ),
          ),
        ],
      );
    });
  }

  Widget _dateTimeCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  /// Champs de texte pour la carte bancaire avec formatage automatique (espaces, slash).
  Widget _buildPaymentFields(BookingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [Icon(Icons.payment, size: 20), SizedBox(width: 8), Text("Paiement par carte", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
        const SizedBox(height: 16),
        TextField(controller: controller.cardNameController, decoration: _inputDecoration("Nom complet sur la carte", Icons.person_outline)),
        const SizedBox(height: 12),
        TextField(
          controller: controller.cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16), _CardNumberFormatter()],
          decoration: _inputDecoration("Numéro de carte (16 chiffres)", Icons.credit_card_outlined),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(
              controller: controller.cardExpiryController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), _ExpiryDateFormatter()],
              decoration: _inputDecoration("MM/AA", Icons.calendar_today_outlined),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              controller: controller.cardCvcController,
              keyboardType: TextInputType.number, obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
              decoration: _inputDecoration("CVC", Icons.lock_outline),
            )),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint, prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      filled: true, fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5)),
    );
  }
}

// FORMATTERS PERSONNALISÉS pour une saisie fluide et sans erreur.

/// Ajoute un espace tous les 4 chiffres pour le numéro de carte.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(' ', '');
    String result = "";
    for (int i = 0; i < text.length; i++) {
       result += text[i];
       if ((i + 1) % 4 == 0 && (i + 1) != 16) result += " ";
    }
    return TextEditingValue(text: result, selection: TextSelection.collapsed(offset: result.length));
  }
}

/// Ajoute un slash '/' après le mois dans la date d'expiration.
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('/', '');
    String result = text.length >= 2 ? "${text.substring(0, 2)}/${text.substring(2)}" : text;
    return TextEditingValue(text: result, selection: TextSelection.collapsed(offset: result.length));
  }
}
