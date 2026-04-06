import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

// ═══════════════════════════════════════════════════════════════
//  3D VEHICLE ILLUSTRATION PAINTERS
// ═══════════════════════════════════════════════════════════════

/// Base class for all 3D vehicle painters
abstract class Vehicle3DPainter extends CustomPainter {
  final Color mainColor;
  final Color darkColor;
  final Color lightColor;
  final Color bodyColor;

  Vehicle3DPainter({
    required this.mainColor,
    required this.darkColor,
    required this.lightColor,
    required this.bodyColor,
  });

  void draw3DShadow(Canvas canvas, Offset center, double width, double height) {
    final safeW = width.clamp(10.0, 500.0);
    final safeH = height.clamp(2.0, 100.0);
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(3, 5), width: safeW, height: safeH * 0.15),
        const Radius.circular(8),
      ),
      shadowPaint,
    );
  }

  void drawWheel(Canvas canvas, Offset center, double radius, {bool isFront = false}) {
    final r = radius.clamp(3.0, 50.0);
    // Tire
    final tirePaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, tirePaint);

    // Tire tread ring
    final treadPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.2;
    canvas.drawCircle(center, r * 0.75, treadPaint);

    // Hub
    final hubPaint = Paint()
      ..color = const Color(0xFFC0C0C0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * 0.5, hubPaint);

    // Hub shine
    final hubShine = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(-r * 0.15, -r * 0.15), r * 0.2, hubShine);

    // Axle bolt pattern
    for (var i = 0; i < 5; i++) {
      final angle = (i * 72) * math.pi / 180;
      final boltCenter = center.translate(
        math.cos(angle) * r * 0.3,
        math.sin(angle) * r * 0.3,
      );
      canvas.drawCircle(boltCenter, r * 0.06, Paint()..color = const Color(0xFF666666));
    }
  }

  void drawGlass(Canvas canvas, Rect rect, {double opacity = 0.6}) {
    if (rect.width < 1 || rect.height < 1) return;
    final safeOpacity = opacity.clamp(0.0, 1.0);
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF87CEEB).withOpacity(safeOpacity),
          const Color(0xFF4A90D9).withOpacity((safeOpacity + 0.15).clamp(0.0, 1.0)),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), glassPaint);

    // Glass reflection
    final reflRect = Rect.fromLTRB(rect.left + 2, rect.top + 2, rect.left + rect.width * 0.4, rect.top + rect.height * 0.6);
    if (reflRect.width > 0 && reflRect.height > 0) {
      final reflPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawRect(reflRect, reflPaint);
    }
  }

  void drawHeadlight(Canvas canvas, Offset center, double size) {
    final safeSize = size.clamp(2.0, 100.0);
    final shaderRect = Rect.fromCenter(center: center, width: safeSize, height: safeSize);
    final hlPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1,
        colors: [Colors.yellow.shade200, Colors.yellow.shade50.withOpacity(0.5)],
      ).createShader(shaderRect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, safeSize / 2, hlPaint);

    // Glow
    final glowPaint = Paint()
      ..color = Colors.yellow.shade100.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, safeSize * 0.8, glowPaint);
  }

  void drawTaillight(Canvas canvas, Offset center, double size) {
    final safeSize = size.clamp(2.0, 100.0);
    final shaderRect = Rect.fromCenter(center: center, width: safeSize, height: safeSize);
    final tlPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1,
        colors: [Colors.red.shade400, Colors.red.shade700],
      ).createShader(shaderRect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, safeSize / 2, tlPaint);
  }

  Color get vehicleBodyPaint => bodyColor;
}

/// Jumbo Truck (عربيه نقل جامبو) - Large container truck
class JumboTruckPainter extends Vehicle3DPainter {
  JumboTruckPainter({
    required super.mainColor,
    required super.darkColor,
    required super.lightColor,
    required super.bodyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 280;

    draw3DShadow(canvas, Offset(cx, cy + 40 * scale), 240 * scale, 20 * scale);

    // ── Container body ──
    final containerRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx + 10 * scale, cy - 15 * scale), width: 160 * scale, height: 65 * scale),
      bottomRight: const Radius.circular(3),
      bottomLeft: const Radius.circular(3),
    );
    final containerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightColor, mainColor, darkColor],
      ).createShader(containerRect.outerRect);
    canvas.drawRRect(containerRect, containerPaint);

    // Container highlight line
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.5 * scale;
    canvas.drawLine(
      Offset((cx - 70) * scale, (cy - 47) * scale),
      Offset((cx + 90) * scale, (cy - 47) * scale),
      linePaint,
    );

    // Container ridges
    final ridgePaint = Paint()
      ..color = darkColor.withOpacity(0.4)
      ..strokeWidth = 0.8 * scale;
    for (var i = 0; i < 5; i++) {
      final x = (cx - 50 + i * 30) * scale;
      canvas.drawLine(Offset(x, (cy - 47) * scale), Offset(x, (cy + 17) * scale), ridgePaint);
    }

    // ── Cab ──
    final cabRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx - 85 * scale, cy - 8 * scale), width: 45 * scale, height: 55 * scale),
      topLeft: const Radius.circular(8),
      bottomLeft: const Radius.circular(4),
    );
    final cabPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightColor.withOpacity(0.9), mainColor, darkColor],
      ).createShader(cabRect.outerRect);
    canvas.drawRRect(cabRect, cabPaint);

    // Cab windshield
    drawGlass(canvas, Rect.fromLTRB(
      (cx - 105) * scale, (cy - 30) * scale,
      (cx - 78) * scale, (cy - 5) * scale,
    ));

    // Cab side window
    drawGlass(canvas, Rect.fromLTRB(
      (cx - 105) * scale, (cy - 2) * scale,
      (cx - 80) * scale, (cy + 10) * scale,
    ), opacity: 0.4);

    // Headlight
    drawHeadlight(canvas, Offset((cx - 107) * scale, cy * scale), 10 * scale);

    // Taillight
    drawTaillight(canvas, Offset((cx + 90) * scale, cy * scale), 7 * scale);

    // ── Undercarriage ──
    final chassisPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + 25 * scale), width: 190 * scale, height: 6 * scale),
      chassisPaint,
    );

    // ── Wheels ──
    drawWheel(canvas, Offset((cx - 80) * scale, (cy + 32) * scale), 14 * scale, isFront: true);
    drawWheel(canvas, Offset((cx - 55) * scale, (cy + 32) * scale), 14 * scale);

    // Rear dual wheels
    drawWheel(canvas, Offset((cx + 65) * scale, (cy + 32) * scale), 14 * scale);
    drawWheel(canvas, Offset((cx + 85) * scale, (cy + 32) * scale), 14 * scale);

    // Mud flaps
    final mudPaint = Paint()..color = const Color(0xFF222222);
    canvas.drawRect(
      Rect.fromCenter(center: Offset((cx - 47) * scale, cy * scale + 37 * scale), width: 3 * scale, height: 10 * scale),
      mudPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset((cx + 95) * scale, cy * scale + 37 * scale), width: 3 * scale, height: 10 * scale),
      mudPaint,
    );

    // Cargo capacity indicator bar
    final barPaint = Paint()..color = Colors.white.withOpacity(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 10 * scale, (cy - 32) * scale), width: 140 * scale, height: 3 * scale),
        const Radius.circular(2),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant Vehicle3DPainter oldDelegate) => true;
}

/// Half Truck (عربيه نص نقل / دبابة) - Medium flatbed truck
class HalfTruckPainter extends Vehicle3DPainter {
  HalfTruckPainter({
    required super.mainColor,
    required super.darkColor,
    required super.lightColor,
    required super.bodyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 280;

    draw3DShadow(canvas, Offset(cx, cy + 35 * scale), 200 * scale, 20 * scale);

    // ── Flatbed body ──
    final bedRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx + 5 * scale, cy - 10 * scale), width: 130 * scale, height: 45 * scale),
      topRight: const Radius.circular(2),
      bottomRight: const Radius.circular(3),
    );
    final bedPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightColor, mainColor, darkColor],
      ).createShader(bedRect.outerRect);
    canvas.drawRRect(bedRect, bedPaint);

    // Flatbed side rails
    final railPaint = Paint()
      ..color = darkColor
      ..strokeWidth = 3 * scale;
    canvas.drawLine(
      Offset((cx + 70) * scale, (cy - 32) * scale),
      Offset((cx + 70) * scale, (cy + 12) * scale),
      railPaint,
    );

    // Side rail details
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset((cx + 10 + i * 25) * scale, (cy - 32) * scale),
        Offset((cx + 10 + i * 25) * scale, (cy - 25) * scale),
        railPaint,
      );
    }

    // ── Cab ──
    final cabRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx - 75 * scale, cy - 8 * scale), width: 40 * scale, height: 48 * scale),
      topLeft: const Radius.circular(8),
      bottomLeft: const Radius.circular(4),
    );
    final cabPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightColor.withOpacity(0.9), mainColor, darkColor],
      ).createShader(cabRect.outerRect);
    canvas.drawRRect(cabRect, cabPaint);

    // Windshield
    drawGlass(canvas, Rect.fromLTRB(
      (cx - 94) * scale, (cy - 28) * scale,
      (cx - 68) * scale, (cy - 5) * scale,
    ));

    // Side window
    drawGlass(canvas, Rect.fromLTRB(
      (cx - 94) * scale, (cy) * scale,
      (cx - 72) * scale, (cy + 10) * scale,
    ), opacity: 0.4);

    // Headlight
    drawHeadlight(canvas, Offset((cx - 95) * scale, cy * scale), 8 * scale);

    // Taillight
    drawTaillight(canvas, Offset((cx + 70) * scale, cy * scale), 6 * scale);

    // ── Chassis ──
    final chassisPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx - 5 * scale, cy + 20 * scale), width: 150 * scale, height: 5 * scale),
      chassisPaint,
    );

    // ── Wheels ──
    drawWheel(canvas, Offset((cx - 72) * scale, (cy + 28) * scale), 13 * scale, isFront: true);
    drawWheel(canvas, Offset((cx - 50) * scale, (cy + 28) * scale), 13 * scale);
    drawWheel(canvas, Offset((cx + 50) * scale, (cy + 28) * scale), 13 * scale);

    // Load indicator
    final loadPaint = Paint()..color = Colors.white.withOpacity(0.3);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset((cx + 10 + i * 22) * scale, (cy - 5) * scale), width: 16 * scale, height: 20 * scale),
        loadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant Vehicle3DPainter oldDelegate) => true;
}

/// Bus (أتوبيسات) - Passenger bus
class BusPainter extends Vehicle3DPainter {
  BusPainter({
    required super.mainColor,
    required super.darkColor,
    required super.lightColor,
    required super.bodyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 280;

    draw3DShadow(canvas, Offset(cx, cy + 38 * scale), 210 * scale, 20 * scale);

    // ── Bus body ──
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, cy - 5 * scale), width: 200 * scale, height: 65 * scale),
      topLeft: const Radius.circular(12),
      bottomLeft: const Radius.circular(4),
      topRight: const Radius.circular(12),
      bottomRight: const Radius.circular(4),
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightColor, mainColor, darkColor],
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Stripe decoration
    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 4 * scale;
    canvas.drawLine(
      Offset((cx - 95) * scale, (cy + 5) * scale),
      Offset((cx + 95) * scale, (cy + 5) * scale),
      stripePaint,
    );

    // Top highlight
    final topLine = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 2 * scale;
    canvas.drawLine(
      Offset((cx - 90) * scale, (cy - 35) * scale),
      Offset((cx + 90) * scale, (cy - 35) * scale),
      topLine,
    );

    // ── Windshield ──
    drawGlass(canvas, Rect.fromLTRB(
      (cx - 98) * scale, (cy - 30) * scale,
      (cx - 70) * scale, (cy + 0) * scale,
    ));

    // Rear window
    drawGlass(canvas, Rect.fromLTRB(
      (cx + 75) * scale, (cy - 28) * scale,
      (cx + 95) * scale, (cy + 0) * scale,
    ), opacity: 0.4);

    // Side windows
    for (var i = 0; i < 5; i++) {
      drawGlass(canvas, Rect.fromLTRB(
        (cx - 60 + i * 28) * scale, (cy - 28) * scale,
        (cx - 38 + i * 28) * scale, (cy + 0) * scale,
      ), opacity: 0.5);
    }

    // ── Destination display ──
    final dispPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 15 * scale, (cy - 35) * scale), width: 80 * scale, height: 8 * scale),
        const Radius.circular(3),
      ),
      dispPaint,
    );
    // Route text effect
    final textPaint = Paint()..color = Colors.green.shade400;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx - 15 * scale, (cy - 35) * scale), width: 70 * scale, height: 4 * scale),
      textPaint,
    );

    // ── Headlight ──
    drawHeadlight(canvas, Offset((cx - 99) * scale, cy * scale), 8 * scale);

    // ── Taillight ──
    drawTaillight(canvas, Offset((cx + 99) * scale, cy * scale), 7 * scale);

    // ── Door ──
    final doorPaint = Paint()
      ..color = darkColor.withOpacity(0.5)
      ..strokeWidth = 1 * scale
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB((cx - 65) * scale, (cy - 2) * scale, (cx - 40) * scale, (cy + 25) * scale),
        const Radius.circular(2),
      ),
      doorPaint,
    );

    // ── Chassis ──
    final chassisPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + 28) * scale / 1, width: 185 * scale, height: 5 * scale),
      chassisPaint,
    );

    // ── Wheels ──
    drawWheel(canvas, Offset((cx - 75) * scale, (cy + 35) * scale), 14 * scale, isFront: true);
    drawWheel(canvas, Offset((cx - 50) * scale, (cy + 35) * scale), 14 * scale);
    drawWheel(canvas, Offset((cx + 60) * scale, (cy + 35) * scale), 14 * scale);
    drawWheel(canvas, Offset((cx + 85) * scale, (cy + 35) * scale), 14 * scale);

    // Passenger silhouettes in windows
    final silPaint = Paint()..color = const Color(0xFF1A1A1A).withOpacity(0.15);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset((cx - 45 + i * 28) * scale, (cy - 22) * scale), 4 * scale, silPaint);
    }
  }

  @override
  bool shouldRepaint(covariant Vehicle3DPainter oldDelegate) => true;
}

/// Microbus (ميكروباص) - Small van/minibus
class MicrobusPainter extends Vehicle3DPainter {
  MicrobusPainter({
    required super.mainColor,
    required super.darkColor,
    required super.lightColor,
    required super.bodyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 280;

    draw3DShadow(canvas, Offset(cx, cy + 32 * scale), 170 * scale, 20 * scale);

    // ── Van body ──
    final bodyPath = Path();
    final bw = 80 * scale;
    final bh = 50 * scale;
    final bodyLeft = cx - bw;
    final bodyTop = cy - bh * 0.7;
    bodyPath.moveTo(bodyLeft, cy + bh * 0.3); // bottom-left
    bodyPath.lineTo(bodyLeft, bodyTop + 8 * scale); // left side going up
    bodyPath.quadraticBezierTo(bodyLeft, bodyTop, bodyLeft + 10 * scale, bodyTop); // top-left corner
    bodyPath.lineTo(cx + bw - 10 * scale, bodyTop); // top edge
    bodyPath.quadraticBezierTo(cx + bw, bodyTop, cx + bw, bodyTop + 8 * scale); // top-right corner
    bodyPath.lineTo(cx + bw, cy + bh * 0.3); // right side down
    bodyPath.lineTo(cx + bw, cy + bh * 0.3 + 5 * scale); // bottom-right
    bodyPath.lineTo(bodyLeft, cy + bh * 0.3 + 5 * scale); // bottom edge
    bodyPath.close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightColor, mainColor, darkColor],
      ).createShader(Rect.fromLTRB(bodyLeft, bodyTop, cx + bw, cy + bh * 0.3 + 5 * scale));
    canvas.drawPath(bodyPath, bodyPaint);

    // Highlight stripe
    final stripe = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2.5 * scale;
    canvas.drawLine(
      Offset((cx - 78) * scale, (cy - 10) * scale),
      Offset((cx + 78) * scale, (cy - 10) * scale),
      stripe,
    );

    // ── Windshield ──
    drawGlass(canvas, Rect.fromLTRB(
      (cx - 78) * scale, (cy - 30) * scale,
      (cx - 55) * scale, (cy - 5) * scale,
    ));

    // Side windows
    for (var i = 0; i < 4; i++) {
      drawGlass(canvas, Rect.fromLTRB(
        (cx - 45 + i * 26) * scale, (cy - 30) * scale,
        (cx - 25 + i * 26) * scale, (cy - 5) * scale,
      ), opacity: 0.45);
    }

    // Headlight
    drawHeadlight(canvas, Offset((cx - 80) * scale, (cy - 5) * scale), 7 * scale);

    // Taillight
    drawTaillight(canvas, Offset((cx + 80) * scale, (cy - 5) * scale), 6 * scale);

    // ── Chassis ──
    final chassisPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, (cy + 18) * scale), width: 155 * scale, height: 5 * scale),
      chassisPaint,
    );

    // ── Wheels ──
    drawWheel(canvas, Offset((cx - 60) * scale, (cy + 26) * scale), 12 * scale, isFront: true);
    drawWheel(canvas, Offset((cx + 55) * scale, (cy + 26) * scale), 12 * scale);

    // Roof rack
    final rackPaint = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 1.5 * scale;
    canvas.drawLine(
      Offset((cx - 55) * scale, (cy - 33) * scale),
      Offset((cx + 55) * scale, (cy - 33) * scale),
      rackPaint,
    );
    canvas.drawLine(Offset((cx - 40) * scale, (cy - 33) * scale), Offset((cx - 40) * scale, (cy - 36) * scale), rackPaint);
    canvas.drawLine(Offset((cx) * scale, (cy - 33) * scale), Offset((cx) * scale, (cy - 36) * scale), rackPaint);
    canvas.drawLine(Offset((cx + 40) * scale, (cy - 33) * scale), Offset((cx + 40) * scale, (cy - 36) * scale), rackPaint);
  }

  @override
  bool shouldRepaint(covariant Vehicle3DPainter oldDelegate) => true;
}

/// Double Cabin (عربيه دبل كابينه) - Pickup truck with double cabin
class DoubleCabinPainter extends Vehicle3DPainter {
  DoubleCabinPainter({
    required super.mainColor,
    required super.darkColor,
    required super.lightColor,
    required super.bodyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 280;

    draw3DShadow(canvas, Offset(cx, cy + 30 * scale), 180 * scale, 20 * scale);

    // ── Truck bed ──
    final bedRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx + 40 * scale, cy - 5 * scale), width: 70 * scale, height: 38 * scale),
      topRight: const Radius.circular(4),
      bottomRight: const Radius.circular(3),
    );
    final bedPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightColor, mainColor, darkColor],
      ).createShader(bedRect.outerRect);
    canvas.drawRRect(bedRect, bedPaint);

    // Bed side wall top rail
    final railPaint = Paint()
      ..color = darkColor
      ..strokeWidth = 3 * scale;
    canvas.drawLine(
      Offset((cx + 75) * scale, (cy - 23) * scale),
      Offset((cx + 75) * scale, (cy + 12) * scale),
      railPaint,
    );

    // Bed inner shadow
    final innerPaint = Paint()
      ..color = const Color(0xFF333333).withOpacity(0.3);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx + 40 * scale, (cy - 2) * scale), width: 64 * scale, height: 28 * scale),
      innerPaint,
    );

    // ── Double cab ──
    final cabRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx - 30 * scale, cy - 8 * scale), width: 75 * scale, height: 50 * scale),
      topLeft: const Radius.circular(10),
      bottomLeft: const Radius.circular(4),
    );
    final cabPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightColor, mainColor, darkColor],
      ).createShader(cabRect.outerRect);
    canvas.drawRRect(cabRect, cabPaint);

    // ── Windshield ──
    drawGlass(canvas, Rect.fromLTRB(
      (cx - 67) * scale, (cy - 28) * scale,
      (cx - 40) * scale, (cy - 5) * scale,
    ));

    // ── Rear window ──
    drawGlass(canvas, Rect.fromLTRB(
      (cx + 2) * scale, (cy - 25) * scale,
      (cx + 15) * scale, (cy - 5) * scale),
    opacity: 0.35,
    );

    // Door line
    final doorPaint = Paint()
      ..color = darkColor.withOpacity(0.3)
      ..strokeWidth = 1 * scale;
    canvas.drawLine(
      Offset((cx - 30) * scale, (cy - 30) * scale),
      Offset((cx - 30) * scale, (cy + 14) * scale),
      doorPaint,
    );

    // Headlight
    drawHeadlight(canvas, Offset((cx - 68) * scale, cy * scale), 8 * scale);

    // Taillight
    drawTaillight(canvas, Offset((cx + 75) * scale, cy * scale), 6 * scale);

    // ── Chassis ──
    final chassisPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + 20) * scale / 1, width: 145 * scale, height: 5 * scale),
      chassisPaint,
    );

    // ── Wheels ──
    drawWheel(canvas, Offset((cx - 55) * scale, (cy + 28) * scale), 13 * scale, isFront: true);
    drawWheel(canvas, Offset((cx + 50) * scale, (cy + 28) * scale), 13 * scale);

    // Step bar
    final stepPaint = Paint()
      ..color = const Color(0xFF999999)
      ..strokeWidth = 2 * scale;
    canvas.drawLine(
      Offset((cx - 45) * scale, (cy + 15) * scale),
      Offset((cx - 15) * scale, (cy + 15) * scale),
      stepPaint,
    );

    // Side mirror
    canvas.drawCircle(Offset((cx - 70) * scale, (cy - 12) * scale), 3 * scale, Paint()..color = darkColor);
  }

  @override
  bool shouldRepaint(covariant Vehicle3DPainter oldDelegate) => true;
}

/// Forklift (كلارك) - Industrial forklift
class ForkliftPainter extends Vehicle3DPainter {
  ForkliftPainter({
    required super.mainColor,
    required super.darkColor,
    required super.lightColor,
    required super.bodyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 280;

    draw3DShadow(canvas, Offset(cx + 10 * scale, cy + 40 * scale), 160 * scale, 20 * scale);

    // ── Counterweight (rear) ──
    final counterRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx + 60 * scale, cy - 8 * scale), width: 30 * scale, height: 50 * scale),
      topLeft: const Radius.circular(6),
      bottomLeft: const Radius.circular(4),
    );
    final counterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkColor, const Color(0xFF444444)],
      ).createShader(counterRect.outerRect);
    canvas.drawRRect(counterRect, counterPaint);

    // ── Main body ──
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx + 10 * scale, cy - 12 * scale), width: 60 * scale, height: 55 * scale),
      topLeft: const Radius.circular(8),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.yellow.shade400, Colors.yellow.shade600, Colors.orange.shade700],
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Safety stripe
    final stripePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 4 * scale;
    canvas.drawLine(
      Offset((cx - 15) * scale, (cy - 5) * scale),
      Offset((cx + 35) * scale, (cy - 5) * scale),
      stripePaint,
    );

    // ── Overhead guard ──
    final guardPaint = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 3 * scale;
    // Vertical posts
    canvas.drawLine(
      Offset((cx - 20) * scale, (cy - 38) * scale),
      Offset((cx - 20) * scale, (cy - 15) * scale),
      guardPaint,
    );
    // Horizontal bar
    canvas.drawLine(
      Offset((cx - 20) * scale, (cy - 38) * scale),
      Offset((cx + 40) * scale, (cy - 38) * scale),
      guardPaint,
    );
    canvas.drawLine(
      Offset((cx - 20) * scale, (cy - 30) * scale),
      Offset((cx + 40) * scale, (cy - 30) * scale),
      guardPaint,
    );

    // ── Mast (vertical fork guide) ──
    final mastPaint = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 6 * scale;
    canvas.drawLine(
      Offset((cx - 25) * scale, (cy - 45) * scale),
      Offset((cx - 25) * scale, (cy + 18) * scale),
      mastPaint,
    );

    // Mast cross bars
    for (var i = 0; i < 3; i++) {
      final barPaint = Paint()
        ..color = const Color(0xFF888888)
        ..strokeWidth = 2 * scale;
      canvas.drawLine(
        Offset((cx - 28) * scale, (cy - 35 + i * 18) * scale),
        Offset((cx - 22) * scale, (cy - 35 + i * 18) * scale),
        barPaint,
      );
    }

    // ── Forks ──
    final forkPaint = Paint()
      ..color = const Color(0xFFC0C0C0)
      ..strokeWidth = 3.5 * scale
      ..strokeCap = StrokeCap.round;
    // Top fork
    canvas.drawLine(
      Offset((cx - 28) * scale, (cy - 10) * scale),
      Offset((cx - 70) * scale, (cy - 10) * scale),
      forkPaint,
    );
    // Bottom fork
    canvas.drawLine(
      Offset((cx - 28) * scale, (cy + 2) * scale),
      Offset((cx - 70) * scale, (cy + 2) * scale),
      forkPaint,
    );
    // Fork tips (curved up)
    final tipPaint = Paint()
      ..color = const Color(0xFFC0C0C0)
      ..strokeWidth = 3 * scale;
    canvas.drawArc(
      Rect.fromCenter(center: Offset((cx - 70) * scale, (cy - 10) * scale), width: 8 * scale, height: 8 * scale),
      math.pi * 0.5,
      math.pi,
      false,
      tipPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset((cx - 70) * scale, (cy + 2) * scale), width: 8 * scale, height: 8 * scale),
      math.pi * 0.5,
      math.pi,
      false,
      tipPaint,
    );

    // ── Steering wheel area ──
    drawGlass(canvas, Rect.fromLTRB(
      (cx - 5) * scale, (cy - 30) * scale,
      (cx + 25) * scale, (cy - 12) * scale,
    ), opacity: 0.5);

    // ── Chassis ──
    final chassisPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx + 15 * scale, (cy + 20) * scale), width: 90 * scale, height: 6 * scale),
      chassisPaint,
    );

    // ── Wheels ──
    drawWheel(canvas, Offset((cx + 65) * scale, (cy + 28) * scale), 14 * scale, isFront: true);
    drawWheel(canvas, Offset((cx + 45) * scale, (cy + 28) * scale), 11 * scale);

    // Small front wheel
    final smallWheel = Paint()..color = const Color(0xFF2D2D2D);
    canvas.drawCircle(Offset((cx - 45) * scale, (cy + 22) * scale), 5 * scale, smallWheel);
    canvas.drawCircle(Offset((cx - 45) * scale, (cy + 22) * scale), 2.5 * scale, Paint()..color = const Color(0xFFC0C0C0));

    // Load on forks
    final loadPaint = Paint()..color = const Color(0xFF8B4513).withOpacity(0.6);
    canvas.drawRect(
      Rect.fromCenter(center: Offset((cx - 55) * scale, (cy - 15) * scale), width: 25 * scale, height: 20 * scale),
      loadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant Vehicle3DPainter oldDelegate) => true;
}


// ═══════════════════════════════════════════════════════════════
//  3D INTERACTIVE VEHICLE CARD
// ═══════════════════════════════════════════════════════════════

class Vehicle3DCard extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMaintenance;

  const Vehicle3DCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onMaintenance,
  });

  @override
  State<Vehicle3DCard> createState() => _Vehicle3DCardState();
}

class _Vehicle3DCardState extends State<Vehicle3DCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _shadowAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _shadowAnim = Tween<double>(begin: 12.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() => _isPressed = false);
    onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  void onTap() {
    widget.onTap?.call();
  }

  Color get _typeColor {
    if (widget.vehicle.vehicleType != null && widget.vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypeColors[widget.vehicle.vehicleType] ?? AppColors.primary;
    }
    return AppColors.primary;
  }

  String get _typeLabel {
    if (widget.vehicle.vehicleType != null && widget.vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypes[widget.vehicle.vehicleType] ?? '';
    }
    return '';
  }

  IconData get _typeIcon {
    if (widget.vehicle.vehicleType != null && widget.vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypeIcons[widget.vehicle.vehicleType] ?? Icons.directions_car;
    }
    return Icons.directions_car;
  }

  Color get _statusColor =>
      AppConstants.vehicleStatusColors[widget.vehicle.status] ?? AppColors.textSecondary;

  String get _statusLabel =>
      AppConstants.vehicleStatuses[widget.vehicle.status] ?? '';

  Vehicle3DPainter _getPainter() {
    final c = _typeColor;
    final light = Color.lerp(c, Colors.white, 0.35) ?? c;
    final dark = Color.lerp(c, Colors.black, 0.3) ?? c;
    return switch (widget.vehicle.vehicleType) {
      'jumbo_truck' => JumboTruckPainter(
        mainColor: c, darkColor: dark, lightColor: light, bodyColor: c),
      'half_truck' => HalfTruckPainter(
        mainColor: c, darkColor: dark, lightColor: light, bodyColor: c),
      'bus' => BusPainter(
        mainColor: c, darkColor: dark, lightColor: light, bodyColor: c),
      'microbus' => MicrobusPainter(
        mainColor: c, darkColor: dark, lightColor: light, bodyColor: c),
      'double_cabin' => DoubleCabinPainter(
        mainColor: c, darkColor: dark, lightColor: light, bodyColor: c),
      'forklift' => ForkliftPainter(
        mainColor: Colors.yellow.shade600, darkColor: Colors.orange.shade800, lightColor: Colors.yellow.shade300, bodyColor: Colors.yellow.shade600),
      _ => HalfTruckPainter(
        mainColor: c, darkColor: dark, lightColor: light, bodyColor: c),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _typeColor.withOpacity(0.15),
                  blurRadius: _shadowAnim.value,
                  offset: Offset(0, _shadowAnim.value * 0.4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: _shadowAnim.value,
                  offset: Offset(0, _shadowAnim.value * 0.2),
                ),
              ],
            ),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              elevation: _isPressed ? 2 : 6,
              child: InkWell(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // ── 3D Vehicle Illustration Area ──
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _typeColor.withOpacity(0.08),
                            _typeColor.withOpacity(0.03),
                            AppColors.surface,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Stack(
                        children: [
                          // Grid pattern background
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GridPainter(color: _typeColor.withOpacity(0.06)),
                            ),
                          ),
                          // Vehicle 3D illustration
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _getPainter(),
                            ),
                          ),
                          // Status badge (top-left)
                          Positioned(
                            top: 10,
                            right: 12,
                            child: _StatusBadge(
                              color: _statusColor,
                              label: _statusLabel,
                            ),
                          ),
                          // Type badge (top-right)
                          Positioned(
                            top: 10,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _typeColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _typeColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_typeIcon, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    _typeLabel,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Vehicle Info Section ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle name + plate
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.vehicle.displayName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        height: 1.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // Plate badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryContainer,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            widget.vehicle.plateNumber,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Color indicator
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: _getColorFromName(widget.vehicle.color),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.border, width: 1),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppConstants.vehicleColors[widget.vehicle.color.toLowerCase()] ?? widget.vehicle.color,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Actions menu
                              if (widget.onEdit != null || widget.onMaintenance != null)
                                _buildActionsMenu(),
                            ],
                          ),
                          // Driver info
                          if (widget.vehicle.hasDriver) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _typeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(Icons.person, size: 14, color: _typeColor),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.vehicle.driverDisplayName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.vehicle.driverPhone != null && widget.vehicle.driverPhone!.isNotEmpty)
                                    Icon(Icons.phone_outlined, size: 13, color: AppColors.textHint),
                                ],
                              ),
                            ),
                          ],
                          // Quick stats
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _QuickStat(
                                icon: Icons.speed,
                                label: 'العداد',
                                value: AppFormatters.formatOdometer(widget.vehicle.currentOdometer),
                                color: _typeColor,
                              ),
                              const SizedBox(width: 10),
                              _QuickStat(
                                icon: Icons.local_gas_station,
                                label: 'الوقود',
                                value: AppConstants.fuelTypes[widget.vehicle.fuelType] ?? '',
                                color: AppColors.accent,
                              ),
                              if (widget.vehicle.cargoCapacityTons != null) ...[
                                const SizedBox(width: 10),
                                _QuickStat(
                                  icon: Icons.inventory_2_outlined,
                                  label: 'حمولة',
                                  value: '${widget.vehicle.cargoCapacityTons} طن',
                                  color: AppColors.warning,
                                ),
                              ],
                              if (widget.vehicle.passengerCapacity != null) ...[
                                const SizedBox(width: 10),
                                _QuickStat(
                                  icon: Icons.airline_seat_recline_normal_outlined,
                                  label: 'ركاب',
                                  value: '${widget.vehicle.passengerCapacity}',
                                  color: AppColors.info,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textHint, size: 20),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'edit': widget.onEdit?.call();
          case 'maintenance': widget.onMaintenance?.call();
          case 'delete': widget.onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        if (widget.onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('تعديل'),
            ]),
          ),
        if (widget.onMaintenance != null)
          const PopupMenuItem(
            value: 'maintenance',
            child: Row(children: [
              Icon(Icons.build, size: 18, color: AppColors.accent),
              SizedBox(width: 8),
              Text('سجل الصيانة'),
            ]),
          ),
        if (widget.onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text('حذف', style: TextStyle(color: AppColors.error)),
            ]),
          ),
      ],
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white': return const Color(0xFFFFFFFF);
      case 'black': return const Color(0xFF1A1A1A);
      case 'silver': return const Color(0xFFC0C0C0);
      case 'gray': case 'grey': return const Color(0xFF808080);
      case 'red': return const Color(0xFFDC2626);
      case 'blue': return const Color(0xFF2563EB);
      case 'green': return const Color(0xFF16A34A);
      case 'brown': return const Color(0xFF78350F);
      case 'gold': return const Color(0xFFD4A017);
      case 'beige': return const Color(0xFFF5F5DC);
      default: return AppColors.primary;
    }
  }
}


// ═══════════════════════════════════════════════════════════════
//  SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    final spacing = 20.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _anim = Tween(begin: 1.0, end: 1.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 6 * _anim.value,
                spreadRadius: 2 * _anim.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHint,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
