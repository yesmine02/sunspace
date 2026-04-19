import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/users_controller.dart';
import '../../../data/models/user.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Authenticated';
  bool _isConfirmed = true;
  bool _isBlocked = false;

  @override
  Widget build(BuildContext context) {
    final UsersController controller = Get.find<UsersController>();
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        width: isMobile ? double.infinity : 500,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nouvel utilisateur',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ajoutez un nouvel utilisateur au système.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Username
                _buildLabel("Nom d'utilisateur"),
                _buildTextField(
                  controller: _usernameController,
                  hint: 'johndoe',
                ),
                const SizedBox(height: 16),

                // Email
                _buildLabel("Email"),
                _buildTextField(
                  controller: _emailController,
                  hint: 'john@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Role
                _buildLabel("Rôle"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      items: ['Admin', 'Authenticated'].map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                _buildLabel("Mot de passe"),
                _buildTextField(
                  controller: _passwordController,
                  hint: '******',
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                // Toggles
                isMobile 
                  ? Column(
                      children: [
                        _buildToggleRow('Confirmé', _isConfirmed, (val) => setState(() => _isConfirmed = val)),
                        _buildToggleRow('Bloqué', _isBlocked, (val) => setState(() => _isBlocked = val)),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildToggleRow('Confirmé', _isConfirmed, (val) => setState(() => _isConfirmed = val))),
                        Expanded(child: _buildToggleRow('Bloqué', _isBlocked, (val) => setState(() => _isBlocked = val))),
                      ],
                    ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _submit(controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Enregistrer l\'utilisateur',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ce champ est obligatoire';
        return null;
      },
    );
  }

  void _submit(UsersController controller) async {
    if (_formKey.currentState!.validate()) {
      try {
        final newUser = User(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          username: _usernameController.text,
          email: _emailController.text,
          role: {'name': _selectedRole, 'type': _selectedRole.toLowerCase()},
          confirmed: _isConfirmed,
          blocked: _isBlocked,
          createdAt: DateTime.now().toIso8601String(),
        );

        await controller.addUser(newUser);
        
        Get.back(); // Close dialog first

        Get.snackbar(
          'Succès',
          'L\'utilisateur "${newUser.username}" a été créé.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDCFCE7),
          colorText: const Color(0xFF166534),
        );
      } catch (e) {
        Get.snackbar(
          'Erreur d\'enregistrement',
          'Une erreur est survenue : $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }
    } else {
      Get.snackbar(
        'Champs requis',
        'Veuillez remplir tous les champs obligatoires.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
    }
  }
}
