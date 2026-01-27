import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SporsalApp());
    // Since we start at login, we might check for "Sporsal" text
    expect(find.text('Sporsal'), findsOneWidget);
  });
}
