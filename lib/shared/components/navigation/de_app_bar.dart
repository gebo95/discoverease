import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';

class DEAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String destination;
  final String location;
  final VoidCallback? onDestinationTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const DEAppBar({
    super.key,
    required this.destination,
    required this.location,
    this.onDestinationTap,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 90,

      title: GestureDetector(
        onTap: onDestinationTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              destination,
              style: const TextStyle(
                color: DEColors.textSecondary,
                fontSize: 13,
              ),
            ),
            Row(
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    color: DEColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: DEColors.primary),
              ],
            ),
          ],
        ),
      ),

      actions: [
        IconButton(
          onPressed: onNotificationsTap,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: DEColors.textPrimary,
          ),
        ),

        IconButton(
          onPressed: onProfileTap,
          icon: const CircleAvatar(radius: 16, child: Icon(Icons.person)),
        ),

        const SizedBox(width: 8),
      ],
    );
  }
}
