// ===============================================
// Dialogue de Consultation d'un Devoir
// Affiche les détails en lecture seule
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/assignment.dart';

class ViewAssignmentDialog extends StatelessWidget {
  final Assignment assignment;
  const ViewAssignmentDialog({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double dialogWidth = isMobile ? MediaQuery.of(context).size.width * 0.95 : 550;

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

                    // Pièce jointe
                    if (assignment.attachment != null) ...[
                      _buildSectionTitle('Pièce jointe'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, color: Color(0xFF0284C7), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                assignment.attachment?['name'] ?? 'Fichier joint',
                                style: const TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _InfoItem(this.icon, this.label, this.value, this.color);
}
