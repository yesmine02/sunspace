import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/associations_controller.dart';
import '../../../controllers/users_controller.dart';
import '../../../data/models/association_model.dart';
import '../../../data/models/user.dart';

class ManageMembersDialog extends StatefulWidget {
  final Association association;

  const ManageMembersDialog({super.key, required this.association});

  @override
  State<ManageMembersDialog> createState() => _ManageMembersDialogState();
}

class _ManageMembersDialogState extends State<ManageMembersDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';
  final AssociationsController _assocCtrl = Get.find<AssociationsController>();
  final UsersController _usersCtrl = Get.find<UsersController>();

  // IDs of members currently in this association
  Set<int> get _memberIds {
    final Set<int> ids = {};
    final assoc = _assocCtrl.associations
        .firstWhereOrNull((a) => a.documentId == widget.association.documentId)
        ?? widget.association;
    for (var m in (assoc.members ?? [])) {
      if (m is Map && m['id'] != null) ids.add(m['id']);
      if (m is int) ids.add(m);
    }
    return ids;
  }

  // Current members (User objects)
  List<User> get _currentMembers =>
      _usersCtrl.users.where((u) => u.id != null && _memberIds.contains(u.id)).toList();

  // Users NOT yet in the association (candidates to add)
  List<User> get _availableUsers {
    final ids = _memberIds;
    return _usersCtrl.users.where((u) {
      if (u.id == null || ids.contains(u.id)) return false;
      if (_searchText.isEmpty) return true;
      return (u.username ?? '').toLowerCase().contains(_searchText) ||
          (u.email ?? '').toLowerCase().contains(_searchText);
    }).toList();
  }

  Association get _liveAssoc =>
      _assocCtrl.associations
          .firstWhereOrNull((a) => a.documentId == widget.association.documentId)
          ?? widget.association;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _usersCtrl.loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 620),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membres de ${widget.association.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gérez la liste des membres appartenant à cette association.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            // ── Tabs ─────────────────────────────────────────────
            Obx(() {
              final count = _currentMembers.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)
                      ],
                    ),
                    labelColor: const Color(0xFF0F172A),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: [
                      Tab(text: 'Actuels ($count)'),
                      const Tab(text: 'Ajouter des membres'),
                    ],
                    onTap: (_) => setState(() => _searchText = ''),
                  ),
                ),
              );
            }),

            // ── Tab content ──────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCurrentMembersTab(),
                  _buildAddMembersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Onglet 1 : Membres actuels ──────────────────────────────
  Widget _buildCurrentMembersTab() {
    return Obx(() {
      final members = _currentMembers;
      if (_assocCtrl.isLoading.value || _usersCtrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (members.isEmpty) {
        return const Center(
          child: Text('Aucun membre dans cette association.',
              style: TextStyle(color: Color(0xFF64748B))),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: members.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => _memberTile(members[i], canRemove: true),
      );
    });
  }

  // ─── Onglet 2 : Ajouter des membres ─────────────────────────
  Widget _buildAddMembersTab() {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_usersCtrl.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final available = _availableUsers;
            if (available.isEmpty) {
              return const Center(
                child: Text('Tous les utilisateurs sont déjà membres.',
                    style: TextStyle(color: Color(0xFF64748B))),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: available.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _memberTile(available[i], canRemove: false),
            );
          }),
        ),
      ],
    );
  }

  // ─── Tuile utilisateur (ajouter ou retirer) ──────────────────
  Widget _memberTile(User user, {required bool canRemove}) {
    final initial = (user.username ?? '?')[0].toUpperCase();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEFF6FF),
        child: Text(
          initial,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
        ),
      ),
      title: Text(user.username ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(user.email ?? '-',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      trailing: Obx(() => _assocCtrl.isLoading.value
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : IconButton(
              onPressed: () => canRemove ? _removeMember(user) : _addMember(user),
              icon: Icon(
                canRemove ? Icons.person_remove_outlined : Icons.person_add_outlined,
                color: canRemove ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
              ),
            )),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────

  Future<void> _addMember(User user) async {
    if (widget.association.documentId == null || user.id == null) return;
    final success = await _assocCtrl.addMemberToAssociation(
      widget.association.documentId!,
      user.id!,
      newMemberUsername: user.username,
      associationName: _liveAssoc.name,
    );
    if (success) {
      Get.snackbar('Succès', '${user.username} a été ajouté.',
          backgroundColor: const Color(0xFFDCFCE7),
          colorText: const Color(0xFF166534));
      setState(() {});
    } else {
      Get.snackbar('Erreur', 'Impossible d\'ajouter le membre.',
          backgroundColor: const Color(0xFFFEE2E2),
          colorText: const Color(0xFF991B1B));
    }
  }

  Future<void> _removeMember(User user) async {
    if (widget.association.documentId == null || user.id == null) return;
    final success = await _assocCtrl.removeMemberFromAssociation(
      widget.association.documentId!,
      user.id!,
    );
    if (success) {
      Get.snackbar('Retiré', '${user.username} a été retiré de l\'association.',
          backgroundColor: const Color(0xFFFFF7ED),
          colorText: const Color(0xFF92400E));
      setState(() {});
    } else {
      Get.snackbar('Erreur', 'Impossible de retirer le membre.',
          backgroundColor: const Color(0xFFFEE2E2),
          colorText: const Color(0xFF991B1B));
    }
  }
}
