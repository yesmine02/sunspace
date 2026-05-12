import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/users_controller.dart';
import '../../../data/models/user.dart';
import '../../../controllers/associations_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../data/models/association_model.dart';

class SendInvitationDialog extends StatefulWidget {
  const SendInvitationDialog({super.key});

  @override
  State<SendInvitationDialog> createState() => _SendInvitationDialogState();
}

class _SendInvitationDialogState extends State<SendInvitationDialog> {
  final controller = Get.find<UsersController>();
  final assocController = Get.find<AssociationsController>();
  final TextEditingController emailController = TextEditingController();
  User? foundUser;
  bool isSearching = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: isMobile ? double.infinity : 500,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2563EB), size: 28),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Envoyer une invitation',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Saisissez l\'email de l\'utilisateur à inviter dans l\'association.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Label
            const Text(
              'UTILISATEUR (EMAIL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Dropdown
            // Email TextField
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Entrez l\'email de l\'utilisateur...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
                ),
                onChanged: (val) {
                  // Optionnel : trouver l'utilisateur en temps réel pour validation visuelle
                  setState(() {
                    foundUser = controller.users.firstWhereOrNull(
                      (u) => u.email?.toLowerCase() == val.trim().toLowerCase()
                    );
                  });
                },
              ),
            ),
            if (emailController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: foundUser != null
                  ? Text('✓ Utilisateur trouvé : ${foundUser?.username}', style: const TextStyle(color: Colors.green, fontSize: 12))
                  : const Text('✗ Aucun utilisateur trouvé avec cet email', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 48),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: foundUser == null ? null : () async {
                    if (foundUser?.id == null) return;

                    // 1. On trouve l'association active de l'utilisateur connecté
                    final myId = Get.find<AuthController>().currentUser.value?['id'];
                    final activeAssoc = assocController.associations.firstWhereOrNull((a) {
                      if (a.admin?.id == myId) return true;
                      for (var m in (a.members ?? [])) {
                        if (m is Map && m['id'] == myId) return true;
                        if (m == myId) return true;
                      }
                      return false;
                    });

                    if (activeAssoc == null || activeAssoc.documentId == null) {
                       Get.snackbar('Erreur', 'Aucune association active trouvée');
                       return;
                    }

                    // 2. On appelle le serveur pour ajouter le membre
                    final success = await assocController.addMemberToAssociation(
                      activeAssoc.documentId!, 
                      foundUser!.id!,
                      newMemberUsername: foundUser!.username,
                      associationName: activeAssoc.name,
                    );

                    if (success) {
                      Get.back();
                      Get.snackbar(
                        'Succès',
                        'L\'utilisateur ${foundUser!.username} a été ajouté à l\'association.',
                        backgroundColor: const Color(0xFFDCFCE7),
                        colorText: const Color(0xFF166534),
                      );
                    } else {
                      Get.snackbar(
                        'Erreur',
                        'Impossible d\'ajouter le membre sur le serveur.',
                        backgroundColor: const Color(0xFFFEE2E2),
                        colorText: const Color(0xFF991B1B),
                      );
                    }
                  },
                  icon: Obx(() => assocController.isLoading.value 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline_rounded, size: 20)),
                  label: const Text(
                    'ENVOYER',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF60A5FA), // Bleu plus clair comme sur la capture
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
