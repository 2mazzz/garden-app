# 0020 — `@Query` needs an explicit `modelContext.save()` to observe a new insert

## Context

While building Task 7 (the Today tab's add-task flow), `AddGardenTaskSheet`
inserted a new `GardenTask` via `modelContext.insert(task)` and dismissed
the sheet — the same pattern `AddPlantSheet`, `AddStructureSheet`, and
other existing "add" sheets already use. On a **freshly installed** app
(confirmed via `xcrun simctl uninstall` before each test), `TodayView`'s
`@Query private var allTasks: [GardenTask]` never re-rendered after the
insert: `NSLog` instrumentation showed the row genuinely existed
(`modelContext.fetchCount(FetchDescriptor<GardenTask>())` returned the
correct count immediately after `insert()`), but `TodayView.body` was
never re-invoked — confirmed by an `NSLog` at the top of `body` that
simply stopped firing after the insert, for the rest of a 150+ second UI
test. The same insert-only code, run against an already-"warmed" store
(reused across several `xcodebuild test` invocations without
uninstalling), updated the UI within milliseconds.

Adding an explicit `try? modelContext.save()` right after `insert()` fixed
it deterministically across multiple clean (uninstalled) reruns. This
matches known SwiftData+CloudKit behavior: for a CloudKit-backed-or-
fallback `ModelConfiguration`, `@Query`'s live-update mechanism appears to
key off the context's save notification (closer to Core Data's
`NSManagedObjectContextDidSave`) rather than observing uncommitted,
in-context inserts directly. A raw `insert()` is visible to *that same*
context's own fetches (`fetchCount` proved this) but not necessarily to
SwiftUI's `@Query` subscription until a save flushes it.

This is the same class of bug as [0008](0008-cloudkit-fallback.md) and
[0009](0009-cloudkit-attribute-defaults.md): invisible when just reading
the code, and only reproducible with a real build against a genuinely
fresh install — a warm/reused simulator install (the common case when
iterating quickly) can mask it entirely, since *some* unrelated save
eventually flushes the pending insert and the view catches up late enough
that a human tester rarely notices the gap.

## Decision

`AddGardenTaskSheet.addTask()` now calls `try? modelContext.save()`
immediately after `modelContext.insert(task)`, before `dismiss()`.

## Consequences

- This is now a standing rule for any new "insert and dismiss" flow: call
  `try? modelContext.save()` right after `modelContext.insert(...)`, don't
  rely on SwiftData's autosave or a later, unrelated save to make the
  change visible to `@Query`.
- **Follow-up, not yet done:** `AddPlantSheet`, `AddStructureSheet`,
  `AddSpeciesSheet`, and `LogHarvestSheet` all insert without an explicit
  save today. They appear to work in practice because `GardenAppUITests`
  runs as one long-lived suite where an earlier test's save already
  "warms" the same store, and interactive use naturally triggers other
  saves (backgrounding, other edits) soon after. They carry the same
  latent gap this ADR fixes for `GardenTask` and should get the same
  explicit `save()` next time one of them is touched.
- Confirmed via a real build + a `-only-testing` UI test run against a
  freshly `simctl uninstall`-ed app (not just the full suite, which was
  warm enough to hide the bug), per the "Done means" rule in CLAUDE.md.
