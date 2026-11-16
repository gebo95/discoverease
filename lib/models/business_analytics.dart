class BusinessDailyAnalytics {
  const BusinessDailyAnalytics({
    this.views = 0,
    this.likes = 0,
    this.shares = 0,
    this.saves = 0,
  });

  final int views;
  final int likes;
  final int shares;
  final int saves;

  factory BusinessDailyAnalytics.fromJson(Map<String, Object?> data) =>
      BusinessDailyAnalytics(
        views: (data['views'] as num?)?.toInt() ?? 0,
        likes: (data['likes'] as num?)?.toInt() ?? 0,
        shares: (data['shares'] as num?)?.toInt() ?? 0,
        saves: (data['saves'] as num?)?.toInt() ?? 0,
      );

  BusinessDailyAnalytics operator +(BusinessDailyAnalytics other) =>
      BusinessDailyAnalytics(
        views: views + other.views,
        likes: likes + other.likes,
        shares: shares + other.shares,
        saves: saves + other.saves,
      );
}

/// Lifetime figures for one listing that are not tied to a date range.
class BusinessAnalyticsSummary {
  const BusinessAnalyticsSummary({this.uniqueSharers = 0});

  /// Number of different accounts that have shared the listing. Counts only;
  /// the business never sees who they are.
  final int uniqueSharers;

  factory BusinessAnalyticsSummary.fromJson(Map<String, Object?> data) =>
      BusinessAnalyticsSummary(
        uniqueSharers: (data['uniqueSharers'] as num?)?.toInt() ?? 0,
      );
}
