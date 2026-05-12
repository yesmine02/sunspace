// ===============================================
// Dialogue de Consultation d'un Devoir
// Affiche les détails en lecture seule
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/assignment.dart';
import '../../../data/models/submission.dart';
import '../../../controllers/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewAssignmentDialog extends StatelessWidget {
  final Assignment assignment;
  const ViewAssignmentDialog({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double dialogWidth = isMobile ? MediaQuery.of(context).size.width * 0.95 : 550;
    final AuthController authController = Get.find<AuthController>();
    final bool canSeeSubmissions = authController.isInstructor || authController.isAdmin;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment, color: Color(0xFF007AFF), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assignment.title,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Infos principales en grille
                    _buildInfoGrid(isMobile),
                    const SizedBox(height: 20),

                    // Description / Instructions
                    _buildSectionTitle('Instructions'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        assignment.description.isNotEmpty ? assignment.description : 'Aucune instruction.',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Soumissions (Design Capture)
                    if (canSeeSubmissions) ...[
                      const SizedBox(height: 32),
                      _buildSectionTitle('Soumissions des étudiants'),
                      const SizedBox(height: 16),
                      _buildSubmissionsList(isMobile),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton fermer
            SizedBox(
              width: isMobile ? double.infinity : null,
              child: TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: const Color(0xFFF1F5F9),
                ),
                child: const Text('Fermer', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(bool isMobile) {
    final items = [
      _InfoItem(Icons.school, 'Cours', assignment.courseName ?? '-', const Color(0xFF7C3AED)),
      _InfoItem(Icons.calendar_today, 'Échéance', _formatDueDate(), const Color(0xFFEA580C)),
      _InfoItem(Icons.star, 'Points max', '${assignment.maxPoints.toInt()}', const Color(0xFF2563EB)),
      _InfoItem(Icons.check_circle_outline, 'Note de passage', '${assignment.passingScore.toInt()}', const Color(0xFF059669)),
      _InfoItem(
        Icons.schedule,
        'Retard autorisé',
        assignment.allowLateSubmission ? 'Oui' : 'Non',
        assignment.allowLateSubmission ? const Color(0xFF059669) : const Color(0xFFDC2626),
      ),
    ];

    if (isMobile) {
      return Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildInfoRow(item),
        )).toList(),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) => SizedBox(
        width: 250,
        child: _buildInfoRow(item),
      )).toList(),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 16, color: item.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(item.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
    );
  }

  String _formatDueDate() {
    if (assignment.dueDate == null) return '-';
    return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(assignment.dueDate!);
  }
//affiche les soumissions
  Widget _buildSubmissionsList(bool isMobile) {
    if (assignment.submissions == null || assignment.submissions!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text("Aucune soumission pour le moment.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        ),
      );
    }

    return Column(
      children: assignment.submissions!.map((subData) {
        final submission = Submission.fromJson(subData);
        return _buildSubmissionCard(submission, isMobile);
      }).toList(),
    );
  }

  Widget _buildSubmissionCard(Submission sub, bool isMobile) {
    final DateTime? displayDate = sub.submittedAt ?? sub.createdAt;
    final String dateStr = displayDate != null 
        ? DateFormat('dd/MM/yyyy HH:mm:ss').format(displayDate)
        : '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.studentName ?? 'etudiant',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Soumis le : $dateStr",
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: sub.attachmentUrl != null ? () => _openFile(sub.attachmentUrl) : null,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE0F2FE),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  "Ouvrir",
                  style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              sub.status,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) {
      Get.snackbar('Erreur', 'Lien invalide ou inexistant');
      return;
    }
    
    String fullUrl = url;
    if (!url.startsWith('http')) {
      // Si ça ne commence pas par http, c'est un lien relatif, on ajoute le serveur
      // On s'assure qu'il y a bien un seul slash entre le port et le lien
      String separator = url.startsWith('/') ? '' : '/';
      fullUrl = 'http://193.111.250.244:3046$separator$url';
    }

    // Affiche l'URL pour que vous puissiez me la copier si ça échoue encore
    Get.snackbar(
      'Ouverture...', 
      fullUrl,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );

    // Encodage de l'URL pour gérer les espaces ou caractères spéciaux
    final encodedUrl = Uri.encodeFull(fullUrl);
    final uri = Uri.parse(encodedUrl);

    try {
      // On tente directement l'ouverture car canLaunchUrl est capricieux sur Android
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print("❌ Erreur launchUrl: $e");
      Get.snackbar('Erreur', 'Impossible d\'ouvrir le lien : $e');
    }
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _InfoItem(this.icon, this.label, this.value, this.color);
}
