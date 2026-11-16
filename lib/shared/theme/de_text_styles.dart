import 'package:flutter/material.dart';

import 'de_colors.dart';

class DETextStyles {
  DETextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: DEColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: DEColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: DEColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: DEColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: DEColors.textSecondary,
  );
}
