import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Material theme from DEC-024 / Task 02 draft tokens.
ThemeData buildVrijdagTheme({Brightness brightness = Brightness.light}) {
  final tokens = brightness == Brightness.dark
      ? VrijdagColorTokens.autumnDark
      : VrijdagColorTokens.autumnLight;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: tokens.moss,
    onPrimary: tokens.paper,
    secondary: tokens.rust,
    onSecondary: tokens.paper,
    surface: tokens.paper,
    onSurface: tokens.ink,
    onSurfaceVariant: tokens.inkSoft,
    outline: tokens.dust,
    error: tokens.rust,
    onError: tokens.paper,
  );

  final displayFont = GoogleFonts.frauncesTextTheme();
  final bodyFont = GoogleFonts.ibmPlexSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.paper,
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.paper,
      foregroundColor: tokens.ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: tokens.ink,
      ),
    ),
    textTheme: displayFont.copyWith(
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: tokens.ink,
      ),
      titleMedium: GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: tokens.ink,
      ),
      bodyMedium: bodyFont.bodyMedium?.copyWith(
        color: tokens.inkSoft,
        height: 1.5,
      ),
      bodySmall: bodyFont.bodySmall?.copyWith(color: tokens.warmGrey),
      labelLarge: GoogleFonts.ibmPlexSans(
        fontWeight: FontWeight.w500,
        color: tokens.rust,
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      VrijdagThemeExtension(tokens: tokens),
    ],
  );
}

/// Access seasonal colour tokens from [ThemeData].
@immutable
class VrijdagThemeExtension extends ThemeExtension<VrijdagThemeExtension> {
  const VrijdagThemeExtension({required this.tokens});

  final VrijdagColorTokens tokens;

  @override
  VrijdagThemeExtension copyWith({VrijdagColorTokens? tokens}) {
    return VrijdagThemeExtension(tokens: tokens ?? this.tokens);
  }

  @override
  VrijdagThemeExtension lerp(VrijdagThemeExtension? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension VrijdagThemeX on ThemeData {
  VrijdagColorTokens get vrijdagColors =>
      extension<VrijdagThemeExtension>()?.tokens ??
      VrijdagColorTokens.autumnLight;
}
