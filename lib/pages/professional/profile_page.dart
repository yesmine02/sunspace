// ============================================
// Page Mon Profil (Professionnel) - Redésignée
// ============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/notification_bell.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController authController = Get.find<AuthController>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _organizationController;
  late TextEditingController _bioController;
  late TextEditingController _specializationController;

  @override
  void initState() {
    super.initState();
    final user = authController.currentUser.value;
    _nameController = TextEditingController(text: user?['username'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');
    _organizationController = TextEditingController(text: user?['organization'] ?? '');
    _bioController = TextEditingController(text: user?['bio'] ?? '');
    _specializationController = TextEditingController(text: user?['specialization'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _bioController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final Map<String, dynamic> data = {
      'username': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'organization': _organizationController.text.trim(),
      'bio': _bioController.text.trim(),
      'specialization': _specializationController.text.trim(),
    };
    
    await authController.updateProfile(data);
  }

  void _showImageOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Photo de profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF007AFF)),
              title: const Text('Choisir une photo'),
              onTap: () {
                Get.back();
                _pickNewImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Supprimer la photo', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Get.back();
                await authController.removeProfilePicture();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickNewImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      await authController.uploadProfilePicture(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    final user = authController.currentUser.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Background color from image
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOP BAR (Search & Notifications)
            _buildTopBar(isMobile),

            Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. PROFILE BANNER CARD
                  _buildProfileBanner(user, isMobile),
                  const SizedBox(height: 32),

                  // 3. MAIN CONTENT (GRID)
                  isMobile 
                    ? Column(
                        children: [
                          _buildAboutCard(user),
                          const SizedBox(height: 24),
                          _buildDetailsCard(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: _buildAboutCard(user)),
                          const SizedBox(width: 32),
                          Expanded(flex: 2, child: _buildDetailsCard()),
                        ],
                      ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Rechercher...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Notifications
          const NotificationBell(iconColor: Color(0xFF1E293B)),
          const SizedBox(width: 20),
          // User Avatar
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, color: Color(0xFF64748B), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBanner(Map<String, dynamic>? user, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // Blue Header
            Container(height: 120, color: const Color(0xFF007AFF)),
            // Content
            Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 24 : 40, 0, isMobile ? 24 : 40, isMobile ? 24 : 40),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  isMobile 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 70), // Espace pour l'avatar qui dépasse
                        const Text(
                          "ESPACE PROFESSIONNEL",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF007AFF), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?['username'] ?? 'Utilisateur',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.verified, color: Color(0xFF007AFF), size: 18),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mail_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(user?['email'] ?? 'email@gmail.com', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveProfile, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Modifier le profil", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 140),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              "ESPACE PROFESSIONNEL",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF007AFF), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  user?['username'] ?? 'Utilisateur',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.verified, color: Color(0xFF007AFF), size: 24),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.mail_outline, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(user?['email'] ?? 'email@gmail.com', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: const Color(0xFF007AFF).withOpacity(0.4),
                        ),
                        child: const Text("Modifier le profil", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Avatar Overlap
                  Positioned(
                    top: -60,
                    left: isMobile ? null : 0,
                    right: isMobile ? 0 : null,
                    child: Center(
                      child: GestureDetector(
                        onTap: _showImageOptions, // Propose Modifier ou Supprimer la photo
                        child: Container(
                          width: isMobile ? 100 : 120,
                          height: isMobile ? 100 : 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
                            child: Stack(
                              children: [
                                // Affichage de l'image de l'utilisateur ou de l'icône par défaut
                                Obx(() {
                                  final user = authController.currentUser.value;
                                  
                                  // Le champ correct identifié via les logs est 'avatar'
                                  final avatar = user?['avatar'];
                                  String? imageUrl;
                                  
                                  if (avatar != null) {
                                    if (avatar is Map) {
                                      imageUrl = avatar['url'];
                                    } else if (avatar is List && avatar.isNotEmpty) {
                                      imageUrl = avatar[0]['url'];
                                    }
                                  } 
                                  // Fallback secondaire
                                  else {
                                    final fallback = user?['image'] ?? user?['photo'] ?? user?['images'];
                                    if (fallback is Map) imageUrl = fallback['url'];
                                    else if (fallback is List && fallback.isNotEmpty) imageUrl = fallback[0]['url'];
                                  }

                                  if (imageUrl != null) {
                                    // On ajoute un "cache-buster" (?v=...) pour forcer Flutter à retélécharger l'image si elle vient de changer
                                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                                    final fullUrl = imageUrl.startsWith('http') 
                                      ? "$imageUrl?v=$timestamp" 
                                      : "http://193.111.250.244:3046$imageUrl?v=$timestamp";
                                    
                                    return Image.network(
                                      fullUrl,
                                      key: ValueKey(timestamp), // Force le widget à se reconstruire
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                          child: Icon(Icons.person, size: isMobile ? 50 : 60, color: const Color(0xFFE2E8F0))),
                                    );
                                  }

                                  return Center(
                                    child: Icon(Icons.person_outline_rounded, size: isMobile ? 50 : 60, color: const Color(0xFFE2E8F0)),
                                  );
                                }),

                                // Overlay "Caméra"
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Color(0xFF007AFF), shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                  ),
                                ),

                                // Indicateur de chargement si l'upload est en cours
                                Obx(() => authController.isLoading.value 
                                  ? Container(
                                      color: Colors.black26, 
                                      child: const Center(child: CircularProgressIndicator(color: Colors.white)))
                                  : const SizedBox.shrink()
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("À propos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 32),
          _buildAboutTile(Icons.workspace_premium_outlined, "SPÉCIALITÉ", user?['specialization'] ?? "Non renseigné", const Color(0xFFE0F2FE), const Color(0xFF007AFF)),
          const SizedBox(height: 24),
          _buildAboutTile(Icons.business_outlined, "ORGANISATION", user?['organization'] ?? "Indépendant", const Color(0xFFF1F5F9), const Color(0xFF64748B)),
          const SizedBox(height: 24),
          _buildAboutTile(
            Icons.calendar_today_outlined, 
            "MEMBRE DEPUIS", 
            user?['createdAt'] != null 
                ? DateFormat('MMMM yyyy', 'fr_FR').format(DateTime.parse(user!['createdAt']).toLocal())
                : "février 2026", 
            const Color(0xFFFEF3C7), 
            const Color(0xFFD97706)
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text("Status  Profil Professionnel", style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 16),
          const Text(
            "Votre profil est visible par les organisateurs d'espaces et les instructeurs de formations.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTile(IconData icon, String label, String value, Color bgColor, Color iconColor) {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Informations détaillées", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text("Mettez à jour vos informations pour une meilleure expérience.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: _buildInputField("NUMÉRO DE TÉLÉPHONE", _phoneController, Icons.phone_outlined, placeholder: "+216 -- --- ---")),
              const SizedBox(width: 24),
              Expanded(child: _buildInputField("ENTREPRISE / ORGANISATION", _organizationController, Icons.business_outlined, placeholder: "Nom de votre entreprise")),
            ],
          ),
          const SizedBox(height: 32),
          _buildInputField("SPÉCIALISATION PROFESSIONNELLE", _specializationController, Icons.workspace_premium_outlined, placeholder: "Ex: Consultant RH, Développeur Senior, Freelance..."),
          const SizedBox(height: 32),
          _buildInputField("BIOGRAPHIE / RÉSUMÉ", _bioController, null, placeholder: "Décrivez brièvement votre parcours et vos expertises...", maxLines: 5),
          
          const SizedBox(height: 48),
          Align(
            alignment: Alignment.centerRight,
            child: Obx(() => ElevatedButton(
              onPressed: authController.isLoading.value ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: const Color(0xFF007AFF).withOpacity(0.3),
              ),
              child: authController.isLoading.value 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData? icon, {String? placeholder, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.8)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF94A3B8), size: 20) : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC), // Matching mockup's subtle grey
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}
