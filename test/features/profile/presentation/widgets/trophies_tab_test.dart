import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/features/profile/presentation/models/trophy_definition.dart';
import 'package:sporsal/features/profile/presentation/widgets/trophy_card.dart';
import 'package:sporsal/features/profile/presentation/widgets/trophies_tab.dart';

void main() {
  final testTrophies = const [
    TrophyDefinition(
      id: 'organizer',
      emoji: '🏆',
      name: 'Organizatör',
      description: '10+ etkinlik organize eden',
      criteria: 'totalOrganized >= 10',
    ),
    TrophyDefinition(
      id: 'loyal',
      emoji: '⚡',
      name: 'Sadık Oyuncu',
      description: 'Son 5 etkinliğe katılan',
      criteria: 'lastFiveAttended == 5',
    ),
    TrophyDefinition(
      id: 'social',
      emoji: '🤝',
      name: 'Sosyal Kelebek',
      description: '20+ farklı partner',
      criteria: 'partnersCount >= 20',
    ),
  ];

  final earnedBadges = [
    const Badge(
      id: 'organizer',
      name: 'Organizatör',
      description: '10+ etkinlik',
      iconPath: 'assets/badges/organizer.png',
      type: BadgeType.organizer,
    ),
  ];

  Widget buildWidget({
    List<Badge>? badges,
    List<TrophyDefinition>? trophies,
    Function(TrophyDefinition)? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TrophiesTab(
            earnedBadges: badges ?? earnedBadges,
            allTrophies: trophies ?? testTrophies,
            onTrophyTap: onTap ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders "Kazanılan Rozetler" title', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.text('Kazanılan Rozetler'), findsOneWidget);
  });

  testWidgets('renders correct number of TrophyCard widgets', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.byType(TrophyCard), findsNWidgets(3));
  });

  testWidgets('earned trophy has full opacity', (tester) async {
    await tester.pumpWidget(buildWidget());

    // First TrophyCard (organizer) should be earned
    final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    expect(opacityWidgets[0].opacity, 1.0);
  });

  testWidgets('locked trophy has 0.4 opacity', (tester) async {
    await tester.pumpWidget(buildWidget());

    final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    // Second and third trophies (loyal, social) should be locked
    expect(opacityWidgets[1].opacity, 0.4);
    expect(opacityWidgets[2].opacity, 0.4);
  });

  testWidgets('onTrophyTap is called for earned trophy', (tester) async {
    TrophyDefinition? tappedTrophy;
    await tester.pumpWidget(buildWidget(
      onTap: (trophy) => tappedTrophy = trophy,
    ));

    // Tap the earned trophy emoji
    await tester.tap(find.text('🏆'));
    expect(tappedTrophy, isNotNull);
    expect(tappedTrophy!.id, 'organizer');
  });

  testWidgets('onTrophyTap is NOT called for locked trophy', (tester) async {
    TrophyDefinition? tappedTrophy;
    await tester.pumpWidget(buildWidget(
      onTap: (trophy) => tappedTrophy = trophy,
    ));

    // Tap a locked trophy emoji
    await tester.tap(find.text('⚡'));
    expect(tappedTrophy, isNull);
  });

  testWidgets('grid uses 3-column layout', (tester) async {
    await tester.pumpWidget(buildWidget());

    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(delegate.crossAxisSpacing, 10);
    expect(delegate.mainAxisSpacing, 10);
  });
}
