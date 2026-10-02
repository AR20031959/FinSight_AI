import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinSightApp()));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('FinSight AI'), findsWidgets);
  });
}

