# 0018: Adopt the "Greenhouse" design system; keep the freeform map

Date: 2026-09-15

## Context

A high-fidelity design handoff (`design/design_handoff_garden_app/`) was
supplied: a full visual system ("Greenhouse" — color roles, Work
Sans/IBM Plex Mono type scale, a component kit) plus a click-through
prototype of every screen, including a 5th "Today" tab and a redesigned
plot map. See `docs/plans/2026-09-15-greenhouse-redesign-design.md` for
the full screen-by-screen mapping.

Two things in the handoff needed a real decision rather than a straight
port:

1. **One fixed style vs. the existing 3-theme picker.** ADR 0013 gave the
   app three switchable "gardeny" visual directions. The handoff is one
   opinionated, fully-specified system with no variants.
2. **The plot map.** The handoff's Garden screen is a fixed
   `grid-template-areas` layout of named tiles (Bed 1, Bed 2, Greenhouse,
   ...) with no editing model — its own README lists "how beds are
   created, renamed, resized and arranged" as the single biggest
   undesigned gap. This app already has a working answer to that exact
   problem: a from-scratch freeform, direct-manipulation map (endless
   grid, drag-to-move/resize beds and plant zones, triangle beds — ADRs
   0010, 0011, 0012, 0014, 0017), built and refined over several sessions
   specifically because a fixed/generic layout didn't match how a real,
   irregular garden plot is shaped.

## Decision

**Replace `GardenTheme` with a single static `GreenhouseTheme` namespace**
(colors/fonts/spacing/radii/elevation as constants, no enum, no
`@AppStorage`, no environment key). There is exactly one visual style now,
so instance-based theming machinery is pure overhead. The Settings
"Garden style" picker is removed.

**Keep the freeform map's interaction model; adopt only Greenhouse's
colors and component styling for it.** The handoff's fixed plot-tile grid
is not built. This means we deliberately diverge from the handoff on this
one screen's structure (not just its skin) — the handoff is treated as
authoritative for visual language, not as a mandate to regress a
direct-manipulation feature that took real iteration to get right and has
no replacement design for editing.

## Consequences

- ADR 0013 (three switchable themes) is superseded by this decision.
- ADRs 0010, 0011, 0012, 0014, 0017 (the freeform map's interaction model)
  remain fully in effect — only rendering colors/components change on that
  screen, not geometry or gesture code.
- Every screen otherwise adopts the handoff's structure closely (Today tab,
  Wiki fact tiles/filters, Calendar month/year modes, restyled Settings
  groups) since none of those had an existing, deliberately-built
  alternative to preserve.
- If a future design pass wants an actual "edit the plot as named tiles"
  mode, it needs its own design work (the handoff didn't provide one) —
  not a reason to revisit this decision on its own.
