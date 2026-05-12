// pages/assignments/widgets/submit_work_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../controllers/assignments_controller.dart';
import '../../../data/models/assignment.dart';

class SubmitWorkDialog extends StatefulWidget {
  final dynamic assignment; // Peut être un Assignment ou un objet JSON compatible

  const SubmitWorkDialog({super.key, required this.assignment});

  @override
  State<SubmitWorkDialog> createState() => _SubmitWorkDialogState();
}

class _SubmitWorkDialogState extends State<SubmitWorkDialog> {
  final TextEditingController _commentController = TextEditingController();
  final AssignmentsController _controller = Get.find<AssignmentsController>();
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _handleSubmit() async {
    // 🕑 Vérification de la date d'échéance
    final dueDate = widget.assignment.dueDate as DateTime?;
    final bool allowLate = widget.assignment.allowLateSubmission as bool? ?? false;
    if (dueDate != null && DateTime.now().isAfter(dueDate) && !allowLate) {
      Get.snackbar(
        'Soumission impossible',
        'La date d\'\u00e9chéance est dépassée. ',
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.lock_clock, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Vérification du fichier obligatoire
    if (_selectedFile == null) {
      Get.snackbar(
        'Action requise', 
        'Veuillez joindre votre travail (fichier) avant de soumettre.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    final assignmentId = widget.assignment.id.toString();
    final success = await _controller.submitAssignment(
      assignmentId,
      content: _commentController.text,
      file: _selectedFile,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      Get.back(); // Ferme le formulaire d'envoi
      
      // Affiche le message de succès après la fermeture
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 60),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Travail Envoyé !",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Votre devoir a été soumis avec succès. Votre enseignant pourra bientôt le consulter et le noter.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 15),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Génial !", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Vérifie si la soumission est bloquée (date dépassée + pas de retard autorisé)
  bool get _isBlocked {
    final dueDate = widget.assignment.dueDate as DateTime?;
    final bool allowLate = widget.assignment.allowLateSubmission as bool? ?? false;
    return dueDate != null && DateTime.now().isAfter(dueDate) && !allowLate;
  }

  // Vérifie si on est simplement en retard (qu'on soit bloqué ou non)
  bool get _isLate {
    final dueDate = widget.assignment.dueDate as DateTime?;
    return dueDate != null && DateTime.now().isAfter(dueDate);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.send_rounded, color: Color(0xFF007AFF), size: 24),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      "Soumettre mon travail",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
  
              // 🚨 Bandeau rouge si soumission impossible
              if (_isBlocked)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_clock, color: Color(0xFFDC2626), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'La date d\'\u00e9chéance est dépassée. Soumission impossible.',
                          style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_isLate)
                // 🟠 Bandeau orange si en retard mais autorisé
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.history_rounded, color: Color(0xFFEA580C), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Note : Vous êtes en retard, mais l\'enseignant autorise encore la soumission.',
                          style: TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Comment Field
              const Text(
                "Commentaire (optionnel)",
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), fontSize: 15),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Écrivez ici vos remarques sur le travail...",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
  
              // File Attachment
              const Text(
                "Pièce jointe",
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), fontSize: 15),
              ),
              const SizedBox(height: 12),
              if (_selectedFile == null)
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                    ),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.cloud_upload_outlined, size: 32, color: Color(0xFF94A3B8)),
                          SizedBox(height: 8),
                          Text("Cliquez pour choisir un fichier", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF007AFF)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: _removeFile,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),
  
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Annuler", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      // Bouton désactivé si soumission bloquée ou en cours
                      onPressed: (_isSubmitting || _isBlocked) ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBlocked ? const Color(0xFF94A3B8) : const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _isBlocked ? 'Fermé' : 'Soumettre',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
