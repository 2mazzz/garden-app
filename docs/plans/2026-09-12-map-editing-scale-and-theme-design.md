# Map editing, garden scale, and visual theme — design session (2026-09-12)

## Origin

Real usage feedback after the first working build surfaced a cluster of
requests in one message:

1. Adding a plant and choosing a bed for it didn't make the plant show up
   inside that bed.
2. The greenhouse structure couldn't be moved.
3. The garden should be resizable/scalable.
4. Want to add a house and a driveway to the map (no functionality needed,
   just for laying out the property).
5. Want the visual design to feel more "gardeny," with a few style
   directions to choose from.
6. The bed color picker only showed raw hex strings, not real colors.

A follow-up mid-implementation request asked for the grid to scroll
"endlessly" in every direction rather than being boxed into a small fixed
rectangle, while still having a clear starting point.

This document records the resulting design; see `docs/decisions/` for the
individual non-obvious technical decisions (0011–0014) made while
implementing it.

## Bug fixes

- **Plant-into-bed positioning** (`AddPlantSheet`): selecting a bed from
  the general "Add Plant" sheet's picker now snaps the plant's position to
  the first free cell inside that bed, reusing the same logic the
  bed's own "Add a plant to this bed" shortcut already used. Previously
  only that shortcut positioned correctly — the general picker set the
  `bed` relationship but never touched `x`/`y`.
- **Greenhouse (and any structure) couldn't move**: `StructureView` had no
  gesture code at all. See 0011.
- **Bed color picker showed hex strings**: replaced with a native
  `ColorPicker`, via a new `Color.toHexString()` round-trip so the
  existing `colorHex: String` storage didn't need to change.

## Features

- **House/driveway/shed structures**: see 0011. Reuses the existing
  `Structure` model (already designed in 0006 to support more than the
  greenhouse) — no schema change, just a new "Add Structure" sheet and a
  preset picker.
- **Garden scale**: see 0012 (pinch-to-zoom, `MapArea.resize`, a new
  Settings tab exposing size controls) and 0014 (the grid became large
  and centered instead of small and corner-anchored, in response to the
  "endless scrolling" follow-up).
- **Three visual themes**: see 0013. Hand-drawn Garden Journal, Rustic
  Wood & Soil, and Botanical Illustration — switchable per-device from
  Settings, applied to the map's grid/beds/structures and the app's
  accent color.

## Explicitly out of scope (this session)

- Theming the Calendar/Wiki tabs (still plain system styling).
- Theme-specific plant marker shapes (leaf/flower glyphs) — markers are
  still a plain colored circle regardless of theme.
- A truly unbounded/infinite canvas with negative coordinates — the grid
  is large (100x100 cells, 50m x 50m, resizable up to 400 cells/side) but
  finite. See 0014's Consequences for why.
- Per-map remembered zoom level.
