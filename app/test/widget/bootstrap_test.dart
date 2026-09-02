import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/app.dart';

void main() {
  testWidgets('bootstrap screen shows Vrijdag', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VrijdagApp()));
    expect(find.text('Vrijdag'), findsOneWidget);
    expect(find.textContaining('F-001'), findsOneWidget);
  });
}
