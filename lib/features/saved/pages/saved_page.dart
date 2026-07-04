import 'package:flutter/material.dart';

import '../../../shared/components/cards/de_saved_list_card.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_spacing.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DEColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DESpacing.md),
          children: const [
            SizedBox(height: 12),

            Text(
              "Saved",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: DEColors.textPrimary,
              ),
            ),

            SizedBox(height: 6),

            Text(
              "Organize the places you want to experience.",
              style: TextStyle(fontSize: 15, color: DEColors.textSecondary),
            ),

            SizedBox(height: 24),

            DESavedListCard(
              icon: "📥",
              title: "Unsorted",
              subtitle: "6 experiences • Quick saves",
            ),

            DESavedListCard(
              icon: "🍽",
              title: "Restaurants",
              subtitle: "12 experiences • Last added Graycliff",
              imageUrl:
                  "https://images.unsplash.com/photo-1555396273-367ea4eb4db5",
            ),

            DESavedListCard(
              icon: "🏖",
              title: "Beaches",
              subtitle: "4 experiences • Last added Cable Beach",
              imageUrl:
                  "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
            ),

            DESavedListCard(
              icon: "❤️",
              title: "Date Night",
              subtitle: "8 experiences • Romantic ideas",
            ),

            DESavedListCard(
              icon: "＋",
              title: "Create New List",
              subtitle: "Organize this your way",
            ),
          ],
        ),
      ),
    );
  }
}
