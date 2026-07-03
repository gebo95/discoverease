import 'package:flutter/material.dart';

import '../../../shared/components/navigation/de_app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DEAppBar(destination: "Bahamas", location: "Nassau"),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 10),

          Text(
            "Find your next adventure",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 12),

          TextField(
            decoration: InputDecoration(
              hintText: "Search restaurants, tours, festivals...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),

          SizedBox(height: 30),

          Text(
            "⭐ Featured Experiences",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 150),

          Text(
            "🔥 Live Now",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 150),

          Text(
            "🍽 Categories",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 150),

          Text(
            "🏝 Listings",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 300),
        ],
      ),
    );
  }
}
