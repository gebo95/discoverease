import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';

import 'repositories/listing_repository.dart';
import 'repositories/saved_repository.dart';
import 'repositories/trip_repository.dart';
import 'app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ListingRepository()),
        Provider(create: (_) => SavedRepository()),
        ChangeNotifierProvider(create: (_) => TripRepository()),
      ],
      child: const DiscoverEaseApp(),
    ),
  );
}
