import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';

import 'repositories/business_pulse_repository.dart';
import 'repositories/listing_repository.dart';
import 'repositories/saved_repository.dart';
import 'repositories/trip_repository.dart';
import 'repositories/pulse_repository.dart';
import 'app.dart';
import 'repositories/destination_repository.dart';
import 'firebase_options_dev.dart';
import 'services/experience_photo_service.dart';
import 'services/firebase_account_service.dart';
import 'services/firebase_user_data_store.dart';
import 'services/account_sync_coordinator.dart';
import 'services/firebase_business_pulse_service.dart';
import 'services/firebase_business_service.dart';
import 'services/firebase_catalog_sync_service.dart';
import 'services/firebase_unavailability_sync_service.dart';
import 'services/firebase_admin_review_service.dart';
import 'repositories/featured_repository.dart';
import 'services/firebase_billing_service.dart';
import 'services/firebase_engagement_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _activateAppCheck();
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => FirebaseAccountService()),
        Provider(create: (_) => FirebaseUserDataStore()),
        Provider(create: (_) => FirebaseBusinessService()),
        Provider(create: (_) => FirebaseBusinessPulseService()),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => BusinessPulseRepository(
            source: context.read<FirebaseBusinessPulseService>().watchActive(),
          ),
        ),
        Provider(create: (_) => FirebaseBillingService()),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => FeaturedRepository(source: FeaturedSource().watch()),
        ),
        Provider(create: (_) => ExperiencePhotoService()),
        Provider(create: (_) => FirebaseAdminReviewService()),
        Provider(create: (_) => FirebaseEngagementService()),
        ChangeNotifierProvider(create: (_) => ListingRepository()),
        Provider(
          lazy: false,
          create: (context) => FirebaseCatalogSyncService(
            listings: context.read<ListingRepository>(),
          )..start(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider(create: (_) => SavedRepository()),
        ChangeNotifierProvider(create: (_) => TripRepository()),
        Provider(
          lazy: false,
          create: (context) => FirebaseUnavailabilitySyncService(
            listings: context.read<ListingRepository>(),
            saved: context.read<SavedRepository>(),
            trips: context.read<TripRepository>(),
          )..start(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider(
          create: (context) => PulseRepository(
            tripRepository: context.read<TripRepository>(),
            listingRepository: context.read<ListingRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => DestinationRepository()),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => AccountSyncCoordinator(
            accounts: context.read<FirebaseAccountService>(),
            store: context.read<FirebaseUserDataStore>(),
            trips: context.read<TripRepository>(),
            saved: context.read<SavedRepository>(),
          )..start(),
        ),
      ],
      child: const DiscoverEaseApp(),
    ),
  );
}

Future<void> _activateAppCheck() async {
  if (kIsWeb) {
    if (kDebugMode) {
      const debugToken = String.fromEnvironment('APP_CHECK_WEB_DEBUG_TOKEN');
      await FirebaseAppCheck.instance.activate(
        providerWeb: WebDebugProvider(
          debugToken: debugToken.isEmpty ? null : debugToken,
        ),
      );
      return;
    }
    const siteKey = String.fromEnvironment('APP_CHECK_WEB_SITE_KEY');
    if (siteKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(siteKey),
      );
    }
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
      break;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      await FirebaseAppCheck.instance.activate(
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
      break;
    case TargetPlatform.windows:
      if (kDebugMode) {
        const token = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
        await FirebaseAppCheck.instance.activate(
          providerWindows: WindowsDebugProvider(
            debugToken: token.isEmpty ? null : token,
          ),
        );
      }
      break;
    case TargetPlatform.linux:
      // App Check is not configured for Linux; analytics callables remain
      // unavailable there while the rest of the app continues to work.
      break;
    default:
      break;
  }
}
