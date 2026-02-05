class RatingDistribution {
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  const RatingDistribution({
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  int get totalCount =>
      fiveStarCount + fourStarCount + threeStarCount + twoStarCount + oneStarCount;

  double get fiveStarPercentage =>
      totalCount > 0 ? (fiveStarCount / totalCount) * 100 : 0.0;

  double get fourStarPercentage =>
      totalCount > 0 ? (fourStarCount / totalCount) * 100 : 0.0;

  double get threeStarPercentage =>
      totalCount > 0 ? (threeStarCount / totalCount) * 100 : 0.0;

  double get twoStarPercentage =>
      totalCount > 0 ? (twoStarCount / totalCount) * 100 : 0.0;

  double get oneStarPercentage =>
      totalCount > 0 ? (oneStarCount / totalCount) * 100 : 0.0;

  factory RatingDistribution.empty() {
    return const RatingDistribution(
      fiveStarCount: 0,
      fourStarCount: 0,
      threeStarCount: 0,
      twoStarCount: 0,
      oneStarCount: 0,
    );
  }

  RatingDistribution copyWith({
    int? fiveStarCount,
    int? fourStarCount,
    int? threeStarCount,
    int? twoStarCount,
    int? oneStarCount,
  }) {
    return RatingDistribution(
      fiveStarCount: fiveStarCount ?? this.fiveStarCount,
      fourStarCount: fourStarCount ?? this.fourStarCount,
      threeStarCount: threeStarCount ?? this.threeStarCount,
      twoStarCount: twoStarCount ?? this.twoStarCount,
      oneStarCount: oneStarCount ?? this.oneStarCount,
    );
  }
}
