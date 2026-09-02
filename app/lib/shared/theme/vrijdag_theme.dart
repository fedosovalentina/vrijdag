import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrijdag/shared/theme/vrijdag_colors.dart';

/// Material theme aligned with Design Task 01 typography and autumn tokens.
ThemeData buildVrijdagTheme() {
  const colorScheme = ColorScheme.light(
    primary: VrijdagColors.moss,
    onPrimary: VrijdagColors.paper,
    secondary: VrijdagColors.rust,
    onSecondary: VrijdagColors.paper,
    surface: VrijdagColors.paper,
    onSurface: VrijdagColors.ink,
    onSurfaceVariant: VrijdagColors.inkSoft,
    outline: VrijdagColors.dust,
  );

  final displayFont = GoogleFonts.frauncesTextTheme();
  final bodyFont = GoogleFonts.ibmPlexSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: VrijdagColors.paper,
    appBarTheme: AppBarTheme(
      backgroundColor: VrijdagColors.paper,
      foregroundColor: VrijdagColors.ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: VrijdagColors.ink,
      ),
    ),
    textTheme: displayFont.copyWith(
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: VrijdagColors.ink,
      ),
      bodyMedium: bodyFont.bodyMedium?.copyWith(
        color: VrijdagColors.inkSoft,
        height: 1.5,
      ),
      bodySmall: bodyFont.bodySmall?.copyWith(
        color: VrijdagColors.warmGrey,
      ),
      labelLarge: GoogleFonts.ibmPlexSans(
        fontWeight: FontWeight.w500,
        color: VrijdagColors.rust,
      ),
    ),
  );
}
