import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Optional app locale override (profile language / onboarding / settings).
///
/// `null` means follow the device via [resolveAppLocale].
final appLocaleProvider = StateProvider<Locale?>((ref) => null);
