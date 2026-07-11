import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DESearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const DESearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DESpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.pill),
        border: Border.all(color: DEColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: DEColors.textSecondary,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: DEColors.textSecondary,
            fontSize: 15,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
