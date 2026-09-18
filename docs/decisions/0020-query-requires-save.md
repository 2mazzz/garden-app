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
- **Follow-up (2026-09-18): done.** `AddPlantSheet`, `AddStructureSheet`,
  `AddSpeciesSheet`, `AddTaskSheet`, and `GardenMapView.addBed` all
  inserted without an explicit save — `LogHarvestSheet` and
  `AddPlantNoteSheet` had already picked up the fix independently. Found
  while writing a Task 15 UI test that relaunches the app mid-test
  (`app.terminate(); app.launch()`) to reset navigation state: a plant
  added via `AddPlantSheet` was **gone** after relaunch — not just stale
  in the UI, but never actually written to disk. Confirms this bug is
  worse than "UI doesn't refresh": an insert with no save can be lost
  entirely if the process is terminated before some *other*, unrelated
  save happens to flush it. All five now call `try? modelContext.save()`
  right after `insert()`.
- Confirmed via a real build + a `-only-testing` UI test run against a
  freshly `simctl uninstall`-ed app (not just the full suite, which was
  warm enough to hide the bug), per the "Done means" rule in CLAUDE.md.

## Addendum (2026-09-18): deletes don't have this problem

While reviewing Task 9's `PlacedPlantDetailSheet`, we noticed
`deleteHarvestLogs` calls `modelContext.delete(...)` with no following
`save()` — the same shape as this ADR's insert bug. A UI test
(`GardenAppUITests.testHarvestLogDeleteUpdatesUIOnFreshInstall`) reproduced
the scenario against a freshly `simctl uninstall`-ed app: log two harvests,
swipe-to-delete one, and check — without backgrounding or relaunching —
that the row disappears immediately. It does, consistently across repeated
clean-install runs. **No fix was needed.**

The likely reason this differs from the insert case: `PlacedPlantDetailSheet`
doesn't read harvest logs via a `@Query` — it reads
`placedPlant.harvestLogs` directly off an `@Bindable var placedPlant:
PlacedPlant`. SwiftUI's `@Bindable`/Observation machinery appears to
propagate a relationship-array change on an already-observed model
immediately, without waiting for the context's save notification that
`@Query`'s live-update mechanism depends on. This is consistent with the
original finding above (`@Query` specifically needs a save notification to
refresh), not a contradiction of it.

**This does not relax the standing rule.** Any screen backed by a `@Query`
still needs an explicit `save()` after `insert()` (and, by the same logic,
probably after `delete()` too — untested, since no current `@Query`-backed
delete flow exists to check). The rule only doesn't apply to relationship
reads off an already-`@Bindable`/observed model, like this one.
