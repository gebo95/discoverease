import 'package:flutter/material.dart';

import 'features/home/pages/home_page.dart';
import 'shared/theme/de_theme.dart';

class DiscoverEaseApp extends StatelessWidget {
  const DiscoverEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DiscoverEase',
      theme: DETheme.lightTheme,
      home: const HomePage(),
    );
  }
}
