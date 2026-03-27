import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Colours (matching portal CSS variables) ──
  static const ink      = Color(0xFF0D1117);
  static const ink2     = Color(0xFF1C2333);
  static const ink3     = Color(0xFF2D3748);
  static const mist     = Color(0xFFF4F6FA);
  static const fog      = Color(0xFFE8ECF4);
  static const slate    = Color(0xFF8895A7);
  static const white    = Color(0xFFFFFFFF);
  static const purple   = Color(0xFF7C3AED);
  static const purpleBg = Color(0xFFEDE9FE);
  static const blue     = Color(0xFF0284C7);
  static const blueBg   = Color(0xFFE0F2FE);
  static const green    = Color(0xFF059669);
  static const greenBg  = Color(0xFFD1FAE5);
  static const amber    = Color(0xFFD97706);
  static const amberBg  = Color(0xFFFEF3C7);
  static const red      = Color(0xFFE11D48);
  static const redBg    = Color(0xFFFFE4E6);

  static const subjectPalette = [
    Color(0xFF7C3AED), Color(0xFF0284C7), Color(0xFF059669),
    Color(0xFFEA580C), Color(0xFFD97706), Color(0xFFE11D48),
    Color(0xFF0891B2), Color(0xFF9333EA), Color(0xFF16A34A),
    Color(0xFFDC2626),
  ];

  static Color subjectColor(String subject) {
    int hash = 0;
    for (final c in subject.runes) {
      hash = (hash * 31 + c) & 0xFFFF;
    }
    return subjectPalette[hash % subjectPalette.length];
  }

  static String subjectIcon(String subject) {
    final k = subject.toLowerCase();
    if (k.contains('math'))      return '📐';
    if (k.contains('sejarah') || k.contains('history')) return '🏛️';
    if (k.contains('english') || k.contains('eng'))     return '📖';
    if (k.contains('science'))   return '🔬';
    if (k.contains('pai') || k.contains('pendidikan islam')) return '📿';
    if (k.contains('bahasa') || k.contains('melayu'))   return '🗣️';
    if (k.contains('physics'))   return '⚡';
    if (k.contains('chemistry')) return '⚗️';
    if (k.contains('biology'))   return '🧬';
    if (k.contains('addmath'))   return '🔢';
    if (k.contains('geo'))       return '🌍';
    if (k.contains('moral'))     return '🕊️';
    if (k.contains('ict'))       return '💻';
    if (k.contains('pe') || k.contains('sport')) return '⚽';
    return '📚';
  }

  static String initials(String name) {
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  static Color avatarColor(String name) {
    int h = 0;
    for (final c in name.runes) {
      h = (h * 31 + c) & 0xFFFF;
    }
    return subjectPalette[h % subjectPalette.length];
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: mist,
    colorScheme: ColorScheme.fromSeed(
      seedColor: purple,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: GoogleFonts.fraunces(fontSize: 32, fontWeight: FontWeight.w700, color: ink),
      displayMedium: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w700, color: ink),
      displaySmall: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w700, color: ink),
      headlineMedium: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: ink),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ink,
      foregroundColor: white,
      elevation: 0,
      titleTextStyle: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: white),
    ),
    cardTheme: const CardThemeData(
      color: white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: fog),
      ),
    ),
  );
}
