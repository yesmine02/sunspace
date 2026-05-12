// ===============================================
// Dialogue Ajout/Modification Session – Association
// Sans champ "Cours associé", avec Récurrence
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/training_session.dart';
import '../../../controllers/sessions_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/spaces_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../data/models/space.dart';
import '../../../widgets/shared/booking_dialog.dart';

// Options de récurrence
enum RecurrenceType { aucune, quotidienne, hebdomadaire, mensuelle }

extension RecurrenceLabel on RecurrenceType {
  String get label {
    switch (this) {
      case RecurrenceType.aucune: return 'Aucune';
      case RecurrenceType.quotidienne: return 'Quotidienne';
      case RecurrenceType.hebdomadaire: return 'Hebdomadaire';
      case RecurrenceType.mensuelle: return 'Mensuelle';
    }
  }
}

class AddAssocSessionDialog extends StatefulWidget {
  final TrainingSession? session;
  const AddAssocSessionDialog({super.key, this.session});

  @override
  State<AddAssocSessionDialog> createState() => _AddAssocSessionDialogState();
}

class _AddAssocSessionDialogState extends State<AddAssocSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final SessionsController _controller = Get.find<SessionsController>();

  late TextEditingController _titleController;
  late TextEditingController _maxParticipantsController;
  late TextEditingController _meetingLinkController;
  late TextEditingController _notesController;

  SessionType _selectedType = SessionType.enLigne;
  DateTime? _startDate;
  DateTime? _endDate;
  RecurrenceType _recurrence = RecurrenceType.aucune;
  DateTime? _recurrenceEndDate;

  // Gestion de l'espace
  final SpacesController spacesController = Get.put(SpacesController());
  final BookingController bookingController = Get.put(BookingController());
  Space? _selectedSpace;
  bool _isSpaceReserved = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.session?.title ?? '');
    _maxParticipantsController = TextEditingController(
        text: widget.session?.maxParticipants.toString() ?? '10');
    _meetingLinkController =
        TextEditingController(text: widget.session?.meetingLink ?? '');
    _notesController = TextEditingController(text: widget.session?.notes ?? '');
    _startDate = widget.session?.startDate;
    _endDate = widget.session?.endDate;
    _selectedType = widget.session?.type ?? SessionType.enLigne;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _maxParticipantsController.dispose();
    _meetingLinkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── Pickers ────────────────────────────────────────────
  Future<void> _pickDateTime(bool isStart) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(minutes: 1)),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // Validation : pas dans le passé
    if (dt.isBefore(DateTime.now().subtract(const Duration(minutes: 2)))) {
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
        _startDate = dt;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate!.add(const Duration(hours: 1));
        }
      } else {
        if (_startDate != null && dt.isBefore(_startDate!)) {
          Get.snackbar("Date invalide", "La date de fin doit être après la date de début.");
          return;
        }
        _endDate = dt;
      }
    });
  }

  Future<void> _pickRecurrenceEndDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _recurrenceEndDate = date);
  }

  // ─── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isMobile = context.width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 620,
        constraints: BoxConstraints(maxHeight: context.height * 0.92),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── En-tête ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session == null
                            ? 'Nouvelle Session / Parcours'
                            : 'Modifier la Session',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Planifiez une nouvelle session de formation pour vos membres.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
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

            // ── Formulaire scrollable ──
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      _label('Titre de la session'),
                      _textField(_titleController, 'Ex: Masterclass Q&A React',
                          validator: (v) => v!.isEmpty ? 'Requis' : null),
                      const SizedBox(height: 20),

                      // --- TYPE DE SESSION ---
                      _label('Type de session'),
                      _typeDropdown(),
                      const SizedBox(height: 20),

                      // --- CONFIGURATION DYNAMIQUE ---
                      if (_selectedType == SessionType.enLigne) ...[
                        // Mode En ligne : Participants + Dates + Lien
                        _label('Nombre max. de participants'),
                        _textField(_maxParticipantsController, '20', isNumeric: true),
                        const SizedBox(height: 20),

                        if (isMobile) ...[
                          _dateTimePicker('Début', _startDate, () => _pickDateTime(true)),
                          const SizedBox(height: 16),
                          _dateTimePicker('Fin', _endDate, () => _pickDateTime(false)),
                        ] else
                          Row(
                            children: [
                              Expanded(child: _dateTimePicker('Début', _startDate, () => _pickDateTime(true))),
                              const SizedBox(width: 16),
                              Expanded(child: _dateTimePicker('Fin', _endDate, () => _pickDateTime(false))),
                            ],
                          ),
                        const SizedBox(height: 20),

                        _label('Lien de réunion (Zoom, Google Meet...)'),
                        _textField(_meetingLinkController, 'https://zoom.us/...', prefixIcon: Icons.link_rounded),
                      ] else ...[
                        // Mode Présentiel : Choix de l'espace (les dates seront dans le calendrier)
                        _label('Espace de formation (Requis)'),
                        Obx(() => _dropdown<Space?>(
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
                                _maxParticipantsController.text = val.capacity.toString();
                                _openReservationForm(val);
                              }
                            });
                          },
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

                      // Récurrence + Fin de récurrence
                      if (isMobile) ...[
                        _label('Récurrence'),
                        _recurrenceDropdown(),
                        if (_recurrence != RecurrenceType.aucune) ...[
                          const SizedBox(height: 16),
                          _dateOnlyPicker('Fin de récurrence', _recurrenceEndDate, _pickRecurrenceEndDate),
                        ],
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _label('Récurrence'),
                                _recurrenceDropdown(),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _label('Fin de récurrence'),
                                _dateOnlyPicker(null, _recurrenceEndDate, _pickRecurrenceEndDate,
                                    disabled: _recurrence == RecurrenceType.aucune),
                              ]),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),

                      // Notes
                      _label('Notes & Objectifs'),
                      _textField(_notesController, 'Notes pour les participants...', maxLines: 3),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Bouton ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
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

  // ─── Widgets helpers ────────────────────────────────────
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
      );

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    bool isNumeric = false,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: Colors.grey[400]) : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2563EB))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _dropdown<T>(T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
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
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items,
          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _typeDropdown() => _dropdown<SessionType>(
        _selectedType,
        SessionType.values.map((t) {
          final label = t == SessionType.presentiel
              ? 'Présentiel'
              : t == SessionType.hybride
                  ? 'Hybride'
                  : 'En ligne';
          final icon = t == SessionType.presentiel
              ? Icons.location_on
              : t == SessionType.hybride
                  ? Icons.domain_verification
                  : Icons.videocam;
          return DropdownMenuItem(
            value: t,
            child: Row(children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(label),
            ]),
          );
        }).toList(),
        (val) => setState(() => _selectedType = val!),
      );

  Widget _recurrenceDropdown() => _dropdown<RecurrenceType>(
        _recurrence,
        RecurrenceType.values
            .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
            .toList(),
        (val) => setState(() {
          _recurrence = val!;
          if (_recurrence == RecurrenceType.aucune) _recurrenceEndDate = null;
        }),
      );

  Widget _dateTimePicker(String label, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
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
                    value != null
                        ? DateFormat('dd/MM/yyyy HH:mm', 'fr').format(value)
                        : 'jj/mm/aaaa --:--',
                    style: TextStyle(
                        color: value != null ? const Color(0xFF1E293B) : Colors.grey[400],
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateOnlyPicker(String? label, DateTime? value, VoidCallback onTap,
      {bool disabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) _label(label),
        InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: disabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormat('dd/MM/yyyy', 'fr').format(value)
                        : 'jj/mm/aaaa',
                    style: TextStyle(
                        color: disabled
                            ? Colors.grey[400]
                            : value != null
                                ? const Color(0xFF1E293B)
                                : Colors.grey[400],
                        fontSize: 14),
                  ),
                ),
                Icon(Icons.calendar_today_rounded,
                    size: 16,
                    color: disabled ? Colors.grey[300] : const Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Soumission ─────────────────────────────────────────
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // --- VALIDATION DES DATES ---
    if (_selectedType == SessionType.enLigne) {
      if (_startDate == null || _endDate == null) {
        Get.snackbar('Date manquante', 'Veuillez sélectionner une date de début et de fin',
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
    } else {
      // En présentiel, on force la récupération depuis le calendrier
      _startDate = bookingController.startDateTime.value;
      _endDate = bookingController.endDateTime.value;
      if (_startDate == null || _endDate == null) {
        Get.snackbar('Date manquante', 'Veuillez d\'abord réserver un espace.',
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
    }

    if (_endDate!.isBefore(_startDate!)) {
      Get.snackbar('Erreur de date', 'La date de fin doit être après la date de début',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16));
      return;
    }

    // ── VÉRIFICATION DE CHEVAUCHEMENT (Conflit d'horaire) ──
    final auth = Get.find<AuthController>();
    final userId = int.tryParse(auth.currentUser.value?['id']?.toString() ?? '');
    
    if (userId != null) {
      final hasOverlap = _controller.isSessionOverlapping(
        instructorId: userId,
        start: _startDate!,
        end: _endDate!,
        isAssociation: true,
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
                    "Il existe déjà une formation prévue sur ce créneau pour cet administrateur d'association.",
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

    final notes = [
      if (_notesController.text.isNotEmpty) _notesController.text,
      if (_recurrence != RecurrenceType.aucune)
        'Récurrence: ${_recurrence.label}'
            '${_recurrenceEndDate != null ? ' jusqu\'au ${DateFormat('dd/MM/yyyy').format(_recurrenceEndDate!)}' : ''}',
    ].join('\n');

    // --- RÉCUPÉRATION DU NOMBRE DE PARTICIPANTS (Priorité au calendrier pour le présentiel) ---
    int participants = int.tryParse(_maxParticipantsController.text) ?? 10;
    if (_selectedType != SessionType.enLigne) {
      participants = bookingController.numberOfPeople.value;
    }

    // Injecter le nom de la salle dans les notes pour les sessions présentielles
    String sessionNotes = notes;
    if (_selectedType != SessionType.enLigne && _selectedSpace != null) {
      final spaceName = _selectedSpace!.name;
      sessionNotes = "📍 Espace: $spaceName\n${sessionNotes}".trim();
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
      notes: sessionNotes.isEmpty ? null : sessionNotes,
      status: SessionStatus.publie,
    );

    if (widget.session == null) {
      if (_selectedType == SessionType.enLigne) {
        _controller.addSession(session, null);
      } else {
        if (_isSpaceReserved) {
          _controller.addSession(session, null);
        } else {
          // Création auto avec réservation (En_attente est géré dans SessionsController)
          double amount = 0;
          if (_startDate != null && _endDate != null && _selectedSpace != null) {
            final hours = _endDate!.difference(_startDate!).inMinutes / 60.0;
            amount = hours * _selectedSpace!.hourlyPrice;
          }
          _controller.addSessionWithReservation(
            session: session, 
            courseId: null,
            spaceId: _selectedSpace!.documentId ?? _selectedSpace!.id,
            totalAmount: amount,
          );
        }
      }
    } else {
      _controller.updateSession(session, null);
    }

    // Get.back(); // Géré dans le contrôleur
  }

  // --- RÉSERVATION ---
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
        _startDate = bookingController.startDateTime.value;
        _endDate = bookingController.endDateTime.value;
        _maxParticipantsController.text = bookingController.numberOfPeople.value.toString();
      });
      _submit();
    }
  }
}
