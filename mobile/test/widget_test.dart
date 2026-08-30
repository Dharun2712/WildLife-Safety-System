import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forestguard/main.dart';

void main() {
  testWidgets('ForestGuard App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ForestGuardApp()));
    expect(find.byType(ForestGuardApp), findsOneWidget);
  });
}
