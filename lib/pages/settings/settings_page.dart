// ===============================================
// Page de Paramètres (SettingsPage)
// Redésignée selon les maquettes haute-fidélité
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routing/app_routes.dart';
import '../../widgets/notification_bell.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // États locaux pour les préférences
  bool emailNotifications = true;
  bool smsNotifications = false;
  bool pushNotifications = true;

  // États pour le changement de mot de passe
  bool isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔷 TOP BAR DE RECHERCHE
            _buildTopBar(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔷 TITRE
                  const Text(
                    'Paramètres',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -1.0,
                    ),
                  ),
                  const Text(
                    'Gérez vos préférences et votre sécurité',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 🔷 SECTION : ORGANISATION / ASSOCIATION (Nouvelle Page Ajoutée ici)
                  _buildAssociationSection(isMobile),
                  const SizedBox(height: 24),

                  // 🔷 SECTION : SÉCURITÉ
                  _buildSecuritySection(isMobile),
                  const SizedBox(height: 24),

                  // 🔷 SECTION : NOTIFICATIONS
                  _buildNotificationsSection(isMobile),
                  const SizedBox(height: 24),

                  // 🔷 SECTION : QUITTER
                  _buildLogoutSection(isMobile),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Rechercher...",
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          const NotificationBell(size: 18, iconColor: Color(0xFF64748B)),
          const SizedBox(width: 12),
          _buildTopIcon(Icons.help_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildTopIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFF64748B), size: 18),
    );
  }

  Widget _buildSectionCard({required Widget child, Color? bgColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSecuritySection(bool isMobile) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBox(Icons.lock_outline_rounded, Colors.blue),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Sécurité', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Text('Modifier votre mot de passe', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (!isChangingPassword)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => isChangingPassword = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Changer le mot de passe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Mot de passe actuel"),
                _buildPasswordField(
                  controller: _currentPasswordController,
                  hint: "Entrez votre mot de passe actuel",
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                const SizedBox(height: 20),
                _buildLabel("Nouveau mot de passe"),
                _buildPasswordField(
                  controller: _newPasswordController,
                  hint: "Entrez votre nouveau mot de passe",
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 20),
                _buildLabel("Confirmer le mot de passe"),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hint: "Confirmez votre nouveau mot de passe",
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final authController = Get.find<AuthController>();
                        
                        // Validation locale
                        if (_currentPasswordController.text.isEmpty || 
                            _newPasswordController.text.isEmpty || 
                            _confirmPasswordController.text.isEmpty) {
                          Get.snackbar('Erreur', 'Veuillez remplir tous les champs', 
                              backgroundColor: Colors.red, colorText: Colors.white);
                          return;
                        }

                        if (_newPasswordController.text != _confirmPasswordController.text) {
                          Get.snackbar('Erreur', 'Les nouveaux mots de passe ne correspondent pas', 
                              backgroundColor: Colors.red, colorText: Colors.white);
                          return;
                        }

                        // Appel au backend
                        bool success = await authController.changePassword(
                          _currentPasswordController.text,
                          _newPasswordController.text,
                          _confirmPasswordController.text,
                        );

                        if (success) {
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                          setState(() => isChangingPassword = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Obx(() => Get.find<AuthController>().isLoading.value 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => setState(() => isChangingPassword = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFFDFDFD),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFF94A3B8),
            size: 20,
          ),
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildNotificationsSection(bool isMobile) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBox(Icons.notifications_none_rounded, Colors.blue),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Text('Contrôlez comment vous recevez les notifications', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSwitchItem("Notifications par email", "Recevez les mises à jour importantes par email", emailNotifications, (v) => setState(() => emailNotifications = v)),
          const SizedBox(height: 16),
          _buildSwitchItem("Notifications par SMS", "Recevez les alertes critiques par SMS", smsNotifications, (v) => setState(() => smsNotifications = v)),
          const SizedBox(height: 16),
          _buildSwitchItem("Notifications push", "Recevez les notifications en temps réel", pushNotifications, (v) => setState(() => pushNotifications = v)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.snackbar('Succès', 'Vos préférences ont été enregistrées', 
                  backgroundColor: const Color(0xFF10B981), colorText: Colors.white);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Enregistrer les préférences', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssociationSection(bool isMobile) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBox(Icons.account_balance_wallet_outlined, const Color(0xFF10B981)),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Compte Association', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Text('Gérez votre budget et vos services organisationnels', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildSmallDetailCard("Solde Restant", "3 259,50 €", const Color(0xFF10B981)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSmallDetailCard("Dépenses Mois", "1 240,50 €", Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Get.toNamed(AppRoutes.ASSOC_BUDGET),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Voir le rapport détaillé', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007AFF), fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDetailCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(bool isMobile) {
    final authController = Get.find<AuthController>();

    return _buildSectionCard(
      bgColor: const Color(0xFFFEF2F2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quitter', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF991B1B))),
          const SizedBox(height: 8),
          const Text('Déconnectez-vous de votre compte', style: TextStyle(color: Color(0xFFEF4444), fontSize: 15)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => authController.logout(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                ),
              ),
              child: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444), fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          activeColor: const Color(0xFF007AFF),
          onChanged: (v) => onChanged(v ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
              Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
