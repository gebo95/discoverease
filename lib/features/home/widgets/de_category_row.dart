import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../explore/pages/explore_page.dart';
import '../../main_shell/main_shell_controller.dart';
import '../../../shared/navigation/de_page_route.dart';
import '../../../models/listing.dart';
import '../../../shared/components/cards/de_experience_card.dart';
import '../../../shared/components/sections/de_section_header.dart';
import '../../listing/pages/listing_detail_page.dart';

class DECategoryRow extends StatelessWidget {
  final String title;
  final List<Listing> listings;
  final String? sectionCategory;

  const DECategoryRow({
    super.key,
    required this.title,
    required this.listings,
    this.sectionCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DESectionHeader(
          title: title,
          actionText: "See all",
          // Opens Explore with this row's category already chosen.
          onAction: () => openExploreFrom(
            context,
            category: sectionCategory ?? title,
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];

              return DEExperienceCard(
                listing: listing,
                sectionCategory: sectionCategory,
                onTap: () {
                  Navigator.push(
                    context,
                    dePageRoute(page: ListingDetailPage(listing: listing)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


/// Goes to the Explore tab (keeping the bottom bar) with something chosen.
/// Where there is no tab bar to go through, opens Explore as its own page with
/// a back button instead.
void openExploreFrom(
  BuildContext context, {
  String? category,
  String? areaId,
  String? filter,
}) {
  final shell = context.read<MainShellController?>();
  if (shell != null) {
    shell.openExplore(category: category, areaId: areaId, filter: filter);
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ExplorePage(
        initialCategory: category,
        initialAreaId: areaId,
        initialFilter: filter,
        showBackButton: true,
      ),
    ),
  );
}
