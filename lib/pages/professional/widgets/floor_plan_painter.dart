// =====================================================
// FloorPlanPainter — Plan Architectural Détaillé
// Reproduit fidèlement le plan du Sunspace avec :
//   - Couloirs en gris
//   - Pièces en gris clair avec bordures vertes
//   - Mobilier (tables, chaises)
//   - Plantes décoratives
//   - Zones interactives (hover vert, sélection bleu)
// Dimensions originales du SVG web : 2780 x 1974
// =====================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Data model ──────────────────────────────────────
class FloorPlanArea {
  final String slug;
  final List<Offset> points;
  final bool isRect;
  final Rect? rect;

  FloorPlanArea({
    required this.slug,
    this.points = const [],
    this.isRect = false,
    this.rect,
  });

  Path getPath(double scaleX, double scaleY) {
    final Path path = Path();
    if (isRect && rect != null) {
      path.addRect(Rect.fromLTRB(
        rect!.left * scaleX,
        rect!.top * scaleY,
        rect!.right * scaleX,
        rect!.bottom * scaleY,
      ));
    } else if (points.isNotEmpty) {
      path.moveTo(points[0].dx * scaleX, points[0].dy * scaleY);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx * scaleX, points[i].dy * scaleY);
      }
      path.close();
    }
    return path;
  }
}

// ── Main painter ────────────────────────────────────
class FloorPlanPainter extends CustomPainter {
  final List<FloorPlanArea> areas;
  final String? hoveredSlug;
  final String? selectedSlug;

  static const double W = 2780;
  static const double H = 1974;

  FloorPlanPainter({
    required this.areas,
    this.hoveredSlug,
    this.selectedSlug,
  });

  // ── Colour palette (matching web CSS) ──────────────
  static const Color kCorridorBg   = Color(0xFFCDCDCD); // grey corridors
  static const Color kRoomBg       = Color(0xFFD9D9D9); // lighter room fill
  static const Color kRoomBorder   = Color(0xFF7ED9A0); // green border
  static const Color kFurniture    = Color(0xFFEAEAEA); // table / chair
  static const Color kFurnBorder   = Color(0xFFBDBDBD);
  static const Color kPlantFill    = Color(0xFF7ED9A0); // green plant
  static const Color kPlantDark    = Color(0xFF4CB87A);
  static const Color kHoverFill    = Color(0xFF7ED9A020);
  static const Color kHoverBorder  = Color(0xFF4CB87A);
  static const Color kSelectFill   = Color(0xFF2563EB20);
  static const Color kSelectBorder = Color(0xFF2563EB);
  static const Color kWall         = Color(0xFFAAAAAA);

  @override
  void paint(Canvas canvas, Size size) {
    final double sx = size.width  / W;
    final double sy = size.height / H;

    // 1) Background (corridor floor)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = kCorridorBg);

    // 2) Draw all rooms
    _drawAllRooms(canvas, sx, sy);

    // 3) Draw all furniture decorations
    _drawAllFurniture(canvas, sx, sy);

    // 4) Interactive overlays (hover / selected)
    _drawInteractiveOverlays(canvas, sx, sy);

    // 5) Room labels
    _drawLabels(canvas, sx, sy);
  }

  // ── 1. Rooms ────────────────────────────────────────
  void _drawAllRooms(Canvas canvas, double sx, double sy) {
    final roomPaint  = Paint()..color = kRoomBg;
    final borderPaint = Paint()
      ..color = kRoomBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    void room(Rect r) {
      canvas.drawRect(_s(r, sx, sy), roomPaint);
      canvas.drawRect(_s(r, sx, sy), borderPaint);
    }

    void roomPoly(List<Offset> pts) {
      final p = _poly(pts, sx, sy);
      canvas.drawPath(p, roomPaint);
      canvas.drawPath(p, borderPaint);
    }

    // ── Top row (Espace 1 — wide open space) ──────────
    roomPoly([
      const Offset(571, 22), const Offset(1598, 20), const Offset(1598, 246),
      const Offset(1507, 248), const Offset(1509, 444), const Offset(573, 442),
    ]);

    // ── Right column rooms ─────────────────────────────
    room(const Rect.fromLTRB(2263, 22,   2754, 452));   // Espace 2
    room(const Rect.fromLTRB(2261, 469,  2752, 840));   // Espace 3
    room(const Rect.fromLTRB(2261, 857,  2747, 1220));  // Espace 4
    room(const Rect.fromLTRB(2263, 1237, 2747, 1630));  // Espace 5

    // ── Center-right cluster ───────────────────────────
    roomPoly([
      const Offset(1563, 1520), const Offset(1828, 1520), const Offset(1828, 1446),
      const Offset(2030, 1444), const Offset(2027, 1932), const Offset(1558, 1930),
      const Offset(1561, 1721),
    ]);  // Espace 6

    roomPoly([
      const Offset(1428, 1120), 
      const Offset(1680, 1120), 
      const Offset(1680, 1450), 
      const Offset(1428, 1450),
    ]);  // Espace 7

    // ── Centre ────────────────────────────────────────
    room(const Rect.fromLTRB(829,  1122, 1205, 1512));  // Espace 8
    room(const Rect.fromLTRB(470,  869,  814,  1579));  // Espace 9
    room(const Rect.fromLTRB(14,   602,  453,  1458));  // Espace 10
    room(const Rect.fromLTRB(473,  469,  770,  857));   // Espace 11

    roomPoly([
      const Offset(1065, 466), const Offset(1507, 464), const Offset(1509, 508),
      const Offset(1492, 511), const Offset(1492, 837), const Offset(1413, 840),
      const Offset(1411, 940), const Offset(1065, 943),
    ]);  // Espace 12

    roomPoly([
      const Offset(1499, 516), const Offset(1946, 518), const Offset(1944, 850),
      const Offset(1558, 854), const Offset(1558, 945), const Offset(1428, 943),
      const Offset(1426, 845), const Offset(1497, 845),
    ]);  // Espace 13

    // ── Stairs / elevator / WC areas ──────────────────
    // Stairs top-left
    _drawStairs(canvas, const Rect.fromLTRB(0, 0, 565, 450), sx, sy);

    // ── 2 WC sous Espace 13 (un seul bloc = 2 cabines) ──
    _drawWCBlock(canvas, const Rect.fromLTRB(1428, 950, 1558, 1070), sx, sy);

    // ── Lave-mains au-dessus de l'Espace 7 ───────────
    _drawSinks(canvas, const Offset(1428, 1120), 252, 55, sx, sy);

    // ── Cuisine à droite des WC ──────────────────────
    _drawKitchen(canvas, const Rect.fromLTRB(1680, 855, 1750, 1165), sx, sy);

    // ── Espaces verts (Hedges) ────────────────────────
    // Hedge around Espace 13 (L-shape)
    _drawHedge(canvas, [
      const Offset(1500, 430), const Offset(2080, 430), const Offset(2080, 950),
      const Offset(2000, 950), const Offset(2000, 510), const Offset(1500, 510),
    ], sx, sy);

    // Vertical hedge for Espace 6
    _drawHedge(canvas, [
      const Offset(1480, 1520), const Offset(1540, 1520), 
      const Offset(1540, 1930), const Offset(1480, 1930),
    ], sx, sy);

    // Plant corner top
    _drawPlant(canvas, _sc(Offset(600, 45), sx, sy), 18 * math.min(sx, sy));
    _drawPlant(canvas, _sc(Offset(1560, 145), sx, sy), 18 * math.min(sx, sy));
    _drawPlant(canvas, _sc(Offset(45, 620), sx, sy), 14 * math.min(sx, sy));
    _drawPlant(canvas, _sc(Offset(45, 1430), sx, sy), 14 * math.min(sx, sy));
  }

  // ── 2. Furniture ─────────────────────────────────────
  void _drawAllFurniture(Canvas canvas, double sx, double sy) {
    // Espace 1 — 2 conference tables
    _drawConferenceTable(canvas, const Rect.fromLTRB(680, 60, 940, 200), 4, 2, sx, sy);
    _drawConferenceTable(canvas, const Rect.fromLTRB(1000, 60, 1260, 200), 4, 2, sx, sy);

    // Espace 2 — office desks
    _drawDeskRow(canvas, const Offset(2310, 100), 3, sx, sy);
    _drawConferenceTable(canvas, const Rect.fromLTRB(2300, 200, 2700, 400), 6, 2, sx, sy);

    // Espace 3
    _drawConferenceTable(canvas, const Rect.fromLTRB(2300, 530, 2700, 700), 6, 2, sx, sy);
    _drawDeskRow(canvas, const Offset(2310, 730), 3, sx, sy);

    // Espace 4
    _drawConferenceTable(canvas, const Rect.fromLTRB(2300, 900, 2700, 1060), 6, 2, sx, sy);
    _drawDeskRow(canvas, const Offset(2310, 1100), 3, sx, sy);

    // Espace 5
    _drawConferenceTable(canvas, const Rect.fromLTRB(2300, 1280, 2700, 1450), 6, 2, sx, sy);
    _drawDeskRow(canvas, const Offset(2310, 1480), 3, sx, sy);

    // Espace 10 (left) — long cluster
    _drawDeskCluster(canvas, const Offset(60, 700), 2, 4, sx, sy);

    // Espace 11
    _drawSmallTable(canvas, const Rect.fromLTRB(510, 530, 730, 660), sx, sy);
    _drawChairs(canvas, const Rect.fromLTRB(510, 530, 730, 660), sx, sy);

    // Espace 9
    _drawSmallTable(canvas, const Rect.fromLTRB(510, 950, 730, 1100), sx, sy);
    _drawChairs(canvas, const Rect.fromLTRB(510, 950, 730, 1100), sx, sy);
    _drawSmallTable(canvas, const Rect.fromLTRB(510, 1200, 730, 1350), sx, sy);
    _drawChairs(canvas, const Rect.fromLTRB(510, 1200, 730, 1350), sx, sy);

    // Espace 12 — meeting table in centre
    _drawConferenceTable(canvas, const Rect.fromLTRB(1100, 560, 1470, 760), 5, 2, sx, sy);

    // Espace 13 — second meeting table
    _drawConferenceTable(canvas, const Rect.fromLTRB(1540, 570, 1900, 800), 5, 2, sx, sy);

    // Espace 8 — small meeting
    _drawConferenceTable(canvas, const Rect.fromLTRB(860, 1160, 1160, 1460), 3, 3, sx, sy);

    // Espace 7 — pod tables
    _drawPodGroup(canvas, const Offset(1500, 1230), sx, sy);
    _drawPodGroup(canvas, const Offset(1610, 1230), sx, sy);
    _drawPodGroup(canvas, const Offset(1555, 1365), sx, sy);

    // Espace 6 — 4 pod tables (2x2 grid)
    _drawPodGroup(canvas, const Offset(1650, 1620), sx, sy);
    _drawPodGroup(canvas, const Offset(1850, 1620), sx, sy);
    _drawPodGroup(canvas, const Offset(1650, 1825), sx, sy);
    _drawPodGroup(canvas, const Offset(1850, 1825), sx, sy);

    // Entrance security panel
    _drawSecurityPanel(canvas, const Offset(1690, 960), sx, sy);

  }

  // ── 3. Interactive overlays ───────────────────────────
  void _drawInteractiveOverlays(Canvas canvas, double sx, double sy) {
    for (final area in areas) {
      final bool isHov = area.slug == hoveredSlug;
      final bool isSel = area.slug == selectedSlug;
      if (!isHov && !isSel) continue;

      final path = area.getPath(sx, sy);

      // Fill
      canvas.drawPath(path,
          Paint()..color = isSel ? kSelectFill : kHoverFill);

      // Border
      canvas.drawPath(path,
          Paint()
            ..color = isSel ? kSelectBorder : kHoverBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0);
    }
  }

  // ── 4. Labels ─────────────────────────────────────────
  void _drawLabels(Canvas canvas, double sx, double sy) {
    final Map<String, Offset> centres = {
      'espace1':  const Offset(1085, 230),
      'espace2':  const Offset(2508, 237),
      'espace3':  const Offset(2506, 654),
      'espace4':  const Offset(2504, 1038),
      'espace5':  const Offset(2505, 1433),
      'espace6':  const Offset(1793, 1720),
      'espace7':  const Offset(1554, 1285),
      'espace8':  const Offset(1017, 1317),
      'espace9':  const Offset(642,  1224),
      'espace10': const Offset(233,  1030),
      'espace11': const Offset(621,  663),
      'espace12': const Offset(1285, 700),
      'espace13': const Offset(1721, 683),
    };

    final bgPaint = Paint()..color = Colors.white.withOpacity(0.75);

    for (final entry in centres.entries) {
      final slug = entry.key;
      final centre = entry.value;
      final isHov = slug == hoveredSlug;
      final isSel = slug == selectedSlug;

      final String label = slug.replaceFirst('espace', 'Espace ');
      final textStyle = TextStyle(
        color: isSel
            ? const Color(0xFF1D4ED8)
            : (isHov ? const Color(0xFF166534) : const Color(0xFF4B5563)),
        fontSize: 11 * math.min(sx, sy) * (W / 500),
        fontWeight: (isHov || isSel) ? FontWeight.bold : FontWeight.normal,
      );

      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final dx = centre.dx * sx - tp.width / 2;
      final dy = centre.dy * sy - tp.height / 2;

      // Background pill
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx - 4, dy - 2, tp.width + 8, tp.height + 4),
        const Radius.circular(4),
      );
      canvas.drawRRect(bgRect, bgPaint);

      tp.paint(canvas, Offset(dx, dy));
    }
  }

  // ── Helpers ───────────────────────────────────────────

  /// Scale a rect
  Rect _s(Rect r, double sx, double sy) =>
      Rect.fromLTRB(r.left * sx, r.top * sy, r.right * sx, r.bottom * sy);

  /// Scale an offset
  Offset _sc(Offset o, double sx, double sy) => Offset(o.dx * sx, o.dy * sy);

  /// Build polygon path
  Path _poly(List<Offset> pts, double sx, double sy) {
    final p = Path();
    p.moveTo(pts[0].dx * sx, pts[0].dy * sy);
    for (int i = 1; i < pts.length; i++) {
      p.lineTo(pts[i].dx * sx, pts[i].dy * sy);
    }
    p.close();
    return p;
  }

  /// Draw a conference table with chairs around it
  void _drawConferenceTable(Canvas canvas, Rect raw, int cols, int rows,
      double sx, double sy) {
    final r = _s(raw, sx, sy);
    final tp = Paint()..color = kFurniture;
    final tb = Paint()
      ..color = kFurnBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final cp = Paint()..color = kFurniture;
    final cb = Paint()
      ..color = kFurnBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Chairs around the table
    final cw = (r.width / cols) * 0.55;
    final ch = cw * 0.7;
    final gap = 4.0;

    // Top row
    for (int i = 0; i < cols; i++) {
      final cx = r.left + (r.width / cols) * i + (r.width / cols) * 0.25;
      final cy = r.top - ch - gap;
      _roundRect(canvas, Rect.fromLTWH(cx - cw / 2, cy, cw, ch), 3, cp, cb);
    }
    // Bottom row
    for (int i = 0; i < cols; i++) {
      final cx = r.left + (r.width / cols) * i + (r.width / cols) * 0.25;
      final cy = r.bottom + gap;
      _roundRect(canvas, Rect.fromLTWH(cx - cw / 2, cy, cw, ch), 3, cp, cb);
    }

    // Table surface
    _roundRect(canvas, r, 4, tp, tb);
  }

  /// Draw a small single table + chairs
  void _drawSmallTable(Canvas canvas, Rect raw, double sx, double sy) {
    final r = _s(raw, sx, sy);
    _roundRect(canvas, r, 4, Paint()..color = kFurniture,
        Paint()
          ..color = kFurnBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  void _drawChairs(Canvas canvas, Rect raw, double sx, double sy) {
    final r = _s(raw, sx, sy);
    final cw = r.width * 0.22;
    final ch = cw * 0.65;
    const gap = 4.0;
    final cp = Paint()..color = kFurniture;
    final cb = Paint()
      ..color = kFurnBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    // top chairs
    for (int i = 0; i < 2; i++) {
      final cx = r.left + r.width * (0.2 + i * 0.45);
      _roundRect(canvas, Rect.fromLTWH(cx - cw / 2, r.top - ch - gap, cw, ch),
          3, cp, cb);
    }
    // bottom chairs
    for (int i = 0; i < 2; i++) {
      final cx = r.left + r.width * (0.2 + i * 0.45);
      _roundRect(canvas, Rect.fromLTWH(cx - cw / 2, r.bottom + gap, cw, ch),
          3, cp, cb);
    }
    // left
    _roundRect(canvas,
        Rect.fromLTWH(r.left - ch - gap, r.center.dy - cw / 2, ch, cw),
        3, cp, cb);
    // right
    _roundRect(canvas,
        Rect.fromLTWH(r.right + gap, r.center.dy - cw / 2, ch, cw),
        3, cp, cb);
  }

  /// Draw a row of single desks
  void _drawDeskRow(Canvas canvas, Offset origin, int count, double sx, double sy) {
    final dw = 160.0 * sx;
    final dh = 90.0 * sy;
    for (int i = 0; i < count; i++) {
      final dx = origin.dx * sx + i * (dw + 25 * sx);
      final dy = origin.dy * sy;
      _roundRect(canvas, Rect.fromLTWH(dx, dy, dw, dh), 3,
          Paint()..color = kFurniture,
          Paint()
            ..color = kFurnBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
      // chair
      _roundRect(canvas,
          Rect.fromLTWH(dx + dw * 0.2, dy + dh + 4 * sy, dw * 0.6, dh * 0.55),
          3, Paint()..color = kFurniture,
          Paint()
            ..color = kFurnBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
    }
  }

  /// Draw a cluster of desks (rows x cols)
  void _drawDeskCluster(Canvas canvas, Offset origin, int rows, int cols,
      double sx, double sy) {
    final dw = 130.0 * sx;
    final dh = 80.0 * sy;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final dx = origin.dx * sx + c * (dw + 18 * sx);
        final dy = origin.dy * sy + r * (dh + 50 * sy);
        _roundRect(canvas, Rect.fromLTWH(dx, dy, dw, dh), 3,
            Paint()..color = kFurniture,
            Paint()
              ..color = kFurnBorder
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0);
        // chair below
        _roundRect(canvas,
            Rect.fromLTWH(dx + dw * 0.15, dy + dh + 4 * sy, dw * 0.7, dh * 0.5),
            3, Paint()..color = kFurniture,
            Paint()
              ..color = kFurnBorder
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0);
      }
    }
  }

  /// Draw a pod / cluster seating group
  void _drawPodGroup(Canvas canvas, Offset origin, double sx, double sy) {
    final o = _sc(origin, sx, sy);
    final r = 30.0 * math.min(sx, sy);
    // Central table
    canvas.drawCircle(o, r,
        Paint()..color = kFurniture);
    canvas.drawCircle(o, r,
        Paint()
          ..color = kFurnBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    // 4 chairs around
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final co = Offset(o.dx + math.cos(angle) * (r + 15 * math.min(sx, sy)),
          o.dy + math.sin(angle) * (r + 15 * math.min(sx, sy)));
      final cr = 12.0 * math.min(sx, sy);
      canvas.drawCircle(co, cr, Paint()..color = kFurniture);
      canvas.drawCircle(co, cr,
          Paint()
            ..color = kFurnBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
    }
  }

  /// Draw a decorative plant
  void _drawPlant(Canvas canvas, Offset centre, double radius) {
    // pot
    canvas.drawCircle(centre, radius,
        Paint()..color = kPlantFill.withOpacity(0.3));
    // inner dots (leaves)
    for (int i = 0; i < 7; i++) {
      final angle = i * math.pi * 2 / 7;
      final dx = centre.dx + math.cos(angle) * radius * 0.5;
      final dy = centre.dy + math.sin(angle) * radius * 0.5;
      canvas.drawCircle(Offset(dx, dy), radius * 0.28,
          Paint()..color = kPlantDark);
    }
    canvas.drawCircle(centre, radius * 0.25, Paint()..color = kPlantDark);
  }

  /// Draw staircase graphic
  void _drawStairs(Canvas canvas, Rect raw, double sx, double sy) {
    final r = _s(raw, sx, sy);
    canvas.drawRect(r, Paint()..color = const Color(0xFFC4C4C4));
    canvas.drawRect(r,
        Paint()
          ..color = kWall
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // Steps
    final steps = 6;
    final stepH = r.height / steps;
    for (int i = 0; i <= steps; i++) {
      canvas.drawLine(Offset(r.left, r.top + stepH * i),
          Offset(r.right, r.top + stepH * i),
          Paint()
            ..color = kWall
            ..strokeWidth = 1.0);
    }
  }

  /// Draw WC block — 2 stalls side by side with toilet icons
  void _drawWCBlock(Canvas canvas, Rect raw, double sx, double sy) {
    final r = _s(raw, sx, sy);

    // Room background
    canvas.drawRect(r, Paint()..color = const Color(0xFFD4D4D4));

    // Outer border (white/light wall)
    canvas.drawRect(r,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * math.min(sx, sy) * 2);

    // Green bottom accent border
    final greenBorder = Paint()
      ..color = kRoomBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(r.left, r.bottom),
      Offset(r.right, r.bottom),
      greenBorder,
    );

    // Divider wall between the 2 stalls
    final midX = r.left + r.width / 2;
    canvas.drawLine(
      Offset(midX, r.top),
      Offset(midX, r.bottom),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5,
    );

    // Draw a toilet in each stall
    final stallW = r.width / 2;
    _drawToilet(canvas,
        Rect.fromLTWH(r.left, r.top, stallW, r.height), sx, sy);
    _drawToilet(canvas,
        Rect.fromLTWH(midX, r.top, stallW, r.height), sx, sy);
  }

  /// Draw a top-view toilet inside [stallRect]:
  ///   - rectangular tank (top)
  ///   - oval bowl / seat (below)
  void _drawToilet(Canvas canvas, Rect stall, double sx, double sy) {
    final pad   = stall.width * 0.15;
    final inner = stall.deflate(pad);

    // ── Tank (rectangle, top 30% of inner area) ──────
    final tankH = inner.height * 0.30;
    final tankR = Rect.fromLTWH(inner.left, inner.top, inner.width, tankH);
    _roundRect(
      canvas,
      tankR,
      4,
      Paint()..color = Colors.white,
      Paint()
        ..color = const Color(0xFFCCCCCC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Flush button dot on tank
    final btnC = Offset(tankR.center.dx, tankR.center.dy);
    final btnR = tankH * 0.22;
    canvas.drawCircle(btnC, btnR, Paint()..color = const Color(0xFFE0E0E0));
    canvas.drawCircle(
        btnC,
        btnR,
        Paint()
          ..color = const Color(0xFFBBBBBB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);

    // ── Bowl (oval, bottom 60%) ───────────────────────
    final bowlTop = inner.top + tankH + 3 * sy;
    final bowlRect = Rect.fromLTWH(
      inner.left + inner.width * 0.04,
      bowlTop,
      inner.width * 0.92,
      inner.height - tankH - 3 * sy,
    );

    // Outer seat (slightly larger, slightly darker)
    final seatRect = bowlRect.inflate(2.0);
    canvas.drawOval(seatRect, Paint()..color = const Color(0xFFDDDDDD));
    canvas.drawOval(
        seatRect,
        Paint()
          ..color = const Color(0xFFBBBBBB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    // Inner bowl (white oval)
    final innerBowl = bowlRect.deflate(bowlRect.width * 0.12);
    canvas.drawOval(innerBowl, Paint()..color = Colors.white);
    canvas.drawOval(
        innerBowl,
        Paint()
          ..color = const Color(0xFFCCCCCC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }


  /// Draw elevator
  void _drawElevator(Canvas canvas, Rect raw, double sx, double sy) {
    final r = _s(raw, sx, sy);
    canvas.drawRect(r, Paint()..color = const Color(0xFF333333));
    final icon = Paint()..color = Colors.white;
    // Up arrow
    final px = r.center.dx;
    final py = r.center.dy;
    final a = r.width * 0.2;
    canvas.drawLine(Offset(px - a, py - 2), Offset(px, py - a * 2 - 2), icon..strokeWidth = 1.5 * math.min(sx, sy));
    canvas.drawLine(Offset(px, py - a * 2 - 2), Offset(px + a, py - 2), icon);
  }

  /// Draw security panel marker
  void _drawSecurityPanel(Canvas canvas, Offset origin, double sx, double sy) {
    final o = _sc(origin, sx, sy);
    final w = 24.0 * sx, h = 36.0 * sy;
    canvas.drawRect(
        Rect.fromCenter(center: o, width: w, height: h),
        Paint()..color = const Color(0xFF333333));
  }

  /// Rounded rectangle helper
  void _roundRect(Canvas canvas, Rect r, double radius, Paint fill, Paint stroke) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    canvas.drawRRect(rr, fill);
    canvas.drawRRect(rr, stroke);
  }

  /// Draw a block of sinks (washbasins) above a room — Enhanced design
  void _drawSinks(Canvas canvas, Offset bottomLeft, double width, double height, double sx, double sy) {
    final rect = _s(Rect.fromLTWH(bottomLeft.dx, bottomLeft.dy - height, width, height), sx, sy);
    
    // Support counter (long white shelf)
    final shelfRR = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(shelfRR, Paint()..color = Colors.white);
    canvas.drawRRect(shelfRR, Paint()..color = const Color(0xFFE0E0E0)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    final sinkUnitW = rect.width * 0.28;
    final sinkUnitH = rect.height * 0.9;
    final sinkUnitY = rect.top + (rect.height - sinkUnitH) / 2;

    void drawOneSinkUnit(double x) {
      final unitRect = Rect.fromLTWH(x, sinkUnitY, sinkUnitW, sinkUnitH);
      final unitRR = RRect.fromRectAndRadius(unitRect, const Radius.circular(6));
      
      // Sink base unit (light grey)
      canvas.drawRRect(unitRR, Paint()..color = const Color(0xFFF0F0F0));
      canvas.drawRRect(unitRR, Paint()..color = const Color(0xFFE5E5E5)..style = PaintingStyle.stroke..strokeWidth = 1.0);

      // Basin (Semi-circle at the top)
      final basinRect = Rect.fromLTWH(
        unitRect.left + unitRect.width * 0.1,
        unitRect.top + unitRect.height * 0.05,
        unitRect.width * 0.8,
        unitRect.height * 0.6
      );
      
      final basinPath = Path();
      basinPath.moveTo(basinRect.left, basinRect.top + basinRect.height * 0.3);
      basinPath.arcTo(basinRect, math.pi, math.pi, false);
      basinPath.lineTo(basinRect.right, basinRect.top + basinRect.height * 0.3);
      basinPath.close();

      // Water fill (Light Blue Gradient-like)
      canvas.drawPath(basinPath, Paint()..color = const Color(0xFFD1E9FF));
      canvas.drawPath(basinPath, Paint()..color = const Color(0xFF94CCFF)..style = PaintingStyle.stroke..strokeWidth = 1.2);

      // Drain hole
      final drainC = Offset(basinRect.center.dx, basinRect.top + basinRect.height * 0.45);
      canvas.drawCircle(drainC, 2.5 * math.min(sx, sy), Paint()..color = const Color(0xFF555555));
      canvas.drawCircle(drainC, 2.5 * math.min(sx, sy), Paint()..color = const Color(0xFF333333)..style = PaintingStyle.stroke..strokeWidth = 0.5);

      // Faucet (detailed)
      final faucetBaseC = Offset(unitRect.center.dx, unitRect.bottom - unitRect.height * 0.3);
      
      // Tap Pipe
      final pipePath = Path();
      final pW = 5 * sx;
      pipePath.moveTo(faucetBaseC.dx - pW/2, faucetBaseC.dy);
      pipePath.lineTo(faucetBaseC.dx - pW/2, faucetBaseC.dy - unitRect.height * 0.25);
      pipePath.arcToPoint(Offset(faucetBaseC.dx + pW/2, faucetBaseC.dy - unitRect.height * 0.25), radius: Radius.circular(pW/2));
      pipePath.lineTo(faucetBaseC.dx + pW/2, faucetBaseC.dy);
      
      canvas.drawPath(pipePath, Paint()..color = const Color(0xFFBDBDBD));
      canvas.drawPath(pipePath, Paint()..color = const Color(0xFF9E9E9E)..style = PaintingStyle.stroke..strokeWidth = 0.8);
      
      // Faucet handle/base
      canvas.drawCircle(faucetBaseC, 6 * math.min(sx, sy), Paint()..color = const Color(0xFFCCCCCC));
      canvas.drawCircle(faucetBaseC, 6 * math.min(sx, sy), Paint()..color = const Color(0xFFB0B0B0)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }

    // Place the two sinks on the counter
    drawOneSinkUnit(rect.left + rect.width * 0.15);
    drawOneSinkUnit(rect.right - rect.width * 0.15 - sinkUnitW);
  }

  /// Draw a kitchen area (hob, sink, counter and chairs)
  void _drawKitchen(Canvas canvas, Rect raw, double sx, double sy) {
    final r = _s(raw, sx, sy);
    // Counter
    canvas.drawRect(r, Paint()..color = Colors.white);
    canvas.drawRect(r, Paint()..color = const Color(0xFFE0E0E0)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // 1. Induction Hob (top)
    final hobW = r.width * 0.8;
    final hobH = hobW * 1.1;
    final hobTop = r.top + 15 * sy;
    final hobRect = Rect.fromCenter(center: Offset(r.center.dx, hobTop + hobH/2), width: hobW, height: hobH);
    _roundRect(canvas, hobRect, 4, Paint()..color = const Color(0xFF333333), Paint()..color = const Color(0xFF111111)..style = PaintingStyle.stroke);
    
    // Hob burners (circles)
    final rad = hobW * 0.18;
    final p = Paint()..color = Colors.white.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    canvas.drawCircle(Offset(hobRect.left + hobW * 0.3, hobRect.top + hobH * 0.3), rad, p);
    canvas.drawCircle(Offset(hobRect.right - hobW * 0.3, hobRect.top + hobH * 0.3), rad, p);
    canvas.drawCircle(Offset(hobRect.left + hobW * 0.3, hobRect.bottom - hobH * 0.3), rad * 0.8, p);
    canvas.drawCircle(Offset(hobRect.right - hobW * 0.3, hobRect.bottom - hobH * 0.3), rad * 0.8, p);

    // 2. Sink (middle)
    final sinkW = r.width * 0.88;
    final sinkH = sinkW * 1.5;
    final sinkTop = hobRect.bottom + 45 * sy;
    final sinkRect = Rect.fromCenter(center: Offset(r.center.dx, sinkTop + sinkH/2), width: sinkW, height: sinkH);
    
    // Outer sink shell
    _roundRect(canvas, sinkRect, 2, Paint()..color = const Color(0xFFF5F5F5), Paint()..color = const Color(0xFFD0D0D0)..style = PaintingStyle.stroke);
    
    // Basin
    final bW = sinkW * 0.75, bH = sinkH * 0.5;
    final bR = Rect.fromCenter(center: Offset(sinkRect.center.dx, sinkRect.bottom - bH/2 - 6*sy), width: bW, height: bH);
    canvas.drawRect(bR, Paint()..color = Colors.white);
    canvas.drawRect(bR, Paint()..color = const Color(0xFFC0C0C0)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    
    // Draining rack (lines)
    final rackT = sinkRect.top + 8 * sy;
    final rackB = bR.top - 8 * sy;
    for (int i = 0; i < 6; i++) {
      final lx = sinkRect.left + sinkW * (0.2 + i * 0.12);
      canvas.drawLine(Offset(lx, rackT), Offset(lx, rackB), Paint()..color = const Color(0xFFD0D0D0)..strokeWidth = 1.2);
    }
    
    // Faucet (detailed)
    final faucetC = Offset(sinkRect.left - 6*sx, bR.top + 8*sy);
    final fPath = Path();
    fPath.moveTo(faucetC.dx, faucetC.dy);
    fPath.relativeLineTo(-5*sx, 0);
    fPath.relativeLineTo(0, -12*sy);
    fPath.relativeArcToPoint(Offset(18*sx, 0), radius: const Radius.circular(9));
    fPath.relativeLineTo(0, 10*sy);
    canvas.drawPath(fPath, Paint()..color = const Color(0xFF9E9E9E)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round);

    // 3. Chairs (bar stools facing the counter from the left)
    final stoolW = r.width * 0.8;
    final stoolH = stoolW * 0.7;
    for (int i = 0; i < 2; i++) {
      final cy = sinkRect.bottom + 60 * sy + i * (stoolH + 60 * sy);
      final stoolC = Offset(r.left - 40 * sx, cy);
      final stoolR = Rect.fromCenter(center: stoolC, width: stoolW, height: stoolH);
      
      // Chair seat
      _roundRect(canvas, stoolR, 12, Paint()..color = Colors.white, Paint()..color = const Color(0xFFE0E0E0)..style = PaintingStyle.stroke..strokeWidth = 1.2);
      // Small backrest
      final backR = Rect.fromLTWH(stoolR.left, stoolR.top, stoolR.width * 0.1, stoolR.height);
      canvas.drawRRect(RRect.fromRectAndRadius(backR, const Radius.circular(2)), Paint()..color = const Color(0xFFF0F0F0));
    }
  }

  /// Draw a green hedge / green space with a checkered pattern
  void _drawHedge(Canvas canvas, List<Offset> points, double sx, double sy) {
    final path = _poly(points, sx, sy);
    
    // 1. Base Green Fill
    canvas.drawPath(path, Paint()..color = kPlantFill);
    
    // 2. Stroke Border
    canvas.drawPath(path, Paint()..color = kPlantDark.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    
    // 3. Pattern (Checkered texture)
    // We clip to the hedge path to only draw pattern inside
    canvas.save();
    canvas.clipPath(path);
    
    final patternPaint = Paint()..color = kPlantDark.withOpacity(0.7)..strokeWidth = 1.0;
    final double step = 20 * math.min(sx, sy);
    
    // Get path bounds to limit pattern loop
    final bounds = path.getBounds();
    
    for (double x = bounds.left; x < bounds.right; x += step) {
      for (double y = bounds.top; y < bounds.bottom; y += step) {
        // Offset pattern for checker effect
        final bool offset = ((x / step).floor() + (y / step).floor()) % 2 == 0;
        if (offset) {
           canvas.drawRect(
             Rect.fromLTWH(x + 5*sx, y + 5*sy, 8*sx, 8*sy), 
             patternPaint
           );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter old) =>
    old.hoveredSlug != hoveredSlug || old.selectedSlug != selectedSlug;
}
