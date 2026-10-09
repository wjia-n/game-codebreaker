import 'dart:math';
import 'package:flutter/material.dart';
import 'vault_themes.dart';

/// Detective's Vault design system — warm physical materials, serif display
/// type, brass accents. Pegs and board feel carved, lacquered, heavy.
class Vault {
  static const displayFont = 'serif';

  static TextStyle display(double size, {Color? color, VaultThemeDef? theme}) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Color(0xFF1A0F08), offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, VaultThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.ivory ?? const Color(0xFFF5EFE0),
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, VaultThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 0.8,
      );

  static ThemeData theme([VaultThemeDef? t]) {
    t ??= VaultThemes.byId('classic');
    final lightBg = t.id == 'ivory' || t.id == 'honey' || t.id == 'sandstone';
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.woodDark,
      colorScheme: ColorScheme(
        brightness: lightBg ? Brightness.light : Brightness.dark,
        primary: t.accent,
        onPrimary: t.woodDeep,
        secondary: t.accentLight,
        onSecondary: t.woodDeep,
        surface: t.woodMid,
        onSurface: t.ivory,
        error: t.pegColors[0],
        onError: t.ivory,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.woodMid),
    );
  }
}

/// Walnut wood-grain background with warm vignette, theme-aware.
class WoodBackdrop extends StatelessWidget {
  final Widget child;
  final VaultThemeDef? theme;
  const WoodBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? VaultThemes.byId('classic');
    return Container(
      decoration: BoxDecoration(color: t.woodDark),
      child: CustomPaint(
        painter: _WoodGrainPainter(t),
        child: child,
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  final VaultThemeDef t;
  _WoodGrainPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Warm top-light vignette.
    final vignette = RadialGradient(
      center: const Alignment(0, -0.25),
      radius: 1.15,
      colors: [
        t.woodMid.withValues(alpha: 0.55),
        t.woodDark.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: 0.5),
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette.createShader(Offset.zero & size),
    );
    // Long horizontal grain strokes.
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rnd = Random(7);
    for (int i = 0; i < 26; i++) {
      final y = rnd.nextDouble() * size.height;
      final path = Path()..moveTo(-20, y);
      for (double x = 0; x <= size.width + 20; x += 60) {
        path.quadraticBezierTo(
          x + 30,
          y + (rnd.nextDouble() - 0.5) * 26,
          x + 60,
          y + (rnd.nextDouble() - 0.5) * 12,
        );
      }
      grain.color = (rnd.nextBool() ? t.woodDeep : t.woodMid)
          .withValues(alpha: 0.28);
      canvas.drawPath(path, grain);
    }
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter old) => old.t != t;
}

/// Big wooden plaque button with brass rim.
class VaultButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VaultThemeDef theme;
  final double width;
  final double fontSize;
  const VaultButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    this.width = 240,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.accent.withValues(alpha: 0.95), theme.accentDark],
          ),
          border: Border.all(color: theme.accentLight, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Vault.label(fontSize, theme: theme, color: theme.woodDeep),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Card: carved wooden panel with brass border.
class VaultCard extends StatelessWidget {
  final VaultThemeDef theme;
  final String title;
  final Widget child;
  const VaultCard({
    super.key,
    required this.theme,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.woodMid.withValues(alpha: 0.9),
            theme.woodDeep.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: theme.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: Vault.display(20, theme: theme)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// A physical lacquered peg, drawn in the active peg style.
class Peg extends StatelessWidget {
  final Color color;
  final int style;
  final double size;
  final bool empty;
  final VaultThemeDef theme;
  const Peg({
    super.key,
    required this.color,
    required this.style,
    required this.size,
    required this.theme,
    this.empty = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PegPainter(
          color: color,
          style: style,
          empty: empty,
          hole: theme.holeDark,
          rim: theme.accent,
        ),
      ),
    );
  }
}

class _PegPainter extends CustomPainter {
  final Color color;
  final int style;
  final bool empty;
  final Color hole;
  final Color rim;
  _PegPainter({
    required this.color,
    required this.style,
    required this.empty,
    required this.hole,
    required this.rim,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    if (empty) {
      // Drilled socket: dark hole with carved rim.
      canvas.drawCircle(c, r, Paint()..color = hole);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.14
          ..color = rim.withValues(alpha: 0.45),
      );
      canvas.drawCircle(
        c + Offset(-r * 0.25, -r * 0.25),
        r * 0.5,
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );
      return;
    }
    final body = Rect.fromCircle(center: c, radius: r * 0.92);
    switch (style) {
      case 1: // Marble: base + veins.
        canvas.drawCircle(c, r * 0.92,
            Paint()..color = Color.lerp(color, Colors.white, 0.35)!);
        final vein = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.07
          ..color = color.withValues(alpha: 0.65);
        canvas.drawArc(body, 0.4, 1.6, false, vein);
        canvas.drawArc(body, 2.6, 1.1, false, vein);
        canvas.drawArc(body, 4.4, 1.4, false, vein);
        break;
      case 2: // Gem: faceted polygon.
        final path = Path();
        for (int i = 0; i < 8; i++) {
          final a = i * pi / 4;
          final p = c + Offset(cos(a), sin(a)) * r * 0.92;
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, Paint()..color = color);
        for (int i = 0; i < 8; i += 2) {
          final a = i * pi / 4;
          canvas.drawLine(
            c,
            c + Offset(cos(a), sin(a)) * r * 0.92,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.06
              ..color = Colors.white.withValues(alpha: 0.5),
          );
        }
        break;
      case 3: // Turned Wood: lathe rings.
        canvas.drawCircle(c, r * 0.92, Paint()..color = color);
        for (int i = 0; i < 4; i++) {
          canvas.drawCircle(
            c,
            r * (0.75 - i * 0.16),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.06
              ..color = Colors.black.withValues(alpha: 0.3),
          );
        }
        break;
      case 4: // Brass Stud: metallic dome with screw slots.
        final metal = RadialGradient(colors: [
          Color.lerp(color, Colors.white, 0.55)!,
          color,
          Color.lerp(color, Colors.black, 0.45)!,
        ]);
        canvas.drawCircle(
            c, r * 0.92, Paint()..shader = metal.createShader(body));
        canvas.drawLine(
          c + Offset(-r * 0.4, 0),
          c + Offset(r * 0.4, 0),
          Paint()
            ..strokeWidth = r * 0.1
            ..color = Colors.black.withValues(alpha: 0.5),
        );
        break;
      case 5: // Pearl: pearlescent sheen.
        canvas.drawCircle(c, r * 0.92,
            Paint()..color = Color.lerp(color, Colors.white, 0.55)!);
        final sheen = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.0),
          ],
        );
        canvas.drawCircle(
            c, r * 0.92, Paint()..shader = sheen.createShader(body));
        break;
      case 6: // Jade Carved: dark swirl.
        canvas.drawCircle(c, r * 0.92, Paint()..color = color);
        final swirl = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(color, Colors.black, 0.35)!;
        canvas.drawArc(body, 0.2, 2.4, false, swirl);
        canvas.drawArc(
            Rect.fromCircle(center: c, radius: r * 0.55), 3.4, 2.0, false,
            swirl);
        break;
      case 7: // Obsidian: glassy black sheen over the color.
        canvas.drawCircle(
            c, r * 0.92, Paint()..color = Color.lerp(color, Colors.black, 0.55)!);
        final gloss = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.05),
          ],
        );
        canvas.drawCircle(
            c, r * 0.92, Paint()..shader = gloss.createShader(body));
        break;
      default: // 0 Classic: lacquered dome with top-left light.
        final lacquer = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [
            Color.lerp(color, Colors.white, 0.5)!,
            color,
            Color.lerp(color, Colors.black, 0.4)!,
          ],
        );
        canvas.drawCircle(
            c, r * 0.92, Paint()..shader = lacquer.createShader(body));
    }
    // Universal top-left highlight + drop shadow for weight.
    canvas.drawCircle(
      c + Offset(-r * 0.3, -r * 0.32),
      r * 0.24,
      Paint()..color = Colors.white.withValues(alpha: style == 0 ? 0.55 : 0.3),
    );
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08
        ..color = Colors.black.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _PegPainter old) =>
      old.color != color ||
      old.style != style ||
      old.empty != empty ||
      old.hole != hole ||
      old.rim != rim;
}

/// Small feedback pin: black = right color right place, white = right color
/// wrong place. [kind]: 0 none, 1 black, 2 white.
class FeedbackPin extends StatelessWidget {
  final int kind;
  final double size;
  final VaultThemeDef theme;
  const FeedbackPin(
      {super.key, required this.kind, required this.size, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PinPainter(kind: kind, hole: theme.holeDark),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final int kind;
  final Color hole;
  _PinPainter({required this.kind, required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    if (kind == 0) {
      canvas.drawCircle(c, r * 0.9, Paint()..color = hole);
      return;
    }
    final col = kind == 1 ? const Color(0xFF141414) : const Color(0xFFF5F0E2);
    final g = RadialGradient(
      center: const Alignment(-0.35, -0.4),
      radius: 1.1,
      colors: [
        Color.lerp(col, Colors.white, kind == 1 ? 0.25 : 0.4)!,
        col,
        Color.lerp(col, Colors.black, 0.35)!,
      ],
    );
    canvas.drawCircle(
        c, r * 0.9, Paint()..shader = g.createShader(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..color = Colors.black.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) =>
      old.kind != kind || old.hole != hole;
}
