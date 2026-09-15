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
