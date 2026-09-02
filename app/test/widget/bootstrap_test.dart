import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/app.dart';

void main() {
  testWidgets('bootstrap screen shows localized Dutch copy', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: VrijdagApp(locale: Locale('nl'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vrijdag'), findsWidgets);
    expect(find.textContaining('F-001'), findsOneWidget);
    expect(find.text('Omgevingsskelet gereed.'), findsOneWidget);
  });

  testWidgets('bootstrap screen shows localized English copy', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: VrijdagApp(locale: Locale('en'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Environment scaffold ready.'), findsOneWidget);
  });
}
