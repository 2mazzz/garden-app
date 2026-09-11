# Garden App

A personal iPhone app for planning and tracking our garden and greenhouse: a
virtual map for placing plants and trees into beds, a monthly care calendar,
and a plant care wiki. Built for two people (shared iCloud account), not for
public distribution.

See `CLAUDE.md` for how this repo is organized and how decisions are logged,
and `docs/plans/2026-09-11-garden-app-design.md` for the full design.

## Requirements

- A Mac with **Xcode** installed (Command Line Tools alone are not enough —
  SwiftData's `@Model` macro and the iOS SDK both require full Xcode).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) —
  already installed if you're reading this after the initial setup.
- Both iPhones signed into the **same iCloud account**, with iCloud Drive
  enabled, so CloudKit sync works between them.

## Building and running

The `.xcodeproj` is generated from `project.yml` — don't hand-edit the
project file itself, edit `project.yml` and regenerate:

```sh
xcodegen generate
open GardenApp.xcodeproj
```

Then in Xcode: pick your iPhone as the run destination, set your Apple ID
under Signing & Capabilities (Automatic signing), and hit Run.

Because this project currently uses free (non-paid) Apple ID provisioning
(see `docs/decisions/0005-free-provisioning.md`), the app's on-device
signature expires roughly every 7 days — just reconnect the phone and hit
Run again in Xcode to refresh it.

## Project layout

```
GardenApp/
  App/          App entry point, ModelContainer setup, entitlements
  Models/       SwiftData models (PlantSpecies, MapArea, Bed, PlacedPlant, MonthlyTaskTemplate)
  Views/        SwiftUI views, one folder per tab
  Seed/         First-launch starter data (wiki catalog, monthly tasks)
  Resources/    Asset catalog
docs/
  plans/        Design documents
  decisions/    Architecture decision records (ADRs)
```
