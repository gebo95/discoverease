import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

void showDEToast(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final overlay = Overlay.of(context);

  final entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        left: DESpacing.md,
        right: DESpacing.md,
        bottom: 32,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(DESpacing.md),
            decoration: BoxDecoration(
              color: DEColors.textPrimary,
              borderRadius: BorderRadius.circular(DERadius.extraLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: DEColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: DESpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);

  Future.delayed(const Duration(seconds: 2), () {
    entry.remove();
  });
}
