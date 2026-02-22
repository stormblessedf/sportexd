import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/features/profile/presentation/widgets/sport_tags_row.dart';

void main() {
  testWidgets('renders SizedBox.shrink when sports list is empty',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SportTagsRow(sports: []),
        ),
      ),
    );

    // SizedBox.shrink has zero size
    final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
    expect(sizedBox.width, 0.0);
    expect(sizedBox.height, 0.0);
  });

  testWidgets('renders emoji + sport name tags for non-empty list',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SportTagsRow(
            sports: [SportType.football, SportType.tennis],
          ),
        ),
      ),
    );

    expect(find.text('⚽ Futbol'), findsOneWidget);
    expect(find.text('🎾 Tenis'), findsOneWidget);
  });
}
