# 0016 — Additive, per-species wiki seeding instead of empty-catalog gating

## Context

`SeedData.populateIfNeeded` seeded the plant wiki (`starterSpecies`) only
when the `PlantSpecies` table was completely empty (`existing.isEmpty`).
That's the right guard for `MapArea`s and `MonthlyTaskTemplate`s, which the
user edits directly and where re-seeding could clobber or duplicate their
changes.

For the wiki catalog it's the wrong guard. The app is past its first real
build and running on-device (see 0008/0009), meaning the catalog is no
longer empty on either phone. Any species added to `starterSpecies` in a
future session — including via the `adding-a-new-plant` skill — would
never actually reach an already-provisioned device, because the
empty-check short-circuits before it's inserted. The addition would build
and look correct in a diff, but silently do nothing at runtime. This was
caught by baseline-testing that skill before writing it (see
[[adding-a-new-plant]]), not by inspection.

## Decision

`seedSpeciesIfNeeded` now inserts any `starterSpecies` entry whose
`commonName` isn't already present in the catalog, instead of gating on
the catalog being empty. A fresh install still gets the full starter list
(no existing names to match); an already-seeded device picks up newly
added species on its next launch without duplicating ones it already has.

## Consequences

- Renaming an existing starter species' `commonName` will cause it to be
  re-seeded as a new entry rather than updated in place — acceptable,
  since `commonName` edits are rare and the wiki is otherwise
  user-editable in-app.
- `MapArea` and `MonthlyTaskTemplate` seeding are intentionally left on the
  empty-catalog gate; this change is scoped to `PlantSpecies` only.
- This is what makes it safe for the `adding-a-new-plant` skill to add
  entries directly to `starterSpecies` as its normal workflow, rather than
  needing a one-off migration per plant.
