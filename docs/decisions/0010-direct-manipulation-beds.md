# 0010 — Direct-manipulation bed editing instead of a form popup

## Context

First real usage feedback (2026-09-12) surfaced three issues at once:
beds couldn't be deleted, there was no way to move or resize a bed after
creating it, and the creation flow (a full-screen `Form` with steppers for
name/position/size/color) felt like "a big popup" for what should be a
quick, visual action on a map. The user explicitly suggested either a
smaller menu or drawing directly on the map to resize.

Separately, while looking at deletion, found that `Bed`'s relationship to
its `PlacedPlant`s used `deleteRule: .cascade` — deleting a bed would have
silently deleted every plant placed inside it. Fixed to `.nullify`: the
plants stay on the map, just detached from the bed.

## Decision

Replaced form-based bed creation/editing with direct manipulation on the
map itself:

- **Add Bed** (toolbar) creates a bed immediately with defaults (2x2 at the
  top-left, named "New bed") — no popup at all.
- **Drag the bed's body** to move it; **drag the small corner handle** to
  resize it. Both snap to the grid and clamp to map bounds. A single
  `DragGesture(minimumDistance: 0)` disambiguates a tap from a drag by the
  final displacement (`BedView.swift`), rather than fighting SwiftUI with
  two competing recognizers.
- **Tapping a bed** (not dragging it) opens `BedDetailSheet` — a genuinely
  small menu (`.presentationDetents([.height(360), .medium])`, not a
  full-screen `Form`) with just name, color, an "Add a plant to this bed"
  shortcut, and delete.
- Planting *into* a bed no longer happens by tapping an arbitrary cell
  inside it (that tap now always means "move/resize/select the bed"
  instead). It goes through the bed's own "Add a plant to this bed" menu
  action, which auto-picks the first free cell inside the bed's rectangle.
  Cells covered by a bed are excluded from the map's general empty-cell
  tap targets for the same reason (mirrors how structure cells were
  already excluded).

## Consequences

- Removed `AddBedSheet.swift` entirely — creation no longer needs a form.
- Resizing/moving is now discoverable only via the corner-handle icon and
  the "drag the bed" affordance; there's no on-screen hint for first-time
  users beyond the one line of text in `BedDetailSheet`. Worth watching —
  add a first-use tooltip if it turns out not to be discoverable enough.
- Precise pixel-drag-to-grid-cell math (snap, clamp, live visual feedback
  during drag) is exactly the kind of code that looks right but can be
  subtly wrong (off-by-one at map edges, anchor point during resize) —
  verify by actually dragging in the Simulator/on-device, not just by
  reading the gesture code.
