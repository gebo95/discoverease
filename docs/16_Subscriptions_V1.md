# Subscriptions, Pulse allowance and Featured placement (V1)

Payments run on Stripe (Checkout + customer portal). The app never handles
card details and never writes a plan: Stripe tells our webhook, and only the
webhook changes plans, packs and Featured placement.

## Plans

| Plan | Pulses | Extras |
|------|--------|--------|
| Free | 3 a month | list experiences, post Pulses |
| Plus | 15 a month | more Pulses for busy weeks |
| Pro  | unlimited (fair use 300 a month) | priority in Explore (Featured sorting only for now), analytics preview (planned) |

Prices are set in Stripe, not in code (planned starting prices: Plus $19/mo, Pro $49/mo, 5 Pulses $5, 15 Pulses $12). A lapsed or unpaid plan counts as Free
(`active`, `trialing`, `past_due` keep the plan).

## Pulse allowance

- The allowance is per **business**, counted by UTC calendar month. Last
  month's use is ignored automatically, so nothing needs resetting.
- A **new post** uses one: monthly Pulses first, then bought packs. Pro ignores
  packs and stops at the fair-use limit.
- A **typo fix** is free: same listing, same tag, same running time, new words.
  It keeps the original start and end, so it does not flash again. A different
  tag or duration counts as a new post.
- Packs (5 or 15) never expire.

## Featured placement

A one-time purchase per listing, 7 or 30 days, stacking onto time left. Featured
listings sort first in Discover This Week (with a Featured badge) and Explore.

## Data (all written by Cloud Functions only)

- `subscriptions/{businessId}`: plan, status, cancelAtPeriodEnd,
  currentPeriodEnd, pulseMonth, pulsesUsed, packBalance. Owner can read.
- `featured/{listingId}`: businessId, destinationId, startsAt, endsAt. Public.
- `billing_private/{businessId}`: Stripe customer id. Nobody can read.
- `stripe_events/{eventId}`: handled webhook events, so a retry does nothing.
- `businesses/{id}.subscriptionTier` is kept in step by the webhook.

## Functions

- `createCheckoutSession` (owner only): opens Stripe Checkout for plus, pro,
  pack5, pack15, featured7 or featured30. Refuses a second plan (use billing).
- `createPortalSession` (owner only): change/cancel plan, receipts.
- `stripeWebhook`: verifies the Stripe signature, then handles
  `checkout.session.completed` and `customer.subscription.*`.
- `postPulse` now checks and spends the allowance.

## Setting up Stripe (test mode)

1. Stripe dashboard, test mode: create products and prices: Plus (monthly),
   Pro (monthly), Pulse pack 5 (one-time), Pulse pack 10 (one-time), Featured 7
   days (one-time), Featured 30 days (one-time).
2. Turn on the customer portal (Settings > Billing > Customer portal) and allow
   switching plans and cancelling.
3. `cd functions && npm install`
4. `firebase functions:secrets:set STRIPE_SECRET_KEY` (the `sk_test_...` key)
5. Copy `functions/.env.example` to `functions/.env.discoverease-dev` and fill
   in `APP_URL` and the six price ids.
6. `firebase deploy --only firestore:rules,functions`
7. In Stripe > Developers > Webhooks add the `stripeWebhook` function address
   with the events `checkout.session.completed`,
   `customer.subscription.created`, `.updated` and `.deleted`. Then
   `firebase functions:secrets:set STRIPE_WEBHOOK_SECRET` with its `whsec_...`
   signing secret and deploy functions again.
8. Test with card 4242 4242 4242 4242.

## Granted plans (founding partners)

An admin can give a business Plus or Pro for 1 to 24 months without Stripe:
Admin review > the plans icon > enter the business email > pick plan and
length > Give plan. It is stored as `compPlan` and `compUntil` on
`subscriptions/{businessId}`, counts as the plan until the date, then stops by
itself. If the business also pays, the better of the two applies. "Remove
granted plan" clears it. The later discount (for example 50% off after the
free months) is a Stripe coupon, applied when they subscribe.

## Explore order

Results are shuffled once per visit (stable while scrolling or filtering).
Filters and search are applied first. Featured listings land at a random spot
within the first ten results rather than always first, and a listing with a live
Pulse gets a slight boost. While a search is typed, results keep match order.
Discover This Week still shows Featured listings first.
