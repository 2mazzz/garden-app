# Garden App — Design

Date: 2026-09-11
Status: v1 scaffold implemented

## Purpose

A personal iPhone app for tracking a home garden and greenhouse: where
things are planted, what to do each month, and how to care for everything
that's been placed. Used by two people (a married couple) sharing one
iCloud account. Not for public use.

## Foundational decisions

See `docs/decisions/` for the full reasoning. Summary:

- Native SwiftUI, iOS 17+, SwiftData ([0001](../decisions/0001-tech-stack.md))
- No in-app auth; shared iCloud account ([0002](../decisions/0002-shared-account.md))
- CloudKit private-database sync, no backend ([0003](../decisions/0003-icloud-sync.md))
- Free Apple ID provisioning for now ([0005](../decisions/0005-free-provisioning.md))

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
- **`PlacedPlant`** — one actual plant or tree instance: references a
  `PlantSpecies`, positioned at (x, y) on a `MapArea`, optionally inside a
  `Bed`, with a status (planned/planted/growing/harvested/removed), a
  planted date, and freeform notes.
- **`MonthlyTaskTemplate`** — a general gardening task tied to a calendar
  month (1-12), shown in the Care Calendar tab. Seeded with generic
  Northern-Hemisphere tasks; users can add their own.

Relationships: `MapArea` 1—* `Bed`, `MapArea` 1—* `PlacedPlant`, `Bed` 1—*
`PlacedPlant`, `PlantSpecies` 1—* `PlacedPlant`. All relationships are
optional, as required by SwiftData + CloudKit sync.

## Features / tabs

1. **Garden** — the outdoor `MapArea`. A scrollable grid canvas. Toolbar
   actions add a bed (name, position, size, color via steppers) or add a
   plant (species picker, position, optional bed, status). Tapping an
   empty cell is a shortcut that pre-fills that cell's coordinates into the
   add-plant sheet. Tapping an existing plant opens a detail sheet to
   change status, planted date, notes, or remove it, plus a link into its
   wiki entry.
2. **Greenhouse** — identical UI, a second `MapArea` (kind `.greenhouse`),
   smaller default grid.
3. **Care Calendar** — a month picker (defaults to the current month)
   showing: which placed plants are good to plant this month, which are
   ready to harvest, and the month's task list (seeded + user-added,
   category-tagged with an icon). Users can add custom tasks.
4. **Wiki** — every `PlantSpecies`, grouped by category, searchable by
   name. Detail view shows sun/water needs, planting/harvest months, soil,
   spacing, and care notes, plus how many places it's been planted. Users
   can add new species from here or directly from the add-plant sheet.

## Seed data

First launch seeds: the two `MapArea`s, a ~14-entry starter plant/tree
catalog spanning vegetables, herbs, flowers, shrubs, trees, and fruit (see
`GardenApp/Seed/SeedData.swift`), and a generic 24-item monthly task list
(2 per month). See [0004](../decisions/0004-seed-data-assumptions.md) for
the Northern Hemisphere caveat.

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

- No drag gesture to reposition beds/plants on the map — placement is via
  steppers in a sheet, which is reliable but not as tactile as dragging.
- No auto-generated "your placed plants suggest doing X" beyond the
  planting/harvest month cross-reference already in the Calendar tab.
- No photos attached to placed plants or wiki entries.
- No unit tests yet (blocked on Xcode being available to run them).
- Southern Hemisphere / climate-zone adjustment is manual (edit seeded
  species), not automatic.
