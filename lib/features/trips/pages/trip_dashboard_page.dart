import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'trip_dashboard_factory.dart';

import '../../../repositories/listing_repository.dart';
import '../../../repositories/destination_repository.dart';
import '../../../repositories/trip_repository.dart';
import '../../../repositories/saved_repository.dart';

import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_spacing.dart';

import '../../../shared/components/trips/de_trip_day_selector.dart';
import '../../../shared/components/trips/de_trip_snapshot.dart';
import '../../../shared/components/trips/de_trip_day_insight.dart';
import '../../../shared/components/trips/de_trip_hero.dart';
import '../../../shared/components/trips/de_trip_notes_card.dart';
import '../../../shared/components/trips/de_trip_timeline.dart';
import '../../../shared/components/trips/de_saved_for_later_section.dart';
import '../../../shared/components/trips/de_trip_budget_card.dart';
import '../../../shared/components/trips/de_right_now_card.dart';

import '../../../models/trip.dart';
import '../../../models/trip_experience.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/components/feedback/de_toast.dart';
import '../../listing/pages/listing_detail_page.dart';
import '../../explore/pages/explore_page.dart';
import 'trip_editor_page.dart';
import '../models/right_now_state.dart';
import '../companion/utils/companion_schedule_utils.dart';

class TripDashboardPage extends StatefulWidget {
  final Trip trip;
  final int initialDayIndex;

  const TripDashboardPage({
    super.key,
    required this.trip,
    this.initialDayIndex = 0,
  });

  @override
  State<TripDashboardPage> createState() => _TripDashboardPageState();
}

class _TripDashboardPageState extends State<TripDashboardPage> {
  late int selectedDayIndex;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    selectedDayIndex = widget.initialDayIndex;
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingRepository = context.watch<ListingRepository>();
    final savedRepository = context.watch<SavedRepository>();
    final tripRepository = context.watch<TripRepository>();
    final trip = tripRepository.getCurrentTrip();

    if (trip.days.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No trip days available.')),
      );
    }

    final dashboard = TripDashboardFactory.build(
      context: context,
      selectedDayIndex: selectedDayIndex,
      listingRepository: listingRepository,
      savedRepository: savedRepository,
      tripRepository: tripRepository,
      onEditExperience: _editExperienceDetails,
    );

    return Scaffold(
      backgroundColor: DEColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DESpacing.md),
          children: [
            Row(
              children: [
                IconButton(
                  alignment: Alignment.centerLeft,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'Edit trip',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripEditorPage(trip: trip),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),

            DETripHero(
              trip: dashboard.trip,
              imageUrl:
                  'https://images.unsplash.com/photo-1552832230-c0197dd311b5',
              savedPlaces: dashboard.savedCount,
            ),

            const SizedBox(height: 24),

            DERightNowCard(
              state: dashboard.rightNow,
              onAction: () => _performCompanionAction(
                dashboard.rightNow,
                dashboard.selectedDay.experiences,
              ),
            ),

            DETripSnapshot(
              plannedExperiences: dashboard.trip.plannedExperiences,
              savedPlaces: dashboard.savedCount,
              estimatedBudget: dashboard.trip.totalEstimatedCost,
              totalDays: dashboard.trip.totalDays,
            ),

            DETripDaySelector(
              days: dashboard.trip.days,
              selectedIndex: dashboard.selectedDayIndex,
              onSelected: (index) {
                setState(() {
                  selectedDayIndex = index;
                });
              },
            ),

            const SizedBox(height: DESpacing.lg),

            DETripDayInsight(
              plannedExperiences: dashboard.selectedDay.experiences.length,
              completedExperiences: dashboard.completedExperiences,
              dayTitle: dashboard.selectedDay.title,
            ),

            const SizedBox(height: DESpacing.lg),

            DETripTimeline(
              items: dashboard.timelineItems,
              onAddExperience: () => _browseForCurrentTrip(trip),
            ),

            const SizedBox(height: 24),

            DESavedForLaterSection(
              items: dashboard.savedItems,
              selectedDayTitle: dashboard.selectedDay.title,
              onBrowse: () => _browseForCurrentTrip(trip),
            ),

            const SizedBox(height: 28),

            DETripBudgetCard(
              estimatedBudget: dashboard.selectedDay.totalEstimatedCost,
              subtitle: 'Estimated cost for ${dashboard.selectedDay.title}',
              emptyMessage:
                  'Add estimated costs to ${dashboard.selectedDay.title} experiences to update this total.',
            ),

            const SizedBox(height: 14),

            DETripNotesCard(
              notes: _combinedNotesPreview(dashboard.trip, listingRepository),
              onTap: () => _editTripNotes(dashboard.trip, listingRepository),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editExperienceDetails(
    TripExperience experience,
    String title,
  ) async {
    final currentCost = experience.estimatedCost;
    final costController = TextEditingController(
      text: currentCost == null
          ? ''
          : currentCost.toStringAsFixed(
              currentCost == currentCost.roundToDouble() ? 0 : 2,
            ),
    );
    final noteController = TextEditingController(text: experience.notes ?? '');
    String? errorText;
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Estimated cost',
                      prefixText: '\$ ',
                      hintText: 'Leave blank if unknown',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Note for this experience',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final text = costController.text.trim().replaceAll(',', '');
                  final cost = text.isEmpty ? null : double.tryParse(text);
                  if (text.isNotEmpty &&
                      (cost == null || !cost.isFinite || cost < 0)) {
                    setDialogState(() => errorText = 'Enter a valid cost or leave it blank.');
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || saved != true) return;
      final text = costController.text.trim().replaceAll(',', '');
      context.read<TripRepository>().updateExperienceDetails(
        experienceId: experience.id,
        estimatedCost: text.isEmpty ? null : double.parse(text),
        notes: noteController.text,
      );
    } finally {
      costController.dispose();
      noteController.dispose();
    }
  }

  String? _combinedNotesPreview(Trip trip, ListingRepository listings) {
    final lines = <String>[];
    final generalNote = trip.notes?.trim();
    if (generalNote != null && generalNote.isNotEmpty) lines.add(generalNote);
    for (final day in trip.days) {
      for (final experience in day.experiences) {
        final note = experience.notes?.trim();
        if (note == null || note.isEmpty) continue;
        final title = listings.getById(experience.listingId)?.title ?? 'Experience';
        lines.add('${day.title} · $title: $note');
      }
    }
    return lines.isEmpty ? null : lines.join('\n');
  }

  Future<void> _editTripNotes(
    Trip trip,
    ListingRepository listings,
  ) async {
    final generalNotes = TextEditingController(text: trip.notes ?? '');
    final experienceNotes = <String, TextEditingController>{
      for (final experience in trip.days.expand((day) => day.experiences))
        experience.id: TextEditingController(text: experience.notes ?? ''),
    };
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Trip notes'),
          content: SizedBox(
            width: 480,
            height: 440,
            child: ListView(
              children: [
                TextField(
                  controller: generalNotes,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'General trip notes',
                    hintText: 'Reminders, packing details, or other trip notes',
                  ),
                ),
                const SizedBox(height: 12),
                for (final day in trip.days)
                  for (final experience in day.experiences)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: experienceNotes[experience.id],
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: listings.getById(experience.listingId)?.title ??
                              'Note for ${day.title}',
                          hintText: 'Optional experience note',
                        ),
                      ),
                    ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save notes'),
            ),
          ],
        ),
      );
      if (!mounted || saved != true) return;
      final repository = context.read<TripRepository>();
      repository.updateNotes(generalNotes.text);
      for (final experience in trip.days.expand((day) => day.experiences)) {
        repository.updateExperienceDetails(
          experienceId: experience.id,
          estimatedCost: experience.estimatedCost,
          notes: experienceNotes[experience.id]?.text,
        );
      }
    } finally {
      generalNotes.dispose();
      for (final controller in experienceNotes.values) {
        controller.dispose();
      }
    }
  }

  void _performCompanionAction(
    RightNowState state,
    List<TripExperience> experiences,
  ) {
    switch (state.action) {
      case CompanionAction.browseExperiences:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExplorePage(
              initialFilter: state.browseFilter,
              showBackButton: true,
            ),
          ),
        );
        break;
      case CompanionAction.viewReservation:
        _showReservationDetails(state);
        break;
      case CompanionAction.openExperience:
        _openExperience(state, experiences);
        break;
      case null:
        break;
    }
  }

  void _browseForCurrentTrip(Trip trip) {
    var destinationId = trip.destinationId;
    if (destinationId == null) {
      final destinations = context.read<DestinationRepository>().getAll();
      for (final destination in destinations) {
        if (destination.country.toLowerCase() == trip.destination.toLowerCase() ||
            destination.name.toLowerCase() == trip.destination.toLowerCase()) {
          destinationId = destination.id;
          break;
        }
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExplorePage(
          initialDestinationId: destinationId,
          showBackButton: true,
        ),
      ),
    );
  }

  void _openExperience(
    RightNowState state,
    List<TripExperience> experiences,
  ) {
    TripExperience? experience;
    for (final item in experiences) {
      if (item.id == state.experienceId) {
        experience = item;
        break;
      }
    }
    if (experience == null) return;
    final listing = context.read<ListingRepository>().getById(
      experience.listingId,
    );
    if (listing == null) {
      showDEToast(
        context,
        title: 'In your itinerary',
        message: experience.time == null
            ? 'This planned experience does not have a time yet.'
            : 'Scheduled for ${CompanionScheduleUtils.formatTime(experience.time!)}.',
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ListingDetailPage(listing: listing)),
    );
  }

  void _showReservationDetails(RightNowState state) {
    final listingRepository = context.read<ListingRepository>();
    TripExperience? experience;
    if (state.experienceId != null) {
      for (final day in context.read<TripRepository>().getCurrentTrip().days) {
        for (final item in day.experiences) {
          if (item.id == state.experienceId) {
            experience = item;
            break;
          }
        }
        if (experience != null) break;
      }
    }
    final listing = experience == null
        ? null
        : listingRepository.getById(experience.listingId);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DERadius.extraLarge)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            DESpacing.lg,
            DESpacing.lg,
            DESpacing.lg,
            DESpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing?.title ?? 'Reservation details',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (experience?.time != null)
                Text(
                  'Scheduled for ${CompanionScheduleUtils.formatTime(experience!.time!)}',
                ),
              if ((state.confirmationNumber ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Confirmation number', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                SelectableText(state.confirmationNumber!),
              ],
              if ((state.ticketUrl ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Ticket link', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                SelectableText(state.ticketUrl!),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: state.ticketUrl!));
                      if (!mounted || !sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      showDEToast(context, title: 'Copied', message: 'Ticket link copied.');
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy link'),
                  ),
                ),
              ],
              if ((state.confirmationNumber ?? '').trim().isEmpty &&
                  (state.ticketUrl ?? '').trim().isEmpty) ...[
                const SizedBox(height: 12),
                const Text('No confirmation number or ticket link was saved for this reservation.'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
