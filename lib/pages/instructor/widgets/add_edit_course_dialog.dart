// ===============================================
// Dialogue d'Ajout ou de Modification de Cours
// Design aligné sur la capture utilisateur
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/course.dart';
import '../../../controllers/courses_controller.dart';

class AddEditCourseDialog extends StatefulWidget {
  final Course? course;
  const AddEditCourseDialog({super.key, this.course});

  @override
  State<AddEditCourseDialog> createState() => _AddEditCourseDialogState();
}

class _AddEditCourseDialogState extends State<AddEditCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final CoursesController controller = Get.find<CoursesController>();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  
  late CourseLevel _selectedLevel;
  late CourseStatus _selectedStatus;
//initialisation des variables
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course?.title ?? '');
    _priceController = TextEditingController(text: widget.course?.price.toInt().toString() ?? '0');
    _descriptionController = TextEditingController(text: widget.course?.description ?? '');
    _selectedLevel = widget.course?.level ?? CourseLevel.debutant;
    _selectedStatus = widget.course?.status ?? CourseStatus.brouillon;
  }
//fonction pour modifier le prix
  void _changePrice(int delta) {
    int current = int.tryParse(_priceController.text) ?? 0;
    int newValue = current + delta;
    if (newValue < 0) newValue = 0;
    setState(() {
      _priceController.text = newValue.toString();
    });
  }

//fonction pour libérer les variables
  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
//fenetre de dialogue pour ajouter ou modifier un cours
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: isMobile ? double.infinity : 550,
        constraints: const BoxConstraints(maxWidth: 550),
        padding: EdgeInsets.all(isMobile ? 20 : 28),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec bouton fermer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.course == null ? 'Créer un nouveau cours' : 'Modifier le cours',
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 22, 
                              fontWeight: FontWeight.bold, 
                              color: const Color(0xFF1E293B)
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Remplissez les détails ci-dessous pour ${widget.course == null ? 'créer un nouveau' : 'modifier ce'} cours.',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Titre du cours
                _buildLabel('Titre du cours'),
                _buildTextField(_titleController, 'Introduction au...', maxLines: 1, isTitle: true),
                const SizedBox(height: 20),

                // Description
                _buildLabel('Description'),
                _buildTextField(_descriptionController, 'Une brève description du cours...', maxLines: 3),
                const SizedBox(height: 20),

                // Niveau et Prix (Côte à côte sur Desktop, Colonne sur Mobile)
                if (isMobile) ...[
                  _buildLabel('Niveau'),
                  _buildDropdown<CourseLevel>(
                    _selectedLevel,
                    CourseLevel.values.map((l) {
                      String label = l == CourseLevel.debutant ? 'Débutant' : (l == CourseLevel.intermediaire ? 'Intermédiaire' : 'Avancé');
                      return DropdownMenuItem(value: l, child: Text(label));
                    }).toList(),
                    (val) => setState(() => _selectedLevel = val!),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Prix (TND)'),
                  _buildPriceField(),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Niveau'),
                            _buildDropdown<CourseLevel>(
                              _selectedLevel,
                              CourseLevel.values.map((l) {
                                String label = l == CourseLevel.debutant ? 'Débutant' : (l == CourseLevel.intermediaire ? 'Intermédiaire' : 'Avancé');
                                return DropdownMenuItem(value: l, child: Text(label)); // Corrected child
                              }).toList(),
                              (val) => setState(() => _selectedLevel = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Prix (TND)'),
                            _buildPriceField(),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Statut (Brouillon / Publié)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Statut'),
                    SizedBox(
                      width: isMobile ? double.infinity : 220,
                      child: _buildDropdown<CourseStatus>(
                        _selectedStatus,
                        [
                          const DropdownMenuItem(value: CourseStatus.brouillon, child: Text('Brouillon')),
                          const DropdownMenuItem(value: CourseStatus.publie, child: Text('Publié')),
                        ],
                        (val) => setState(() => _selectedStatus = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Bouton de validation
                SizedBox(
                  width: isMobile ? double.infinity : null,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.course == null ? 'Créer le cours' : 'Enregistrer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF334155))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, bool isTitle = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Ce champ est requis';
        if (isTitle && RegExp(r'[0-9]').hasMatch(val)) {
          return 'Le titre ne doit pas contenir de chiffres';
        }
        return null;
      },
    );
  }
//champ pour saisir le prix
  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(onTap: () => _changePrice(10), child: const Icon(Icons.keyboard_arrow_up, size: 18)),
            InkWell(onTap: () => _changePrice(-10), child: const Icon(Icons.keyboard_arrow_down, size: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
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
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final course = Course(
        id: widget.course?.id ?? '',
        documentId: widget.course?.documentId,
        title: _titleController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        level: _selectedLevel,
        description: _descriptionController.text,
        status: _selectedStatus,
      );

      if (widget.course == null) {
        controller.addCourse(course);
      } else {
        controller.updateCourse(course);
      }
    }
  }
}
