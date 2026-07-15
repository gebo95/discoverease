import 'package:flutter/material.dart';

import '../../../models/listing.dart';
import '../../../shared/components/cards/de_experience_card.dart';
import '../../../shared/components/sections/de_section_header.dart';

class DECategoryRow extends StatelessWidget {
  final String title;
  final List<Listing> listings;

  const DECategoryRow({super.key, required this.title, required this.listings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DESectionHeader(title: title, actionText: "See all", onAction: () {}),

        const SizedBox(height: 14),

        SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];

              return DEExperienceCard(
                listing: listing,
                onTap: () {},
                onSave: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}
