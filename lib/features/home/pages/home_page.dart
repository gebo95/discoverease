import 'package:flutter/material.dart';

import '../../../shared/components/cards/de_listing_card.dart';
import '../../../shared/components/navigation/de_app_bar.dart';
import '../widgets/live_now_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DEAppBar(destination: "Bahamas", location: "Nassau"),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),

          const Text(
            "Find your next adventure",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          const TextField(
            decoration: InputDecoration(
              hintText: "Search restaurants, tours, festivals...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "⭐ Featured Experiences",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 150),

          const LiveNowSection(),

          const SizedBox(height: 150),

          const Text(
            "🍽 Categories",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 150),

          const Text(
            "🏝 Listings",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          DEListingCard(
            title: "Graycliff Restaurant",
            subtitle: "Historic Bahamian fine dining",
            category: "🍽 Restaurant",
            location: "Nassau",
            imageUrl:
                "https://images.unsplash.com/photo-1555396273-367ea4eb4db5",
            rating: 4.9,
            price: r"$$$",
            status: "OPEN NOW",
            pulse: "Live Jazz Tonight",
          ),

          DEListingCard(
            title: "Exuma Swimming Pigs Tour",
            subtitle: "A once-in-a-lifetime island adventure",
            category: "🚤 Tour",
            location: "Exuma",
            imageUrl:
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
            rating: 4.8,
            price: r"$$",
            status: "BOOKING",
            pulse: "Few spots left today",
          ),
        ],
      ),
    );
  }
}
