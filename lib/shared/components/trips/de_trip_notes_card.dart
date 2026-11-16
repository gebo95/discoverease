import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_spacing.dart';

class DETripNotesCard extends StatelessWidget {
  final String? notes;
  final VoidCallback? onTap;

  const DETripNotesCard({super.key, this.notes, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasNotes = notes != null && notes!.trim().isNotEmpty;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DEColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: DEColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: DEColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasNotes
                          ? notes!.trim()
                          : 'Add trip notes, reminders, reservations, or packing details.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasNotes
                            ? DEColors.textPrimary
                            : DEColors.textSecondary,
                        height: 1.4,
                        fontWeight: hasNotes
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: DEColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
