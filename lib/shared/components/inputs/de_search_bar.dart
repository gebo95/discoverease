import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DESearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;

  const DESearchBar({
    super.key,
    this.hintText = "Search restaurants, tours, festivals...",
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DESpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: DEColors.surface,
          borderRadius: BorderRadius.circular(DERadius.pill),
          border: Border.all(color: DEColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: DEColors.textSecondary),
            const SizedBox(width: DESpacing.sm),
            Text(
              hintText,
              style: const TextStyle(
                color: DEColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
