# Backend Access Control and Deployment (Phase 2)

No credentials, tokens, or service-account files belong in this repository.
The project ID (`discoverease-dev`) is not secret.

## Who can do what

| Data | Public | Signed-in user | Business owner | Admin |
| --- | --- | --- | --- | --- |
| `catalog/*` (published) | read | read | read | read, write |
| `businesses/{id}` profile (contact details) | no | no | read, limited edit of own | read, write |
| `businesses/{id}/experiences/*` | read published only | read published only | read own; edit while pending or rejected | read, write |
| `businesses/{id}/analytics/**` | no | no | read own | read |
| `users/{uid}/**` | no | own only | own only | no |
| `engagementReceipts/*`, analytics writes | no | no | no | no (Functions only) |

Business profiles are private because they hold email, phone, and owner uid.
Public listing content lives in `catalog`. If a public business page is added
later, publish a separate public document with only the fields meant to be
shown.

## Rule tests (Firebase Emulator)

`rules-tests/` checks the Firestore rules against the local emulator. Nothing
is deployed and no cloud data is touched. Requirements: Java 21+ and
`firebase-tools`.

```sh
cd rules-tests && npm install && cd ..
firebase emulators:exec --only firestore --project demo-discoverease-rules "npm --prefix rules-tests test"
```

Storage rules are not covered yet; add tests when photo uploads are built.

## Admin claim workflow

1. The person signs up in the app and you copy their Firebase Auth UID from the
   console.
2. From `backend/admin-tools`, run `npm run grant-admin -- <UID>` using your own
   Application Default Credentials (`gcloud auth application-default login`).
   The script refuses any project other than `discoverease-dev`.
3. The person signs out and back in so the new claim reaches their ID token.

Rules read the `admin` claim only; the client never grants it.

## Indexes

The admin review screen queries `experiences` across all businesses, which
needs a collection-group index on `status`. Capture the deployed indexes so
they are reproducible (read-only, changes nothing in the cloud):

```sh
firebase firestore:indexes > firestore.indexes.json
```

Then add `"indexes": "firestore.indexes.json"` under `"firestore"` in
`firebase.json` and commit the file.

## Storage rules

`storage.rules` decides photo ownership from the business's Firestore document
(`ownerUid`), not from a sign-in claim. Cross-service rules need Firebase
Storage enabled on the project; deploy them only when photo uploads ship.

## Deploying

Deploy only after reviewing the diff, and from the project root:

```sh
firebase use discoverease-dev
firebase deploy --only firestore:rules,functions
```

Do not add `storage` until Storage is enabled and uploads exist. Firestore TTL
for `engagementReceipts` (field `expireAt`) is set in the Firebase Console.

## Production checklist

- Separate Firebase project for production, with its own rules, functions,
  and App Check providers (Play Integrity, App Attest, reCAPTCHA).
- Billing budget alerts on the Blaze plan.
- Firestore App Check enforcement turned on only after every shipping platform
  is registered.
- Review API-key restrictions for each platform key in the Google Cloud
  Console.
- TTL policy on `engagementReceipts.expireAt`.
- `firestore.indexes.json` committed and deployed.
- Rule tests passing before every rules deploy.

## Storage rules tests

Storage rules read the business's Firestore document, so the rules tests need both emulators:

```
firebase emulators:exec --only firestore,storage "npm --prefix rules-tests test"
```

Deploy Storage rules after Storage is enabled: `firebase deploy --only storage --project discoverease-dev`.
