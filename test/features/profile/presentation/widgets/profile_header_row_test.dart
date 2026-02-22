import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/profile/presentation/widgets/profile_header_row.dart';

import '../../../../helpers/test_builders.dart';

void main() {
  Widget buildWidget({
    required TestUserBuilder userBuilder,
    Function(CounterType)? onCounterTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ProfileHeaderRow(
          user: userBuilder.build(),
          onCounterTap: onCounterTap ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renders counter values from user model', (tester) async {
    final user = TestUserBuilder()
        .withTotalMeetupsRegistered(12)
        .withPartners(['a', 'b', 'c'])
        .withReliabilityScore(95.4)
        .withAverageRating(4.7);

    await tester.pumpWidget(buildWidget(userBuilder: user));

    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('4.7⭐'), findsOneWidget);
    expect(find.text('Etkinlik'), findsOneWidget);
    expect(find.text('Partner'), findsOneWidget);
    expect(find.text('Güvenilir'), findsOneWidget);
    expect(find.text('Puan'), findsOneWidget);
  });

  testWidgets('shows online dot when user is currently online', (tester) async {
    final user = TestUserBuilder()
        .withLastSeen(DateTime.now())
        .withIsOnline(true);

    await tester.pumpWidget(buildWidget(userBuilder: user));

    // Online dot is a 14px Container inside a Positioned widget
    final positioned = find.byType(Positioned);
    expect(positioned, findsOneWidget);
  });

  testWidgets('hides online dot when user is offline', (tester) async {
    final user = TestUserBuilder()
        .withLastSeen(DateTime.now().subtract(const Duration(hours: 1)))
        .withIsOnline(false);

    await tester.pumpWidget(buildWidget(userBuilder: user));

    expect(find.byType(Positioned), findsNothing);
  });

  testWidgets('shows default person icon when no profile image', (tester) async {
    final user = TestUserBuilder().withProfileImageUrl(null);

    await tester.pumpWidget(buildWidget(userBuilder: user));

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('invokes onCounterTap with correct CounterType', (tester) async {
    CounterType? tappedType;
    final user = TestUserBuilder()
        .withTotalMeetupsRegistered(5)
        .withPartners([])
        .withReliabilityScore(100)
        .withAverageRating(0);

    await tester.pumpWidget(buildWidget(
      userBuilder: user,
      onCounterTap: (type) => tappedType = type,
    ));

    await tester.tap(find.text('Etkinlik'));
    expect(tappedType, CounterType.events);

    await tester.tap(find.text('Partner'));
    expect(tappedType, CounterType.partners);
  });
}
