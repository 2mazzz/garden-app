# 0012 — Pinch-to-zoom and an in-app garden size control

## Context

The map's grid size (`MapArea.columns`/`rows`) was fixed at seed time
(10x14 outdoor, 6x8 greenhouse) with no way to change it, and no zoom —
one grid cell was always exactly `mapCellSize` (32pt) on screen. Real
usage feedback (2026-09-12) asked for the garden to "be able to have a
different size, like scale it," and separately to see more of the map
comfortably by zooming in and out.

## Decision

- **Pinch-to-zoom**: `GardenMapView` adds a `MagnificationGesture` on the
  scroll view. Following the same committed/live split as `BedView`'s drag
  gestures, `committedZoom` holds the settled scale and `liveZoom` the
  in-progress pinch delta, clamped to 0.5x–3.0x. The zoomed content's
  `ScrollView` frame is explicitly re-declared at `unscaledSize * zoomScale`
  after the `.scaleEffect` — `scaleEffect` alone doesn't change the size
  SwiftUI reports to the enclosing `ScrollView` for layout, so without this
  the scrollable area wouldn't grow/shrink with the zoom level.
- **Each grid cell represents about 0.5 meters** (`metersPerCell` in
  `GardenMapView.swift`) — a fixed display convention, not a stored unit
  conversion used anywhere else in the model. A small pinned legend
  (`scaleLegend`) shows this on the map, outside the zoomed content so it
  stays legible at any zoom level.
- **Garden size is now user-editable**: a new Settings tab
  (`SettingsView`) exposes `MapArea.columns`/`rows` as steppers per map
  area. `MapArea.resize(toColumns:rows:)` changes the grid and clamps
  every bed/structure/plant back inside the new bounds if it shrunk —
  shrinking never deletes anything, it just moves things back inside, in
  keeping with the no-data-loss fix in the previous session (see the
  "fix delete data loss" commit).

## Consequences

- Superseded in part by 0014 (endless grid): the *default* grid size grew
  from a small fixed value to a large one, and the Settings steppers'
  range grew accordingly (4...400, step 5) — the resize/clamp mechanics
  described here are unchanged, only the numbers moved.
- Zoom state (`committedZoom`) is `@State`, not persisted — each time you
  open a map it starts at 1.0x. Acceptable for now; revisit if it turns
  out people want their zoom level remembered per map.
