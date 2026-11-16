import 'package:flutter/material.dart';

import 'de_colors.dart';

class DETheme {
  DETheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: DEColors.background,

    colorScheme: ColorScheme.fromSeed(
      seedColor: DEColors.primary,
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
