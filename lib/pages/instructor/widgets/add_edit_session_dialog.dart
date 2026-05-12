// ===============================================
// Dialogue d'Ajout ou de Modification de Session
// Design Responsive
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/training_session.dart';
import '../../../data/models/course.dart';
import '../../../controllers/sessions_controller.dart';
import '../../../controllers/courses_controller.dart';
import '../../../controllers/spaces_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../data/models/space.dart';
import '../../../widgets/shared/booking_dialog.dart';

class AddEditSessionDialog extends StatefulWidget {
  final TrainingSession? session;
  const AddEditSessionDialog({super.key, this.session});

  @override
  State<AddEditSessionDialog> createState() => _AddEditSessionDialogState();
}

class _AddEditSessionDialogState extends State<AddEditSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final SessionsController controller = Get.find<SessionsController>();
  final CoursesController coursesController = Get.put(CoursesController());
  final SpacesController spacesController = Get.put(SpacesController());
  final BookingController bookingController = Get.put(BookingController());

  // Champs texte
  late TextEditingController _titleController;
  late TextEditingController _maxParticipantsController;
  late TextEditingController _meetingLinkController;
  late TextEditingController _notesController;

  // Sélections
  Course? _selectedCourse;
  SessionType _selectedType = SessionType.enLigne;
  DateTime? _startDate;
  DateTime? _endDate;
  Space? _selectedSpace;
  bool _isSpaceReserved = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.session?.title ?? '');
    _maxParticipantsController = TextEditingController(text: widget.session?.maxParticipants.toString() ?? '10');
    _meetingLinkController = TextEditingController(text: widget.session?.meetingLink ?? '');
    _notesController = TextEditingController(text: widget.session?.notes ?? '');
    
    _startDate = widget.session?.startDate;
    _endDate = widget.session?.endDate;
    _selectedType = widget.session?.type ?? SessionType.enLigne;

    // Tenter de trouver le cours correspondant si on est en édition
    if (widget.session?.courseName != null && widget.session?.courseName != '-') {
      _selectedCourse = coursesController.courses.firstWhereOrNull(
        (c) => c.title == widget.session!.courseName
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _maxParticipantsController.dispose();
    _meetingLinkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Pickers
  Future<void> _pickDateTime(bool isStart) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(minutes: 1)), // Permet aujourd'hui
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
             colorScheme: const ColorScheme.light(
               primary: Color(0xFF007AFF),
             ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    // ignore: use_build_context_synchronously
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime((isStart ? _startDate : _endDate) ?? DateTime.now()),
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
             colorScheme: const ColorScheme.light(
               primary: Color(0xFF007AFF),
             ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    DateTime newDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // Validation : pas dans le passé
    if (newDate.isBefore(DateTime.now().subtract(const Duration(minutes: 2)))) {
      Get.snackbar(
        "Date invalide", 
        "Vous ne pouvez pas choisir une date ou une heure passée.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = newDate;
        // Si la date de fin est avant la nouvelle date de début, on l'ajuste
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
           _endDate = _startDate!.add(const Duration(hours: 1));
        }
      } else {
        // Pour la date de fin, elle doit être après la date de début
        if (_startDate != null && newDate.isBefore(_startDate!)) {
           Get.snackbar("Date invalide", "La date de fin doit être après la date de début.");
           return;
        }
        _endDate = newDate;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Adapter la largeur selon l'écran
    final isMobile = context.width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 600,
        constraints: BoxConstraints(
          maxHeight: context.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             // En-tête fixe
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session == null ? 'Nouvelle Session' : 'Modifier la Session',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Planifiez votre formation',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(), 
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Remove extra padding
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      _buildLabel('Titre de la session'),
                      _buildTextField(_titleController, 'Ex: Introduction à Flutter...', isTitle: true),
                      const SizedBox(height: 20),
              
                      // Cours associé
                      _buildLabel('Cours associé (Requis)'),
                      Obx(() => _buildDropdown<Course?>(
                        _selectedCourse,
                        coursesController.courses.map((c) {
                          return DropdownMenuItem<Course?>(value: c, child: Text(c.title, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        (val) => setState(() => _selectedCourse = val),
                        hint: 'Sélectionner un cours',
                      )),
                      // Type de session
                      _buildLabel('Type de session'),
                      _buildTypeDropdown(),
                      const SizedBox(height: 20),
                      
                      // Max Participants (Uniquement en ligne)
                      if (_selectedType == SessionType.enLigne) ...[
                        _buildLabel('Nombre max. de participants'),
                        _buildTextField(_maxParticipantsController, '10', isNumeric: true),
                        const SizedBox(height: 20),
                      ] else ...[
                        // En présentiel, on pourrait éventuellement afficher Max participants si besoin, 
                        // mais l'utilisateur a demandé de le cacher car géré par la salle.
                      ],
              
                      // Dates Début et Fin (Masquées en présentiel car gérées par le formulaire de réservation)
                      if (_selectedType == SessionType.enLigne) ...[
                        if (isMobile) ...[
                          _buildDateTimePicker('Date de début', _startDate, () => _pickDateTime(true)),
                          const SizedBox(height: 16),
                          _buildDateTimePicker('Date de fin', _endDate, () => _pickDateTime(false)),
                        ] else 
                          Row(
                            children: [
                              Expanded(child: _buildDateTimePicker('Début', _startDate, () => _pickDateTime(true))),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDateTimePicker('Fin', _endDate, () => _pickDateTime(false))),
                            ],
                          ),
                        const SizedBox(height: 20),
                      ],
              
                      // --- CONFIGURATION DU LIEU (DYNAMIQUE) ---
                      if (_selectedType == SessionType.enLigne) ...[
                        // Lien de réunion (OBLIGATOIRE en ligne)
                        _buildLabel('Lien de réunion (Obligatoire)'),
                        _buildTextField(_meetingLinkController, 'https://zoom.us/j/123...', validator: (val) {
                          if (val == null || val.isEmpty) return 'Le lien est obligatoire pour une session en ligne';
                          return null;
                        }),
                      ] else ...[
                        // Choix de l'espace (OBLIGATOIRE en présentiel ou hybride)
                        _buildLabel('Espace de formation (Requis)'),
                        Obx(() => _buildDropdown<Space?>(
                          _selectedSpace,
                          spacesController.spaces.where((s) => s.status == SpaceStatus.disponible).map((s) {
                            return DropdownMenuItem<Space?>(
                              value: s, 
                              child: Text("${s.name} (Capacité: ${s.capacity})", overflow: TextOverflow.ellipsis)
                            );
                          }).toList(),
                          (val) {
                            setState(() {
                              _selectedSpace = val;
                              if (val != null) {
                                // On propose par défaut la capacité max de la salle
                                _maxParticipantsController.text = val.capacity.toString();
                                _openReservationForm(val);
                              }
                            });
                          },
                          hint: 'Choisir la salle',
                        )),
                        if (_isSpaceReserved) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text('Espace réservé et prêt', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),
              
                      // Notes
                      _buildLabel('Notes / Instructions'),
                      _buildTextField(_notesController, 'Instructions pour les participants...', maxLines: 3),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton Action (fixe en bas)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  widget.session == null ? 'Planifier la session' : 'Enregistrer les modifications',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return _buildDropdown<SessionType>(
      _selectedType,
      SessionType.values.map((t) {
        String label = t == SessionType.presentiel ? 'Présentiel' : (t == SessionType.hybride ? 'Hybride' : 'En ligne');
        IconData icon = t == SessionType.presentiel ? Icons.location_on : (t == SessionType.hybride ? Icons.domain_verification : Icons.videocam);
        return DropdownMenuItem(
          value: t, 
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        );
      }).toList(),
      (val) => setState(() => _selectedType = val!),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, bool isNumeric = false, bool isTitle = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF007AFF))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) {
        if (validator != null) return validator(val);
        if (val == null || val.isEmpty) return 'Champ requis';
        if (isTitle && RegExp(r'[0-9]').hasMatch(val)) {
          return 'Le titre ne doit pas contenir de chiffres';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown<T>(T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged, {String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint != null ? Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 14)) : null,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items,
          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(String label, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value != null ? DateFormat('dd/MM/yyyy HH:mm', 'fr').format(value) : 'Choisir une date',
                    style: TextStyle(color: value != null ? const Color(0xFF1E293B) : Colors.grey[400], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
      if (_formKey.currentState!.validate()) {
        if (_selectedCourse == null) {
          Get.snackbar('Cours manquant', 'Veuillez sélectionner un cours associé', 
            backgroundColor: Colors.orange, colorText: Colors.white);
          return;
        }

        // --- VALIDATION DES DATES ---
        // En présentiel, si on vient de réserver, les dates sont dans le BookingController
        if (_selectedType == SessionType.enLigne) {
          if (_startDate == null || _endDate == null) {
            Get.snackbar('Date manquante', 'Veuillez sélectionner une date de début et de fin', 
              backgroundColor: Colors.orange, colorText: Colors.white);
            return;
          }
        } else {
          // En présentiel, on force la récupération des dates depuis le controller de réservation
          _startDate = bookingController.startDateTime.value;
          _endDate = bookingController.endDateTime.value;
          
          if (_startDate == null || _endDate == null) {
            Get.snackbar('Date manquante', 'Veuillez d\'abord réserver un espace pour définir l\'horaire.', 
              backgroundColor: Colors.orange, colorText: Colors.white);
            return;
          }
        }

        // --- VALIDATIONS SPÉCIFIQUES AU TYPE ---
        if (_selectedType == SessionType.enLigne && _meetingLinkController.text.isEmpty) {
          Get.snackbar('Lien manquant', 'Le lien de réunion est obligatoire pour une session en ligne.', 
            backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }

        if (_selectedType != SessionType.enLigne && _selectedSpace == null) {
          Get.snackbar('Espace requis', 'Veuillez choisir une salle pour une session en présentiel.', 
            backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }

      if (_endDate!.isBefore(_startDate!)) {
         Get.snackbar('Erreur de date', 'La date de fin doit être après la date de début', 
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
         return;
      }

      // ── VÉRIFICATION DE CHEVAUCHEMENT (Moteur intelligent) ──
      final auth = Get.find<AuthController>();
      final instructorId = int.tryParse(auth.currentUser.value?['id']?.toString() ?? '');
      
      if (instructorId != null) {
        final hasOverlap = controller.isSessionOverlapping(
          instructorId: instructorId,
          start: _startDate!,
          end: _endDate!,
          isAssociation: false,
          excludeDocumentId: widget.session?.documentId,
        );

        if (hasOverlap) {
          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_busy_rounded, color: Colors.red, size: 64),
                    const SizedBox(height: 20),
                    const Text(
                      "Conflit d'horaire",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "existe deja une formation dans ce temps pour cet enseignant",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                        child: const Text("Modifier l'horaire", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          return; // Blocage
        }
      }

      // ── VÉRIFICATION DE L'ESPACE (Requis par l'enseignant) ──
      if (_selectedSpace == null) {
        Get.snackbar('Espace requis', 'Un enseignant doit obligatoirement réserver un espace pour sa session.', 
          backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return;
      }

      // --- RÉCUPÉRATION DU NOMBRE DE PARTICIPANTS (Priorité au calendrier pour le présentiel) ---
      int participants = int.tryParse(_maxParticipantsController.text) ?? 10;
      if (_selectedType != SessionType.enLigne) {
        participants = bookingController.numberOfPeople.value;
      }

      // Injecter le nom de la salle dans les notes pour les sessions présentielles
      String? sessionNotes = _notesController.text.isEmpty ? null : _notesController.text;
      if (_selectedType != SessionType.enLigne && _selectedSpace != null) {
        final spaceName = _selectedSpace!.name;
        sessionNotes = "📍 Espace: $spaceName\n${sessionNotes ?? ''}".trim();
      }

      final session = TrainingSession(
        id: widget.session?.id ?? '',
        documentId: widget.session?.documentId,
        title: _titleController.text,
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        maxParticipants: participants,
        meetingLink: _meetingLinkController.text.isEmpty ? null : _meetingLinkController.text,
        notes: sessionNotes,
        status: SessionStatus.publie, 
      );

      if (widget.session != null) {
        controller.updateSession(session, _selectedCourse?.id);
      } else {
        // --- LOGIQUE DE CRÉATION ---
        if (_selectedType == SessionType.enLigne) {
          // Session en ligne -> Pas de réservation d'espace physique
          controller.addSession(session, _selectedCourse?.id);
        } else {
          // Session présentielle -> Vérifier si on doit créer la réservation ou si c'est déjà fait
          if (_isSpaceReserved) {
            // Déjà réservé via le dialogue de vérification -> On crée juste la session
            controller.addSession(session, _selectedCourse?.id);
          } else {
            // Pas encore réservé -> On crée les deux en même temps (Fallback)
            double amount = 0;
            if (_startDate != null && _endDate != null && _selectedSpace != null) {
              final hours = _endDate!.difference(_startDate!).inMinutes / 60.0;
              amount = hours * _selectedSpace!.hourlyPrice;
            }

            controller.addSessionWithReservation(
              session: session, 
              courseId: _selectedCourse?.id,
              spaceId: _selectedSpace!.documentId ?? _selectedSpace!.id,
              totalAmount: amount,
            );
          }
        }
      }
      
      // Get.back(); // Retiré car déjà géré dans le contrôleur
    }
  }

  // --- MÉTHODE POUR OUVRIR LE FORMULAIRE DE RÉSERVATION (COMME DANS LE PLAN 2D) ---
  Future<void> _openReservationForm(Space space) async {
    final result = await Get.dialog<bool>(
      BookingDialog(
        space: space, 
        isMobile: MediaQuery.of(context).size.width < 600,
        showPayment: false,
        initialParticipants: int.tryParse(_maxParticipantsController.text) ?? 10,
      ),
    );

    if (result == true) {
      setState(() {
        _isSpaceReserved = true;
        // RÉCUPÉRER LES DATES ET LE NOMBRE DE PERSONNES CHOISIS DANS LE CALENDRIER
        _startDate = bookingController.startDateTime.value;
        _endDate = bookingController.endDateTime.value;
        _maxParticipantsController.text = bookingController.numberOfPeople.value.toString();
      });
      _submit();
    }
  }
}
