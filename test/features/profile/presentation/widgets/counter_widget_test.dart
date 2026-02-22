import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/profile/presentation/widgets/counter_widget.dart';

void main() {
  testWidgets('renders value and label text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CounterWidget(value: '42', label: 'Etkinlik'),
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.text('Etkinlik'), findsOneWidget);
  });

  testWidgets('invokes onTap callback when tapped', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CounterWidget(
            value: '10',
            label: 'Partner',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('10'));
    expect(tapped, isTrue);
  });

  testWidgets('does not crash when onTap is null and tapped', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CounterWidget(value: '5', label: 'Puan'),
        ),
      ),
    );

    // Should not throw
    await tester.tap(find.text('5'));
  });
}
