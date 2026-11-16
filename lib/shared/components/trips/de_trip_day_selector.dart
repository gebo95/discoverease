import 'package:flutter/material.dart';

import '../../../models/trip_day.dart';
import '../../theme/de_colors.dart';

class DETripDaySelector extends StatelessWidget {
  final List<TripDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const DETripDaySelector({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = selectedIndex == index;
          final dayLabel = day.date == null
              ? day.title
              : '${day.title} · '
                    '${MaterialLocalizations.of(context).formatShortDate(day.date!)}';

          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? DEColors.primary : DEColors.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                dayLabel,
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
