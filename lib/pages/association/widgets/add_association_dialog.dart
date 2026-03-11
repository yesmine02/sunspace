import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/associations_controller.dart';
import '../../../controllers/users_controller.dart';
import '../../../data/models/user.dart';
import '../../../data/models/association_model.dart';

class AddAssociationDialog extends StatefulWidget {
  final Association? association;
  const AddAssociationDialog({super.key, this.association});

  @override
  State<AddAssociationDialog> createState() => _AddAssociationDialogState();
}

class _AddAssociationDialogState extends State<AddAssociationDialog> {
  final assocController = Get.find<AssociationsController>();
  final usersController = Get.find<UsersController>();

  final _formKey = GlobalKey<FormState>();
  
  // Controllers pour les champs
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _budgetCtrl;
  
  User? _selectedAdmin;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    final a = widget.association;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _descCtrl = TextEditingController(text: a?.description ?? '');
    _emailCtrl = TextEditingController(text: a?.email ?? '');
    _phoneCtrl = TextEditingController(text: a?.phone ?? '');
    _websiteCtrl = TextEditingController(text: a?.website ?? '');
    _budgetCtrl = TextEditingController(text: a?.budget.toString() ?? '0');
    _isVerified = a?.isVerified ?? false;
    
    // Tenter de retrouver l'admin dans la liste des utilisateurs
    if (a?.admin != null) {
      _selectedAdmin = usersController.users.firstWhereOrNull((u) => u.id == a!.admin!.id);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFF8FAFC),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.association == null ? 'Nouvelle association' : 'Modifier l\'association',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.association == null 
                            ? 'Ajoutez une nouvelle association au système.' 
                            : 'Modifiez les informations de l\'association ici.',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // CHAMP : NOM
                _buildLabel('Nom de l\'association'),
                _buildTextField(
                  _nameCtrl, 
                  hint: 'ASBL Dev', 
                  validator: (v) => v!.isEmpty ? 'Le nom est requis' : null
                ),
                const SizedBox(height: 16),

                // CHAMP : DESCRIPTION
                _buildLabel('Description'),
                _buildTextField(_descCtrl, hint: 'Description de l\'association...', maxLines: 3),
                const SizedBox(height: 16),

                // LIGNE : EMAIL + TELEPHONE
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Email'),
                          _buildTextField(_emailCtrl, hint: 'contact@assoc.com'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Téléphone'),
                          _buildTextField(_phoneCtrl, hint: '+212...'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CHAMP : SITE WEB
                _buildLabel('Site Web'),
                _buildTextField(_websiteCtrl, hint: 'https://...'),
                const SizedBox(height: 16),

                // LIGNE : BUDGET + ADMIN
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Budget initial'),
                          _buildTextField(_budgetCtrl, hint: '0', keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Administrateur principal'),
                          _buildAdminDropdown(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SWITCH : VERIFIED
                Row(
                  children: [
                    Switch(
                      value: _isVerified,
                      onChanged: (v) => setState(() => _isVerified = v),
                      activeColor: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Association vérifiée',
                      style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // BUTTON : ENREGISTRER
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Obx(() => ElevatedButton(
                      onPressed: assocController.isLoading.value ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: assocController.isLoading.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w800)),
                    )),
                  ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, {String? hint, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAdminDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<User>(
          isExpanded: true,
          hint: const Text('Choisir un admin', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          value: _selectedAdmin,
          items: usersController.users.map((User user) {
            return DropdownMenuItem<User>(
              value: user,
              child: Text(user.username ?? '-', style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedAdmin = val),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Construction du payload correspondant exactement à la structure acceptée par le serveur
    final data = {
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'logo': null,
      'website': _websiteCtrl.text,
      'email': _emailCtrl.text,
      'phone': _phoneCtrl.text,
      'budget': double.tryParse(_budgetCtrl.text) ?? 0.0,
      'is_verified': _isVerified,
      'admin': _selectedAdmin?.id,
      'members': _selectedAdmin != null ? [_selectedAdmin!.id] : [],
    };

    final success = widget.association == null 
      ? await assocController.createAssociation(data)
      : await assocController.updateAssociation(widget.association!.documentId!, data);
    
    if (success) {
      Get.back();
    }
  }
}
