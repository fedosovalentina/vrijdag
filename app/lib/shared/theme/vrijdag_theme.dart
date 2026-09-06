import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Material theme from Task 02 tokens. Google Fonts themes default to black
/// body colour — every style must be re-tinted to [VrijdagColorTokens.ink]
/// or dark mode paints ink-light paper with light-theme black type.
ThemeData buildVrijdagTheme({Brightness brightness = Brightness.light}) {
  final tokens = brightness == Brightness.dark
      ? VrijdagColorTokens.autumnDark
      : VrijdagColorTokens.autumnLight;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: tokens.ink,
    onPrimary: tokens.paper,
    secondary: tokens.inkSoft,
    onSecondary: tokens.paper,
    surface: tokens.paper,
    onSurface: tokens.ink,
    onSurfaceVariant: tokens.inkSoft,
    outline: tokens.dust,
    error: tokens.inkSoft,
    onError: tokens.paper,
  );

  final inkText = ThemeData(
    brightness: brightness,
  ).textTheme.apply(bodyColor: tokens.ink, displayColor: tokens.ink);
  final plex = GoogleFonts.ibmPlexSansTextTheme(
    inkText,
  ).apply(bodyColor: tokens.ink, displayColor: tokens.ink);
  final display = GoogleFonts.frauncesTextTheme(
    inkText,
  ).apply(bodyColor: tokens.ink, displayColor: tokens.ink);

  final underline = UnderlineInputBorder(
    borderSide: BorderSide(color: tokens.ink),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.paper,
    canvasColor: tokens.paper,
    dividerColor: tokens.dust,
    iconTheme: IconThemeData(color: tokens.ink),
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
    textTheme: plex.copyWith(
      displayLarge: display.displayLarge,
      displayMedium: display.displayMedium,
      displaySmall: display.displaySmall,
      headlineLarge: display.headlineLarge,
      headlineMedium: display.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: display.headlineSmall,
      titleLarge: display.titleLarge,
      titleMedium: display.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      labelStyle: GoogleFonts.ibmPlexSans(color: tokens.warmGrey, fontSize: 13),
      floatingLabelStyle: GoogleFonts.ibmPlexSans(color: tokens.ink),
      hintStyle: GoogleFonts.ibmPlexSans(color: tokens.warmGrey),
      helperStyle: GoogleFonts.ibmPlexSans(
        color: tokens.warmGrey,
        fontSize: 13,
      ),
      errorStyle: GoogleFonts.ibmPlexSans(color: tokens.inkSoft, fontSize: 13),
      enabledBorder: underline,
      focusedBorder: underline.copyWith(
        borderSide: BorderSide(color: tokens.ink, width: 1.5),
      ),
      disabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: tokens.dust),
      ),
      errorBorder: underline,
      focusedErrorBorder: underline.copyWith(
        borderSide: BorderSide(color: tokens.ink, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: tokens.ink,
      selectionColor: tokens.ink.withValues(alpha: 0.24),
      selectionHandleColor: tokens.ink,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.inkSoft,
        minimumSize: const Size(44, 44),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.ink,
        foregroundColor: tokens.paper,
        disabledBackgroundColor: tokens.dust,
        disabledForegroundColor: tokens.paper,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VrijdagRadii.sm + 2),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.paper,
      titleTextStyle: display.titleLarge,
      contentTextStyle: plex.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.dust,
      contentTextStyle: GoogleFonts.ibmPlexSans(color: tokens.ink),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: tokens.ink,
      textColor: tokens.ink,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: tokens.paper,
      textStyle: plex.bodyMedium,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(tokens.paper),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? tokens.ink : tokens.dust;
      }),
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
    if (other is! VrijdagThemeExtension) {
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
