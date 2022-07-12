// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:blocked_main/main.dart';
import 'package:integration_test/integration_test.dart';

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Increment Counter'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await binding.watchPerformance(
      () async {
        await tester.tap(find.text('Block Main'));

        await tester.tap(find.text('Increment Counter'));
        await tester.tap(find.text('Increment Counter'));
        await tester.tap(find.text('Increment Counter'));
        await tester.tap(find.text('Increment Counter'));
        await tester.tap(find.text('Increment Counter'));
        await tester.pumpAndSettle();
      },
    );
  });
}
