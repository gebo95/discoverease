import 'package:flutter/material.dart';

import '../../../models/trip.dart';
import '../../../models/trip_section.dart';
import '../../../repositories/listing_repository.dart';
import '../../../shared/components/cards/de_trip_experience_card.dart';
import '../../../repositories/trip_repository.dart';
import '../../../shared/components/cards/de_on_my_list_card.dart';
import '../../../shared/components/sections/de_day_section.dart';
import '../../../shared/components/bottom_sheets/de_plan_experience_sheet.dart';
import '../../../repositories/saved_repository.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_spacing.dart';
import '../../../shared/components/bottom_sheets/de_on_my_list_actions_sheet.dart';
import '../../../shared/components/feedback/de_toast.dart';
import 'package:provider/provider.dart';

class TripDashboardPage extends StatefulWidget {
  final Trip trip;

  const TripDashboardPage({super.key, required this.trip});

  @override
  State<TripDashboardPage> createState() => _TripDashboardPageState();
}

class _TripDashboardPageState extends State<TripDashboardPage> {
  int selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final listingRepository = context.read<ListingRepository>();
    final savedRepository = context.read<SavedRepository>();
    final tripRepository = context.watch<TripRepository>();
    final trip = tripRepository.getCurrentTrip();

    final savedExperiences = savedRepository
        .getSavedForDestination(trip.destination)
        .where((saved) => !tripRepository.isListingPlanned(saved.listingId))
        .toList();

    final selectedDay = trip.days[selectedDayIndex];

    final morning = selectedDay.experiences
        .where((e) => e.section == TripSection.morning)
        .toList();

    final afternoon = selectedDay.experiences
        .where((e) => e.section == TripSection.afternoon)
        .toList();

    final evening = selectedDay.experiences
        .where((e) => e.section == TripSection.evening)
        .toList();

    return Scaffold(
      backgroundColor: DEColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DESpacing.md),
          children: [
            IconButton(
              alignment: Alignment.centerLeft,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),

            Text(
              trip.title,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 6),

            Text(
              "${trip.destination} • 2 travelers",
              style: const TextStyle(
                color: DEColors.textSecondary,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trip.days.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedDayIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDayIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? DEColors.primary : DEColors.surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        trip.days[index].title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : DEColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 26),

            DEDaySection(
              title: "☀️ Morning",
              experiences: morning.map((tripExperience) {
                final listing = listingRepository.getById(
                  tripExperience.listingId,
                );

                return DETripExperienceCard(
                  title: listing?.title ?? "Unknown Experience",
                  time: tripExperience.time?.format(context),
                  note: tripExperience.notes,
                  estimatedCost: tripExperience.estimatedCost,
                  completed: tripExperience.completed,
                );
              }).toList(),
            ),

            DEDaySection(
              title: "🌤 Afternoon",
              experiences: afternoon.map((tripExperience) {
                final listing = listingRepository.getById(
                  tripExperience.listingId,
                );

                return DETripExperienceCard(
                  title: listing?.title ?? "Unknown Experience",
                  time: tripExperience.time?.format(context),
                  note: tripExperience.notes,
                  estimatedCost: tripExperience.estimatedCost,
                  completed: tripExperience.completed,
                );
              }).toList(),
            ),

            DEDaySection(
              title: "🌅 Evening",
              experiences: evening.map((tripExperience) {
                final listing = listingRepository.getById(
                  tripExperience.listingId,
                );

                return DETripExperienceCard(
                  title: listing?.title ?? "Unknown Experience",
                  time: tripExperience.time?.format(context),
                  note: tripExperience.notes,
                  estimatedCost: tripExperience.estimatedCost,
                  completed: tripExperience.completed,
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            const Text(
              "✨ On My List",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: savedExperiences.length,
                itemBuilder: (context, index) {
                  final saved = savedExperiences[index];

                  final listing = listingRepository.getById(saved.listingId);

                  if (listing == null) {
                    return const SizedBox.shrink();
                  }

                  return DEOnMyListCard(
                    title: listing.title,
                    imageUrl: listing.imageUrl,
                    onTap: () {
                      showDEOnMyListActionsSheet(
                        context,
                        title: listing.title,
                        onViewListing: () {
                          showDEToast(
                            context,
                            title: "View Listing",
                            message: "Listing page coming next",
                          );
                        },
                        onPlanExperience: () {
                          showDEPlanExperienceSheet(
                            context,
                            experienceTitle: listing.title,
                            days: trip.days.map((day) => day.title).toList(),
                            onPlan: (dayIndex, section) {
                              tripRepository.planExperience(
                                listingId: listing.id,
                                dayIndex: dayIndex,
                                section: section,
                              );

                              showDEToast(
                                context,
                                title: "Planned!",
                                message:
                                    "${listing.title} planned for ${trip.days[dayIndex].title}.",
                              );
                            },
                          );
                        },
                        onRemove: () {
                          showDEToast(
                            context,
                            title: "Removed",
                            message: "${listing.title} removed from your list",
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            const _DashboardCard(
              title: "💰 Budget",
              body: "Trip estimate: \$3,200 • Today estimate coming soon",
            ),

            const SizedBox(height: 14),

            const _DashboardCard(
              title: "📝 Notes",
              body:
                  "Add trip notes, reminders, reservations, or packing details.",
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String body;

  const _DashboardCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DESpacing.md),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: DEColors.textSecondary)),
        ],
      ),
    );
  }
}
