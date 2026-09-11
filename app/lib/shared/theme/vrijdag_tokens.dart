import 'package:flutter/material.dart';

/// Named colour tokens (DEC-024). Values change by season + brightness.
@immutable
class VrijdagColorTokens {
  const VrijdagColorTokens({
    required this.paper,
    required this.ink,
    required this.inkSoft,
    required this.warmGrey,
    required this.dust,
    required this.moss,
    required this.rust,
    required this.banner,
  });

  final Color paper;
  final Color ink;
  final Color inkSoft;
  final Color warmGrey;
  final Color dust;
  final Color moss;
  final Color rust;

  /// System-state fill (offline banner). Seasonal derived token (Task 02).
  final Color banner;

  /// Ink at 12% — hairlines between nav chrome (Task 02).
  Color get hair => ink.withValues(alpha: 0.12);

  static const autumnLight = VrijdagColorTokens(
    paper: Color(0xFFF5F0E8),
    ink: Color(0xFF1A1A18),
    inkSoft: Color(0xFF4A4A44),
    warmGrey: Color(0xFF8C8578),
    dust: Color(0xFFC4BAA8),
    moss: Color(0xFF2D5016),
    rust: Color(0xFF9E4A3A),
    banner: Color(0xFFE8E0D4),
  );

  static const autumnDark = VrijdagColorTokens(
    paper: Color(0xFF161512),
    ink: Color(0xFFF0EBE3),
    inkSoft: Color(0xFFC8C2B6),
    warmGrey: Color(0xFF8A8376),
    dust: Color(0xFF3A362F),
    moss: Color(0xFF8FBF6A),
    rust: Color(0xFFD4886A),
    banner: Color(0xFF24201A),
  );
}

/// Spacing scale (Fibonacci-ish rhythm from Task 01).
///
/// [page] is Task 02 Day padding (16) — do not snap to [md]/[lg].
abstract final class VrijdagSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 13.0;

  /// Day page / date / spine horizontal padding (task-02-measurements).
  static const page = 16.0;
  static const lg = 21.0;
  static const xl = 34.0;
  static const xxl = 55.0;
}

/// Motion durations — honour reduce-motion at call sites.
abstract final class VrijdagMotion {
  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 360);

  static Duration resolve(BuildContext context, Duration preferred) {
    final disable = MediaQuery.disableAnimationsOf(context);
    return disable ? Duration.zero : preferred;
  }
}

/// Corner radii.
///
/// [control] is Task 02 banner / all-day radius (8) — do not snap to [sm]/[md].
abstract final class VrijdagRadii {
  static const sm = 6.0;

  /// Banner and all-day band (task-02-measurements).
  static const control = 8.0;
  static const md = 10.0;
  static const lg = 16.0;
}
