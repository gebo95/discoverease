import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/business_plan.dart';
import '../../../services/firebase_billing_service.dart';

/// Opens a Stripe address. Replaceable in tests.
typedef OpenLink = Future<bool> Function(Uri uri);

Future<bool> openBillingLink(Uri uri) =>
    launchUrl(uri, webOnlyWindowName: '_self');

/// Compares plans, shows Pulses left, sells Pulse packs and opens Stripe's
/// billing page. Nothing changes here until Stripe confirms the payment.
class PlansPage extends StatelessWidget {
  const PlansPage({super.key, required this.uid, this.openLink = openBillingLink});

  final String uid;
  final OpenLink openLink;

  @override
  Widget build(BuildContext context) {
    final billing = context.read<FirebaseBillingService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Plans and Pulses')),
      body: StreamBuilder<BillingSummary>(
        stream: billing.watch(uid),
        builder: (context, snapshot) {
          final summary = snapshot.data ?? BillingSummary.empty;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PulsesLeftCard(summary: summary),
              const SizedBox(height: 20),
              Text('Plans', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final plan in businessPlans)
                _PlanCard(
                  plan: plan,
                  current: summary.effectivePlan == plan.id,
                  onChoose: plan.id == BusinessPlanId.free
                      ? null
                      : () => _go(
                          context,
                          !summary.hasPaidPlan
                              ? billing.checkoutUrl(
                                  uid: uid,
                                  product: plan.id == BusinessPlanId.plus
                                      ? BillingProduct.plus
                                      : BillingProduct.pro,
                                )
                              : billing.portalUrl(uid),
                        ),
                  changesPlan: summary.hasPaidPlan,
                ),
              const SizedBox(height: 20),
              Text('Pulse packs', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text(
                'Extra Pulses that never expire. They are used after your '
                'monthly Pulses run out.',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _go(
                      context,
                      billing.checkoutUrl(uid: uid, product: BillingProduct.pack5),
                    ),
                    child: const Text('Add 5 Pulses'),
                  ),
                  OutlinedButton(
                    onPressed: () => _go(
                      context,
                      billing.checkoutUrl(uid: uid, product: BillingProduct.pack15),
                    ),
                    child: const Text('Add 15 Pulses'),
                  ),
                ],
              ),
              if (summary.effectivePlan == BusinessPlanId.pro)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Pro already includes unlimited Pulses, so packs are not needed.'),
                ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => _go(context, billing.portalUrl(uid)),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Manage billing and receipts'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _go(BuildContext context, Future<Uri> url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final opened = await openLink(await url);
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the billing page.')),
        );
      }
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open billing. Try again.')),
      );
    }
  }
}

/// "Plus plan · 11 Pulses left this month", shown on the plans page and the
/// business dashboard.
class PulsesLeftCard extends StatelessWidget {
  const PulsesLeftCard({super.key, required this.summary, this.onTap, this.now});

  final BillingSummary summary;
  final VoidCallback? onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final clock = now ?? DateTime.now();
    final plan = planInfo(summary.effectivePlanAt(clock));
    final left = summary.pulsesLeft(clock);
    final unlimited = summary.isUnlimitedAt(clock);
    final packs = summary.packBalance;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.bolt_rounded),
        title: Text(
          unlimited
              ? '${plan.label} plan · Unlimited Pulses'
              : '${plan.label} plan · $left Pulses left this month',
        ),
        subtitle: Text(
          [
            unlimited ? 'Fair use: up to $fairUseMonthlyPulses a month' : plan.pulsesText,
            if (packs > 0 && !summary.isUnlimitedAt(clock)) '$packs from packs',
            if (summary.hasGrant(clock) && summary.compUntil != null)
              'Free until ${_date(summary.compUntil!)}',
            if (summary.cancelAtPeriodEnd && summary.currentPeriodEnd != null)
              'Ends ${_date(summary.currentPeriodEnd!)}',
          ].join(' · '),
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.current,
    required this.onChoose,
    required this.changesPlan,
  });

  final BusinessPlanInfo plan;
  final bool current;
  final VoidCallback? onChoose;
  final bool changesPlan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plan.label, style: Theme.of(context).textTheme.titleMedium),
                ),
                if (current)
                  const Flexible(
                    child: Chip(
                      label: Text('Your plan', overflow: TextOverflow.ellipsis),
                    ),
                  ),
              ],
            ),
            Text(plan.pulsesText),
            const SizedBox(height: 6),
            for (final perk in plan.perks)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(perk)),
                  ],
                ),
              ),
            if (!current && onChoose != null) ...[
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onChoose,
                child: Text(changesPlan ? 'Change in billing' : 'Choose ${plan.label}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Picks 7 or 30 days of Featured placement for one experience and opens
/// checkout. Returns after the checkout page has been opened.
Future<void> showFeatureDialog({
  required BuildContext context,
  required String uid,
  required String experienceId,
  required String title,
  OpenLink openLink = openBillingLink,
}) async {
  final billing = context.read<FirebaseBillingService>();
  final messenger = ScaffoldMessenger.of(context);
  final product = await showDialog<BillingProduct>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text('Feature "$title"'),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            'Featured experiences show first in Discover This Week and '
            'Explore, with a Featured label.',
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, BillingProduct.featured7),
          child: const Text('Feature for 7 days'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, BillingProduct.featured30),
          child: const Text('Feature for 30 days'),
        ),
      ],
    ),
  );
  if (product == null) return;
  try {
    await openLink(
      await billing.checkoutUrl(uid: uid, product: product, experienceId: experienceId),
    );
  } on StateError catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open checkout. Try again.')),
    );
  }
}
