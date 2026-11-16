import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DEDayPicker extends StatelessWidget {
  final List<String> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const DEDayPicker({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              margin: const EdgeInsets.only(right: DESpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? DEColors.primary : DEColors.surface,
                borderRadius: BorderRadius.circular(DERadius.pill),
                border: Border.all(
                  color: isSelected ? DEColors.primary : DEColors.border,
                ),
              ),
              child: Text(
                days[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : DEColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
