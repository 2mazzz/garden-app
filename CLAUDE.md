# Garden App

## What this is

A personal iPhone app (native SwiftUI) for tracking a home garden and
greenhouse: a virtual map for placing plants/trees into beds, a monthly
care-task calendar, and a plant care wiki. Built for exactly two users
(the repo owner and their spouse) sharing one iCloud account — there is no
in-app authentication, multi-tenancy, or public distribution. See
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
verified.

## Architecture at a glance

- **Stack:** Native SwiftUI, iOS 17+, SwiftData for persistence, synced via
  CloudKit (private database) — see `docs/decisions/0001-tech-stack.md` and
  `0003-icloud-sync.md`.
- **Project generation:** The `.xcodeproj` is generated from `project.yml`
  via XcodeGen. Edit `project.yml`, then run `xcodegen generate` — never
  hand-edit `GardenApp.xcodeproj` directly, those changes will be lost on
  the next generate.
- **Data model:** `PlantSpecies` (the wiki entry / catalog, e.g. "Tomato"),
  `MapArea` (the Garden or the Greenhouse), `Bed` (a plot/pallet within a
  MapArea), `PlacedPlant` (one actual plant/tree instance, positioned on a
  MapArea and optionally inside a Bed), `MonthlyTaskTemplate` (calendar
  tasks by month, 1-12).
- **Tabs:** Garden map, Greenhouse map (same `GardenMapView`, different
  `MapArea`), Care Calendar, Plant Wiki.
- **First-launch data:** `GardenApp/Seed/SeedData.swift` seeds the two
  MapAreas, a starter plant/tree catalog, and generic monthly tasks —
  Northern Hemisphere assumptions, see `docs/decisions/0004-seed-data-assumptions.md`.
