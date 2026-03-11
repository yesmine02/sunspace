// ===============================================
// Dialogue de modification d'équipement (EditEquipmentDialog)
// C'est une fenêtre contextuelle (pop-up) qui permet
// de modifier les détails d'un équipement existant.
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/equipment.dart';
import '../../../controllers/equipments_controller.dart';
import '../../../controllers/spaces_controller.dart';

class EditEquipmentDialog extends StatefulWidget {
  final Equipment equipment; // L'équipement à modifier, passé en paramètre
  const EditEquipmentDialog({super.key, required this.equipment});

  @override
  State<EditEquipmentDialog> createState() => _EditEquipmentDialogState();
}

class _EditEquipmentDialogState extends State<EditEquipmentDialog> {
  // Clé pour identifier le formulaire et valider les champs
  final _formKey = GlobalKey<FormState>();

  // Récupération des contrôleurs nécessaires
  final EquipmentsController controller = Get.find<EquipmentsController>();
  final SpacesController spacesController = Get.put(SpacesController());

  // Contrôleurs de texte pour les champs de saisie
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _serialController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  // Variables d'état pour les champs non textuels
  late EquipmentStatus _selectedStatus;
  String? _selectedSpace;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;

  // Initialisation du formulaire avec les données actuelles de l'équipement
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment.name);
    _typeController = TextEditingController(text: widget.equipment.type);
    _serialController = TextEditingController(text: widget.equipment.serialNumber);
    _priceController = TextEditingController(text: widget.equipment.price?.toString() ?? '0');
    _descriptionController = TextEditingController(text: widget.equipment.description);
    _notesController = TextEditingController(text: widget.equipment.notes);

    _selectedStatus = widget.equipment.status;
    _selectedSpace = widget.equipment.spaceName == '-' ? null : widget.equipment.spaceName;
    _purchaseDate = widget.equipment.purchaseDate;
    _warrantyExpiry = widget.equipment.warrantyExpiry;
  }

  // Libérer la mémoire quand le dialogue est fermé
  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _serialController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Fonction pour afficher un calendrier et choisir une date
  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isPurchaseDate ? _purchaseDate : _warrantyExpiry) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
        } else {
          _warrantyExpiry = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Détection si l'écran est petit (mobile)
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      child: Container(
        width: isMobile ? double.infinity : 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec titre et bouton fermer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Modifier l\'équipement',
                        style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                Text(
                  'Modifiez les détails de l\'équipement existant.',
                  style: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 12 : 14),
                ),
                const SizedBox(height: 24),
                
                // Champs Nom et Type
                _buildResponsiveRow(
                  isMobile: isMobile,
                  children: [
                    Expanded(flex: isMobile ? 0 : 1, child: _buildTextField('Nom', _nameController, 'Nom de l\'équipement')),
                    if (!isMobile) const SizedBox(width: 16),
                    if (isMobile) const SizedBox(height: 16),
                    Expanded(flex: isMobile ? 0 : 1, child: _buildTextField('Type', _typeController, 'Type d\'équipement')),
                  ],
                ),
                const SizedBox(height: 16),

                // Champs Numéro de série et Statut
                _buildResponsiveRow(
                  isMobile: isMobile,
                  children: [
                    Expanded(flex: isMobile ? 0 : 1, child: _buildTextField('Numéro de série', _serialController, 'Numéro de série')),
                    if (!isMobile) const SizedBox(width: 16),
                    if (isMobile) const SizedBox(height: 16),
                    Expanded(flex: isMobile ? 0 : 1, child: _buildDropdownField<EquipmentStatus>(
                      'Statut',
                      _selectedStatus,
                      EquipmentStatus.values.map((s) {
                        String label = s == EquipmentStatus.disponible ? 'Disponible' : (s == EquipmentStatus.enMaintenance ? 'En maintenance' : (s == EquipmentStatus.enPanne ? 'En panne' : 'Hors service'));
                        return DropdownMenuItem(value: s, child: Text(label));
                      }).toList(),
                      (val) => setState(() => _selectedStatus = val!),
                    )),
                  ],
                ),
                const SizedBox(height: 16),

                // Champs Date d'achat et Prix
                _buildResponsiveRow(
                  isMobile: isMobile,
                  children: [
                    Expanded(flex: isMobile ? 0 : 1, child: _buildDatePickerField('Date d\'achat', _purchaseDate, () => _selectDate(context, true))),
                    if (!isMobile) const SizedBox(width: 16),
                    if (isMobile) const SizedBox(height: 16),
                    Expanded(flex: isMobile ? 0 : 1, child: _buildTextField('Prix d\'achat', _priceController, '0', isNumeric: true)),
                  ],
                ),
                const SizedBox(height: 16),

                // Expiration de la garantie
                _buildDatePickerField('Expiration de la garantie', _warrantyExpiry, () => _selectDate(context, false)),
                const SizedBox(height: 16),

                // Association à un espace (Optionnel)
                _buildDropdownField<String?>(
                  'Espaces (Optionnel)',
                  _selectedSpace,
                  [
                    const DropdownMenuItem(value: null, child: Text('Aucun')),
                    ...spacesController.spaces.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))),
                  ],
                  (val) => setState(() => _selectedSpace = val),
                ),
                const SizedBox(height: 16),

                // Description
                _buildTextField('Description', _descriptionController, 'Description détaillée...', maxLines: 3),
                const SizedBox(height: 16),

                // Notes
                _buildTextField('Notes', _notesController, 'Notes additionnelles...', maxLines: 3),
                const SizedBox(height: 32),

                // Boutons d'action (Annuler / Enregistrer)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: isMobile ? 1 : 0,
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: const Text('Annuler', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: isMobile ? 1 : 0,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(isMobile ? 'Modifier' : 'Enregistrer les modifications', 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget utilitaire pour organiser les éléments en ligne (desktop) ou colonne (mobile)
  Widget _buildResponsiveRow({required bool isMobile, required List<Widget> children}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // Widget personnalisé pour les champs de texte
  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1, bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          // Validation : certains champs sont obligatoires
          validator: (val) => (val == null || val.isEmpty) && label != 'Description' && label != 'Notes' ? 'Champ requis' : null,
        ),
      ],
    );
  }

  // Widget personnalisé pour les menus déroulants
  Widget _buildDropdownField<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Widget personnalisé pour le choix de date
  Widget _buildDatePickerField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? DateFormat('dd/MM/yyyy').format(date) : 'jj/mm/aaaa',
                  style: TextStyle(color: date != null ? Colors.black : Colors.grey[400], fontSize: 14),
                ),
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Fonction appelée pour valider et envoyer les modifications au contrôleur
  void _submit() {
    if (_formKey.currentState!.validate()) {
      final equipment = Equipment(
        id: widget.equipment.id,
        documentId: widget.equipment.documentId, // Crucial pour l'API Strapi
        name: _nameController.text,
        type: _typeController.text,
        serialNumber: _serialController.text,
        status: _selectedStatus,
        spaceName: _selectedSpace ?? '-',
        description: _descriptionController.text,
        purchaseDate: _purchaseDate,
        price: double.tryParse(_priceController.text) ?? 0,
        warrantyExpiry: _warrantyExpiry,
        notes: _notesController.text,
      );
      // Appel de la méthode updateEquipment du contrôleur
      controller.updateEquipment(equipment);
    }
  }
}
