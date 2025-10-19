// lib/widgets/ui_atoms.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Image réseau robuste
/// placeholder + pas d’exception en cas d’erreur
Widget netImage(String url, {BoxFit fit = BoxFit.cover}) {
  return Image.network(
    url,
    fit: fit,
    loadingBuilder: (c, w, ev) => Container(color: const Color(0x11000000)),
    errorBuilder: (c, err, st) {
      // helpful console hint while developing
      // ignore: avoid_print
      print(' WAIT netImage error for $url => $err');
      return Container(color: const Color(0x22000000));
    },
  );
}

/// Variante douce de la couleur primaire (pour les dégradés)
Color pairColor(Color c) {
  final hsl = HSLColor.fromColor(c);
  final shifted = hsl
      .withHue((hsl.hue + 30) % 360)
      .withSaturation((hsl.saturation + .1).clamp(0, 1))
      .withLightness((hsl.lightness + .05).clamp(0, 1));
  return shifted.toColor();
}

/// Carte “glass” (blur + transparence)
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 16,
    this.opacity = .08,
    this.blur = 18,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.25),
                blurRadius: 26,
                spreadRadius: -8,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Bordure dégradée + contenu en glass
class GlassGradientBorder extends StatelessWidget {
  const GlassGradientBorder({
    super.key,
    required this.child,
    required this.gradient,
    this.innerPadding = const EdgeInsets.all(24),
    this.radius = 18,
    this.opacity = .07,
    this.blur = 20,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsets innerPadding;
  final double radius;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: _GradientBorder(radius: radius, gradient: gradient),
      ),
      child: Glass(
        radius: radius,
        opacity: opacity,
        blur: blur,
        padding: innerPadding,
        child: child,
      ),
    );
  }
}

class _GradientBorder extends ShapeBorder {
  const _GradientBorder({required this.radius, required this.gradient, this.width = 1.2});
  final double radius;
  final Gradient gradient;
  final double width;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(width), Radius.circular(radius)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final r = RRect.fromRectAndRadius(rect.deflate(width / 2), Radius.circular(radius));
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawRRect(r, paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}

/// Badge icône circulaire avec dégradé
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.gradient});
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.35),
            blurRadius: 26,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black, size: 26),
    );
  }
}

/// Effet hover --> scale
class HoverScale extends StatefulWidget {
  const HoverScale({super.key, required this.child});
  final Widget child;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Effet hover --> élévation des box (categoryTile ..)
class HoverLift extends StatefulWidget {
  const HoverLift({super.key, required this.child});
  final Widget child;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()..translate(0.0, _hover ? -4.0 : 0.0),
        child: widget.child,
      ),
    );
  }
}

/// Texte avec dégradé
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, required this.gradient, required this.style});
  final String text;
  final Gradient gradient;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => gradient.createShader(r),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

/// AppBar effet 'glass'
class GlassBar extends StatelessWidget {
  const GlassBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.06),
            border: Border.all(color: Colors.white.withOpacity(.12)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ),
    );
  }
}


/// Fond animé + bruit optionnel (assets/images/noise.png)
class AnimatedBackdrop extends StatefulWidget {
  const AnimatedBackdrop({super.key});

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 22))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            // dégradé radial animé
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.6 - t * 0.4, -0.4 + t * 0.3),
                  radius: 1.2,
                  colors: [
                    pairColor(theme.primary).withOpacity(.25),
                    Colors.transparent,
                  ],
                  stops: const [.0, 1.0],
                ),
              ),
            ),
            // voile diagonal
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(.02),
                    Colors.white.withOpacity(.00),
                    Colors.white.withOpacity(.02),
                  ],
                  stops: const [0, .5, 1],
                ),
              ),
            ),
            // Fond effet mural
            IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 0.25, sigmaY: 0.25),
                child: Image.asset(
                  'assets/images/noises.jpg',
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(.06),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


// ---- Labeled Dropdown (label texte + vraie boîte de sélection) ----
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right:5),
          child: Text(
            label,
            style:
            theme.titleMedium.override(
              font: GoogleFonts.interTight(
                fontWeight: FontWeight.w300,
                fontStyle: theme
                    .bodySmall.fontStyle,
              ),
              fontSize: 16,
              color: theme.white,
              letterSpacing: .2,
            ),
          ),
        ),
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.bg,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: theme.primary.withOpacity(.15), width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(

              value: value,
              isDense: true,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              dropdownColor: theme.bg,
              style:
              theme.titleMedium.override(
                font: GoogleFonts.interTight(
                  fontWeight: FontWeight.w200,
                  fontStyle: theme
                      .bodySmall.fontStyle,
                ),
                fontSize: 14,
                color: theme.white,
              ),
              onChanged: onChanged,
              items: items,
            ),
          ),
        ),
      ],
    );
  }
}