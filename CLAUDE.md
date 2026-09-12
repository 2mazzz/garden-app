# Garden App

## What this is

A personal iPhone app (native SwiftUI) for tracking a home garden and
greenhouse **in Sweden**: a virtual map for placing plants/trees into beds,
a monthly care-task calendar, and a plant care wiki. Focused specifically
on Sweden — Swedish climate/growing season and common Swedish garden
plants, not a generic international gardening app. Built for exactly two
users (the repo owner and their spouse) sharing one iCloud account — there
is no in-app authentication, multi-tenancy, or public distribution. See
`docs/plans/2026-09-11-garden-app-design.md` for the full product design and
`docs/decisions/` for why specific technical choices were made.

## Standing instructions for agents working in this repo

- **You own this repo end-to-end.** Keep it in a working, buildable state.
  Don't leave it broken between sessions.
- **Log decisions, not just code.** Any non-obvious architectural or product
  choice goes in `docs/decisions/NNNN-title.md` (ADR-style: context, decision,
  consequences) so a future agent session can understand *why*, not just
  *what*. Update `docs/decisions/README.md`'s index when you add one.
- **Design docs live in `docs/plans/`**, one per dated design session,
  following the `superpowers:brainstorming` skill's convention
  (`YYYY-MM-DD-<topic>-design.md`).
- **Self-improve.** When you notice recurring friction, missing tests, a
  stale assumption (e.g. seed data assumes the Northern Hemisphere), or a
  rough edge in the app itself, either fix it or record it as a decision/
  follow-up rather than silently working around it every time.
- **This project has no CI and no App Store distribution.** "Done" means:
  it builds in Xcode, and the feature was actually exercised in the
  simulator or on-device — not just "the code looks right." If you can't
  build (e.g. Xcode isn't installed in your environment), say so explicitly
  instead of claiming it works.

## Environment note

Full **Xcode** (not just Command Line Tools) is required to build or run
this app — SwiftData's `@Model` macro plugin and the iOS SDK both ship only
with Xcode.app. If your environment only has Command Line Tools, you can
still edit Swift/SwiftUI source and update `project.yml`, but you cannot
compile or verify the build; say so rather than claiming a build was
verified. If `xcode-select -p` points at Command Line Tools even though
`/Applications/Xcode.app` exists, you don't need the user's `sudo` to fix
it for yourself — pass `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
inline on `xcodebuild`/`xcrun` calls (shell env vars don't persist between
tool calls in this harness, so it needs to be on every invocation, or
resolved once via a script). Confirmed working this way on 2026-09-12: full
build + `GardenAppUITests` run + Simulator install/launch, all without
touching `xcode-select`.

Two real (non-hypothetical) bugs only surfaced once an actual build ran —
see [0008](docs/decisions/0008-cloudkit-fallback.md) and
[0009](docs/decisions/0009-cloudkit-attribute-defaults.md). Static
reasoning about SwiftData+CloudKit code is not a substitute for building
it; when Xcode is available, always actually build (and ideally run
`GardenAppUITests`) before claiming a change works, per the "Done means"
rule above.

## Architecture at a glance

- **Stack:** Native SwiftUI, iOS 17+, SwiftData for persistence, synced via
  CloudKit (private database) — see `docs/decisions/0001-tech-stack.md` and
  `0003-icloud-sync.md`.
- **Project generation:** The `.xcodeproj` is generated from `project.yml`
  via XcodeGen. Edit `project.yml`, then run `xcodegen generate` — never
  hand-edit `GardenApp.xcodeproj` directly, those changes will be lost on
  the next generate.
- **Data model:** `PlantSpecies` (the wiki entry / catalog, e.g.
  "Äppelträd"), `MapArea` (the Garden or the Greenhouse), `Bed` (a
  plot/pallet within a MapArea), `Structure` (a physical thing placed on a
  MapArea, e.g. the greenhouse building, optionally linking into another
  MapArea when tapped), `PlacedPlant` (one actual plant/tree instance,
  positioned on a MapArea and optionally inside a Bed),
  `MonthlyTaskTemplate` (calendar tasks by month, 1-12).
- **Tabs:** Garden (home screen — outdoor map, including the greenhouse
  building; tapping it pushes into the Greenhouse's own map via the same
  `GardenMapView`), Care Calendar, Plant Wiki. There is no separate
  Greenhouse tab — see `docs/decisions/0006-garden-home-with-structures.md`.
- **First-launch data:** `GardenApp/Seed/SeedData.swift` seeds the two
  MapAreas, the Greenhouse Structure, a starter catalog of common Swedish
  garden plants, and monthly tasks tuned to a Swedish growing season — see
  `docs/decisions/0007-sweden-focus.md`.
