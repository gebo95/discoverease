# Business Performance Analytics V1

## Metrics and definitions

The Performance section shows counts per published business experience for the
last 7, 30, or 90 UTC calendar days.

| Metric | Count rule |
| --- | --- |
| Views | One view per signed-in account, listing, and UTC day when its detail page opens |
| Likes | A signed-in account's first like action per listing per UTC day |
| Shares | A signed-in account's successful native share or web clipboard copy, up to 5 counted per account, listing, and UTC day |
| People sharing | The number of different accounts that have ever had a share counted for the listing (lifetime, not tied to the date range) |
| Saves | A signed-in account's first save action per listing per UTC day |

Counts are interaction events in the chosen date range. Removing a like or save
does not erase its historical event, so Likes and Saves are events rather than
current totals. Guest actions, curated local listings,
failed or cancelled native share attempts, and activity before backend
deployment are not included. No individual user identities are exposed to a
business.

## Architecture and access

- Flutter creates a real like in `users/{uid}/likes/{listingId}` and uses the
  existing saved-experience collection for saves.
- Authenticated, App Check-enforced callable functions record listing views
  and successful shares. On web, when the browser share sheet is unavailable,
  a successful clipboard copy is the share fallback. Views are deduplicated
  daily; shares are capped at 5 counted per account/listing/UTC day, and the
  first counted share by each account also adds one to the listing's
  `uniqueSharers` count on `businesses/{businessId}/analytics/{listingId}`.
  A business sees only these counts, never who shared.
- Firestore Functions aggregate eligible actions into
  `businesses/{businessId}/analytics/{listingId}/daily/{YYYYMMDD}`. A private,
  hashed receipt prevents duplicate trigger/callable delivery from incrementing
  a daily total twice. Receipt documents include a 90-day expiry timestamp,
  except the one small per-account, per-listing sharer receipt, which has no
  expiry so the unique-sharer count is never double counted.
- Client Firestore Rules deny all analytics writes. A business owner can read
  only analytics below their own business document; admins can read all.
- The business portal checks the analytics callable before showing totals. If
  the backend or App Check is not ready, it explains that setup is required.

## Development and deployment setup

The `discoverease-dev` callable functions are deployed with App Check
enforcement. For local Chrome testing, pass the registered web debug token
with `--dart-define=APP_CHECK_WEB_DEBUG_TOKEN=...`; do not commit the token or
ship it in release builds. Other debug platforms use their platform debug
providers. Windows requires a registered debug token provided with
`--dart-define=APP_CHECK_DEBUG_TOKEN=...`. Linux does not run analytics
callables. Release Android uses Play Integrity, Apple platforms use App Attest
with DeviceCheck fallback, and release web requires a real reCAPTCHA site key
provided with `--dart-define=APP_CHECK_WEB_SITE_KEY=...`.

The current FlutterFire App Check SDK requires Android API 24+ and macOS 11+;
the project platform targets are set to those minimums. iOS remains at API 13+.

From the project root:

```sh
flutter pub get
cd functions && npm install && cd ..
firebase deploy --only firestore:rules,functions
```

The project is configured to use the `discoverease-dev` Firebase project. If
your Firebase CLI does not have that project selected, deploy with
`firebase deploy --project discoverease-dev --only firestore:rules,functions`.

Firestore App Check enforcement is a separate Firebase Console setting from
the callable enforcement used by analytics. Before enabling it, register each
real app and development debug token, and confirm every platform that should
use cloud sync has a supported App Check provider. This ensures saved/liked
document triggers receive requests only from registered app instances.

Cloud Functions deployment requires the Firebase project to use the Blaze
pay-as-you-go plan. Check the billing setup and add budget alerts before
deploying. The Emulator Suite can be used for local function development
without deploying to Firebase.

Firestore TTL is optional but recommended: configure the `engagementReceipts`
collection to expire on the `expireAt` field after reviewing retention
requirements. Until TTL is configured, receipt documents remain in Firestore.

## Boundaries

This V1 has no bookings, reach attribution, impressions from search-card
rendering, unique anonymous users, or external social-platform confirmation.
Share counts indicate a native share API success or a successful web clipboard
copy; they do not confirm delivery or clicks. Analytics do not backfill
activity from before Functions were deployed.
