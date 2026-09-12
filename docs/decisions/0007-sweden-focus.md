# 0007 — Focus on Sweden and Swedish climate

## Context

This app is being built for a garden in Sweden. The original seed data
(0004) used generic Northern-Hemisphere assumptions and English/American
plant names (tomato, cucumber, lemon tree...), which don't match Swedish
growing conditions or what's actually common in a Swedish garden. Tomas
asked (2026-09-12) that Sweden be a defining detail of the app, not an
afterthought, and that this be reflected in the project's core
instructions, not just the seed data.

## Decision

- The app's charter now explicitly states it is focused on Sweden and
  Swedish climate/common plants — recorded in
  `docs/plans/2026-09-11-garden-app-design.md` and in the assistant's
  cross-session project memory, alongside the original charter.
- The starter wiki catalog (`SeedData.swift`) was replaced with plants and
  trees common in Swedish home gardens, using Swedish common names:
  potatis, morot, rabarber, dill, gräslök, persilja, jordgubbe, svarta
  vinbär, krusbär, äppelträd, plommonträd, syrén, tulpan, pion.
- Planting/harvest months and the monthly task list were retuned to a
  typical central/southern Swedish growing season (roughly odlingszon
  II-III / Svealand): short summers, frost risk lingering into mid/late
  May, bare-root planting in spring and autumn, heavy reliance on the
  greenhouse to extend the season for tomatoes/peppers/cucumbers.
- This **supersedes [0004](0004-seed-data-assumptions.md)**, which assumed
  a generic Northern Hemisphere climate and English-named plants. 0004 is
  kept for history but no longer describes the actual seed data.

## Consequences

- Seed data is now opinionated toward one specific climate and garden
  culture, which is the right trade-off for a single-family personal app,
  but would need rework (not just relabeling) to suit a different region.
- Plant *names* in the wiki are Swedish; the rest of the UI (tab labels,
  categories like "Vegetable"/"Herb", buttons) is still in English. Full UI
  localization to Swedish was not requested and is out of scope for now —
  worth asking about explicitly if it matters, rather than assuming.
- Exact odlingszon varies a lot within Sweden (Skåne vs. Norrland can differ
  by a month or more on both ends of the season); the seeded months assume
  the more populous central/southern zones and are editable per-species in
  the Wiki tab if a specific garden's zone differs.
