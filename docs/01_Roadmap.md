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
