# Business Portal V1

## Included

- A signed-in traveler can register one business profile from Profile.
- Business profiles are stored at `businesses/{uid}` with `ownerUid` equal to
  the Firebase Auth UID and begin in `pending_review` status.
- Owners can submit experiences under
  `businesses/{uid}/experiences/{experienceId}`.
- Submitted experiences also begin in `pending_review` and show their status
  in the owner's portal.
- Owners can update pending submissions and see the reason an experience was
  rejected. Rejected experiences can be edited and resubmitted for review.
- Published experiences are not editable through the owner form; this avoids
  changing the public catalog outside of moderation.
- Firestore Rules prevent the client from changing ownership, verification,
  subscription tier, or review status. Business owners cannot publish their
  own profile or experiences.

An Admin Review screen is available only to accounts with the trusted Firebase
Auth `admin` custom claim. It supports approve/reject decisions for pending
businesses and experiences. Admins must provide feedback when rejecting an
experience. Approving a business marks it published and verified. An
experience can be published after its business is approved; the approval reads
the latest submitted content and updates the submission and public catalog
entry in one Firestore batch. The catalog stream is merged with local curated
listings.

Admin claims are granted by the trusted local utility in
`backend/admin-tools`; see [Backend Foundation](14_Backend_Foundation.md).
Firestore Rules enforce the claim independently of the client UI.

## Current boundaries

- Business profiles and experience text are stored in Firestore.
- Photo upload is not implemented. The form does not pretend that a photo has
  been uploaded.
- Existing curated mock listings remain local; approved business experiences
  appear from Firestore. Importing the local curated catalog is a separate step.
- Business-submitted experiences have no verified ratings or uploaded images
  yet. They display as new/unrated, and Cloud Storage photo upload remains
  external work.
- The Business Portal includes 7/30/90-day views, likes, shares, and saves
  summaries for published experiences. Analytics are deployed and verified in
  `discoverease-dev` with authenticated, App Check-enforced Functions.

## Performance metric definitions

The V1 Performance section reads real daily aggregates. Definitions and setup
are documented in [`16_Business_Analytics_V1.md`](16_Business_Analytics_V1.md).
Further analytics work should extend the real app/backend instrumentation:

| Metric | Count when |
| --- | --- |
| Views | One signed-in account views a listing once per UTC day |
| Saves | A signed-in account saves a listing once per UTC day |
| Likes | A signed-in account likes a listing once per UTC day |
| Shares | A signed-in account completes a native share or successful web clipboard copy once per listing per minute |

Counts are aggregated in daily Firestore documents; businesses cannot read
individual event receipts. Bookings should appear only after a real booking
integration exists. See the setup and retention notes in
[`16_Business_Analytics_V1.md`](16_Business_Analytics_V1.md).

## Listing details (Phase 3, part A)

Experiences can carry optional details that travelers see in "Know before you
go" once the experience is approved: street address, phone number, website,
booking or ticket link, hours, and a schedule note ("Fri and Sat 8pm"). Hours
and schedule are plain text for now; structured dates are a later step.

- Links must be plain `http` or `https` addresses (a bare `example.com` is
  saved as `https://example.com`). Firestore rules and the form both reject
  other schemes such as `javascript:`.
- Length limits: address 200, phone 40, hours and schedule 300, links 300.
- Details can be edited while an experience is pending review or after a
  rejection. Editing a live experience is the next step.
- Approval copies the details into the public `catalog` record. Reviewers see
  them on the admin review card before approving.
- Phone and link rows are tappable on the listing page and open the device's
  phone or browser app.

