import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/features/profile/presentation/widgets/name_section.dart';

import '../../../../helpers/test_builders.dart';

void main() {
  Widget buildWidget(TestUserBuilder userBuilder) {
    return MaterialApp(
      home: Scaffold(
        body: NameSection(user: userBuilder.build()),
      ),
    );
  }

  testWidgets('renders name and age when birthDate is set', (tester) async {
    final user = TestUserBuilder()
        .withUsername('Ali')
        .withBirthDate(DateTime(2000, 1, 1));

    await tester.pumpWidget(buildWidget(user));

    // Age will be calculated from birthDate
    final rendered = find.textContaining('Ali,');
    expect(rendered, findsOneWidget);
  });

  testWidgets('renders only name when birthDate is null', (tester) async {
    final user = TestUserBuilder()
        .withUsername('Veli')
        .withBirthDate(null);

    await tester.pumpWidget(buildWidget(user));

    expect(find.text('Veli'), findsOneWidget);
  });

  testWidgets('hides bio when null', (tester) async {
    final user = TestUserBuilder().withBio(null);

    await tester.pumpWidget(buildWidget(user));

    // Bio text should not appear — only name should be present
    final textWidgets = find.byType(Text);
    // Should only have the name text
    expect(textWidgets, findsOneWidget);
  });

  testWidgets('hides bio when empty string', (tester) async {
    final user = TestUserBuilder().withBio('');

    await tester.pumpWidget(buildWidget(user));

    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('shows bio when provided', (tester) async {
    final user = TestUserBuilder().withBio('Spor tutkunu');

    await tester.pumpWidget(buildWidget(user));

    expect(find.text('Spor tutkunu'), findsOneWidget);
  });

  testWidgets('hides location when null', (tester) async {
    final user = TestUserBuilder().withLocation(null);

    await tester.pumpWidget(buildWidget(user));

    expect(find.byIcon(Icons.location_on), findsNothing);
  });

  testWidgets('shows location with icon when provided', (tester) async {
    final user = TestUserBuilder().withLocation('İstanbul');

    await tester.pumpWidget(buildWidget(user));

    expect(find.byIcon(Icons.location_on), findsOneWidget);
    expect(find.text('İstanbul'), findsOneWidget);
  });

  testWidgets('hides sport tags when interestedSports is null', (tester) async {
    final user = TestUserBuilder().withInterestedSports(null);

    await tester.pumpWidget(buildWidget(user));

    expect(find.textContaining('⚽'), findsNothing);
  });

  testWidgets('shows sport tags when interestedSports is provided', (tester) async {
    final user = TestUserBuilder()
        .withInterestedSports([SportType.football, SportType.basketball]);

    await tester.pumpWidget(buildWidget(user));

    expect(find.textContaining('⚽'), findsOneWidget);
    expect(find.textContaining('🏀'), findsOneWidget);
  });
}
