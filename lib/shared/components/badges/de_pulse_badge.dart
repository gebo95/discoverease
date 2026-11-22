import 'package:flutter/material.dart';

/// "● Live Music": a small pill with a softly flashing dot, shown on a card
/// when the business has an active Pulse. The dot stops flashing when the
/// device asks for reduced motion.
class DEPulseBadge extends StatefulWidget {
  const DEPulseBadge({super.key, required this.label, this.animate = true});

  final String label;

  /// Flash while the traveler has not seen this post yet. Once they have, the
  /// dot holds still, so a flashing one means something new.
  final bool animate;

  @override
  State<DEPulseBadge> createState() => _DEPulseBadgeState();
}

class _DEPulseBadgeState extends State<DEPulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(DEPulseBadge old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still =
        !widget.animate || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (still) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFF5A5F), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.25, end: 1).animate(_controller),
            child: const Icon(Icons.circle, size: 9, color: Color(0xFFFF5A5F)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
