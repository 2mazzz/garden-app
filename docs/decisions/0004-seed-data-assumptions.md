# 0004 — Seed data assumes Northern Hemisphere

## Context

The starter plant/tree catalog and monthly task list need concrete
planting/harvest months and seasonal tasks to be useful out of the box.

## Decision

`GardenApp/Seed/SeedData.swift` assumes a temperate Northern Hemisphere
climate (e.g. spring planting in March-May, harvest in summer/autumn,
dormant pruning in winter).

## Consequences

- Immediately useful without any setup, but wrong if the garden is in the
  Southern Hemisphere (months would need to shift by 6) or a notably
  different climate zone (tropical, arid, etc.).
- All planting/harvest months live on `PlantSpecies` and are editable
  in-app via the Wiki tab, so this is a one-time data-entry correction, not
  an architectural constraint. No code change needed to fix it for a
  different climate — just edit the seeded species (or delete and re-add
  them) after first launch.
