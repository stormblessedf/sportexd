import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/profile/presentation/widgets/action_buttons_row.dart';

void main() {
  testWidgets('renders both button labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionButtonsRow(
            onEditTap: () {},
            onShareTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Profili Düzenle'), findsOneWidget);
    expect(find.text('Paylaş'), findsOneWidget);
  });

  testWidgets('invokes onEditTap when edit button is tapped', (tester) async {
    var editTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionButtonsRow(
            onEditTap: () => editTapped = true,
            onShareTap: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Profili Düzenle'));
    expect(editTapped, isTrue);
  });

  testWidgets('invokes onShareTap when share button is tapped', (tester) async {
    var shareTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionButtonsRow(
            onEditTap: () {},
            onShareTap: () => shareTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Paylaş'));
    expect(shareTapped, isTrue);
  });

  testWidgets('buttons use Expanded for equal width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionButtonsRow(
            onEditTap: () {},
            onShareTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(Expanded), findsNWidgets(2));
  });
}
