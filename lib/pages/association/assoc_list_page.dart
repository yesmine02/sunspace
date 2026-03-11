import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/users_controller.dart';
import '../../controllers/associations_controller.dart';
import '../../data/models/association_model.dart';
import 'widgets/add_association_dialog.dart';

class AssocListPage extends StatelessWidget {
  const AssocListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AssociationsController());
    Get.put(UsersController()); // Ajout pour éviter l'erreur "not found" dans le dialogue
    final bool isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light blue-grey background
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 32.0,
          vertical: isMobile ? 24.0 : 36.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ──────────────────────────────
            _buildHeader(isMobile),
            const SizedBox(height: 32),

            // ─── LIST / TABLE ────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                }
                
                if (controller.associations.isEmpty) {
                  return _buildEmptyState();
                }

                if (isMobile) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildMobileList(controller.associations),
                  );
                }

                return _buildTable(controller.associations);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Associations',
              style: TextStyle(
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            if (!isMobile)
              ElevatedButton.icon(
                onPressed: () => Get.dialog(const AddAssociationDialog()),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nouvelle Association', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Gérez les associations, leurs administrateurs et membres.',
          style: TextStyle(color: const Color(0xFF64748B), fontSize: isMobile ? 14 : 16),
        ),
        if (isMobile) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.dialog(const AddAssociationDialog()),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Nouvelle Association', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTable(List<Association> associations) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 56,
        dataRowHeight: 72,
        horizontalMargin: 24,
        columnSpacing: 24,
        headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
        columns: const [
          DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
          DataColumn(label: Text('Admin', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
          DataColumn(label: Text('Budget', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
          DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
          DataColumn(label: Text('Membres', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
        ],
        rows: associations.map((assoc) {
          return DataRow(cells: [
            DataCell(_buildNameCell(assoc)),
            DataCell(_buildAdminCell(assoc)),
            DataCell(Text('${assoc.budget.toInt()} TND', style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(_buildStatusBadge(assoc.isVerified)),
            DataCell(_buildMembersCell(assoc)),
            DataCell(_buildActionButtons(assoc)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<Association> associations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: associations.length,
      itemBuilder: (context, index) {
        final assoc = associations[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEFF6FF),
              child: const Icon(Icons.business, color: Color(0xFF2563EB)),
            ),
            title: Text(assoc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(assoc.email ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Admin', assoc.admin?.username ?? '-'),
                    _buildInfoRow('Budget', '${assoc.budget.toInt()} TND'),
                    _buildInfoRow('Statut', '', customWidget: _buildStatusBadge(assoc.isVerified)),
                    _buildInfoRow('Membres', '${assoc.members?.length ?? 0} membres'),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => launchUrl(Uri.parse('https://sunevit.tn/')),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Voir'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Get.dialog(AddAssociationDialog(association: assoc)),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Modifier'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _confirmDelete(context, assoc, Get.find<AssociationsController>()),
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          label: const Text('Supprimer', style: TextStyle(color: Color(0xFFEF4444))),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? customWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          customWidget ?? Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildNameCell(Association assoc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(assoc.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 15)),
        Text(assoc.email ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ],
    );
  }

  Widget _buildAdminCell(Association assoc) {
    if (assoc.admin == null) {
      return const Text(
        "Pas d'admin",
        style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(assoc.admin?.username ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        Text(assoc.admin?.email ?? '-', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusBadge(bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: verified ? const Color(0xFF00CC66) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: verified ? null : Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 16,
            color: verified ? Colors.white : const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 6),
          Text(
            verified ? 'Vérifiée' : 'Non vérifiée',
            style: TextStyle(
              color: verified ? Colors.white : const Color(0xFF3B82F6),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersCell(Association assoc) {
    return Row(
      children: [
        const Icon(Icons.people_outline, size: 18, color: Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text('${assoc.members?.length ?? 0} membres', style: const TextStyle(color: Color(0xFF475569))),
      ],
    );
  }

  Widget _buildActionButtons(Association assoc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => launchUrl(Uri.parse('https://sunevit.tn/')),
          icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF475569)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => Get.dialog(AddAssociationDialog(association: assoc)),
          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => _confirmDelete(Get.context!, assoc, Get.find<AssociationsController>()),
          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(60),
        child: Text('Aucune association trouvée.'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Association assoc, AssociationsController controller) {
    if (assoc.documentId == null) return;

    Get.defaultDialog(
      title: 'Supprimer l\'association',
      middleText: 'Voulez-vous vraiment supprimer "${assoc.name}" ? Cette action est irréversible.',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFEF4444),
      onConfirm: () async {
        Get.back(); // Ferme le dialogue
        await controller.deleteAssociation(assoc.documentId!);
      },
    );
  }
}
