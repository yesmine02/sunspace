import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/users_controller.dart';
import '../../data/models/user.dart';
import 'widgets/add_user_dialog.dart';
import 'widgets/edit_user_dialog.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UsersController());
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    final double horizontalPadding = isMobile ? 16.0 : 40.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            isMobile 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderTitle(),
                    const SizedBox(height: 16),
                    _buildAddButton(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderTitle(),
                    _buildAddButton(),
                  ],
                ),
            const SizedBox(height: 32),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: controller.updateSearch,
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey[400]),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Users Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - (horizontalPadding * 2),
                    ),
                    child: Obx(() => DataTable(
                      headingRowHeight: 56,
                      dataRowHeight: 80,
                      horizontalMargin: 24,
                      columnSpacing: 24,
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFFDFDFD)),
                      dividerThickness: 1,
                      columns: const [
                        DataColumn(label: Text('Utilisateur', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                        DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                        DataColumn(label: Text('Rôle', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                        DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                        DataColumn(label: Text('Inscrit le', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                      ],
                      rows: controller.filteredUsers.map((user) => _buildUserRow(context, user, controller)).toList(),
                    )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_outline, size: 28, color: Colors.blue),
            const SizedBox(width: 12),
            const Text(
              'Gestion des utilisateurs',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Gérez les utilisateurs et leurs permissions',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Get.dialog(const AddUserDialog());
      },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Nouvel utilisateur'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  DataRow _buildUserRow(BuildContext context, User user, UsersController controller) {
    final String dateStr = user.createdAt != null 
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(user.createdAt!))
        : '-';

    return DataRow(cells: [
      // Utilisateur
      DataCell(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.username ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            Row(
              children: [
                Text(
                  'ID: ${user.id}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: user.id.toString()));
                    Get.snackbar('Copié', 'ID copié dans le presse-papier', 
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 1));
                  },
                  child: Icon(Icons.copy, size: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
      // Email
      DataCell(
        Row(
          children: [
            Icon(Icons.mail_outline, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(user.email ?? '-', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
      // Role
      DataCell(
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: Colors.blue[300]),
            const SizedBox(width: 8),
            Text(user.role ?? 'Authenticated', style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
      // Status
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (user.confirmed ?? false) ? const Color(0xFFDCFCE7) : Colors.orange[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            (user.confirmed ?? false) ? 'Confirmé' : 'Non confirmé',
            style: TextStyle(
              color: (user.confirmed ?? false) ? const Color(0xFF166534) : Colors.orange[900],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // Created At
      DataCell(Text(dateStr, style: TextStyle(color: Colors.grey[600]))),
      // Actions
      DataCell(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: Colors.grey[600],
              onPressed: () {
                Get.dialog(EditUserDialog(user: user));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.grey[600],
              onPressed: () {
                _showDeleteConfirmation(user, controller);
              },
            ),
          ],
        ),
      ),
    ]);
  }

  void _showDeleteConfirmation(User user, UsersController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${user.username} ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (user.id != null) {
                controller.deleteUser(user.id!);
                Get.back();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
