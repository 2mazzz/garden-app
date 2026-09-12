# 0006 — Garden overview as the home screen; greenhouse is an enterable structure

## Context

Originally the Garden and Greenhouse were two independent tabs, each its
own full-grid `MapArea`, with no relationship between them. Tomas asked
(2026-09-12) for the app to open directly onto a single garden overview
showing beds, trees, *and* the greenhouse together, where tapping the
greenhouse enters it — closer to how a real garden actually looks (the
greenhouse is a building standing in the garden, not a separate place).

## Decision

- Added a `Structure` model: a physical thing placed on a `MapArea` (x, y,
  width, height, name, icon), optionally with a `linkedMapArea` — tapping
  it pushes into that area's own map. The Greenhouse is now seeded as a
  `Structure` placed on the Garden `MapArea`, linked to the Greenhouse
  `MapArea`.
- Removed the standalone Greenhouse tab. The app now has 3 tabs: **Garden**
  (home screen — the full outdoor overview, including the greenhouse
  building), **Calendar**, **Wiki**.
- `GardenMapView` no longer owns its own `NavigationStack` — it's hosted
  inside one `NavigationStack` per tab, with `.navigationDestination(for:
  MapArea.self)` registered once at the Garden tab's root. Entering the
  greenhouse is a normal push (with a back button), not a tab switch.

## Consequences

- The data model now supports structures generally, not just the
  greenhouse — a shed or a compost bin could be added later the same way,
  with no further migration.
- Tap targets for "place a plant here" on the garden grid now exclude any
  cell covered by a structure, so the invisible per-cell buttons don't
  shadow the structure's own tap target.
- `PreviewData`/`GardenAppApp` schemas needed `Structure.self` added
  alongside the existing models.
