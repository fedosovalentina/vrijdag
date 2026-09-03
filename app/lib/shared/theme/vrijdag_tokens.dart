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
  });

  final Color paper;
  final Color ink;
  final Color inkSoft;
  final Color warmGrey;
  final Color dust;
  final Color moss;
  final Color rust;

  static const autumnLight = VrijdagColorTokens(
    paper: Color(0xFFF5F0E8),
    ink: Color(0xFF1A1A18),
    inkSoft: Color(0xFF4A4A44),
    warmGrey: Color(0xFF8C8578),
    dust: Color(0xFFC4BAA8),
    moss: Color(0xFF2D5016),
    rust: Color(0xFF9E4A3A),
  );

  static const autumnDark = VrijdagColorTokens(
    paper: Color(0xFF161512),
    ink: Color(0xFFF0EBE3),
    inkSoft: Color(0xFFC8C2B6),
    warmGrey: Color(0xFF8A8376),
    dust: Color(0xFF3A362F),
    moss: Color(0xFF8FBF6A),
    rust: Color(0xFFD4886A),
  );
}

/// Spacing scale (Fibonacci-ish rhythm from Task 01).
abstract final class VrijdagSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 13.0;
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
abstract final class VrijdagRadii {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 16.0;
}
