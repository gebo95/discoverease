# Claim your business (V1)

An admin adds a business with the contact details on file. The owner signs in,
finds it, and is emailed a one-time code at that address. Typing the code makes
them the owner. This proves the person controls the contact on file.

## How it works

1. **Admin adds the business** (Admin review > the "Claims" icon > Add a business
   to be claimed): name, contact email (required), phone, category, destination.
   This creates a private `businesses/{id}` record (`claimStatus: unclaimed`, no
   owner) and a public `claimable/{id}` record that holds only the name,
   category and a masked hint of the contact ("ow***@cafe.com").
2. **Owner opens the Business portal.** With no business yet, the top card says
   "Already listed? Claim your business". They search by name and pick theirs.
3. **A code is emailed** to the real address on file. The app only ever shows
   the masked hint. The code is 6 digits and works for 15 minutes.
4. **They type it.** Right code: they become the owner (`ownerUid` set,
   `claimStatus: claimed`) and the portal opens on that business.

## Safety rules (enforced on the server)

- Only a hash of the code is stored. The code is never logged or returned.
- 5 wrong tries, then a new code is needed.
- A business can be sent 3 codes an hour (60 seconds apart); one account can ask
  for 6 an hour.
- One account can manage one business.
- Claimed businesses and the contact on file are not readable by anyone else.
- An owner cannot change `ownerUid`, `claimStatus` or `claimedAt` (rules).

## "I can't get the code"

If the email on file is old, the person sends a request with how to reach them
and a note (3 a day). An admin sees it under Claims > Requests for help and can
Approve (gives ownership) or Reject. Updating the contact on file, revoking
ownership and an audit log come with the next phase (Claim and ownership tools).

## Ownership is looked up, not assumed

A business created by signing up has the account's own id. A claimed one keeps
the id it was given. The portal finds the owned business with
`ownerUid == signed-in account`, and uses that id for experiences, Pulses,
plans and analytics.

## Setting up email (Resend)

1. Create an account at resend.com and make an API key (Sending access).
2. `firebase functions:secrets:set RESEND_API_KEY` and paste the key.
3. Deploy: `firebase deploy --only firestore:rules,functions`.
4. While testing, Resend's built-in sender (`onboarding@resend.dev`) only
   delivers to the email address you signed up to Resend with, so add a test
   business using **that** address.
5. Before real owners use this: add and verify your own domain in Resend, then
   set `CLAIM_FROM_EMAIL=DiscoverEase <claims@your-domain>` in
   `functions/.env.discoverease-dev` and deploy functions again.

SMS and WhatsApp codes come later; the phone number is stored (and masked) but
not used yet.

## Taking a business back (revoke)

Admin review > Claims > Claimed businesses > Take back. The owner loses access
at once (every rule checks the business record), the business's live Pulses end,
and it goes back up for claiming. Listings and any paid plan are left alone. Each
revoke is written to `ownership_log` (who, when, reason) and readable by admins.
This works only for businesses that were claimed, not ones that signed up by
themselves. Still to come: updating the contact on file, notifying the old
contact, disabling a compromised account, and an in-app audit log view.
