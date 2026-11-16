# DiscoverEase Changelog

## Business Submission Review V1

- Added owner editing for pending business experiences and edit/resubmit for
  rejected submissions.
- Added required reviewer feedback on rejected experiences and exposed that
  feedback in the Business Portal.
- Locked published experience content against owner edits so the moderated
  Firestore catalog remains consistent.
- Made admin publishing use the latest submission content at review time.

## Firebase Account and Business Portal V1

- Connected development Firebase Auth and Firestore for account profiles, trips,
  and saved experiences while keeping guest demo data separate.
- Added owner-scoped business profile registration and pending-review experience
  submissions in the signed-in Business Portal.
- Tightened Firestore rules so owners cannot change ownership, verification,
  subscription, or review fields, and cannot publish their own submissions.
- Documented that catalog publishing, admin review tools, media uploads, and
  measured business analytics remain future work.

## Backend Foundation V1

- Added versioned JSON document shapes for trips, itinerary days/experiences,
  reservations, and saved experiences.
- Added Firestore ownership and publication rules plus business photo Storage
  rules and a Firebase CLI deployment manifest.
- Documented the separate real Firebase project setup and clearly marked Auth,
  cloud persistence, uploads, and trusted role assignment as not connected yet.

## Trip Planning V1

- Added a destination-first trip editor with optional date ranges and trip names.
- Generated one itinerary day per selected date while keeping flexible-date
  trips usable with a Day 1.
- Added in-session upcoming-trip creation and switching, plus editing of the
  active trip's name, destination, and dates.
- Preserved planned experiences when trip dates change; when the date range is
  shortened, overflow experiences move to the final remaining day.
- Added confirmed removal for planned experiences and opened Explore in the
  trip's destination from an empty itinerary.
- Kept all trip state local to the app session pending Firebase persistence.

## Listing Detail V1

- Reworked listing details into a photo-led hierarchy with scannable facts,
  experience information, practical details, traveler tips, and curated next
  experiences.
- Connected Save to the Saved view and Add to Trip to the existing planning
  sheet and trip repository.
- Removed nonfunctional visit and share controls; future service-dependent
  actions will appear only when verified listing data and integrations exist.
- Documented that current saves and plans are session-only pending backend
  persistence.

## Destination System

- Added stable destination and area IDs plus country, region, and timezone
  metadata.
- Connected listing records and Explore queries through destination and area
  IDs while preserving existing country-name queries.
- Added destination search and working area filters from Home into Explore.
- Replaced time-sensitive destination taglines with evergreen copy.
- Documented local-catalog limits and backend handoff needs.

## Companion and Pulse V1

- Added an in-app Pulse reminder feed derived from dated trip plans.
- Added reservation, saved travel estimate, and 15-minute start reminders.
- Connected Pulse items to their trip day and added explicit empty-state guidance.
- Kept live business, weather, sunset, location, and push notification data out
  until real services and permissions are available.

## v0.4.1

- Added Home screen foundation
- Added reusable listing card
- Added Live Now carousel
- Added mock listing data
- Added premium Home header
- Added custom search bar
