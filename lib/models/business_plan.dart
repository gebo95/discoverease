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
    perks: ['More Pulses for busy weeks', 'Basic stats'],
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
  pack15('pack15'),
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
    this.compPlan = BusinessPlanId.free,
    this.compUntil,
  });

  final BusinessPlanId plan;
  final String status;
  final bool cancelAtPeriodEnd;
  final DateTime? currentPeriodEnd;
  final String pulseMonth;
  final int pulsesUsed;
  final int packBalance;

  /// A plan the team granted, such as a founding partner's free months. It
  /// counts until [compUntil] and then stops by itself.
  final BusinessPlanId compPlan;
  final DateTime? compUntil;

  static const empty = BillingSummary();

  static const _entitled = {'active', 'trialing', 'past_due'};

  static BusinessPlanId _planFrom(Object? value) {
    for (final id in BusinessPlanId.values) {
      if (id.name == value) return id;
    }
    return BusinessPlanId.free;
  }

  static BillingSummary fromJson(Map<String, Object?> json) {
    int count(Object? value) => value is int && value > 0 ? value : 0;
    return BillingSummary(
      plan: _planFrom(json['plan']),
      status: json['status'] as String? ?? '',
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
      currentPeriodEnd: _toDate(json['currentPeriodEnd']),
      pulseMonth: json['pulseMonth'] as String? ?? '',
      pulsesUsed: count(json['pulsesUsed']),
      packBalance: count(json['packBalance']),
      compPlan: _planFrom(json['compPlan']),
      compUntil: _toDate(json['compUntil']),
    );
  }

  static DateTime? _toDate(Object? value) {
    if (value is DateTime) return value;
    // Firestore timestamps expose toDate(); kept dynamic so this model stays
    // free of Firebase imports.
    try {
      final date = (value as dynamic)?.toDate();
      return date is DateTime ? date : null;
    } catch (_) {
      return null;
    }
  }

  BusinessPlanId get _paidPlan =>
      plan != BusinessPlanId.free && _entitled.contains(status)
      ? plan
      : BusinessPlanId.free;

  /// Whether the business pays for a plan, as opposed to being granted one.
  bool get hasPaidPlan => _paidPlan != BusinessPlanId.free;

  /// Whether a granted plan is still running at [now].
  bool hasGrant(DateTime now) =>
      compPlan != BusinessPlanId.free &&
      compUntil != null &&
      compUntil!.isAfter(now);

  /// The plan the business actually gets: the better of what it pays for and
  /// what it was granted. A lapsed paid plan counts as Free.
  BusinessPlanId effectivePlanAt(DateTime now) {
    final granted = hasGrant(now) ? compPlan : BusinessPlanId.free;
    return granted.index > _paidPlan.index ? granted : _paidPlan;
  }

  BusinessPlanId get effectivePlan => effectivePlanAt(DateTime.now());

  static String monthKey(DateTime now) {
    final utc = now.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}';
  }

  int usedThisMonth(DateTime now) =>
      pulseMonth == monthKey(now) ? pulsesUsed : 0;

  bool isUnlimitedAt(DateTime now) =>
      planInfo(effectivePlanAt(now)).monthlyPulses == null;

  bool get isUnlimited => isUnlimitedAt(DateTime.now());

  int monthlyLimit([DateTime? now]) =>
      planInfo(effectivePlanAt(now ?? DateTime.now())).monthlyPulses ??
      fairUseMonthlyPulses;

  /// Pulses that can still be posted: the plan's own first, then packs
  /// (packs do not apply on an unlimited plan).
  int pulsesLeft(DateTime now) {
    final included = (monthlyLimit(now) - usedThisMonth(now)).clamp(0, 1 << 30);
    return isUnlimitedAt(now) ? included : included + packBalance;
  }
}
