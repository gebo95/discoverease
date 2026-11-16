# Backend Foundation V1

## Status

The app initializes the `discoverease-dev` Firebase project and supports
email/password account creation and sign-in. Account creation writes a
user-owned profile document under `users/{uid}`. Signed-in trips and saved
places load from and sync to the matching user's Firestore subcollections.
Guest mode continues to use the existing demo repositories; demo records are
not copied into a new account. Discovery catalog data remains local.

## Document layout

| Path | Purpose | Access |
| --- | --- | --- |
| `users/{uid}` | Traveler profile | That signed-in user; profile fields only |
| `users/{uid}/trips/{tripId}` | One complete V1 itinerary | That signed-in user |
| `users/{uid}/saved/{listingId}` | One saved listing | That signed-in user |
| `businesses/{businessId}` | Business profile | Owner can read; public when published; owner cannot change review or verification fields |
| `businesses/{businessId}/experiences/{experienceId}` | Business-submitted experience | Owner can read; public when published; owner cannot change review status |
| `catalog/{experienceId}` | Publicly discoverable approved experience | Public reads published records; admin-only writes |
| `businesses/{businessId}/analytics/{listingId}/daily/{date}` | Aggregated engagement totals | Business owner reads own totals; Cloud Functions write |
| `businesses/{businessId}/photos/{fileName}` | Public promotional photo | Public read; business owner upload/delete |

Trip and saved document serializers include `schemaVersion: 1`. Trip dates are
calendar dates (`YYYY-MM-DD`); reservation reminders are UTC ISO-8601
timestamps. Itinerary sections, reservation types, and times are stored as
explicit strings/maps, not Dart enum indexes or display-formatted text.
Trip documents add a `lifecycle` field (`current` or `upcoming`) so the app can
restore active and upcoming trips without placing account state in the trip
model serializer.

The complete itinerary is one trip document for V1. If trips approach
Firestore's document-size limit, experiences should move into day/experience
subcollections with a migration before that limit is reached.

Admin authorization uses a trusted Firebase Auth custom claim, not an editable
profile field. Business ownership is tied to the authenticated UID in the
business document; the client cannot change its owner or set a profile or
experience to `published`. The app's Admin Review screen checks this claim and
Firestore Rules enforce it for all moderation and catalog writes.

## Real Firebase project setup

Create separate development and production Firebase projects. For each project:

1. Register the actual Android, iOS, and web app IDs used for that environment.
2. Enable the chosen Firebase Authentication providers, create a Firestore
   database, and create the Storage bucket.
3. From the Flutter project root, install/use the FlutterFire CLI and run
   `flutterfire configure --project=<real-project-id> --out=lib/firebase_options_dev.dart`
   for development. Repeat with the production project and
   `--out=lib/firebase_options_prod.dart`.
4. Enable Email/Password in Firebase Authentication and create Firestore in
   the intended region (the development database was created in `nam5`).
5. Deploy `firestore.rules` after reviewing them in the Firebase Emulator Suite.
   Storage rules can wait until photo upload is implemented and Storage billing
   is enabled for the project.
6. Use a separate production options file and build configuration before any
   production release.

### Granting development admin access

The admin claim must only be granted from a trusted environment. Never add an
admin toggle to the Flutter client or include service-account credentials in
the app bundle. An authorized project operator can use Google Application
Default Credentials (for example, `gcloud auth application-default login` with
an account that has Firebase Authentication Admin permissions) from
`backend/admin-tools`:

```sh
npm install
npm run grant-admin -- <Firebase-Auth-UID>
```

The tool is pinned to `discoverease-dev` by default. Restart the user's session
or refresh its ID token, then open Profile → Admin review. This is a local
trusted admin utility, not a deployed backend service.

After reviewing `firestore.rules`, deploy them to the development project:

```sh
firebase use discoverease-dev
firebase deploy --only firestore:rules
```

The FlutterFire client options file is included in the app. It identifies the
Firebase client app; it is not a substitute for Security Rules. Never ship
service-account credentials in the Flutter app.

Install the Firebase CLI, authenticate to the intended project, then review
and deploy the rules with:

```sh
firebase use <real-project-id>
firebase deploy --only firestore:rules
```

## External services still required

- Email/Password must be enabled in Firebase Authentication for account access.
- Cloud Firestore must be provisioned and its rules deployed for profile,
  trip, and saved-place sync.
- Cloud Storage is not integrated yet; business photo upload will require a
  Storage bucket and billing setup.
- Admin custom claims are provisioned by the trusted local utility above;
  ongoing production operations still need a controlled operator workflow.
- The current curated destination/listing catalog remains local mock data.
  Approved business experiences are published to the public Firestore
  `catalog` collection and merged into Explore; importing the existing curated
  mock catalog to Firestore remains separate work.
- Business performance events are aggregated by `functions/` only after
  Cloud Functions, Firebase App Check, and the required project billing setup
  are configured; see [Business Analytics V1](16_Business_Analytics_V1.md).

The Firebase Security Rules are the access boundary for client SDK requests.
Server/Admin SDKs bypass those rules and must enforce authorization separately.
