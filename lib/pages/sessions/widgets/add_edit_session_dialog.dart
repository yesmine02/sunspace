// ===============================================
// Dialogue d'Ajout ou de Modification de Session
// Design Responsive
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/training_session.dart';
import '../../../data/models/course.dart';
import '../../../controllers/sessions_controller.dart';
import '../../../controllers/courses_controller.dart';

class AddEditSessionDialog extends StatefulWidget {
  final TrainingSession? session;
  const AddEditSessionDialog({super.key, this.session});

  @override
  State<AddEditSessionDialog> createState() => _AddEditSessionDialogState();
}

class _AddEditSessionDialogState extends State<AddEditSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final SessionsController controller = Get.find<SessionsController>();
  final CoursesController coursesController = Get.put(CoursesController());

  // Champs texte
  late TextEditingController _titleController;
  late TextEditingController _maxParticipantsController;
  late TextEditingController _meetingLinkController;
  late TextEditingController _notesController;

  // Sélections
  Course? _selectedCourse;
  SessionType _selectedType = SessionType.enLigne;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.session?.title ?? '');
    _maxParticipantsController = TextEditingController(text: widget.session?.maxParticipants.toString() ?? '10');
    _meetingLinkController = TextEditingController(text: widget.session?.meetingLink ?? '');
    _notesController = TextEditingController(text: widget.session?.notes ?? '');
    
    _startDate = widget.session?.startDate;
    _endDate = widget.session?.endDate;
    _selectedType = widget.session?.type ?? SessionType.enLigne;

    // Tenter de trouver le cours correspondant si on est en édition
    if (widget.session?.courseName != null && widget.session?.courseName != '-') {
      _selectedCourse = coursesController.courses.firstWhereOrNull(
        (c) => c.title == widget.session!.courseName
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _maxParticipantsController.dispose();
    _meetingLinkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Pickers
  Future<void> _pickDateTime(bool isStart) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
             colorScheme: const ColorScheme.light(
               primary: Color(0xFF007AFF),
             ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    // ignore: use_build_context_synchronously
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime((isStart ? _startDate : _endDate) ?? DateTime.now()),
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
             colorScheme: const ColorScheme.light(
               primary: Color(0xFF007AFF),
             ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    setState(() {
      DateTime newDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startDate = newDate;
        // Si la date de fin est avant la nouvelle date de début, on l'ajuste
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
           _endDate = _startDate!.add(const Duration(hours: 1));
        }
      } else {
        _endDate = newDate;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Adapter la largeur selon l'écran
    final isMobile = context.width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 600,
        constraints: BoxConstraints(
          maxHeight: context.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             // En-tête fixe
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session == null ? 'Nouvelle Session' : 'Modifier la Session',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Planifiez votre formation',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(), 
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Remove extra padding
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      _buildLabel('Titre de la session'),
                      _buildTextField(_titleController, 'Ex: Introduction à Flutter...', validator: (v) => v!.isEmpty ? 'Requis' : null),
                      const SizedBox(height: 20),
              
                      // Cours associé
                      _buildLabel('Cours associé (Optionnel)'),
                      Obx(() => _buildDropdown<Course?>(
                        _selectedCourse,
                        coursesController.courses.map((c) {
                          return DropdownMenuItem<Course?>(value: c, child: Text(c.title, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        (val) => setState(() => _selectedCourse = val),
                        hint: 'Sélectionner un cours',
                      )),
                      const SizedBox(height: 20),
              
                      // Type et Max Participants
                      // Sur mobile, on les empile. Sur desktop, côte à côte.
                      if (isMobile) ...[
                        _buildLabel('Type de session'),
                        _buildTypeDropdown(),
                        const SizedBox(height: 20),
                        _buildLabel('Nombre max. de participants'),
                        _buildTextField(_maxParticipantsController, '10', isNumeric: true),
                      ] else 
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Type'),
                                  _buildTypeDropdown(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Max. Partic.'),
                                  _buildTextField(_maxParticipantsController, '10', isNumeric: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
              
                      // Dates Début et Fin
                      if (isMobile) ...[
                        _buildDateTimePicker('Date de début', _startDate, () => _pickDateTime(true)),
                        const SizedBox(height: 16),
                        _buildDateTimePicker('Date de fin', _endDate, () => _pickDateTime(false)),
                      ] else 
                        Row(
                          children: [
                            Expanded(child: _buildDateTimePicker('Début', _startDate, () => _pickDateTime(true))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDateTimePicker('Fin', _endDate, () => _pickDateTime(false))),
                          ],
                        ),
                      const SizedBox(height: 20),
              
                      // Lien de réunion
                      _buildLabel('Lien de réunion / Salle'),
                      _buildTextField(_meetingLinkController, 'https://zoom.us/... ou Salle 3B'),
                      const SizedBox(height: 20),
              
                      // Notes
                      _buildLabel('Notes / Instructions'),
                      _buildTextField(_notesController, 'Instructions pour les participants...', maxLines: 3),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton Action (fixe en bas)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  widget.session == null ? 'Planifier la session' : 'Enregistrer les modifications',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return _buildDropdown<SessionType>(
      _selectedType,
      SessionType.values.map((t) {
        String label = t == SessionType.presentiel ? 'Présentiel' : (t == SessionType.hybride ? 'Hybride' : 'En ligne');
        IconData icon = t == SessionType.presentiel ? Icons.location_on : (t == SessionType.hybride ? Icons.domain_verification : Icons.videocam);
        return DropdownMenuItem(
          value: t, 
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        );
      }).toList(),
      (val) => setState(() => _selectedType = val!),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, bool isNumeric = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF007AFF))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>(T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged, {String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint != null ? Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 14)) : null,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items,
          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(String label, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value != null ? DateFormat('dd/MM/yyyy HH:mm', 'fr').format(value) : 'Choisir une date',
                    style: TextStyle(color: value != null ? const Color(0xFF1E293B) : Colors.grey[400], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        Get.snackbar('Date manquante', 'Veuillez sélectionner une date de début et de fin', 
          backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return;
      }

      if (_endDate!.isBefore(_startDate!)) {
         Get.snackbar('Erreur de date', 'La date de fin doit être après la date de début', 
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
         return;
      }

      final session = TrainingSession(
        id: widget.session?.id ?? '',
        documentId: widget.session?.documentId,
        title: _titleController.text,
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        maxParticipants: int.tryParse(_maxParticipantsController.text) ?? 10,
        meetingLink: _meetingLinkController.text,
        notes: _notesController.text,
        status: SessionStatus.publie, // On publie par défaut à la planification
      );

      if (widget.session == null) {
        controller.addSession(session, _selectedCourse?.id);
      } else {
        controller.updateSession(session, _selectedCourse?.id);
      }
      
      Get.back(); // Fermer le dialogue après soumission
    }
  }
}
