// =====================================================
// FloorPlanWidget — Interface Interactive du Plan
// Gère les clics, survols et la mise à jour de l'état.
// =====================================================

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'floor_plan_painter.dart';

/// Le Widget principal qui affiche le plan d'étage et gère les interactions utilisateur.
class FloorPlanWidget extends StatefulWidget {
  final Function(String slug) onAreaSelected; // Callback déclenché quand un espace est sélectionné.
  final String? selectedSlug; // NOUVEAU: slug sélectionné depuis le parent

  const FloorPlanWidget({super.key, required this.onAreaSelected, this.selectedSlug});

  @override
  State<FloorPlanWidget> createState() => _FloorPlanWidgetState();
}

class _FloorPlanWidgetState extends State<FloorPlanWidget> {
  String? hoveredSlug;  // Stocke l'ID de l'espace survolé par la souris (Desktop).

  // Dimensions d'origine du plan (coordonnées de base pour le dessin).
  static const double kOrigW = 2780;
  static const double kOrigH = 1974;

  /// Définition des zones interactives (polygones et rectangles).
  /// Ces coordonnées doivent correspondre au dessin fait dans le Painter.
  final List<FloorPlanArea> areas = [
    FloorPlanArea(
      slug: 'espace1',
      points: [
        const Offset(571, 22), const Offset(1598, 20), const Offset(1598, 246),
        const Offset(1507, 248), const Offset(1509, 444), const Offset(573, 442),
      ],
    ),
    FloorPlanArea(slug: 'espace2',  isRect: true, rect: const Rect.fromLTRB(2263, 22,   2754, 452)),
    FloorPlanArea(slug: 'espace3',  isRect: true, rect: const Rect.fromLTRB(2261, 469,  2752, 840)),
    FloorPlanArea(slug: 'espace4',  isRect: true, rect: const Rect.fromLTRB(2261, 857,  2747, 1220)),
    FloorPlanArea(slug: 'espace5',  isRect: true, rect: const Rect.fromLTRB(2263, 1237, 2747, 1630)),
    FloorPlanArea(
      slug: 'espace6',
      points: [
        const Offset(1563, 1520), const Offset(1828, 1520), const Offset(1828, 1446),
        const Offset(2030, 1444), const Offset(2027, 1932), const Offset(1558, 1930),
        const Offset(1561, 1721),
      ],
    ),
    FloorPlanArea(
      slug: 'espace7',
      points: [
        const Offset(1428, 1120), 
        const Offset(1680, 1120), 
        const Offset(1680, 1450), 
        const Offset(1428, 1450),
      ],
    ),
    FloorPlanArea(slug: 'espace8',  isRect: true, rect: const Rect.fromLTRB(829,  1122, 1205, 1512)),
    FloorPlanArea(slug: 'espace9',  isRect: true, rect: const Rect.fromLTRB(470,  869,  814,  1579)),
    FloorPlanArea(slug: 'espace10', isRect: true, rect: const Rect.fromLTRB(14,   602,  453,  1458)),
    FloorPlanArea(slug: 'espace11', isRect: true, rect: const Rect.fromLTRB(473,  469,  770,  857)),
    FloorPlanArea(
      slug: 'espace12',
      points: [
        const Offset(1065, 466), const Offset(1507, 464), const Offset(1509, 508),
        const Offset(1492, 511), const Offset(1492, 837), const Offset(1413, 840),
        const Offset(1411, 940), const Offset(1065, 943),
      ],
    ),
    FloorPlanArea(
      slug: 'espace13',
      points: [
        const Offset(1499, 516), const Offset(1946, 518), const Offset(1944, 850),
        const Offset(1558, 854), const Offset(1558, 945), const Offset(1428, 943),
        const Offset(1426, 845), const Offset(1497, 845),
      ],
    ),
  ];

  /// Gère le clic (ou tap) sur le plan.
  /// Identifie si la position cliquée appartient à l'une des zones définies.
  void _onTap(TapDownDetails details, double sx, double sy) {
    final pos = details.localPosition;//position du clic
    String? foundSlug;
    for (final area in areas) {//boucle sur toute les zones
      if (area.getPath(sx, sy).contains(pos)) {//si la zone contient le clic
        foundSlug = area.slug;//on récupère le slug de la zone
        break;
      }
    }
    
    // Informe le composant parent de la sélection.
    widget.onAreaSelected(foundSlug ?? "");
  }

  /// Gère le survol de la souris (Desktop uniquement).
  void _onHover(PointerHoverEvent event, double sx, double sy) {
    final pos = event.localPosition;
    String? found;
    for (final area in areas) {
      if (area.getPath(sx, sy).contains(pos)) {
        found = area.slug;
        break;
      }
    }
    // Ne déclenche un setState que si l'espace survolé a changé (Performance).
    if (found != hoveredSlug) setState(() => hoveredSlug = found);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Récupère la largeur disponible pour rendre le plan responsive.
      final double availW = constraints.maxWidth;
      
      // Calcul du ratio pour conserver les proportions du plan d'origine.
      final double drawW = availW;
      final double drawH = drawW * (kOrigH / kOrigW);

      // Échelles (sx, sy) pour convertir les coordonnées d'origine vers la taille réelle à l'écran.
      final double sx = drawW / kOrigW;
      final double sy = drawH / kOrigH;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        // Permet le zoom et le déplacement (Pan & Zoom) surtout sur mobile.
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(400),
          minScale: 0.1,
          maxScale: 3.0,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onHover: (e) => _onHover(e, sx, sy),
            onExit: (_) => setState(() => hoveredSlug = null),
            child: GestureDetector(
              onTapDown: (d) => _onTap(d, sx, sy),
              child: CustomPaint(
                size: Size(drawW, drawH),
                // Le dessinateur qui utilise les échelles calculées pour dessiner à la bonne taille.
                painter: FloorPlanPainter(
                  areas: areas,
                  hoveredSlug: hoveredSlug,
                  selectedSlug: widget.selectedSlug,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
