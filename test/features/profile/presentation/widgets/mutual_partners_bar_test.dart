import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/features/profile/presentation/widgets/mutual_partners_bar.dart';

import '../../../../helpers/test_builders.dart';

/// Helper to find RichText containing a specific substring.
Finder findRichTextContaining(String text) {
  return find.byWidgetPredicate((widget) {
    if (widget is RichText) {
      return widget.text.toPlainText().contains(text);
    }
    return false;
  });
}

void main() {
  testWidgets('renders SizedBox.shrink when no mutual partners',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MutualPartnersBar(
            currentUserId: 'user1',
            profileUserId: 'user2',
            loader: (_, _) async => <UserModel>[],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(findRichTextContaining('ortak spor partneriniz'), findsNothing);
  });

  testWidgets('renders avatars and count when mutual partners exist',
      (tester) async {
    final partners = [
      TestUserBuilder().withId('p1').withUsername('Partner1').build(),
      TestUserBuilder().withId('p2').withUsername('Partner2').build(),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MutualPartnersBar(
            currentUserId: 'user1',
            profileUserId: 'user2',
            loader: (_, _) async => partners,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(findRichTextContaining('2 ortak spor partneriniz'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNWidgets(2));
  });

  testWidgets('renders SizedBox.shrink while loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MutualPartnersBar(
            currentUserId: 'user1',
            profileUserId: 'user2',
            loader: (_, _) async {
              return [TestUserBuilder().withId('p1').build()];
            },
          ),
        ),
      ),
    );

    // Before pumpAndSettle — still loading
    expect(findRichTextContaining('ortak spor partneriniz'), findsNothing);

    await tester.pumpAndSettle();

    // After loading
    expect(findRichTextContaining('1 ortak spor partneriniz'), findsOneWidget);
  });
}
