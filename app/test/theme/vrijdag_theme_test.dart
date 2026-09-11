import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

void main() {
  testWidgets('dark theme paints type in ink, not light-theme black', (
    tester,
  ) async {
    late ThemeData theme;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVrijdagTheme(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final ink = VrijdagColorTokens.autumnDark.ink;
    expect(theme.scaffoldBackgroundColor, VrijdagColorTokens.autumnDark.paper);
    expect(theme.colorScheme.onSurface, ink);
    expect(theme.textTheme.bodyLarge?.color, ink);
    expect(theme.textTheme.bodyMedium?.color, ink);
    expect(theme.textTheme.headlineMedium?.color, ink);
    expect(theme.textTheme.titleMedium?.color, ink);
    expect(theme.inputDecorationTheme.floatingLabelStyle?.color, ink);
    expect(theme.textSelectionTheme.cursorColor, ink);
  });

  testWidgets('light theme still uses dark ink on paper', (tester) async {
    late ThemeData theme;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVrijdagTheme(),
        home: Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final ink = VrijdagColorTokens.autumnLight.ink;
    expect(theme.scaffoldBackgroundColor, VrijdagColorTokens.autumnLight.paper);
    expect(theme.textTheme.bodyLarge?.color, ink);
    expect(theme.colorScheme.onSurface, ink);
  });
}
