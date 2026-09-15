# Weather-Aware Care Calendar & Harvest Log — Design

Date: 2026-09-14
Status: approved, implementing

## Purpose

Two related v2 features, picked from a broader feature-inspiration pass
over established gardening apps (Planta, GrowVeg, Gardenize, Garden.gg,
etc. — see chat history, not written up as a doc since it was a scoped
research pass, not a design):

1. **Weather-aware Care Calendar**: proactive frost warnings for outdoor
   frost-tender plants, using a real forecast for the garden's actual
   location, plus a Care Calendar nudge that cross-references what's
   currently plantable/harvestable against near-term frost risk.
2. **Harvest logging**: a lightweight per-planting harvest log (date,
   quantity, notes) — the smallest, most self-contained of the ideas
   considered, and complementary to (1): a frost warning can call out
   "these are ready — harvest before tonight" using the same
   plantable/harvestable cross-reference the Calendar already computes.

## Scope correction: no climatological planting-window engine

The original pitch was "frost-date-derived planting windows replacing
fixed months." That overreaches what's actually buildable: computing a
real "average last frost date for your specific location" needs
historical climate-normal data, not just a forecast. SMHI's point-forecast
API (see [0015](../decisions/0015-weather-data-source.md)) only covers
live forecast ~10 days out.

Scoped-down version, which is both buildable and more honest:

- `PlantSpecies.plantingMonths` stays as the existing, manually-edited
  per-species months (already the odlingszon-adjustable mechanism noted
  as a gap in the original design doc — this feature doesn't replace it).
- **New**: a live, near-term frost-risk check layered on top. If a
  frost-tender species falls within its plantingMonths *and* frost is
  forecast in the next few days, the Calendar shows a "hold off a few more
  days" nudge instead of silently saying "good time to plant."
- **New**: for plants already placed outdoors, a proactive warning (see
  below) rather than a planting-window computation at all — this is
  where the actual value is, since it's about protecting what's already
  in the ground, not choosing a start date.

## Data model

- **`GardenLocation`** (new, single row, syncs via CloudKit like
  everything else): `latitude`, `longitude`, `placeName`. Deliberately a
  fixed, once-set coordinate (not live device GPS) — the garden doesn't
  move, and this avoids needing any location permission at all, let alone
  background location. Set from a "Garden weather" section in
  `SettingsView`, geocoded from a typed address via `CLGeocoder`.
- **`PlantSpecies.isFrostTender`** (new `Bool`, default `false`): marks
  species that need protection from frost (tomatoes, potatoes, dahlias,
  etc. — hardy natives like rhubarb or currants stay `false`). Editable
  from `AddSpeciesSheet`, shown in `PlantWikiDetailView`.
- **`HarvestLog`** (new model): `date`, `quantity: Double?`, `unit:
  String`, `notes: String`, owned by a `PlacedPlant`
  (`deleteRule: .cascade`, so logs disappear if the planting is removed —
  consistent with how the rest of the model treats a `PlacedPlant` as the
  source of truth for one physical planting's history).

## Weather source & frost-risk logic

SMHI open data point-forecast API, per
[0015](../decisions/0015-weather-data-source.md) — a plain `URLSession`
GET, JSON response, no key. `SMHIWeatherService` fetches the forecast for
the stored `GardenLocation` and extracts the minimum temperature for each
of the next ~5 days. A day counts as frost risk at ≤ 2°C air temperature,
not ≤ 0°C — ground frost ("markfrost") routinely occurs a couple of
degrees above the air-temperature freezing point, and erring toward an
earlier warning is the right failure mode for something whose job is to
prevent losing plants.

`FrostAlertService` ties this together: given a `ModelContext`, it loads
the `GardenLocation` (no-ops if unset), fetches the frost-risk days, and
cross-references outdoor (`MapArea.kind == .outdoor`) `PlacedPlant`s whose
species `isFrostTender` and whose status is `.planted`/`.growing`/
`.planned`. It runs in two places:

1. **Foreground**: on `scenePhase` becoming `.active`, from
   `GardenAppApp`. This is the reliable path — iOS background scheduling
   timing is never guaranteed, so the app checking every time it's opened
   is the actual fallback that makes this feature trustworthy, not an
   afterthought.
2. **Background**: a daily `BGAppRefreshTask`
   (`com.tomasrojder.gardenapp.frostcheck`), best-effort, so a warning can
   arrive even on a day the app isn't opened. Requires
   `BGTaskSchedulerPermittedIdentifiers` and `UIBackgroundModes: [fetch]`
   in `project.yml`'s Info.plist block, plus notification permission
   (`UNUserNotificationCenter`) requested when the user turns on the new
   "Frost alerts" toggle in Settings — not at first launch, so it's tied
   to an explicit choice rather than a generic startup permission prompt.

Known limitation to log rather than paper over: background task timing on
iOS is opportunistic (typically once every day or so, more if the app is
used often, less if it isn't) — this is a real constraint of the
platform, not a bug to chase.

## Care Calendar integration

`CareCalendarView` gains a "Frost risk" section (shown only when relevant)
listing frost-tender outdoor plants alongside the next at-risk date, and,
where a plant is also in `harvestMonths` for the current month, a
combined "ready to harvest — frost forecast, consider picking now"
message — the one place the two features connect, as discussed.

## Harvest log UI

`PlacedPlantDetailSheet` gains a "Harvest log" section: a list of past
entries plus a "Log harvest" button opening `LogHarvestSheet` (date,
quantity, unit, notes — mirrors the existing `AddSpeciesSheet`/
`AddTaskSheet` form pattern). `PlantWikiDetailView` shows a simple
lifetime total (sum of `quantity` across all placements of that species,
where units match) — enough to see "how much did we get this year"
without building a charting feature nobody asked for.

## Testing approach

`SMHIWeatherService`'s JSON parsing and `FrostAlertService`'s
risk/cross-reference logic are pure functions over a `ModelContext` and a
decoded forecast — unit-testable without hitting the network (inject a
fixture JSON response). No new UI test beyond extending the existing smoke
test if time allows; the existing `GardenAppUITests` pattern
(`docs/plans/2026-09-11-garden-app-design.md`) is the model to follow. As
always in this repo, "done" means actually built and run in the
Simulator, not just type-checked — see `CLAUDE.md`.

## Known gaps this doesn't attempt

- No climatological last-frost-date computation (see scope correction
  above) — would need a different, non-forecast data source if ever
  wanted.
- No irrigation/watering-skip nudges from rain forecast — same
  `SMHIWeatherService` could support it later, out of scope for this pass.
- No photo journaling (identified in the same research pass as a strong
  candidate) — separate feature, not bundled here.
