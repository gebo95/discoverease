import 'package:discoverease/models/business_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('combines daily business activity without losing counters', () {
    const first = BusinessDailyAnalytics(views: 5, likes: 2, shares: 1, saves: 3);
    const second = BusinessDailyAnalytics(views: 7, likes: 1, shares: 2, saves: 0);

    final total = first + second;

    expect(total.views, 12);
    expect(total.likes, 3);
    expect(total.shares, 3);
    expect(total.saves, 3);
  });

  test('reads lifetime unique sharers and defaults to zero', () {
    expect(
      BusinessAnalyticsSummary.fromJson(const {'uniqueSharers': 4}).uniqueSharers,
      4,
    );
    expect(BusinessAnalyticsSummary.fromJson(const {}).uniqueSharers, 0);
  });
}
