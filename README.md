# DiscoverEase

DiscoverEase is a Flutter app for discovering destination experiences, saving
them, and planning trips. The app currently uses local mock data and Provider
repositories.

## Run locally

Install the Flutter SDK, then run:

```sh
flutter pub get
flutter run
```

Check the project with:

```sh
flutter analyze
flutter test
```

## Project layout

- `lib/features/` contains app screens and feature logic.
- `lib/models/` contains the trip, listing, and user models.
- `lib/repositories/` supplies app data and in-memory trip updates.
- `lib/shared/` contains reusable widgets, navigation, and theme components.
- `test/` contains model, repository, and feature tests.

## Trip Companion V1

Companion evaluates the selected itinerary day using its planned start times,
travel estimates, completion state, and saved reservation details. It can show
departure reminders, upcoming plans, meal prompts, and free-time suggestions.
Open [the Companion V1 notes](docs/11_Companion_V1.md) for current behavior
and the boundaries for future location, weather, places, events, flight, and AI
services.

See [the Pulse V1 notes](docs/12_Pulse_V1.md) for itinerary reminder behavior
and service boundaries.

See [the Destination System notes](docs/13_Destination_System.md) for catalog
IDs, area browsing, and the current data limits.

See [the Backend Foundation notes](docs/14_Backend_Foundation.md) for the
versioned cloud document shapes, Firebase security rules, and project setup.
Development Firebase is initialized with email/password account access and a
Firestore profile record. Trips and saved places sync for signed-in accounts;
guest demo data stays local. Discovery listings remain local, and business
photo uploads and their Storage billing setup are not implemented.

The signed-in Profile links to Business Portal V1 for business and experience
submissions. Admin-claim accounts can review submissions, and approved
experiences are merged into Explore from Firestore. Business analytics uses
real per-experience counts after Cloud Functions and App Check are deployed;
see [`docs/16_Business_Analytics_V1.md`](docs/16_Business_Analytics_V1.md).
