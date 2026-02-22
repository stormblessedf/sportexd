import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/profile/presentation/widgets/highlights_row.dart';

void main() {
  Widget buildWidget({
    required bool isOwnProfile,
    Function(HighlightType)? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HighlightsRow(
          isOwnProfile: isOwnProfile,
          onTap: onTap ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('shows 5 items when isOwnProfile is true', (tester) async {
    await tester.pumpWidget(buildWidget(isOwnProfile: true));

    expect(find.text('Rozetler'), findsOneWidget);
    expect(find.text('Sertifika'), findsOneWidget);
    expect(find.text('İstatistik'), findsOneWidget);
    expect(find.text('Başarılar'), findsOneWidget);
    expect(find.text('Yaklaşan'), findsOneWidget);
  });

  testWidgets('shows 4 items when isOwnProfile is false (no Yaklaşan)',
      (tester) async {
    await tester.pumpWidget(buildWidget(isOwnProfile: false));

    expect(find.text('Rozetler'), findsOneWidget);
    expect(find.text('Sertifika'), findsOneWidget);
    expect(find.text('İstatistik'), findsOneWidget);
    expect(find.text('Başarılar'), findsOneWidget);
    expect(find.text('Yaklaşan'), findsNothing);
  });

  testWidgets('invokes onTap with correct HighlightType', (tester) async {
    HighlightType? tappedType;

    await tester.pumpWidget(buildWidget(
      isOwnProfile: true,
      onTap: (type) => tappedType = type,
    ));

    await tester.tap(find.text('Rozetler'));
    expect(tappedType, HighlightType.badges);

    await tester.tap(find.text('Sertifika'));
    expect(tappedType, HighlightType.certificates);

    await tester.tap(find.text('İstatistik'));
    expect(tappedType, HighlightType.statistics);

    await tester.tap(find.text('Başarılar'));
    expect(tappedType, HighlightType.achievements);

    await tester.tap(find.text('Yaklaşan'));
    expect(tappedType, HighlightType.upcoming);
  });

  testWidgets('renders emoji circles', (tester) async {
    await tester.pumpWidget(buildWidget(isOwnProfile: true));

    expect(find.text('🏆'), findsOneWidget);
    expect(find.text('📜'), findsOneWidget);
    expect(find.text('📊'), findsOneWidget);
    expect(find.text('🏅'), findsOneWidget);
    expect(find.text('📅'), findsOneWidget);
  });
}
