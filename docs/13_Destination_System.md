# Destination System

The local destination catalog uses stable destination IDs. Each destination
contains its country and country code, region, time-zone identifier, tagline,
hero image, home sections, and ordered area IDs. Destination areas point back
to their destination, and listings point to both a destination ID and a
primary area ID.

## In the app

- Home keeps the destination selector at the top and has no search field.
- The selector searches by city/destination, country, or region.
- Explore uses the selected destination ID for its listing query and shows
  area filters.
- Home area cards open Explore with that area selected.
- Existing country-name listing queries remain supported for trip data during
  the model transition.

## Current limits

The catalog and destination selection are in memory and reset to the first
catalog item after restart. The current catalog contains curated entries for
Nassau, Tokyo, and Rome. More destinations should be added with verified
listing content and area mappings. Coordinates are optional and are not
populated, so nearby recommendations and location-based sorting are not active.
The saved time-zone identifier is catalog metadata for now; trip schedule
calculations still use device-local time until a time-zone-aware trip model is
implemented.

The repository accepts catalog lists through its constructor so a backend
adapter can supply them later. Keep destination and area IDs stable when
connecting persistent trip, saved-list, and business records.
