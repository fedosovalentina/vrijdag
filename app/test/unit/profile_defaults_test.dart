import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';

void main() {
  test('resolveProfileLanguage maps nl and falls back to en', () {
    expect(resolveProfileLanguage(const Locale('nl')), 'nl');
    expect(resolveProfileLanguage(const Locale('en')), 'en');
    expect(resolveProfileLanguage(const Locale('de')), 'en');
  });
}
