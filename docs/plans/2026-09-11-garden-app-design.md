# Garden App — Design

Date: 2026-09-11 (updated 2026-09-12)
Status: v1 scaffold implemented

## Purpose

A personal iPhone app for tracking a home garden and greenhouse in Sweden:
where things are planted, what to do each month, and how to care for
everything that's been placed. Focused specifically on Sweden — Swedish
climate/growing season and common Swedish garden plants — not a generic
international gardening app. Used by two people (a married couple) sharing
one iCloud account. Not for public use.

## Foundational decisions

See `docs/decisions/` for the full reasoning. Summary:

- Native SwiftUI, iOS 17+, SwiftData ([0001](../decisions/0001-tech-stack.md))
- No in-app auth; shared iCloud account ([0002](../decisions/0002-shared-account.md))
- CloudKit private-database sync, no backend ([0003](../decisions/0003-icloud-sync.md))
- Free Apple ID provisioning for now ([0005](../decisions/0005-free-provisioning.md))
- Garden overview is the home screen; the greenhouse is a structure you tap
  into, not a separate tab ([0006](../decisions/0006-garden-home-with-structures.md))
- Focused on Sweden: Swedish plant names, Swedish growing season
  ([0007](../decisions/0007-sweden-focus.md))

## Data model

- **`PlantSpecies`** — a *type* of plant or tree (e.g. "Tomato", "Apple
  Tree"). This is the wiki: care notes, sun/water needs, soil, spacing,
  planting months, harvest/bloom months. Independent of whether it's
  actually been placed anywhere.
- **`MapArea`** — a top-level map surface: exactly two exist, seeded on
  first launch — "Garden" (outdoor) and "Greenhouse". Each has a grid size
  (columns × rows). Both are rendered by the same `GardenMapView`.
- **`Bed`** — a "pallet"/plot within a MapArea: a rectangle (x, y, width,
  height, color, name). Plants are typically placed inside a bed; trees
  are usually placed directly on the map instead.
- **`Structure`** — a physical thing placed on a `MapArea` (x, y, width,
  height, name, icon), optionally with a `linkedMapArea`: tapping it
  pushes into that area's own map. The Greenhouse is seeded as a
  `Structure` on the Garden, linked to the Greenhouse `MapArea` — see
  [0006](../decisions/0006-garden-home-with-structures.md).
- **`PlacedPlant`** — one actual plant or tree instance: references a
  `PlantSpecies`, positioned at (x, y) on a `MapArea`, optionally inside a
  `Bed`, with a status (planned/planted/growing/harvested/removed), a
  planted date, and freeform notes.
- **`MonthlyTaskTemplate`** — a general gardening task tied to a calendar
  month (1-12), shown in the Care Calendar tab. Seeded with Swedish-climate
  tasks; users can add their own.

Relationships: `MapArea` 1—* `Bed`, `MapArea` 1—* `Structure`, `MapArea`
1—* `PlacedPlant`, `Structure` *—1 `MapArea` (via `linkedMapArea`), `Bed`
1—* `PlacedPlant`, `PlantSpecies` 1—* `PlacedPlant`. All relationships are
optional, as required by SwiftData + CloudKit sync.

## Features / tabs

1. **Garden** (home screen) — the outdoor `MapArea`, shown first when the
   app opens. A scrollable grid canvas showing beds, placed plants/trees,
   and any structures (currently just the greenhouse). Toolbar actions add
   a bed (name, position, size, color via steppers) or add a plant
   (species picker, position, optional bed, status). Tapping an empty cell
   is a shortcut that pre-fills that cell's coordinates into the add-plant
   sheet. Tapping an existing plant opens a detail sheet to change status,
   planted date, notes, or remove it, plus a link into its wiki entry.
   Tapping the greenhouse structure pushes into its own map (see next).
2. **Greenhouse** — not a separate tab. Entered by tapping the greenhouse
   building on the Garden map; reuses the exact same `GardenMapView`,
   pushed onto the Garden tab's navigation stack (so there's a normal back
   button), with its own smaller grid.
3. **Care Calendar** — a month picker (defaults to the current month)
   showing: which placed plants are good to plant this month, which are
   ready to harvest, and the month's task list (seeded + user-added,
   category-tagged with an icon). Users can add custom tasks.
4. **Wiki** — every `PlantSpecies`, grouped by category, searchable by
   name. Detail view shows sun/water needs, planting/harvest months, soil,
   spacing, and care notes, plus how many places it's been planted. Users
   can add new species from here or directly from the add-plant sheet.

## Seed data

First launch seeds: the two `MapArea`s, the Greenhouse `Structure` placed
on the Garden, a 14-entry starter plant/tree catalog of common Swedish
garden plants (potatis, morot, rabarber, dill, gräslök, persilja,
jordgubbe, svarta vinbär, krusbär, äppelträd, plommonträd, syrén, tulpan,
pion — see `GardenApp/Seed/SeedData.swift`), and a 24-item monthly task
list (2 per month) tuned to a central/southern Swedish growing season. See
[0007](../decisions/0007-sweden-focus.md).

## Testing approach

- Model/logic unit tests (e.g. `PlantSpecies.isGoodToPlant`, seed
  idempotency) via Swift Testing or XCTest, once Xcode is available to run
  them — not yet written in this scaffold.
- UI is verified manually in the simulator/on-device; no UI automation
  harness, which is appropriate for a 2-person personal app.
- This design was written and the full source scaffolded without access to
  Xcode in the working environment (Command Line Tools only) — see the
  "Environment note" in `CLAUDE.md`. The code was type-checked as far as
  possible without the SwiftData macro plugin, but a real build has not
  been verified yet. That's the first thing to do once Xcode is installed.

## Known gaps / not yet built (v2 candidates)

- No drag gesture to reposition beds/plants/structures on the map —
  placement is via steppers in a sheet, which is reliable but not as
  tactile as dragging.
- No UI to add, move, or remove structures (the greenhouse is seeded once
  and fixed) — fine while there's exactly one structure, would need a
  sheet similar to `AddBedSheet` if more are added later (a shed, a
  compost bin).
- No auto-generated "your placed plants suggest doing X" beyond the
  planting/harvest month cross-reference already in the Calendar tab.
- No photos attached to placed plants or wiki entries.
- No unit tests yet (blocked on Xcode being available to run them).
- UI chrome (tab labels, category names like "Vegetable"/"Herb") is still
  English even though plant names and seed content are Swedish — full
  Swedish localization hasn't been requested yet.
- Odlingszon varies a lot within Sweden; seeded months assume central/
  southern Sweden and are manually editable per-species, not
  zone-aware/automatic.
