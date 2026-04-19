// ===============================================
// Page de Création d'Espace (CreateSpacePage)
// Permet de définir les caractéristiques d'un nouvel
// espace de coworking (nom, type, capacité, prix).
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/spaces_controller.dart';
import '../../data/models/space.dart';

class CreateSpacePage extends StatefulWidget {
  const CreateSpacePage({super.key});

  @override
  State<CreateSpacePage> createState() => _CreateSpacePageState();
}

class _CreateSpacePageState extends State<CreateSpacePage> {
  // Clé pour valider le formulaire
  final _formKey = GlobalKey<FormState>();
  
  // Récupération du contrôleur pour enregistrer l'espace
  final SpacesController spacesController = Get.find<SpacesController>();

  // Contrôleurs de texte pour les champs de saisie
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Valeurs par défaut pour les types et statuts
  SpaceType _selectedType = SpaceType.espaceDeTravail;
  SpaceStatus _selectedStatus = SpaceStatus.disponible;
  
  // Variables pour les valeurs numériques
  int _capacity = 1;
  double _hourlyPrice = 0;
  double _dailyPrice = 0;
  double _monthlyPrice = 0;

  @override
  Widget build(BuildContext context) {
    // Adaptabilité selon la largeur de l'écran
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double padding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : Titre et bouton retour
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Créer un nouvel espace',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: isMobile ? 20 : 24,
                              ),
                        ),
                        Text(
                          'Ajoutez un nouvel espace de coworking à votre inventaire',
                          style: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 12 : 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Conteneur du formulaire
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Champs Nom et Type
                    _buildResponsiveRow(
                      isMobile: isMobile,
                      children: [
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: _buildTextField(
                            label: 'Nom de l\'espace',
                            controller: _nameController,
                            hint: 'Espace Alpha',
                          ),
                        ),
                        if (!isMobile) const SizedBox(width: 24),
                        if (isMobile) const SizedBox(height: 24),
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: _buildDropdownField<SpaceType>(
                            label: 'Type',
                            value: _selectedType,
                            items: SpaceType.values.where((t) => t != SpaceType.autre).map((type) {
                              String label = type.name;
                              switch (type) {
                                case SpaceType.espaceDeTravail: label = 'Espace de Travail'; break;
                                case SpaceType.salleDeReunion: label = 'Salle de Réunion'; break;
                                case SpaceType.salleDeFormation: label = 'Salle de Formation'; break;
                                case SpaceType.espaceCreatif: label = 'Espace Créatif'; break;
                                case SpaceType.espaceCollaboratif: label = 'Espace Collaboratif'; break;
                                case SpaceType.bureauPrive: label = 'Bureau Privé'; break;
                                case SpaceType.salleDeConference: label = 'Salle de Conférence'; break;
                                case SpaceType.laboratoire: label = 'Laboratoire'; break;
                                case SpaceType.espaceDetente: label = 'Espace Détente'; break;
                                case SpaceType.cuisine: label = 'Cuisine'; break;
                                case SpaceType.securite: label = 'Sécurité'; break;
                                case SpaceType.accueil: label = 'Accueil'; break;
                                case SpaceType.sanitaires: label = 'Sanitaires'; break;
                                default: label = 'Autre';
                              }
                              return DropdownMenuItem(
                                value: type,
                                child: Text(label),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Champs Localisation et Capacité
                    _buildResponsiveRow(
                      isMobile: isMobile,
                      children: [
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: _buildTextField(
                            label: 'Localisation',
                            controller: _locationController,
                            hint: 'Étage 2, Aile Nord',
                          ),
                        ),
                        if (!isMobile) const SizedBox(width: 24),
                        if (isMobile) const SizedBox(height: 24),
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: _buildNumberAdjuster(
                            label: 'Capacité (personnes)',
                            value: _capacity,
                            onChanged: (val) => setState(() => _capacity = val.toInt()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Champ Statut
                    SizedBox(
                      width: isMobile ? double.infinity : MediaQuery.of(context).size.width * 0.45,
                      child: _buildDropdownField<SpaceStatus>(
                        label: 'Statut',
                        value: _selectedStatus,
                        items: SpaceStatus.values.map((status) {
                          String label;
                          switch (status) {
                            case SpaceStatus.disponible:
                              label = 'Disponible';
                              break;
                            case SpaceStatus.occupe:
                              label = 'Occupé';
                              break;
                            case SpaceStatus.maintenance:
                              label = 'En maintenance';
                              break;
                            case SpaceStatus.enPanne:
                              label = 'En panne';
                              break;
                          }
                          return DropdownMenuItem(
                            value: status,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedStatus = val!),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section des Tarifs (Heure, Jour, Mois)
                    isMobile 
                      ? Column(
                          children: [
                            _buildNumberAdjuster(
                              label: 'Tarif horaire',
                              value: _hourlyPrice,
                              isPrice: true,
                              onChanged: (val) => setState(() => _hourlyPrice = val),
                            ),
                            const SizedBox(height: 24),
                            _buildNumberAdjuster(
                              label: 'Tarif journalier',
                              value: _dailyPrice,
                              isPrice: true,
                              onChanged: (val) => setState(() => _dailyPrice = val),
                            ),
                            const SizedBox(height: 24),
                            _buildNumberAdjuster(
                              label: 'Tarif mensuel',
                              value: _monthlyPrice,
                              isPrice: true,
                              onChanged: (val) => setState(() => _monthlyPrice = val),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildNumberAdjuster(
                                label: 'Tarif horaire',
                                value: _hourlyPrice,
                                isPrice: true,
                                onChanged: (val) => setState(() => _hourlyPrice = val),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildNumberAdjuster(
                                label: 'Tarif journalier',
                                value: _dailyPrice,
                                isPrice: true,
                                onChanged: (val) => setState(() => _dailyPrice = val),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildNumberAdjuster(
                                label: 'Tarif mensuel',
                                value: _monthlyPrice,
                                isPrice: true,
                                onChanged: (val) => setState(() => _monthlyPrice = val),
                              ),
                            ),
                          ],
                        ),
                    const SizedBox(height: 32),

                    // Champ Description
                    _buildTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      hint: 'Description détaillée de l\'espace...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 40),

                    // Bouton final de création
                    SizedBox(
                      width: isMobile ? double.infinity : 180,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Créer l\'espace',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget utilitaire pour organiser les éléments selon l'écran
  Widget _buildResponsiveRow({required bool isMobile, required List<Widget> children}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // Widget pour les champs de saisie de texte
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          // Validation obligatoire pour les champs principaux
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est obligatoire';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Widget pour les menus déroulants (dropdown)
  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour l'ajustement des nombres (compteur/prix)
  Widget _buildNumberAdjuster({
    required String label,
    required num value,
    required ValueChanged<double> onChanged,
    bool isPrice = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          isPrice ? value.toInt().toString() : value.toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => onChanged(value.toDouble() + 1),
                          child: const Icon(Icons.keyboard_arrow_up, size: 18),
                        ),
                        InkWell(
                          onTap: () {
                            if (value > 0) onChanged(value.toDouble() - 1);
                          },
                          child: const Icon(Icons.keyboard_arrow_down, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Procédure de soumission du formulaire
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newSpace = Space(
        // Génération d'un ID temporaire
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        slug: _nameController.text.toLowerCase().replaceAll(' ', ''),
        type: _selectedType,
        location: _locationController.text,
        capacity: _capacity,
        hourlyPrice: _hourlyPrice,
        dailyPrice: _dailyPrice,
        monthlyPrice: _monthlyPrice,
        reservations: 0,
        status: _selectedStatus,
        description: _descriptionController.text,
      );
      
      // Enregistrement via le contrôleur
      spacesController.addSpace(newSpace);
    }
  }
}
