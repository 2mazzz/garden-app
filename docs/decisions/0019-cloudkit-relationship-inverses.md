# 0019 — Every SwiftData relationship needs a declared inverse

## Context

While implementing `GardenTask` and `PlantNote` (two new `@Model` classes
added for the Greenhouse redesign's Today tab and Plant Log), the app built
successfully but crashed on every launch when actually run in the
Simulator. The real error, only visible via `simctl launch --console-pty`
(not shown by static analysis or a clean compile):

> CoreData: error: Store failed to load. ... CloudKit integration requires
> that all relationships have an inverse, the following do not:
> GardenTask: bed
> GardenTask: placedPlant

`GardenTask` had two optional-to-one relationships (`var placedPlant:
PlacedPlant?` and `var bed: Bed?`) with no corresponding collection
property declared on `PlacedPlant` or `Bed` pointing back via
`@Relationship(inverse:)`. This compiles fine — Swift has no way to catch
it — but SwiftData validates the whole schema against CloudKit-compatibility
rules at `ModelContainer` creation, for every `ModelConfiguration`
including the local-only fallback from
[0008](0008-cloudkit-fallback.md), the same way [0009](0009-cloudkit-attribute-defaults.md)'s
missing-default check fires schema-wide, not just for the model actually
being written to at the time. This is a **distinct** constraint from 0009:
0009 is about non-relationship attributes needing declaration-site
defaults, and explicitly notes relationships were unaffected by that rule.
This one is specifically about relationships needing a declared inverse,
regardless of whether either side has a default.

## Decision

Every relationship on every `@Model` class must have its inverse declared
on the other side, even when the link is conceptually a loose, "detached"
reference rather than owned/parent-child data — e.g. a `GardenTask`
naming a `Bed` or `PlacedPlant` it's about, not owned by it. The two
inverses added as the fix:

```swift
// PlacedPlant.swift
@Relationship(deleteRule: .nullify, inverse: \GardenTask.placedPlant)
var gardenTasks: [GardenTask]? = []

// Bed.swift
@Relationship(deleteRule: .nullify, inverse: \GardenTask.bed)
var gardenTasks: [GardenTask]? = []
```

`.nullify` (not `.cascade`) was chosen for both: deleting the bed or plant
a task refers to should just detach the task, not delete the task itself —
consistent with `Bed.placedPlants`'s existing `.nullify` reasoning.

## Consequences

- This is now a standing rule for any new `@Model` relationship: a bare
  `var thing: Other?` (or `[Other]?`) with no matching
  `@Relationship(inverse:)` declared on `Other` will compile clean and then
  fatal-error the `ModelContainer` at first launch. Like 0009, this only
  surfaces at runtime, and only if the app is actually built and run in
  the Simulator/device — not from reading the code or a successful
  `xcodebuild`.
- When adding a relationship property, immediately go add its declared
  inverse on the other model in the same change, before ever building —
  don't treat "it compiled" as evidence the schema is CloudKit-valid.
- Confirmed fixed via a real Simulator launch with `simctl launch
  --console-pty` (fresh install, no stale local store) showing no
  CoreData/SwiftData error and no fatal error, per the "Done means" rule
  in CLAUDE.md — not just by reasoning about the error message.
