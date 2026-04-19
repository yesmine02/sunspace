// ===============================================
// Page de Gestion des Formations (CoursesPage)
// C'est ici que l'enseignant gère ses cours.
// On y retrouve la liste, la recherche et les actions.
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/courses_controller.dart';
import '../../data/models/course.dart';
import './widgets/add_edit_course_dialog.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialisation du contrôleur
    final controller = Get.put(CoursesController());
    
    // Adaptabilité du design
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    final double horizontalPadding = isMobile ? 16.0 : 40.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Titre + Sous-titre + Bouton Nouveau Cours
            _buildHeader(context, isMobile),
            const SizedBox(height: 32),

            // Barre de recherche interne
            _buildInternalSearch(controller),
            const SizedBox(height: 24),

            // Liste des cours (Tableau ou Cartes)
            Obx(() {
              if (controller.isLoading.value && controller.courses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.filteredCourses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: Text('Aucun cours trouvé.')),
                );
              }

              if (isMobile) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.filteredCourses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildCourseCard(context, controller, controller.filteredCourses[index]),
                );
              }

              return _buildCoursesTableContainer(context, controller);
            }),
          ],
        ),
      ),
    );
  }

  // Widget : En-tête stylisé
  Widget _buildHeader(BuildContext context, bool isMobile) {
    return isMobile 
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderTitle(),
            const SizedBox(height: 20),
            _buildAddButton(),
          ],
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeaderTitle(),
            _buildAddButton(),
          ],
        );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: Colors.blue, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Mes Formations',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Gérez vos cours, modules et leçons',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => Get.dialog(
        const AddEditCourseDialog(),
        barrierDismissible: true,
      ),
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Nouveau Cours'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  // Widget : Barre de recherche blanche avec bordures arrondies
  Widget _buildInternalSearch(CoursesController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        onChanged: controller.updateSearch,
        decoration: InputDecoration(
          hintText: 'Rechercher un cours...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // Widget : Carte de cours pour mobile
  Widget _buildCourseCard(BuildContext context, CoursesController controller, Course course) {
    final fmtDate = course.createdAt != null ? DateFormat('dd/MM/yyyy').format(course.createdAt!) : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(course.isPublished),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.levelLabel,
            style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRIX', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('${course.price.toInt()} TND', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('CRÉÉ LE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(fmtDate, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => Get.dialog(AddEditCourseDialog(course: course)),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmation(context, controller, course),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Supprimer'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget : Badge de statut pour mobile
  Widget _buildStatusBadge(bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPublished ? Colors.green[100]! : Colors.orange[100]!),
      ),
      child: Text(
        isPublished ? 'Publié' : 'Brouillon',
        style: TextStyle(
          color: isPublished ? Colors.green[700] : Colors.orange[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget : Tableau des cours dans un conteneur blanc (Desktop)
  Widget _buildCoursesTableContainer(BuildContext context, CoursesController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFFDFDFD)),
            dataRowHeight: 64,
            horizontalMargin: 24,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Titre', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Niveau', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Prix', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Créé le', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: controller.filteredCourses.map((course) {
              return DataRow(cells: [
                DataCell(Text(course.title, style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(course.levelLabel, style: TextStyle(color: Colors.grey[700]))),
                DataCell(Text('${course.price.toInt()} TND', style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(_buildStatusDot(course.isPublished)),
                DataCell(Text(
                  course.createdAt != null 
                      ? DateFormat('dd/MM/yyyy').format(course.createdAt!) 
                      : '-',
                  style: TextStyle(color: Colors.grey[600]),
                )),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                      onPressed: () => Get.dialog(
                        AddEditCourseDialog(course: course),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      onPressed: () => _showDeleteConfirmation(context, controller, course),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Widget : Petit indicateur de statut (Vert = Publié, Jaune = Brouillon)
  Widget _buildStatusDot(bool isPublished) {
    return Container(
      width: 24,
      height: 4,
      decoration: BoxDecoration(
        color: isPublished ? Colors.green.withOpacity(0.5) : Colors.yellow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // Dialogue de confirmation de suppression
  void _showDeleteConfirmation(BuildContext context, CoursesController controller, Course course) {
    Get.defaultDialog(
      title: "Supprimer le cours",
      middleText: "Voulez-vous vraiment supprimer '${course.title}' ?",
      textConfirm: "Supprimer",
      textCancel: "Annuler",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        if (course.documentId != null) {
          controller.deleteCourse(course.documentId!);
        }
        Get.back();
      },
    );
  }
}
