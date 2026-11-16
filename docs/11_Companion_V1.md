# Trip Companion V1

Companion V1 is a local, deterministic assistant for the selected itinerary
day. It evaluates saved trip times, estimated travel and arrival buffers,
completion state, and reservation details. It does not call external services.

## Available now

- Departure reminders when a travel estimate is saved.
- A reminder when an experience's scheduled start passes.
- Upcoming experience details and free-time windows.
- Lunch and dinner prompts when there is enough time before the next scheduled
  start or estimated departure.
- Reservation reminders using a saved reminder time or a 60-minute default.
- In-app experience details and local reservation details, including copying a
  saved ticket URL.
- Start times, travel estimates, reservation numbers, and ticket links can be
  entered while adding an experience to a trip. A traveler can also save a
  venue closing time for a closing reminder. Timeline items can be marked
  complete to clear their reminders.

Companion refreshes the current-time assessment once a minute while the trip
dashboard is open. It does not claim to know whether a traveler has arrived or
whether a venue is open.

If a trip day has no calendar date, Companion treats it as today. A future
departure reminder therefore needs the trip day date and a start time.

## Integration boundaries

Location and routing require device permission and a maps or directions
provider. Weather requires a forecast provider. Nearby places and events need
search/catalog data and current opening or event information. Flight updates
need an airline, airport, or flight-status provider. AI suggestions need an
AI service, network handling, and user-facing safeguards.

Add each external integration behind a repository or service adapter. Load
and normalize its verified response before evaluation, then pass a focused
`CompanionRule` through `CompanionEngine.build(additionalRules: ...)`. Keep the
engine deterministic and testable; never infer live arrival, opening, weather,
event, or flight facts from itinerary text alone or perform network calls from
inside a rule.
