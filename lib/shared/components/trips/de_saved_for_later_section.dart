import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DESavedForLaterItem {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;
  final VoidCallback onAddToDay;

  const DESavedForLaterItem({
    required this.title,
    required this.imageUrl,
    required this.onTap,
    required this.onAddToDay,
  });
}

class DESavedForLaterSection extends StatelessWidget {
  final List<DESavedForLaterItem> items;
  final String selectedDayTitle;
  final VoidCallback? onBrowse;

  const DESavedForLaterSection({
    super.key,
    required this.items,
    required this.selectedDayTitle,
    this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved for Later',
                    style: TextStyle(
                      color: DEColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Ideas you can add whenever the moment feels right.',
                    style: TextStyle(
                      color: DEColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _CountBadge(count: items.length),
          ],
        ),
        const SizedBox(height: DESpacing.md),
        if (items.isEmpty)
          _EmptySavedState(onBrowse: onBrowse)
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: DESpacing.md),
              itemBuilder: (context, index) {
                return _SavedForLaterCard(
                  item: items[index],
                  selectedDayTitle: selectedDayTitle,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: DEColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count saved',
        style: const TextStyle(
          color: DEColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SavedForLaterCard extends StatelessWidget {
  final DESavedForLaterItem item;
  final String selectedDayTitle;

  const _SavedForLaterCard({
    required this.item,
    required this.selectedDayTitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Material(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 112,
                width: double.infinity,
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return const ColoredBox(
                      color: DEColors.background,
                      child: Icon(
                        Icons.explore_rounded,
                        color: DEColors.primary,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DEColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: item.onAddToDay,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            'Add to $selectedDayTitle',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySavedState extends StatelessWidget {
  final VoidCallback? onBrowse;

  const _EmptySavedState({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DESpacing.lg),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DEColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: DEColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nothing saved yet',
            style: TextStyle(
              color: DEColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Save places that catch your eye and keep them here for later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DEColors.textSecondary, height: 1.4),
          ),
          if (onBrowse != null) ...[
            const SizedBox(height: DESpacing.md),
            OutlinedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Browse experiences'),
            ),
          ],
        ],
      ),
    );
  }
}
