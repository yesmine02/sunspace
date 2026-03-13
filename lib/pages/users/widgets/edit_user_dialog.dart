import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/users_controller.dart';
import '../../../data/models/user.dart';

class EditUserDialog extends StatefulWidget {
  final User user;
  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  late String _selectedRole;
  late bool _isConfirmed;
  late bool _isBlocked;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedRole = widget.user.roleName.isNotEmpty ? widget.user.roleName : 'Authenticated';
    _isConfirmed = widget.user.confirmed ?? false;
    _isBlocked = widget.user.blocked ?? false;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UsersController controller = Get.find<UsersController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 500,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modifier l\'utilisateur',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Modifiez les informations de l\'utilisateur ici.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
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
              _buildLabel("Mot de passe (laisser vide pour ne pas changer)"),
              _buildTextField(
                controller: _passwordController,
                hint: '******',
                obscureText: true,
                isRequired: false,
              ),
              const SizedBox(height: 16),

              // Toggles
              Row(
                children: [
                  Switch(
                    value: _isConfirmed,
                    onChanged: (val) => setState(() => _isConfirmed = val),
                    activeColor: Colors.blue,
                  ),
                  const Text('Confirmé', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 24),
                  Switch(
                    value: _isBlocked,
                    onChanged: (val) => setState(() => _isBlocked = val),
                    activeColor: Colors.blue,
                  ),
                  const Text('Bloqué', style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 150,
                  height: 48,
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
                      'Enregistrer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    bool isRequired = true,
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
        if (isRequired && (value == null || value.isEmpty)) return 'Ce champ est obligatoire';
        return null;
      },
    );
  }

  void _submit(UsersController controller) {
    // Vérifier si le formulaire est valide
    if (_formKey.currentState!.validate()) {
      final updatedUser = User(
        id: widget.user.id,
        username: _usernameController.text,
        email: _emailController.text,
        role: {'name': _selectedRole, 'type': _selectedRole.toLowerCase()},
        confirmed: _isConfirmed,
        blocked: _isBlocked,
        createdAt: widget.user.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      controller.updateUser(updatedUser);
      Get.back();
    }
  }
}
