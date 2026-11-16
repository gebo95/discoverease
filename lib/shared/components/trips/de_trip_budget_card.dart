import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_spacing.dart';

class DETripBudgetCard extends StatelessWidget {
  final double estimatedBudget;
  final double? spentAmount;
  final VoidCallback? onTap;
  final String subtitle;
  final String emptyMessage;

  const DETripBudgetCard({
    super.key,
    required this.estimatedBudget,
    this.spentAmount,
    this.onTap,
    this.subtitle = 'Total estimated cost of planned experiences',
    this.emptyMessage = 'Add an estimated cost to an experience to include it in this total.',
  });

  @override
  Widget build(BuildContext context) {
    final hasSpentAmount = spentAmount != null;
    final remainingAmount = estimatedBudget - (spentAmount ?? 0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(DESpacing.md),
          decoration: BoxDecoration(
            color: DEColors.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: DEColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: DEColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: DEColors.textPrimary,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: DEColors.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: DESpacing.md),
              Text(
                _formatCurrency(estimatedBudget),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: DEColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: DEColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasSpentAmount) ...[
                const SizedBox(height: DESpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _BudgetStat(
                        label: 'Spent',
                        value: _formatCurrency(spentAmount!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BudgetStat(
                        label: remainingAmount >= 0
                            ? 'Remaining'
                            : 'Over budget',
                        value: _formatCurrency(remainingAmount.abs()),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: DESpacing.sm),
                Text(
                  emptyMessage,
                  style: TextStyle(color: DEColors.textSecondary, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCurrency(double amount) {
    final hasDecimals = amount != amount.roundToDouble();

    return hasDecimals
        ? '\$${amount.toStringAsFixed(2)}'
        : '\$${amount.toStringAsFixed(0)}';
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;

  const _BudgetStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DESpacing.sm),
      decoration: BoxDecoration(
        color: DEColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: DEColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: DEColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
