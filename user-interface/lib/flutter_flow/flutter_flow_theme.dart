import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlutterFlowTheme {
  FlutterFlowTheme._(this.context);
  final BuildContext context;

  static FlutterFlowTheme of(BuildContext context) => FlutterFlowTheme._(context);
/*
  Color get bg         => const Color(0xFF11111A);
  Color get surface    => const Color(0xFF1A1030);
  Color get surfaceAlt => const Color(0xFF0E0F2B);
  Color get primary    => const Color(0xFFBB86FC);
  Color get secondary  => const Color(0xFF7F5AF0);
*/
  Color get bg         => const Color(0xFF0B0B0E); // fond sombre gris/noir
  Color get surface    => const Color(0xFF1A1030); // violet nuit profond
  Color get surfaceAlt => const Color(0xFF2A2A40); // gris/violet plus doux
  Color get primary    => const Color(0xADFF2DAC); // rose néon (logo)
  Color get secondary  => const Color(0xFF7F5AF0); // violet flashy
  Color get accent     => const Color(0xFFA6C6DA); // bleu clair/gris texte
  Color get bgSoft => const Color(0xFF2B2D30);
  Color get white      => const Color(0xFFFFFFFF);




  TextStyle get displayLarge => GoogleFonts.interTight(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  TextStyle get headlineLarge => GoogleFonts.interTight(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  TextStyle get headlineMedium => GoogleFonts.interTight(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  TextStyle get titleLarge => GoogleFonts.interTight(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  TextStyle get titleMedium => GoogleFonts.interTight(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  TextStyle get titleSmall => GoogleFonts.interTight(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFCCCCCC),
  );

  TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFCCCCCC),
  );

  TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFCCCCCC),
  );
}

extension FFTextStyleHelpers on TextStyle {
  TextStyle override({
    TextStyle? font,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    var base = this;
    if (font != null) {
      base = base.copyWith(
        fontFamily: font.fontFamily,
        fontWeight: font.fontWeight,
        fontStyle: font.fontStyle,
      );
    }
    return base.copyWith(
      color: color ?? base.color,
      fontSize: fontSize ?? base.fontSize,
      fontWeight: fontWeight ?? base.fontWeight,
      fontStyle: fontStyle ?? base.fontStyle,
      letterSpacing: letterSpacing ?? base.letterSpacing,
      height: height ?? base.height,
      decoration: decoration ?? base.decoration,
    );
  }
}
