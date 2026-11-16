import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DENextUpCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? time;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onBrowse;

  const DENextUpCard({
    super.key,
    this.title,
    this.subtitle,
    this.time,
    this.imageUrl,
    this.onTap,
    this.onBrowse,
  });

  bool get hasNextExperience {
    return title != null && title!.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasNextExperience) {
      return _EmptyNextUpCard(onBrowse: onBrowse);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: DESpacing.lg),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
        child: Padding(
          padding: const EdgeInsets.all(DESpacing.md),
          child: Row(
            children: [
              _ExperienceImage(imageUrl: imageUrl),
              const SizedBox(width: DESpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEXT UP',
                      style: TextStyle(
                        color: DEColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DEColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (time != null && time!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 17,
                            color: DEColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              time!,
                              style: const TextStyle(
                                color: DEColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DEColors.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Text(
                          'View experience',
                          style: TextStyle(
                            color: DEColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: DEColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExperienceImage extends StatelessWidget {
  final String? imageUrl;

  const _ExperienceImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DERadius.large),
      child: SizedBox(
        width: 96,
        height: 120,
        child: imageUrl == null || imageUrl!.isEmpty
            ? const ColoredBox(
                color: DEColors.background,
                child: Icon(
                  Icons.explore_rounded,
                  color: DEColors.primary,
                  size: 34,
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(
                    color: DEColors.background,
                    child: Icon(
                      Icons.explore_rounded,
                      color: DEColors.primary,
                      size: 34,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyNextUpCard extends StatelessWidget {
  final VoidCallback? onBrowse;

  const _EmptyNextUpCard({this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DESpacing.lg),
      padding: const EdgeInsets.all(DESpacing.lg),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: DEColors.primary),
              SizedBox(width: 8),
              Text(
                'TODAY IS WIDE OPEN',
                style: TextStyle(
                  color: DEColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Plenty of time to explore',
            style: TextStyle(
              color: DEColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'The best adventures are sometimes unplanned.',
            style: TextStyle(
              color: DEColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DESpacing.md),
          FilledButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.explore_rounded),
            label: const Text('Browse experiences'),
          ),
        ],
      ),
    );
  }
}
