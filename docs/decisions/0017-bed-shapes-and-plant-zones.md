# 0017: Bed shapes (rectangle/triangle) and resizable plant footprints

Date: 2026-09-14

## Context

Two pieces of feedback on the map after using it for real:

1. Placing a plant felt off — it just dropped a small fixed-size icon at a
   point, with no relationship to how much of a bed it actually occupies.
   The mental model wanted was closer to "this section of the bed is
   strawberries," not "there's a strawberry-flavored dot here."
2. Beds only came in one shape (axis-aligned rectangle). Real garden plots
   aren't always rectangular — a triangular corner plot needed to be
   representable too.
3. Trees, placed directly on the open map, always rendered at the same
   tiny size as a single herb, when a tree's real footprint (canopy) is
   much larger.

## Decision

**`PlacedPlant` gets a footprint** (`width`/`height` in grid cells,
default 1×1, bigger by default for trees) and reuses the exact same
direct-manipulation interaction `Bed`/`Structure` already have (ADR 0010,
0011): drag the body to move, drag the corner handle to resize. A
"strawberry zone" inside a bed and a standalone tree on the open map now
work identically — place it, then drag it into the area it should cover.

**Placement is now restricted**, not free-for-all: on the outdoor Garden
map, only trees can be placed directly on the open ground — everything
else must be placed inside an existing bed. On the Greenhouse map, any
species can go either inside a bed or directly on the open floor (indoor
growing is often container-based, not strictly bedded). This is enforced
in `AddPlantSheet` by filtering the species picker based on map kind and
whether a bed is selected, not by a separate validation step.

**`Bed` gets a shape**: `.rectangle` (unchanged behavior) or `.triangle`
— a genuinely freeform triangle with 3 independently draggable vertices,
not a shape clipped to the existing rectangle bounding box. Shape is
chosen once at creation (a `Menu` on the "Add Bed" toolbar button) and
isn't switchable afterward — converting a rectangle's 4-corner geometry
into a 3-vertex triangle (or vice versa) isn't a well-defined operation,
so it's not offered rather than guessing.

## Consequences

- `Bed.occupies(x:y:)` is now shape-aware (rectangle containment vs. a
  point-in-triangle test) — the one call site that mattered
  (`AddPlantSheet`'s old "first free cell in this bed" scan) was removed
  anyway now that placement defaults to "top-left of the bed, then you
  drag it," matching how bed/structure creation already works.
- `MapArea.resize()` (shrinking the grid via Settings) and
  `GridSizeMigration` both needed shape-aware handling: a triangle bed
  isn't "shrunk" the way a rectangle is (there's no well-defined way to
  scale 3 independent vertices down) — it's just translated back inside
  the new bounds if it now overflows them.
- A rectangle bed's `x/y/width/height` stay authoritative as before. A
  triangle bed's `x/y/width/height` are only meaningful as the *creation-
  time* bounding box — `Bed.boundingBox` (computed from the live vertices)
  is what everything else should read afterward.
- No migration needed for existing data: `PlacedPlant.width/height` and
  `Bed.shapeRaw` both have declaration-site defaults (1, 1, and
  `.rectangle` respectively), satisfying the CloudKit attribute-default
  requirement from [0009](0009-cloudkit-attribute-defaults.md) — every
  plant already in the database silently becomes a 1×1 footprint, every
  bed already in the database silently becomes (and stays) a rectangle.

## Addendum (2026-09-18): sharp corners and hard-to-grab hit-testing

Real usage surfaced two problems with the triangle shape specifically:

1. **Sharp corners** — purely visual, fixed with a small
   `roundedPolygonPath()` helper in `BedView.swift` that rounds each
   corner via a quadratic curve, radius clamped to half the shorter
   adjacent edge so small/thin triangles don't self-intersect.
2. **Hard to tap/drag** — the actual root cause was architectural, not a
   gesture bug: `BedView`'s triangle case sized its own view to the
   *entire map canvas* (so its `Path` could use absolute canvas
   coordinates), unlike the rectangle case which sizes tightly to its own
   bounds via `.position()`. Every triangle bed's hit-testable frame
   silently overlapped the whole map — including every other bed,
   structure, and plant on it — degrading tap/drag precision everywhere
   near a triangle, not just on the triangle itself.

   Fixed by sizing/positioning the view to the triangle's own bounding
   box, matching the rectangle bed's pattern. Two things fell out of
   getting this right, both worth remembering for any future freeform-
   shape work on this map:
   - A vertex of a triangle sits **exactly on its own bounding box's
     edge**, by definition. Corner drag handles positioned there, with no
     margin, sit flush against the containing view's own frame boundary —
     where SwiftUI's `.position()`-based hit-testing for a child view is
     least reliable. A fixed padding margin around the bounding box (see
     `BedView.trianglePadding`) keeps every vertex, and its enlarged drag
     target, safely inside the frame's interior.
   - Enlarging a corner dot's tappable area past its ~14pt visual size
     (good — a bare 14pt target is well below what a finger reliably
     hits) has to be capped relative to the shape's own edge lengths, not
     a fixed value. The default new bed is a small 2x2-cell triangle; a
     fixed ~44pt-diameter target per corner is big enough that 3 of them
     cover the *entire* shape, leaving no room to grab the body to move
     it rather than reshape it.
