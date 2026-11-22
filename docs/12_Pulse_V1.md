# Pulse V1

Pulse currently serves as an in-app reminder inbox for the current trip. It
derives reminders from dates, scheduled experience times, saved reservation
reminder times, and saved travel estimates.

## Reminder rules

- A reservation reminder appears at its saved reminder time, or 60 minutes
  before the scheduled start when no reminder time was saved.
- A leave-time reminder appears when the saved travel estimate plus arrival
  buffer reaches its departure time.
- A general start reminder appears 15 minutes before a scheduled experience.
- When more than one rule is active for one experience, Pulse shows the one
  with the latest trigger time.
- Only incomplete experiences scheduled now or within the next 24 hours appear.
- A day must have its own date or inherit one from the trip start date. Pulse
  does not guess dates for undated trips.

Pulse refreshes while the app is open and tapping a reminder opens the matching
trip day. Read state is held in memory for the current app session.

## Not included

Pulse V1 does not send operating-system notifications and does not claim to
know whether a business is open, an event is happening, or a venue is busy.
Business updates, weather and sunset guidance, device location, and push
notifications need real data sources and permissions before they can be added.


## Business Pulse (Phase 3)

Separate from the trip reminders above, a business can post a short update on
one of its live listings, for example "Live Music: band starts at 8".

**Posting.** Dashboard, experience menu, "Post a Pulse". The owner picks what is
happening from a fixed list (Live Music, Happy Hour, Daily Special, Event
Tonight, Limited Time, Now Open, Open Late, Sunset Special, Family Day, Free
Entry), an optional message of up to 100 characters (plain text, no web
addresses), and how long it stays up (3, 6, 12 hours, 1, 3 or 7 days). It goes
live at once with no review, because the tags are fixed and the message is
short and link-free (the same limits as the "unavailable" note).

**One at a time.** A listing has one Pulse; posting again replaces it (after a
30 second pause). The owner can end it early. It also ends by itself when it
expires, when the listing is hidden, ended or deleted, and a scheduled function
tidies up expired ones.

**Where travelers see it.**
- A flashing red dot and the tag on the listing's card (still, with reduced
  motion turned on).
- A banner at the top of the listing page. The first time the listing is opened
  in a session, a popup shows it; tapping the banner opens the popup again.
- A "Happening now" row on the home screen, newest first, for the current
  destination. It is hidden when nothing is live.

**How it is built.** `pulses/{listingId}` is readable by anyone and written only
by the `postPulse`, `endPulse` and cleanup functions (`pulse_logic.js` decides
what is allowed and is unit tested). The app watches posts that have not
expired and also drops one when its time passes while the app is open.

Not included yet: notifications when a saved place posts a Pulse, scheduling a
Pulse for later, and paid extra posts (see the roadmap).
