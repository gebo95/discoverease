import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../repositories/destination_repository.dart';
import '../../../repositories/listing_repository.dart';
import '../../../repositories/pulse_repository.dart';
import '../../../repositories/trip_repository.dart';
import '../widgets/home_content.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final destination = context
        .watch<DestinationRepository>()
        .currentDestination;

    final trip = context.watch<TripRepository>().getCurrentTrip();

    final unreadPulseCount = context.watch<PulseRepository>().unreadCount();

    final listingRepository = context.read<ListingRepository>();

    return Scaffold(
      body: SafeArea(
        child: HomeContent(
          destination: destination,
          trip: trip,
          unreadPulseCount: unreadPulseCount,
          listingRepository: listingRepository,
        ),
      ),
    );
  }
}
