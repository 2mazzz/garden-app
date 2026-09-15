# 0014 — A large, centered grid instead of a small fixed one ("endless" scrolling)

## Context

Following 0012's zoom/resize work, the user asked for the grid to feel
"endless" — scrollable in every direction rather than boxed into a small
rectangle — while still having "a clear start" (a recognizable anchor,
not literally infinite/directionless). A true infinite canvas (unbounded,
negative coordinates, virtualized rendering) was offered as an
alternative but explicitly declined in favor of a large-but-finite canvas
with the existing layout centered inside it, rather than pinned to a
corner.

Implementing this exposed a real scaling problem in the existing code:
`GardenMapView`'s "tap empty space to place a plant" affordance
(`emptyCellTapTargets`) rendered one invisible SwiftUI view per empty grid
cell — O(rows × columns) views. That was fine at 10x14 (140 cells) but
would have been ~10,000 views at the new size, a well-known SwiftUI
anti-pattern (memory/layout cost, dropped frames).

## Decision

- **Grid size grew from 10x14/6x8 to 100x100** for every `MapArea`
  (`GardenGridDefaults.size` in `GridSizeMigration.swift`), still at
  0.5m/cell (50m x 50m) — generously large for a home garden without
  being unreasonably huge to render or scroll.
- **The old small layout is centered, not corner-anchored**: the
  legacy starter layout's offset from its old grid's center is preserved,
  just applied against the new large grid's center
  (`GardenGridDefaults.outdoorOffsetX/Y`, `greenhouseOffsetX/Y`). Both
  fresh installs (`SeedData`) and existing installs
  (`GridSizeMigration.migrateIfNeeded`, run once at launch after seeding)
  go through the same offset math, so they converge on an identical
  result.
- **Migration only touches MapAreas still at their legacy default size**
  (10x14 / 6x8 exactly) — a MapArea the user already resized via Settings
  (0012) no longer matches those dimensions and is left alone, so this
  can't clobber a deliberate size choice.
- **`ScrollView` opens centered**, via `.defaultScrollAnchor(.center)`
  (iOS 17+) — without it, the ScrollView would open at content (0,0),
  which is now a far corner of empty grid, ~45 cells away from the
  visible layout.
- **New beds/structures default near the grid's center**
  (`GardenMapView.centeredOrigin`), not `(0, 0)` — same reasoning: (0,0)
  is now off in a corner nobody is looking at. The general "Add Plant"
  toolbar action (no prefilled point/bed) defaults its position steppers
  to the grid's center for the same reason.
- **Replaced the O(n²) per-cell tap targets with one gesture**: a single
  `DragGesture(minimumDistance: 0)` on the grid background computes which
  cell was tapped from the gesture's location
  (`col = location.x / mapCellSize`). Beds/structures/plants are drawn on
  top of the background and already have their own gestures, so a tap only
  reaches the background gesture when it lands on genuinely empty space —
  no explicit "is this cell blocked" bookkeeping needed anymore.

## Consequences

- Settings' garden-size steppers (0012) now range 4...400 in steps of 5,
  since one-at-a-time up to 100+ would be tedious.
- Still not literally infinite — shrinking the grid via Settings below
  where existing content sits will clamp that content back inside the new
  bounds (unchanged behavior from 0012), and there is a hard upper bound
  (400 cells / 200m per side) past which Settings won't go. Revisit if
  that ever turns out to be limiting in practice; a truly unbounded canvas
  would need negative coordinates and windowed/virtualized rendering,
  which is a substantially bigger change than this.
