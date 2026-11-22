# Product Roadmap

Foundation ✅
Discovery ✅
Explore ✅
Saved ✅
Repository Layer ✅
Destination System ✅ (curated local catalog)
Listing Detail ✅ (V1)
Planning ✅ (local creation and editing V1)
Companion ✅ (schedule-based V1)
Firebase Auth + Traveler Sync ✅
Business Portal V1 ✅ (owner profile and listing submissions)
Business submission feedback + resubmission ✅
Catalog Publishing + Admin Review ✅
Business Analytics ✅ (deployed and verified in discoverease-dev)
Storage / Media Upload ⏸ (requires Storage billing setup)
Beta ⏳

The destination catalog, stable listing/area IDs, searchable destination
picker, and area-filtered Explore flow are in place. Approved business
experiences publish to Firestore and sync into Explore through the existing
catalog stream.

Signed-in trip and saved-place records now sync to Firestore. Guest demo data
remains local and is not copied into new accounts.

Business Portal V1 lets a signed-in owner submit a business profile and
experiences for review. Admins can review and publish experiences, and owners
can read rejection feedback, edit in-review submissions, and resubmit rejected
experiences. Firestore rules protect moderation fields and keep published
catalog records synchronized with reviewed submissions.

Business performance metrics are deployed to `discoverease-dev` on Blaze.
App Check and callable authentication are verified, and views, likes, shares,
and saves appear in the business dashboard. Business Portal QA confirmed that
pending experiences stay out of public analytics. See
`docs/16_Business_Analytics_V1.md`.

Development Firebase Auth, Firestore, and Cloud Functions are integrated.
Production environment configuration and Storage uploads remain future work.
Location, weather, places, events, flight, and AI integrations require external
services and are not simulated. See `docs/14_Backend_Foundation.md`.

## Ideas for later (not scheduled)

**Private events.** An event that is not listed anywhere and opens only from a
link plus an access code. Needs: no `catalog` entry and no search/Explore
presence; the code stored only as a salted hash on the server; a callable that
checks the code (with attempt limits per link and per device) and returns the
event; owner controls to change or revoke the code and end the event; guest
list and RSVP questions to settle first.

**Pulse allowance and pricing (scheduled with the subscriptions phase).** Posts, not edits, are what is
counted. Free monthly allowance per business, more on paid tiers, extra posts
sold as packs. Fixing a typo in a live post is free and does not extend it;
changing what is happening, or restarting the clock, is a new post. Needs the
subscriptions phase first (payments, tiers).

**Pulse notifications.** Not shown on the trip pages (a place not on the trip is
not relevant there). A saved place posting a Pulse is a good notification once
push notifications are built.
