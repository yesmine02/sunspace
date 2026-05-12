// ===============================================
// Dialogue d'Ajout/Édition de Devoir
// Design Responsive (Mobile + Desktop)
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/models/assignment.dart';
import '../../../data/models/course.dart';
import '../../../controllers/assignments_controller.dart';
import '../../../controllers/courses_controller.dart';

class AddEditAssignmentDialog extends StatefulWidget {
  final Assignment? assignment;
  const AddEditAssignmentDialog({super.key, this.assignment});

  @override
  State<AddEditAssignmentDialog> createState() => _AddEditAssignmentDialogState();
}

class _AddEditAssignmentDialogState extends State<AddEditAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final AssignmentsController controller = Get.find<AssignmentsController>();
  final CoursesController coursesController = Get.put(CoursesController());

  late TextEditingController _titleController;
  late TextEditingController _instructionsController;
  late TextEditingController _maxPointsController;
  late TextEditingController _passingScoreController;

  Course? _selectedCourse;
  DateTime? _dueDate;
  bool _allowLateSubmission = false;
  PlatformFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment?.title ?? '');
    _instructionsController = TextEditingController(text: widget.assignment?.description ?? '');
    _maxPointsController = TextEditingController(text: widget.assignment?.maxPoints.toInt().toString());
    _passingScoreController = TextEditingController(text: widget.assignment?.passingScore.toInt().toString());

    _dueDate = widget.assignment?.dueDate;
    _allowLateSubmission = widget.assignment?.allowLateSubmission ?? false;

    if (widget.assignment?.courseName != null && widget.assignment?.courseName != '-') {
      _selectedCourse = coursesController.courses.firstWhereOrNull(
        (c) => c.title == widget.assignment!.courseName,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _maxPointsController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double dialogWidth = isMobile ? MediaQuery.of(context).size.width * 0.95 : 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 40, vertical: isMobile ? 16 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.assignment == null ? 'Créer un devoir' : 'Modifier le devoir',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Formulaire Scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      _buildLabel('Titre du devoir *'),
                      _buildTextField(_titleController, 'Ex: TP1 - Introduction à React', validator: (v) => v!.isEmpty ? 'Requis' : null),
                      const SizedBox(height: 16),

                      // Cours
                      _buildLabel('Cours associé *'),
                      Obx(() => _buildDropdown<Course?>(
                        _selectedCourse,
                        coursesController.courses.map((c) {
                          return DropdownMenuItem<Course?>(value: c, child: Text(c.title, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        (val) => setState(() => _selectedCourse = val),
                        hint: 'Sélectionner un cours',
                      )),
                      const SizedBox(height: 16),

                      // Instructions
                      _buildLabel('Instructions *'),
                      _buildTextField(_instructionsController, 'Décrivez les objectifs...', maxLines: 3, validator: (v) => v!.isEmpty ? 'Requis' : null),
                      const SizedBox(height: 16),

                      // Date et Points — empilés sur mobile, côte à côte sur desktop
                      if (isMobile) ...[
                        _buildLabel('Date d\'échéance *'),
                        _buildDatePicker(),
                        const SizedBox(height: 16),
                        _buildLabel('Points maximum *'),
                        _buildTextField(_maxPointsController, '100', isNumeric: true),
                        const SizedBox(height: 16),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Date d\'échéance *'),
                                  _buildDatePicker(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Points maximum *'),
                                  _buildTextField(_maxPointsController, '100', isNumeric: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Note de passage
                      _buildLabel('Note de passage (optionnel)'),
                      _buildTextField(_passingScoreController, '0', isNumeric: true),
                      const SizedBox(height: 12),

                      // Checkbox Retard
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          'Autoriser les soumissions en retard',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 13 : 14),
                        ),
                        subtitle: Text(
                          "Les étudiants pourront soumettre après la date d'échéance",
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        value: _allowLateSubmission,
                        onChanged: (val) => setState(() => _allowLateSubmission = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 16),

                      // Pièce jointe
                      _buildLabel('Pièce jointe (Optionnel)'),
                      InkWell(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _pickedFile != null ? Icons.check_circle : Icons.upload_file,
                                color: _pickedFile != null ? Colors.green : const Color(0xFF64748B),
                                size: isMobile ? 28 : 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _pickedFile != null ? _pickedFile!.name : 'Cliquez pour télécharger',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                  fontSize: isMobile ? 13 : 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              if (_pickedFile == null)
                                Text('PDF, Word, TXT', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              if (_pickedFile != null)
                                TextButton(
                                  onPressed: () => setState(() => _pickedFile = null),
                                  child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: isMobile ? 12 : 24),

            // Actions
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save, size: 18),
                        label: Text(widget.assignment == null ? 'Créer le devoir' : 'Enregistrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save, size: 18),
                        label: Text(widget.assignment == null ? 'Créer le devoir' : 'Enregistrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // =============================
  // WIDGETS UTILITAIRES
  // =============================

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dueDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(_dueDate!) : 'jj/mm/aaaa --:--',
              style: TextStyle(color: _dueDate != null ? Colors.black : Colors.grey[500], fontSize: 14),
            ),
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {int maxLines = 1, bool isNumeric = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  /// Crée un menu déroulant (liste de choix) avec un design personnalisé
  Widget _buildDropdown<T>(T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged, {String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint != null ? Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 14)) : null,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCourse == null) {
        Get.snackbar('Erreur', 'Veuillez sélectionner un cours', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
      if (_dueDate == null) {
        Get.snackbar('Erreur', 'Veuillez sélectionner une date d\'échéance', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      final assignment = Assignment(
        id: widget.assignment?.id ?? '',
        documentId: widget.assignment?.documentId,
        title: _titleController.text,
        description: _instructionsController.text,
        maxPoints: double.tryParse(_maxPointsController.text) ?? 100,
        passingScore: double.tryParse(_passingScoreController.text) ?? 0,
        allowLateSubmission: _allowLateSubmission,
        dueDate: _dueDate,
      );

      if (widget.assignment == null) {
        controller.addAssignment(assignment, _selectedCourse?.id, file: _pickedFile);
      } else {
        controller.updateAssignment(assignment, _selectedCourse?.documentId);
      }
      Get.back();
    }
  }
}
