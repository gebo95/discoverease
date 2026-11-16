import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DEFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const DEFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: DESpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? DEColors.primary : DEColors.surface,
          borderRadius: BorderRadius.circular(DERadius.pill),
          border: Border.all(
            color: selected ? DEColors.primary : DEColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : DEColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
