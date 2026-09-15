# 0013 — Three switchable "gardeny" visual themes

## Context

The app had no visual identity beyond stock SwiftUI system colors/fonts
and a single accent green — no central theme file, everything ad hoc per
view. Real usage feedback (2026-09-12) asked for the app to look "more
gardeny," and after being shown three text descriptions of possible
directions, asked for all three to be built as switchable themes rather
than one being picked and built.

## Decision

- **`GardenTheme`** (`GardenApp/Theme/GardenTheme.swift`) is a plain enum
  with three cases — `handDrawnJournal`, `rusticWoodSoil`,
  `botanicalIllustration` — each supplying a palette (background, grid
  line color/dash/width, bed/structure fill opacity and corner radius,
  accent color) and font choices (SF Rounded / serif / serif-body, per
  theme) via computed properties. No custom image assets or textures —
  everything is expressed in plain SwiftUI (colors, corner radii, dash
  patterns, system font designs) so the three styles stay meaningfully
  different without adding an asset pipeline.
- **Injected via `@Environment(\.gardenTheme)`**, a custom
  `EnvironmentKey`, set once at `RootTabView` from
  `@AppStorage("gardenTheme")` and read by `BedView`, `StructureView`, and
  `GardenMapView`'s grid background. `RootTabView` also applies
  `.tint(theme.accentColor)` so the theme's accent flows through
  navigation bars/buttons app-wide.
- **Stored via `@AppStorage`, not synced through CloudKit.** This is a
  per-device display preference, not app data — the two users sharing the
  iCloud account (0002) may reasonably want different themes on their own
  phones, and there's no reason to burn a CloudKit schema/sync round-trip
  on something this cosmetic.
- **A new Settings tab** (`SettingsView`) lists all three themes with a
  small swatch preview and a checkmark on the active one; tapping a row
  switches immediately. This tab also hosts the garden-size controls from
  0012, since both are map display preferences.

## Consequences

- Only the map surfaces (beds, structures, grid) and the app-wide accent
  are themed. The Calendar and Wiki tabs still use plain system
  `List`/`Form` styling — extending theming there would mean retrofitting
  every row/section in `CareCalendarView`/`PlantWikiListView`, deferred
  since the request was specifically about the map feeling "gardeny."
  Worth a follow-up ADR if that's wanted later.
- `PlacedPlantView` (plant markers) is not themed — species already carry
  their own `colorHex`, and layering a theme-driven marker *shape* on top
  (leaf/flower glyphs, discussed in the design pass but not built) is a
  larger change than palette/font swaps. Flagged as a future enhancement,
  not done here.
