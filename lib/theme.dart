import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0E0E0E);
  static const surface = Color(0xFF161616);
  static const surface2 = Color(0xFF1E1E1E);
  static const border = Color(0xFF2A2A2A);
  static const text = Color(0xFFF0EDE8);
  static const muted = Color(0xFF5A5A5A);
  static const accent = Color(0xFFE8D5B0);
  static const accent2 = Color(0xFFC4A97D);
  static const red = Color(0xFFE05555);
  static const green = Color(0xFF6DB88A);
  static const textSecondary = Color(0xFFC8C4BE);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      background: AppColors.bg,
      surface: AppColors.surface,
      primary: AppColors.accent,
    ),
    textTheme: GoogleFonts.syneTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyMedium: GoogleFonts.dmMono(color: AppColors.muted, fontSize: 12),
    ),
    useMaterial3: true,
  );

  static TextStyle get heading => GoogleFonts.syne(
    color: AppColors.text,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    letterSpacing: -0.5,
  );

  static TextStyle get bigNumber => GoogleFonts.syne(
    color: AppColors.text,
    fontWeight: FontWeight.w800,
    fontSize: 88,
    letterSpacing: -4,
    height: 1,
  );

  static TextStyle get label => GoogleFonts.dmMono(
    color: AppColors.muted,
    fontSize: 11,
    letterSpacing: 0.1,
  );

  static TextStyle get body => GoogleFonts.syne(
    color: AppColors.textSecondary,
    fontSize: 15,
    height: 1.65,
  );

  static TextStyle get navLabel => GoogleFonts.dmMono(
    fontSize: 9,
    letterSpacing: 0.08,
  );
}
