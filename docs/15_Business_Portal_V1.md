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

## Editing a live experience (Phase 3, part A)

A live experience is never edited in place. The owner proposes changes, an
admin reviews them, and the live version keeps showing to travelers until the
changes are approved.

- The proposal is stored on the experience as `pendingRevision` (the
  reviewable content), with `revisionStatus` (`pending_review` or `rejected`),
  `revisionNote`, and `revisionSubmittedAt`. Live fields are untouched.
- The owner can resubmit, withdraw a pending proposal, or discard a rejected
  one. Firestore rules allow owners to write only these revision fields on a
  published experience, and the proposal must be well-formed (known fields,
  valid links, length limits). Photos cannot change through a revision until
  photo uploads exist.
- Admins see proposals on the "Live edits" tab as a list of "Now / Proposed"
  differences. Approving copies the new content to the experience and its
  public `catalog` entry in one transaction (publish date and ratings are left
  alone); rejecting requires a reason shown to the business.
- Reviewing proposals queries `experiences` by `revisionStatus` across all
  businesses, which needs a collection-group index. The first run prints a
  one-click link to create it; afterwards, capture it with
  `firebase firestore:indexes > firestore.indexes.json`.


## Hide, delete and end (Phase 3)

Owners manage a live experience from the "..." menu on its card. None of these need review, because they only take content away. A note to travelers is the one piece of owner text that skips review, so it is limited to 280 characters of plain text with no web addresses.

| Action | What travelers see |
| --- | --- |
| Hide | Removed from browsing and search. Anyone who saved it or planned it sees "Temporarily unavailable" and the owner's note, if any. Show again restores it. |
| Delete | Permanent. Saved and planned copies show "No longer available" and the note. |
| End date | When the date passes (checked hourly) the experience ends: off the public list, shown to the owner as "Ended", shown to travelers as "Ended". Setting a new date runs it again. |

How it works:

- Everything goes through the `manageExperience` callable (owner or admin only) or the hourly `endExpiredExperiences` job. Each change updates the experience, flips the public `catalog` entry between `published` and `hidden`, and writes or clears a public `unavailable/{listingId}` notice in one transaction. Clients cannot write any of these (see `firestore.rules`).
- The notice holds only what is already public (title, image, destination, category) plus the reason and note.
- The app watches notices only for the places the traveler saved or planned, and shows those places greyed out with the reason instead of dropping them.
- Likes, views, shares and saves stop counting while a listing is hidden, because analytics only record published listings.
- Hidden listings still accept edit proposals; approving one updates the hidden catalog entry without relisting it.
- Not built yet: push notifications to travelers (parked with the app-bar bell) and drafts or archive states.

## Photos (Phase 3)

Owners add up to 5 photos per experience (JPEG, PNG or WebP, 5 MB each) and choose which one is the cover.

- **Review.** New photos are reviewed like any other change. A live experience keeps its current photos until an admin approves the proposed ones; the admin sees the old and new photos side by side in the "Live edits" tab.
- **Cover.** Choosing a different cover among photos that are already approved is instant and needs no review (`manageExperience` action `set_cover`), because it adds nothing new.
- **Storage.** Uploads go to `pending/{businessId}/{experienceId}/`, which only the owner and admins can read. Approval calls the admin-only `publishExperiencePhotos` function, which copies the files to `public/{businessId}/{experienceId}/` (readable by anyone, writable only by the server). Files are never overwritten once uploaded.
- **Data.** `photos` on the experience (and inside a pending revision) lists the photos, cover first. Entries are private upload paths until approved, then public addresses. `imageUrl` mirrors the cover, and the public catalog entry carries `imageUrl` plus `gallery` (the rest).
- **Known limits for now.** Removed or replaced photos are not deleted from Storage, and abandoned uploads stay in the private folder; a cleanup job comes later. Owners can upload several unused files to `pending/` (only size and type are limited).

## Event details form and business name (Phase 3)

Owners can now fill in every section of the public detail page except the two
that DiscoverEase works out itself ("Pair it with" and "Continue your day").

- **Price**: required, one of `$`, `$$`, `$$$`, `$$$$` (budget friendly,
  moderate, pricey, splurge).
- **Type** (subcategory): up to 3 buttons. The category's own types come
  first, then every other type, so a bar can also be tagged Party or Beach and
  shows under each. Stored as one text value ("Bar & Lounge, Beach, Party"),
  which search and the category filters already match on.
- **Hours**: day buttons plus opening and closing time pickers, one or more
  rows; saved as readable text ("Mon–Fri 9:00 AM – 5:00 PM").
- **When it happens**: one date, a date range, or every week on chosen days,
  each with an optional start time, saved as readable text. This is display
  text only; the separate end date (event menu) is what removes an event.
- **Why you'll love it**: free text, up to 600 characters.
- **Perfect for** and **What makes it special**: preset buttons, up to 5 each.
  The choices live in `lib/models/experience_options.dart`.

These follow the same review rules as other text: a live event keeps its old
details until an admin approves the change; the admin "Live edits" card shows
the differences. On approval they are copied to the public `catalog` entry.
Firestore rules cap the text at 600 characters and each list at 5 entries; the
fixed choice lists are enforced by the app, not the rules.

### Business name

The pencil button next to the name on the business dashboard changes it right
away, at any stage. A Cloud Function (`syncBusinessName`) copies the new name
onto every public listing of that business, hidden ones included.

## Address and map pin (Phase 3)

The address field has three helpers, all optional; typing the address alone is
always enough.

- **Tap the map** to drop a pin (OpenStreetMap tiles, no API key or cost).
- **Find on map** looks the typed address up with OpenStreetMap's Nominatim
  service and drops the pin there (only when the button is tapped).
- **Use my location** asks the device for its position, drops the pin and fills
  the address if it was empty. Needs location permission; refusal just falls
  back to typing.

The pin is saved as `latitude` and `longitude` (both or neither) on the
experience, and is public content, so on a live event moving it goes through
review like any text change (the review card shows "Map pin"). Approval copies
it to the catalog; a proposal without a pin removes the old one. On the listing
page the address row becomes **Directions**: it opens the device's maps app at
the exact pin, or searches the typed address plus the destination name.

Setup once per machine: `flutter pub add flutter_map latlong2 geolocator http`.
Android needs `ACCESS_FINE_LOCATION` in `AndroidManifest.xml`; iOS needs
`NSLocationWhenInUseUsageDescription` in `Info.plist`. Web works as is (the
browser asks for permission, and the site must be served over HTTPS in
production). OpenStreetMap's public tile and search servers are for light use;
if DiscoverEase grows, move to a paid map provider.

## Business dashboard thumbnails

Each experience card on the dashboard shows its cover photo, including photos
still waiting for review (the owner can see their own private uploads).

## Highlight tag and card tags

Owners can pick one optional **highlight tag** (Local Favorite, Hidden Gem, Best
Seller, Great Value, Limited Time, Family Favorite, Date Night Pick, Must Try).
It is reviewed like other text. The tag on a card is chosen in this order: a
live Pulse (cards only), an end date ("Ends Dec 3"), the owner's highlight, then
the automatic "New", which wears off 14 days after approval. If none apply, the
card shows no tag.

## Explore and navigation

- Home rows' **See all**, "View Areas", an area card and the other "Explore"
  buttons switch to the **Explore tab**, so the bottom bar stays. "See all"
  arrives with that row's category already chosen (and uses the same matching
  as the row, so the same places appear).
- Explore has a **Browse by category** row (the destination's home-row
  categories) above the area and mood buttons. Selecting the chosen one again,
  or **All**, clears it.
- A page opened on its own (from a trip) shows a back button.
- **Double tap** a card on Home or Explore saves or removes it; the heart only
  shows while saved.
