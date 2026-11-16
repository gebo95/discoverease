import 'package:flutter/material.dart';

import '../../../models/trip_section.dart';
import '../../theme/de_colors.dart';
import '../../theme/de_spacing.dart';
import '../cards/de_trip_experience_card.dart';

class DETimelineItem {
  final String title;
  final TimeOfDay? time;
  final String? note;
  final double? estimatedCost;
  final bool completed;
  final TripSection section;
  final ValueChanged<bool>? onCompletedChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit;

  const DETimelineItem({
    required this.title,
    required this.section,
    required this.completed,
    this.time,
    this.note,
    this.estimatedCost,
    this.onCompletedChanged,
    this.onRemove,
    this.onEdit,
  });
}

class DETripTimeline extends StatelessWidget {
  final List<DETimelineItem> items;
  final VoidCallback? onAddExperience;

  const DETripTimeline({super.key, required this.items, this.onAddExperience});

  @override
  Widget build(BuildContext context) {
    final sortedItems = [...items]..sort(_compareItems);

    if (sortedItems.isEmpty) {
      return _EmptyTimeline(onAddExperience: onAddExperience);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Day',
          style: TextStyle(
            color: DEColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: DESpacing.md),
        ...List.generate(sortedItems.length, (index) {
          final item = sortedItems[index];

          return _TimelineRow(
            item: item,
            isFirst: index == 0,
            isLast: index == sortedItems.length - 1,
          );
        }),
      ],
    );
  }

  static int _compareItems(DETimelineItem a, DETimelineItem b) {
    final aMinutes = _minutesForItem(a);
    final bMinutes = _minutesForItem(b);

    return aMinutes.compareTo(bMinutes);
  }

  static int _minutesForItem(DETimelineItem item) {
    if (item.time != null) {
      return (item.time!.hour * 60) + item.time!.minute;
    }

    return switch (item.section) {
      TripSection.morning => 8 * 60,
      TripSection.afternoon => 13 * 60,
      TripSection.evening => 18 * 60,
    };
  }
}

class _TimelineRow extends StatelessWidget {
  final DETimelineItem item;
  final bool isFirst;
  final bool isLast;

  const _TimelineRow({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : DEColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                _TimelineMarker(
                  icon: _sectionIcon(item.section),
                  completed: item.completed,
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : DEColors.primary.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: DESpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimelineLabel(item: item),
                  const SizedBox(height: 8),
                  DETripExperienceCard(
                    title: item.title,
                    onTap: item.onEdit,
                    time: item.time?.format(context),
                    note: item.note,
                    estimatedCost: item.estimatedCost,
                    completed: item.completed,
                    onCompletedChanged: item.onCompletedChanged,
                    onEdit: item.onEdit,
                    onMore: item.onRemove,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _sectionIcon(TripSection section) {
    return switch (section) {
      TripSection.morning => Icons.wb_sunny_rounded,
      TripSection.afternoon => Icons.light_mode_rounded,
      TripSection.evening => Icons.nights_stay_rounded,
    };
  }
}

class _TimelineMarker extends StatelessWidget {
  final IconData icon;
  final bool completed;

  const _TimelineMarker({required this.icon, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: completed ? DEColors.primary : DEColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: DEColors.primary.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Icon(
        completed ? Icons.check_rounded : icon,
        size: 19,
        color: completed ? Colors.white : DEColors.primary,
      ),
    );
  }
}

class _TimelineLabel extends StatelessWidget {
  final DETimelineItem item;

  const _TimelineLabel({required this.item});

  @override
  Widget build(BuildContext context) {
    final sectionLabel = switch (item.section) {
      TripSection.morning => 'Morning',
      TripSection.afternoon => 'Afternoon',
      TripSection.evening => 'Evening',
    };

    return Row(
      children: [
        if (item.time != null) ...[
          Text(
            item.time!.format(context),
            style: const TextStyle(
              color: DEColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: DEColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          sectionLabel,
          style: const TextStyle(
            color: DEColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  final VoidCallback? onAddExperience;

  const _EmptyTimeline({this.onAddExperience});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DESpacing.lg),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: DEColors.primary,
            size: 30,
          ),
          const SizedBox(height: 12),
          const Text(
            'This day is yours',
            style: TextStyle(
              color: DEColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Keep it open or add an experience when inspiration strikes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DEColors.textSecondary, height: 1.4),
          ),
          if (onAddExperience != null) ...[
            const SizedBox(height: DESpacing.md),
            FilledButton.icon(
              onPressed: onAddExperience,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Find something to do'),
            ),
          ],
        ],
      ),
    );
  }
}
