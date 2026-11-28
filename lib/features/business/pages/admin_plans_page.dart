import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/business_plan.dart';
import '../../../services/firebase_billing_service.dart';

/// Admin only: give a business a plan for some months without Stripe (for
/// example a founding partner's free Plus), or remove one. The grant ends by
/// itself; the server checks that the caller is an admin.
class AdminPlansPage extends StatefulWidget {
  const AdminPlansPage({super.key});

  @override
  State<AdminPlansPage> createState() => _AdminPlansPageState();
}

class _AdminPlansPageState extends State<AdminPlansPage> {
  final _email = TextEditingController();
  BusinessPlanId _plan = BusinessPlanId.plus;
  int _months = 6;
  bool _busy = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _apply({required bool remove}) async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'Enter the business email.';
        _result = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final message = await context.read<FirebaseBillingService>().grantPlan(
        email: email,
        plan: remove ? BusinessPlanId.free : _plan,
        months: remove ? 0 : _months,
      );
      if (mounted) setState(() => _result = message);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not change the plan. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business plans')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Give a business a plan without payment, such as a founding '
            'partner\'s free months. It ends by itself on the date shown.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Business email',
              helperText: 'The email on the business profile.',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Plan'),
          Wrap(
            spacing: 8,
            children: [
              for (final id in [BusinessPlanId.plus, BusinessPlanId.pro])
                ChoiceChip(
                  label: Text(planInfo(id).label),
                  selected: _plan == id,
                  onSelected: _busy ? null : (_) => setState(() => _plan = id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('For how long'),
          Wrap(
            spacing: 8,
            children: [
              for (final months in const [1, 3, 6, 12])
                ChoiceChip(
                  label: Text(months == 12 ? '1 year' : '$months mo'),
                  selected: _months == months,
                  onSelected: _busy ? null : (_) => setState(() => _months = months),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy ? null : () => _apply(remove: false),
                child: const Text('Give plan'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => _apply(remove: true),
                child: const Text('Remove granted plan'),
              ),
            ],
          ),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_result!),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
