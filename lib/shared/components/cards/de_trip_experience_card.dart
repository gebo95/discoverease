import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DETripExperienceCard extends StatelessWidget {
  final String title;
  final String? time;
  final String? note;
  final double? estimatedCost;
  final bool completed;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onMore;
  final ValueChanged<bool>? onCompletedChanged;

  const DETripExperienceCard({
    super.key,
    required this.title,
    this.time,
    this.note,
    this.estimatedCost,
    this.completed = false,
    this.onTap,
    this.onEdit,
    this.onMore,
    this.onCompletedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cost = estimatedCost;
    return InkWell(
      borderRadius: BorderRadius.circular(DERadius.large),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DESpacing.md),
        padding: const EdgeInsets.all(DESpacing.md),
        decoration: BoxDecoration(
          color: DEColors.surface,
          borderRadius: BorderRadius.circular(DERadius.large),
          border: Border.all(color: DEColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: completed,
              onChanged: onCompletedChanged == null
                  ? null
                  : (value) {
                      if (value != null) onCompletedChanged!(value);
                    },
            ),

            const SizedBox(width: DESpacing.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),

                  if (time != null || cost != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 16,
                        children: [
                          if (time != null) Text("🕒 $time"),

                          if (cost != null)
                            Text(
                              '💰 \$${cost.toStringAsFixed(cost == cost.roundToDouble() ? 0 : 2)}',
                            ),
                        ],
                      ),
                    ),

                  if (note != null && note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        note!,
                        style: const TextStyle(color: DEColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),

            if (onEdit != null || onMore != null)
              PopupMenuButton<String>(
                tooltip: 'Experience options',
                onSelected: (action) {
                  if (action == 'edit') onEdit?.call();
                  if (action == 'remove') onMore?.call();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit cost and note'),
                    ),
                  if (onMore != null)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from trip'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
