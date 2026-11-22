// Plans, Pulse allowances and what a business has bought. The numbers mirror
// functions/plans_logic.js, which is what actually enforces them.

const int fairUseMonthlyPulses = 300;

enum BusinessPlanId { free, plus, pro }

class BusinessPlanInfo {
  const BusinessPlanInfo({
    required this.id,
    required this.label,
    required this.monthlyPulses,
    required this.perks,
  });

  final BusinessPlanId id;
  final String label;

  /// Null means unlimited, held back only by the fair-use limit.
  final int? monthlyPulses;
  final List<String> perks;

  String get pulsesText =>
      monthlyPulses == null ? 'Unlimited Pulses' : '$monthlyPulses Pulses a month';
}

const List<BusinessPlanInfo> businessPlans = [
  BusinessPlanInfo(
    id: BusinessPlanId.free,
    label: 'Free',
    monthlyPulses: 3,
    perks: ['List your experiences', 'Post Pulses'],
  ),
  BusinessPlanInfo(
    id: BusinessPlanId.plus,
    label: 'Plus',
    monthlyPulses: 15,
    perks: ['Verified badge', 'More Pulses for busy weeks'],
  ),
  BusinessPlanInfo(
    id: BusinessPlanId.pro,
    label: 'Pro',
    monthlyPulses: null,
    perks: ['Unlimited Pulses', 'Priority in Explore', 'Analytics preview'],
  ),
];

BusinessPlanInfo planInfo(BusinessPlanId id) =>
    businessPlans.firstWhere((plan) => plan.id == id);

/// What can be bought. The keys match the server's product names.
enum BillingProduct {
  plus('plus'),
  pro('pro'),
  pack5('pack5'),
  pack10('pack10'),
  featured7('featured7'),
  featured30('featured30');

  const BillingProduct(this.key);
  final String key;
}

/// A business's plan, Pulse usage and bought packs, read from
/// `subscriptions/{businessId}`. Only the server writes it.
class BillingSummary {
  const BillingSummary({
    this.plan = BusinessPlanId.free,
    this.status = '',
    this.cancelAtPeriodEnd = false,
    this.currentPeriodEnd,
    this.pulseMonth = '',
    this.pulsesUsed = 0,
    this.packBalance = 0,
  });

  final BusinessPlanId plan;
  final String status;
  final bool cancelAtPeriodEnd;
  final DateTime? currentPeriodEnd;
  final String pulseMonth;
  final int pulsesUsed;
  final int packBalance;

  static const empty = BillingSummary();

  static const _entitled = {'active', 'trialing', 'past_due'};

  static BillingSummary fromJson(Map<String, Object?> json) {
    BusinessPlanId plan = BusinessPlanId.free;
    for (final value in BusinessPlanId.values) {
      if (value.name == json['plan']) plan = value;
    }
    int count(Object? value) => value is int && value > 0 ? value : 0;
    final end = json['currentPeriodEnd'];
    return BillingSummary(
      plan: plan,
      status: json['status'] as String? ?? '',
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
      currentPeriodEnd: end is DateTime ? end : _toDate(end),
      pulseMonth: json['pulseMonth'] as String? ?? '',
      pulsesUsed: count(json['pulsesUsed']),
      packBalance: count(json['packBalance']),
    );
  }

  static DateTime? _toDate(Object? value) {
    // Firestore timestamps expose toDate(); kept dynamic so this model stays
    // free of Firebase imports.
    try {
      final date = (value as dynamic)?.toDate();
      return date is DateTime ? date : null;
    } catch (_) {
      return null;
    }
  }

  /// The plan the business actually gets: a lapsed paid plan counts as Free.
  BusinessPlanId get effectivePlan =>
      plan != BusinessPlanId.free && _entitled.contains(status)
      ? plan
      : BusinessPlanId.free;

  static String monthKey(DateTime now) {
    final utc = now.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}';
  }

  int usedThisMonth(DateTime now) =>
      pulseMonth == monthKey(now) ? pulsesUsed : 0;

  bool get isUnlimited => planInfo(effectivePlan).monthlyPulses == null;

  int monthlyLimit() =>
      planInfo(effectivePlan).monthlyPulses ?? fairUseMonthlyPulses;

  /// Pulses that can still be posted: the plan's own first, then packs
  /// (packs do not apply on an unlimited plan).
  int pulsesLeft(DateTime now) {
    final included = (monthlyLimit() - usedThisMonth(now)).clamp(0, 1 << 30);
    return isUnlimited ? included : included + packBalance;
  }
}
