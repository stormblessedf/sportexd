import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/profile/presentation/widgets/trophy_card.dart';

void main() {
  Widget buildCard({required bool isEarned, VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 120,
          height: 140,
          child: TrophyCard(
            emoji: '🏆',
            name: 'Organizatör',
            description: '10 etkinlik düzenle',
            isEarned: isEarned,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  testWidgets('earned state shows full opacity', (tester) async {
    await tester.pumpWidget(buildCard(isEarned: true));

    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 1.0);
  });

  testWidgets('locked state shows 40% opacity', (tester) async {
    await tester.pumpWidget(buildCard(isEarned: false));

    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 0.4);
  });

  testWidgets('tap invokes callback when earned', (tester) async {
    var tapped = false;
    await tester.pumpWidget(buildCard(isEarned: true, onTap: () => tapped = true));

    await tester.tap(find.text('🏆'));
    expect(tapped, isTrue);
  });

  testWidgets('tap does not invoke callback when locked', (tester) async {
    var tapped = false;
    await tester.pumpWidget(buildCard(isEarned: false, onTap: () => tapped = true));

    await tester.tap(find.text('🏆'));
    expect(tapped, isFalse);
  });
}
