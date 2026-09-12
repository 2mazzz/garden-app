# 0009 — Every SwiftData attribute needs a default value at the property declaration

## Context

First real build with Xcode installed (2026-09-12) revealed the app
crashing on every launch, in both the CloudKit and the local-storage
fallback path added in [0008](0008-cloudkit-fallback.md). The actual error,
only visible via `simctl launch --console` (the unified system log redacts
it as "compose failure [shared UUID]"):

> CloudKit integration requires that all attributes be optional, or have a
> default value set. The following attributes are marked non-optional but
> do not have a default value: ...

Every non-relationship, non-optional property across all six models (`id`,
`name`, `x`, `y`, `colorHex`, etc.) was affected. Critically, this check
fires even for the *local-only* `ModelConfiguration` added in 0008 —
SwiftData validates the schema against CloudKit-compatibility rules
regardless of whether that particular configuration uses CloudKit, so 0008
alone did not fix the crash.

The underlying gotcha: giving a parameter a default value in the custom
`init(...)` (e.g. `init(id: UUID = UUID(), ...)`) does **not** register a
default on the underlying schema attribute. SwiftData only picks up
defaults declared directly on the stored property itself (e.g. `var id:
UUID = UUID()`).

## Decision

Every stored, non-optional, non-relationship property on every `@Model`
class now has a default value at its declaration site, in addition to
(not instead of) the existing custom-`init` parameter defaults. One
follow-up gotcha hit along the way: `= .now` on a `Date` property fails
macro expansion ("requires a fully qualified domain named value") — use
`= Date.now` or `= Date()` instead of the shorthand.

## Consequences

- This is now a standing rule for any new `@Model` property: give it a
  declared default, not just an init default, or CloudKit sync will crash
  the app at launch. Easy to forget since the app builds fine either way —
  it only fails at runtime, and the failure is redacted in `log show`
  unless you launch with `simctl launch --console` or read the `.ips`
  crash report directly.
- Relationships (`var mapArea: MapArea?`, `var placedPlants: [PlacedPlant]?
  = []`) were unaffected — they were already optional/defaulted.
- Confirmed fixed via a real build + UI test run on the Simulator (see
  `GardenAppUITests`), not just by reasoning about the error message.
