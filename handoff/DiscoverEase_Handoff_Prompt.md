# DiscoverEase Project Handoff Prompt

You are taking over development of **DiscoverEase**, an in-progress Flutter/Firebase travel discovery and trip-planning app. I am providing the current project bundle with this prompt. Treat the code in the bundle as the source of truth for implementation details, inspect the full project before editing, and preserve the existing architecture and working functionality.

## Product vision

DiscoverEase helps travelers and locals find trustworthy things to do, save experiences, and organize them into practical trips. It should also give local businesses a useful way to publish experiences and understand engagement. The product promise is: **“Discover more. Plan better. Experience together.”** The experience should feel friendly, clear, destination-aware, and useful for real trip planning rather than a generic listings catalog.

The app has three main user groups:

1. **Travelers and locals** discover experiences, save them, and plan trips.
2. **Businesses** create business profiles, submit experiences, and view engagement analytics.
3. **Admins** review and approve business profiles and experiences, with clear rejection feedback and resubmission flows.

The design references emphasize destination/island browsing, experience cards, saved collections, trip planning, profile, and a business dashboard. The palette shown in the design references includes blue `#0066FF`, cyan `#00B4D8`, amber `#FFB703`, green `#22C55E`, red `#EF4444`, dark navy `#0F172A`, slate `#64748B`, and near-white `#F8FAFC`. Preserve the actual app’s established theme and components when making changes.

## How to work on this project

- First inspect the complete project structure, current UI, data flow, Firebase setup, tests, and docs. Give me a short plan before making changes.
- Then implement the requested work end-to-end. Make sensible small decisions without stopping for approval on every minor implementation detail.
- Preserve working features and architecture where appropriate. Add focused tests for meaningful behavior, run `flutter analyze` and `flutter test`, and fix regressions introduced by your work.
- Do not fabricate API responses, bookings, maps, weather, places, events, flight data, or AI results. If a service is not connected, show a clear unavailable/coming-later state and structure an interface so a real provider can be added.
- Maintain a running roadmap. At the end of each completed phase, briefly tell me what is done and ask whether I want to add or change anything before moving to the next phase.
- Do not put passwords, Firebase service-account JSON, OAuth credentials, or App Check debug tokens in source control or in prompts. The project ID and non-secret setup details are okay to document.

## Current project and known implementation

The supplied latest saved bundle is named `DiscoverEase_trip_budget_day_saved_flow.zip` and was saved on Nov. 11, 2026. The repository already has Flutter source, Firebase configuration, Cloud Functions, docs, and tests; inspect the bundle rather than assuming this summary is a complete inventory.

The app is organized around feature folders, models, repositories, shared widgets, and tests. The project README describes Provider-backed repositories. Existing work includes:

- Flutter application shell, themed shared UI, browsing and detail experiences, destination/area browsing, profile, trips, and saved items.
- Firebase initialization and email/password authentication, user profiles, account synchronization, and Firestore persistence for signed-in trips and saved places. Guest/demo data remains local.
- Destination catalog and listing models/repositories; approved submitted experiences can be merged into discovery.
- Business Portal V1: business profile and experience submission/editing, review status, admin approval, rejection feedback, and resubmission. Approved content is protected from business edits where appropriate.
- Business engagement analytics with per-experience views, likes, shares, and saves. Firebase Cloud Functions handle analytics writes/aggregation/readiness checks. The user has seen real likes/saves and later saw successful view callable responses. Share tracking had authentication/App Check troubleshooting; the user later confirmed App Check validation succeeded. Re-test all analytics in the current bundle before relying on them.
- Trip Companion V1: rule-based itinerary prompts (arrival/departure, meal time, free time, reservations, closing soon, upcoming plans), completion state, reservation details, planned start/travel information, and timeline/dashboard refresh behavior. Companion is rule-driven and does not currently call an AI service.
- Trip planning work: per-experience estimated costs and notes, trip-level notes preview/editing, itinerary-day budget totals while the overall trip snapshot keeps the whole-trip total, saved-for-later experiences, day selection, and saved-item grouping by destination/area/category with expandable sections. Check the current implementation carefully against tests and the UX requirements below.
- Firestore rules and Cloud Functions were deployed to the development Firebase project during earlier work. A Blaze billing plan was enabled so Functions could deploy. Do not redeploy or change cloud resources unless the task requires it and you can explain the impact first.

## Latest known QA state and immediate fixes

The latest user-provided Flutter test run had **one known failure**: `test/features/home/de_experience_card_layout_test.dart` reported a horizontal `RenderFlex` overflow of 5 pixels. The app did launch with `flutter run -d chrome` during that session, but that does not mean all tests currently pass. Run the test suite in the current environment and confirm/fix this card overflow before treating the snapshot as green.

Earlier iteration also caught and fixed or added checks for:

- A nullable estimated-cost compile error in the trip experience card.
- A browse-card vertical overflow and trip hero bottom overflow.
- Trip repository serialization/round-trip behavior for per-experience notes and estimated cost.
- Layout and saved-trip filter behavior.

The latest saved bundle includes new trip/saved-flow tests dated Nov. 11. Verify the current trip UI and tests after fixing the known card issue; do not assume every earlier error is still present or already fixed.

Important trip UX requirements from Geo:

- When viewing a specific trip day, the bottom budget display should show that day’s total (for example Day 2 shows Day 2’s planned expenses). The top trip snapshot should continue to show the total for the whole trip.
- In Saved for Later, choosing “Add to Day 2” should open the day picker with Day 2 already selected.
- Saved items should be grouped automatically by destination → area → category (only show groups that contain saved items), with groups collapsed until tapped. Example: Bahamas → Nassau/Freeport/Exuma → Tours/Food/Clubs; Japan → Shibuya/Shinjuku → Tours/Food/Clubs.
- Adding an experience to a trip should support a per-experience cost and note. The trip-level notes area should be an editable combined preview of the itinerary notes.
- Find Something to Do must have a clear way back to the trip. Experience cards must not overflow on narrow layouts.
- Schedule validation should warn when an activity category/time combination is inconsistent (for example, a “morning activity” scheduled at night), without blocking reasonable user choices arbitrarily.
- Saved counts and filters should reflect the user’s actual saved items and work by category/destination, not a hard-coded count or demo-only list.

## Firebase and deployment context

- Firebase project ID: `discoverease-dev`
- Firestore location: `nam5`
- Cloud Functions region: `us-central1`
- Firebase Authentication uses email/password. Admin status is granted through a custom claim; after a claim changes, the account must sign out/in or refresh its ID token.
- Web development uses Firebase App Check’s debug provider. The debug token is a secret-like local development value: never commit it or copy it into this prompt. Pass it locally through `--dart-define=APP_CHECK_WEB_DEBUG_TOKEN=...` after registering the current debug token in Firebase App Check.
- Earlier deployed functions include `recordListingView`, `recordListingShare`, `checkBusinessAnalyticsReady`, `aggregateBusinessLikes`, and `aggregateBusinessSaves`. Verify actual source/deployment names in `functions/` and Firebase before making changes.
- The user has a connected GitHub repository at `gebo95/discoverease`. It is **public**. Its known latest commit when this prompt was prepared is the initial setup commit from June 30, 2026, so it does not yet represent the Nov. 11 saved project snapshot. Treat the provided bundle as newer than the current GitHub default-branch contents unless verified otherwise.
- Firebase web API keys in `firebase_options_dev.dart` are app configuration, not admin credentials; still review project restrictions and Firebase rules. Never add service-account keys, local ADC files, actual debug tokens, or passwords to GitHub.

Useful local commands:

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --dart-define=APP_CHECK_WEB_DEBUG_TOKEN=<registered-local-debug-token>
```

Firebase deployment commands should only be run when needed and from the project root after confirming the target project:

```sh
firebase use discoverease-dev
firebase deploy --only firestore:rules,functions
```

## External services: not implemented yet

Do not simulate these as if they work. Keep integration boundaries clean so real providers can be added later:

- Device location and arrival detection/geofencing.
- Maps, directions, routing, travel times, and distance calculations.
- Weather forecasts and weather-aware activity suggestions.
- Nearby places, restaurants, events, venue hours, and live “open/closing soon” data.
- Flights, airport/flight status, hotel data, ticket availability, reservations, and booking checkout.
- Payment processing, business subscriptions, refunds, taxes, and payouts.
- Push notifications and scheduled reminders beyond what the current app can truthfully support.
- AI itinerary generation or chat recommendations.
- Image storage/uploads for businesses if Firebase Storage setup is not present in the current bundle.

## Suggested roadmap

Treat this as a living plan; inspect the bundle first and adjust based on the actual code.

### Phase 1 — Stabilize the current user experience

1. Run analysis and all tests, fix the known 5-pixel experience-card overflow, and check the full app for layout issues.
2. Validate the complete trips flow: day selection, day-specific vs whole-trip budget, per-experience cost/note, editable trip notes, saved-for-later assignment, and save grouping/expansion.
3. Confirm navigation/back behavior and empty/loading/error states; fix hard-coded saved/analytics values.
4. Validate schedule warnings and Companion suggestions against itinerary dates, times, completion state, and reservations.

### Phase 2 — Validate backend and access control

1. Inspect Firestore models, indexes, rules, and Cloud Functions for least-privilege access and idempotent analytics aggregation.
2. Add meaningful Firebase Emulator tests for auth roles, business submissions, moderation, trip/saved sync, and analytics where practical.
3. Confirm App Check debug flow for local development and plan real production providers per platform. Never weaken security to make a test pass.
4. Document environment setup, indexes, deployment, admin-claim workflow, and production checklist without including credentials.

### Phase 3 — Finish a trustworthy Business V1

1. Complete business profile and experience lifecycle (draft, pending, approved, rejected with feedback, resubmitted, archived).
2. Keep analytics tied to real backend receipts/counts: views, likes, shares, saves. Add bookings only when a real booking flow exists.
3. Make dashboard filters/ranges and empty/loading states clear; avoid presenting zero as real if data is unavailable.
4. Add secure photo uploads only after Storage rules, limits, and billing are configured; do not show fake upload completion.
5. Decide and build real business subscriptions/payments only after pricing, billing, and operational requirements are defined.

### Phase 4 — Improve discovery and content quality

1. Build real search, category filters, destination/area exploration, and sorting from approved catalog data.
2. Add an admin content workflow and seed/curate trustworthy destination data.
3. Improve accessibility, responsive layouts, image fallback states, and performance.
4. Add local business analytics attribution only where the event can be measured accurately.

### Phase 5 — Social and collaborative planning

1. Define sharing permissions and private/public trip links.
2. Add trip collaboration, invitations, and conflict handling only after data ownership/security rules are clear.
3. Add user-generated reviews or collections with moderation/abuse controls.
4. Consider creator itineraries and rewards after core discovery/trip value is proven.

### Phase 6 — Integrate external services incrementally

Choose a provider and define cost, privacy, attribution, and fallback behavior for each before integrating. Prioritize location and places/directions, then weather/events, then reservations/flights/payments as the product needs them. AI itinerary suggestions should be explainable, editable, and grounded in real catalog data.

## Later product ideas, not MVP commitments

Design references and prior brainstorming mention Discover Modes, an AI Trip Planner, AR experiences, offline itineraries, hotel/flight booking, rewards/loyalty, creator itineraries, and public trip sharing. Keep these as later ideas. Do not add placeholders that imply these are available.

## What I want next

Start by inspecting the entire provided project and comparing it with the status above. Give me a concise implementation plan, then continue with Phase 1 stabilization. Preserve the existing working architecture, fix the failing experience-card layout test, verify the trip/day budget and saved-for-later flows, run `flutter analyze` and `flutter test`, and summarize what passed and what remains. After that completed step, ask me whether I want to add or change anything before moving to the next roadmap phase.
