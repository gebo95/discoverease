# DiscoverEase

DiscoverEase is a Flutter app for discovering destination experiences, saving them, and planning trips, with tools for local businesses and admins.

## Current handoff snapshot

The November 11, 2026 project bundle and a detailed continuation prompt are in [handoff/](handoff/):

- [Download the full project bundle](handoff/DiscoverEase_Handoff_Bundle.zip)
- [Read the handoff prompt](handoff/DiscoverEase_Handoff_Prompt.md)

The handoff bundle is the newer project snapshot. The root source tree on this repository's default branch still reflects the original June setup; use the bundle when continuing development unless the root source has since been updated.

## Current scope

Implemented work includes Flutter discovery and trip-planning features, Companion V1 itinerary prompts, Firebase email/password accounts, signed-in trip and saved-place sync, business profile and experience submissions with admin review, and backend-backed business engagement analytics.

The latest user-reported Flutter test run had one known failure: the browse experience card test reported a 5-pixel horizontal overflow. Run analysis and tests before treating the snapshot as passing.

## Firebase development setup

- Project: discoverease-dev
- Firestore location: nam5
- Cloud Functions region: us-central1

Install Flutter and run:

    flutter pub get
    flutter analyze
    flutter test
    flutter run

For web development with App Check, use a registered local debug token through --dart-define=APP_CHECK_WEB_DEBUG_TOKEN=.... Never commit the token, service-account keys, ADC files, or passwords. Do not treat the presence of Firebase client configuration as proof that production hardening is complete.

Location, routing, weather, external places/events, flights, booking/payment, push notifications, and AI integrations are not implemented. Do not simulate those services as if they work.
