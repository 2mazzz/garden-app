# 0011 — Extend direct manipulation to structures; generic house/driveway/shed presets

## Context

Real usage feedback (2026-09-12) reported the greenhouse structure couldn't
be moved, and asked for a way to add a house and a driveway to the map so
the whole property could be laid out, not just planting areas. Looking at
`StructureView`, it had no gesture code at all — structures were placed
once at seed time and were otherwise static; only bed editing had received
the direct-manipulation treatment from 0010.

`Structure` itself already generalized past "just the greenhouse" (see
0006) — `linkedMapArea` is optional specifically so a shed or compost bin
could be added later with no schema change. What was missing was entirely
at the UI layer: no drag/resize gestures, no edit sheet, and no "Add
Structure" flow (the greenhouse only ever existed via seed data).

## Decision

- **`StructureView`** gets the same `DragGesture(minimumDistance: 0)`
  move/resize pattern as `BedView` (0010): drag the body to move, drag the
  corner handle to resize, both snapped to grid and clamped to map bounds.
- **Tap behavior branches on `linkedMapArea`**: a structure with a link
  (the greenhouse) navigates into it, matching existing behavior. A
  structure with no link (a house, a driveway) opens `StructureDetailSheet`
  instead, since there's nowhere to navigate to.
- **A pencil icon is always present** on every structure, regardless of
  link, and always opens the edit sheet. Without it, a linked structure
  like the greenhouse would have no way to be renamed, recolored, resized,
  or deleted, since tapping it is reserved for navigation.
- **`StructureDetailSheet`** mirrors `BedDetailSheet`: name, a native
  `ColorPicker`, and delete. No position/size fields — those are set by
  dragging on the map.
- **`AddStructureSheet`** is a new sheet (toolbar "Add Structure", next to
  "Add Bed"/"Add Plant") with a small preset picker — House, Driveway,
  Shed, or Custom — each with its own default name/icon/color/footprint.
  "Custom" exposes a free-text SF Symbol name field for anything else (a
  fence, a pond). No `StructureKind` enum was added to the model — a
  preset only pre-fills the plain `name`/`symbolName`/`colorHex` fields
  `Structure` already has, per the "no further migration" intent in 0006.
- New structures are placed with `linkedMapArea: nil` — non-functional by
  design, exactly as the user asked ("the house doesn't need any
  functions, just that it helps with mapping").

## Consequences

- `PlacedPlantView` previously had no accessibility label/traits at all
  (an oversight found while writing a UI test for the new "add plant via
  the bed picker" flow, not something asked for) — added
  `.accessibilityLabel`/`.accessibilityAddTraits(.isButton)` matching
  Bed/Structure, which also makes plant markers usable with VoiceOver.
- Deleting a structure only nullifies its `linkedMapArea` relationship
  (the default SwiftData delete rule) — deleting the greenhouse structure
  does not delete the Greenhouse `MapArea` or anything inside it, it just
  removes the doorway into it. Acceptable: re-adding a "Greenhouse"
  structure with the same `linkedMapArea` would restore access, and nothing
  is destroyed.
