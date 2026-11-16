import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_spacing.dart';

class DESectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String actionText;
  final VoidCallback? onAction;

  const DESectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText = "See All",
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DESpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: DEColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: DEColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          TextButton(onPressed: onAction, child: Text(actionText)),
        ],
      ),
    );
  }
}
