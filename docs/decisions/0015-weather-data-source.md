# 0015: SMHI open data API instead of WeatherKit for forecast data

Date: 2026-09-14

## Context

Frost-aware planting windows and harvest logging (see
`docs/plans/2026-09-14-weather-and-harvest-design.md`) need real forecast
data for the garden's location. Apple's **WeatherKit** was the obvious
first choice — no backend, first-party, generous free call quota — but
enabling the WeatherKit capability on an App ID requires enrollment in the
paid Apple Developer Program. That directly conflicts with
[0005](0005-free-provisioning.md), which chose free Apple ID provisioning
specifically to avoid that $99/year cost. Unlike CloudKit
([0008](0008-cloudkit-fallback.md)), there's no free-tier fallback for
WeatherKit — the capability simply isn't available to a free/personal
team.

## Decision

Use **SMHI's open data API**
(`opendata-download-metfcst.smhi.se`) — the Swedish Meteorological and
Hydrological Institute's public point-forecast API — instead. It requires
no API key, no account, and no paid enrollment of any kind: a plain HTTPS
GET with a descriptive `User-Agent` header, called directly from the app.
This also fits the project's Sweden-only focus better than a generic
global weather API would.

Trade-off accepted: SMHI's point forecast only covers the Nordic region
and only extends ~10 days out, and it has no historical climate-normal
data. That's enough for the near-term frost-risk warnings this feature
needs, but it rules out ever computing a true climatological
"average last frost date" per region — see the corresponding scope note
in the design doc.

## Consequences

- No new entitlement or paid account needed; a plain `URLSession` call is
  sufficient — matches the existing "no backend" architecture
  ([0001](0001-tech-stack.md), [0003](0003-icloud-sync.md)).
- If this app is ever used outside the Nordics, the weather feature would
  need a different data source — acceptable since the whole app is
  explicitly Sweden-only ([0007](0007-sweden-focus.md)).
- SMHI's usage policy requires a descriptive `User-Agent`; no rate-limit
  key management needed for a two-person personal app's call volume.
