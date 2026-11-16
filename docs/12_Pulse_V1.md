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
