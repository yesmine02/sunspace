// ===============================================
// Page Membres (AssocMembersPage)
// Pour les Associations : Gérer les membres du groupe
// Design conforme à la capture fournie
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/users_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/associations_controller.dart';
import '../../data/models/user.dart';
import '../../data/models/association_model.dart';
import '../users/widgets/edit_user_dialog.dart';
import 'widgets/send_invitation_dialog.dart';

class AssocMembersPage extends StatefulWidget {
  const AssocMembersPage({super.key});

  @override
  State<AssocMembersPage> createState() => _AssocMembersPageState();
}

class _AssocMembersPageState extends State<AssocMembersPage> {
  // Filtre actif de l'onglet : 'TOUS', 'ADMINS' ou 'MEMBRES'
  String _activeFilter = 'TOUS';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Initialisation des contrôleurs nécessaires
    final controller = Get.put(UsersController());
    final assocCtrl = Get.put(AssociationsController());
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 32.0,
          vertical: isMobile ? 24.0 : 36.0,
        ),
        child: Obx(() {
          // 🔹 IDENTIFICATION DE L'ASSOCIATION ACTIVE
          // On cherche quelle association appartient à l'utilisateur actuellement connecté
          final currentUser = Get.find<AuthController>().currentUser.value;
          Association? activeAssoc;
          if (currentUser != null && currentUser['id'] != null) {
            final myId = currentUser['id'] as int;
            activeAssoc = assocCtrl.associations.firstWhereOrNull((a) {
              // On vérifie si l'utilisateur est soit l'admin, soit un membre de l'association
              if (a.admin?.id == myId) return true;
              for (var m in (a.members ?? [])) {
                if (m is Map && m['id'] == myId) return true;
                if (m == myId) return true;
              }
              return false;
            });
          }
          // Si aucune asso trouvée, on prend la première par défaut
          activeAssoc ??= assocCtrl.associations.isNotEmpty ? assocCtrl.associations.first : null;

          // 🔹 FILTRAGE DES MEMBRES
          // On ne garde que les utilisateurs du serveur qui appartiennent vraiment à cette association
          final filtered = _applyFilters(controller.users, activeAssoc);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── EN-TÊTE ──────────────────────────────
              _buildHeader(context, controller, isMobile, activeAssoc),
              const SizedBox(height: 28),

              // ─── STATS CARDS ──────────────────────────
              _buildStatsCards(filtered, isMobile),
              const SizedBox(height: 24),

              // ─── RECHERCHE + FILTRES ──────────────────
              _buildSearchAndFilters(isMobile),
              const SizedBox(height: 24),

              // ─── LISTE MEMBRES ─────────────────────────
              filtered.isEmpty
                  ? _buildEmptyState()
                  : (isMobile
                      ? _buildMobileCards(filtered, controller)
                      : _buildDesktopGrid(filtered, controller, isMobile)),
            ],
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EN-TÊTE : Affiche le nom de l'association dynamique
  // ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, UsersController controller, bool isMobile, Association? activeAssoc) {
    final titleCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEMBRES',
          style: TextStyle(
            fontSize: isMobile ? 24 : 30,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Association : ${activeAssoc?.name ?? 'Chargement...'}', // Affiche le vrai nom au lieu de Test Association
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () => Get.dialog(const SendInvitationDialog()),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('INVITATION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 10),
        // Bouton rafraîchir pour forcer le rechargement depuis le serveur
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569), size: 20),
            padding: EdgeInsets.zero,
            onPressed: () => controller.loadUsers(),
            tooltip: 'Actualiser',
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleCol, const SizedBox(height: 16), actions],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Expanded(child: titleCol), actions],
    );
  }

  // ─────────────────────────────────────────────
  // STATS CARDS : Calculées sur la liste filtrée
  // ─────────────────────────────────────────────
  Widget _buildStatsCards(List<User> users, bool isMobile) {
    final total  = users.length;
    final admins = users.where((u) => u.roleType.contains('admin')).length;
    final members = total - admins;

    if (isMobile) {
      return Row(
        children: [
          Expanded(child: _statCard('TOTAL',   '$total',   null)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('ADMINS',  '$admins',  const Color(0xFF7C3AED))),
          const SizedBox(width: 12),
          Expanded(child: _statCard('MEMBRES', '$members', const Color(0xFF2563EB))),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _statCard('TOTAL',   '$total',   null)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('ADMINS',  '$admins',  const Color(0xFF7C3AED))),
        const SizedBox(width: 16),
        Expanded(child: _statCard('MEMBRES', '$members', const Color(0xFF2563EB))),
      ],
    );
  }

  Widget _statCard(String label, String count, Color? valueColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BARRE DE RECHERCHE + FILTRES TABS
  // ─────────────────────────────────────────────
  Widget _buildSearchAndFilters(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _searchField(),
          const SizedBox(height: 12),
          _filterTabs(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _searchField()),
        const SizedBox(width: 12),
        _filterTabs(),
      ],
    );
  }

  Widget _searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Rechercher par nom ou email...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          icon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _filterTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['TOUS', 'ADMINS', 'MEMBRES'].map((tab) {
          final isActive = _activeFilter == tab;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🧠 LE FILTRE INTELLIGENT
  // ─────────────────────────────────────────────
  List<User> _applyFilters(List<User> users, Association? activeAssoc) {
    // 1. On liste tous les IDs d'utilisateurs qui ont le droit de figurer sur cette page
    final validIds = <int>{};
    if (activeAssoc != null) {
      if (activeAssoc.admin?.id != null) validIds.add(activeAssoc.admin!.id!);
      for (var m in (activeAssoc.members ?? [])) {
        if (m is Map && m['id'] != null) validIds.add(m['id']);
        if (m is int) validIds.add(m);
      }
    }

    // 2. On filtre la liste globale 'users' (qui contient tout le serveur)
    var result = users.where((u) {
      // SI l'utilisateur n'est pas lié à l'association active => ON LE CACHE
      if (activeAssoc != null && u.id != null && !validIds.contains(u.id)) {
        return false;
      }
      
      // Filtre texte (recherche par nom ou email)
      final name  = (u.username ?? '').toLowerCase();
      final email = (u.email ?? '').toLowerCase();
      return name.contains(_searchText) || email.contains(_searchText);
    }).toList();

    // 3. Filtre par rôle (onglet 'ADMINS' ou 'MEMBRES')
    if (_activeFilter == 'ADMINS') {
      result = result.where((u) => u.roleType.contains('admin')).toList();
    } else if (_activeFilter == 'MEMBRES') {
      result = result.where((u) => !u.roleType.contains('admin')).toList();
    }

    return result;
  }

  // ─────────────────────────────────────────────
  // GRILLE DESKTOP / LISTE MOBILE
  // ─────────────────────────────────────────────
  Widget _buildDesktopGrid(List<User> users, UsersController controller, bool isMobile) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 900 ? 2 : 1;
      return _buildGrid(users, controller, columns);
    });
  }

  Widget _buildMobileCards(List<User> users, UsersController controller) {
    return _buildGrid(users, controller, 1);
  }

  Widget _buildGrid(List<User> users, UsersController controller, int columns) {
    if (columns == 1) {
      return Column(
        children: users.map((u) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _memberCard(u, controller),
        )).toList(),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < users.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: _memberCard(users[i], controller)),
          const SizedBox(width: 16),
          if (i + 1 < users.length)
            Expanded(child: _memberCard(users[i + 1], controller))
          else
            const Expanded(child: SizedBox()),
        ],
      ));
      if (i + 2 < users.length) rows.add(const SizedBox(height: 16));
    }
    return Column(children: rows);
  }

  // ─────────────────────────────────────────────
  // CARTE MEMBRE : Individuelle pour chaque utilisateur
  // ─────────────────────────────────────────────
  Widget _memberCard(User user, UsersController controller) {
    final isAdmin = user.roleType.contains('admin');
    final initial = (user.username ?? '?')[0].toUpperCase();
    final avatarColor = isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF2563EB);

    // Formater la date de création : de yyyy-mm-dd... vers dd/mm/yyyy
    String formattedDate = 'N/A';
    if (user.createdAt != null && user.createdAt!.length >= 10) {
      final parts = user.createdAt!.substring(0, 10).split('-');
      if (parts.length == 3) {
        formattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }
    final joinDate = 'Depuis $formattedDate';

    // 👤 VÉRIFICATION "C'EST MOI" : Compare l'ID du membre avec l'ID connecté
    final currentUser = Get.find<AuthController>().currentUser.value;
    final isMe = currentUser != null && currentUser['id'] == user.id;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Ligne 1 : Avatar + Info + Badge rôle ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar (Icône bouclier pour admin, initiale pour membre)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isAdmin
                      ? const Icon(Icons.shield_rounded, color: Colors.white, size: 22)
                      : Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              // Nom + Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.username ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 🔹 Affiche le badge "VOUS" si c'est la session actuelle
                        if (isMe) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Text('VOUS', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.email ?? '-',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge ROLE (ADMIN ou MEMBRE)
              _roleBadge(isAdmin),
            ],
          ),
          const SizedBox(height: 14),

          // ─── Ligne 2 : Statut Actif + Date dynamique ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Actif', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              Text(joinDate, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),

          // ─── Bouton RETIRER (uniquement pour les membres simples, pas pour l'admin) ───
          if (!isAdmin) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(user, controller),
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                label: const Text(
                  'RETIRER',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: const Color(0xFFFFF1F2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BADGES colorés (Violet pour Admin, Bleu pour Membre)
  // ─────────────────────────────────────────────
  Widget _roleBadge(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFF3E8FF) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAdmin ? const Color(0xFFD8B4FE) : const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.shield_rounded : Icons.person_rounded,
            size: 12,
            color: isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
          ),
          const SizedBox(width: 4),
          Text(
            isAdmin ? 'ADMIN' : 'MEMBRE',
            style: TextStyle(
              color: isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ÉTAT VIDE : Si aucun membre n'est trouvé après filtrage
  // ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
            child: const Icon(Icons.group_add_rounded, color: Color(0xFF2563EB), size: 32),
          ),
          const SizedBox(height: 20),
          const Text('Aucun membre trouvé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text('Invitez des membres pour commencer à gérer votre association.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SUPPRESSION : Dialogue de confirmation
  // ─────────────────────────────────────────────
  void _confirmDelete(User user, UsersController controller) {
    if (user.id == null) return;

    Get.defaultDialog(
      title: 'Retirer le membre',
      middleText: 'Voulez-vous vraiment retirer "${user.username ?? ''}" de votre association ?',
      textConfirm: 'Retirer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFEF4444),
      onConfirm: () {
        controller.deleteUser(user.id!);
        Get.back();
      },
    );
  }
}
