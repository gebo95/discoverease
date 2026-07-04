import 'package:flutter/material.dart';

import '../../../shared/components/inputs/de_search_bar.dart';
import '../../../shared/components/navigation/de_app_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/live_now_section.dart';
import '../widgets/featured_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DEAppBar(destination: "Bahamas", location: "Nassau"),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          HomeHeader(),

          SizedBox(height: 18),

          DESearchBar(),

          SizedBox(height: 26),

          FeaturedSection(),

          SizedBox(height: 28),

          LiveNowSection(),

          SizedBox(height: 28),

          _SectionTitle(title: "🍽 Top Dining"),

          SizedBox(height: 120),

          _SectionTitle(title: "🚤 Adventures"),

          SizedBox(height: 120),

          _SectionTitle(title: "🏝 Hidden Gems"),

          SizedBox(height: 120),

          _ContinuePlanningCard(),

          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    );
  }
}

class _ContinuePlanningCard extends StatelessWidget {
  const _ContinuePlanningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📌 Continue Planning",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12),
          Text(
            "Bahamas Trip",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text("8 places saved • Estimated budget \$1,450"),
          SizedBox(height: 12),
          Text(
            "Day 2 still needs lunch",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
