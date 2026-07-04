import 'package:flutter/material.dart';
import '../feedback/de_toast.dart';
import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

void showDESaveBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const DESaveBottomSheet(),
  );
}

class DESaveBottomSheet extends StatelessWidget {
  const DESaveBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DESpacing.lg),
      decoration: const BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DERadius.extraLarge),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: DEColors.border,
                    borderRadius: BorderRadius.circular(DERadius.pill),
                  ),
                ),
              ),

              const SizedBox(height: DESpacing.lg),

              const Text(
                "Save to...",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 6),

              const Text(
                "Choose where this experience should go.",
                style: TextStyle(color: DEColors.textSecondary),
              ),

              const SizedBox(height: DESpacing.lg),

              const _SaveOption(
                title: "📍 Nassau",
                subtitle: "Unsorted",
                selected: true,
              ),

              const _SaveOption(
                title: "🍽 Restaurants",
                subtitle: "Custom list",
              ),

              const _SaveOption(
                title: "❤️ Date Night",
                subtitle: "Custom list",
              ),

              const _SaveOption(
                title: "＋ Create New List",
                subtitle: "Organize this your way",
              ),

              const SizedBox(height: DESpacing.md),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DEColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DERadius.pill),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);

                    showDEToast(
                      context,
                      title: "Saved",
                      message: "Nassau • Unsorted",
                    );
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(fontWeight: FontWeight.w800),
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

class _SaveOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;

  const _SaveOption({
    required this.title,
    required this.subtitle,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DESpacing.sm),
      padding: const EdgeInsets.all(DESpacing.md),
      decoration: BoxDecoration(
        color: selected
            ? DEColors.primary.withValues(alpha: 0.08)
            : DEColors.background,
        borderRadius: BorderRadius.circular(DERadius.large),
        border: Border.all(
          color: selected ? DEColors.primary : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? DEColors.primary : DEColors.textSecondary,
          ),
          const SizedBox(width: DESpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                subtitle,
                style: const TextStyle(
                  color: DEColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
