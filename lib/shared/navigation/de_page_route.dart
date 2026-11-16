import 'package:flutter/material.dart';

Route<T> dePageRoute<T>({required Widget page}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.025),
        end: Offset.zero,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(position: slideAnimation, child: child),
      );
    },
  );
}
