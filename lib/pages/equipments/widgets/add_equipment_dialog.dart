// ===============================================
// Dialogue d'ajout d'équipement (AddEquipmentDialog)
// C'est une fenêtre contextuelle (pop-up) qui permet
// la saisie et l'enregistrement d'un nouvel équipement.
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/equipment.dart';
import '../../../controllers/equipments_controller.dart';
import '../../../controllers/spaces_controller.dart';

class AddEquipmentDialog extends StatefulWidget {
  const AddEquipmentDialog({super.key});

  @override
  State<AddEquipmentDialog> createState() => _AddEquipmentDialogState();
}

class _AddEquipmentDialogState extends State<AddEquipmentDialog> {
  // Clé pour identifier le formulaire et valider les champs
  final _formKey = GlobalKey<FormState>();

  // Récupération des contrôleurs nécessaires
  final EquipmentsController controller = Get.find<EquipmentsController>();
  final SpacesController spacesController = Get.put(SpacesController());

  // Contrôleurs de texte pour les champs de saisie
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _serialController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  // Variables d'état pour les champs non textuels
  EquipmentStatus _selectedStatus = EquipmentStatus.disponible;
  String? _selectedSpace;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;

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
      initialDate: DateTime.now(),
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
                        'Ajouter un équipement',
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
                  'Ajoutez un nouvel équipement à votre inventaire.',
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
                        String label = '';
                        switch (s) {
                          case EquipmentStatus.disponible: label = 'Disponible'; break;
                          case EquipmentStatus.enMaintenance: label = 'En maintenance'; break;
                          case EquipmentStatus.enPanne: label = 'En panne'; break;
                        }
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
                    Expanded(flex: isMobile ? 0 : 1, child: _buildTextField('Prix de location / Jour', _priceController, '0', isNumeric: true)),
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

                // Boutons d'action (Annuler / Ajouter)
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
                        child: Text(isMobile ? 'Ajouter' : 'Ajouter l\'équipement', 
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
          // Validation : certains champs sont obligatoires et ne doivent pas contenir de chiffres pour les noms
          validator: (val) {
            if (val == null || val.isEmpty) {
              if (label != 'Description' && label != 'Notes') return 'Champ requis';
              return null;
            }
            // Validation stricte : pas de chiffres pour le nom et le type
            if (label == 'Nom' || label == 'Type') {
              if (RegExp(r'[0-9]').hasMatch(val)) {
                return 'Le $label ne doit pas contenir de chiffres';
              }
            }
            return null;
          },
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
                  date != null ? DateFormat('dd / MM / yyyy').format(date) : 'jj / mm / aaaa',
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

  // Fonction appelée pour valider et envoyer les données au contrôleur
  void _submit() {
    if (_formKey.currentState!.validate()) {
      final equipment = Equipment(
        // Génération d'un ID temporaire basé sur le temps
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      // Appel de la méthode addEquipment du contrôleur
      controller.addEquipment(equipment);
    }
  }
}
