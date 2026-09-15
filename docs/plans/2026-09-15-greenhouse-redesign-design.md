# Greenhouse redesign — design

Date: 2026-09-15

## Source

A high-fidelity design handoff was dropped into `design/design_handoff_garden_app/`
(`Garden System.dc.html` + `README.md` + `garden-logo-c-leaf.{svg,png}`). It
specifies a full visual system ("Greenhouse": ink/green/leaf/lichen/clay/
paper/mist/card/line color roles, Work Sans + IBM Plex Mono type, a
component kit, and a click-through prototype of every screen) plus a new
app icon. It is a *reference*, not code to copy — see its README for the
full token tables, which this doc treats as authoritative and doesn't
restate in full.

This doc records what changes in this codebase to adopt it, and — just as
important — where the handoff's assumptions don't fit this app and what we
build instead.

## Goals

- Adopt "Greenhouse" as the app's one fixed visual system, replacing the
  3-way `GardenTheme` picker.
- Add a 5th tab, **Today**, backed by a new hand-entered task model.
- Restyle every existing screen (Garden map + bed/plant detail, Wiki,
  Calendar, Settings) to the new component patterns.
- Replace the app icon with the supplied logo mark.

## Non-goals (explicitly deferred)

- **The handoff's fixed plot-tile map.** The current app has a from-scratch
  freeform, direct-manipulation map (endless grid, drag/resize beds and
  plant zones, triangle beds — ADRs 0010, 0011, 0012, 0014, 0017). The
  handoff's `grid-template-areas` plot map assumes fixed, named tiles with
  no editing model of its own (its README lists "Edit plot" as the single
  biggest open gap). We already solved that problem differently and better
  for two people who actively rearrange beds. **Keep the freeform map,
  restyle its colors/components only.**
- **Real botanical line art and bespoke tab/UI icons.** Placeholders stay
  as striped blocks / SF Symbols for now.
- **Task recurrence, task generation from species data.** `GardenTask` is
  hand-entered only, no recurrence field, for this pass.
- **Multi-user "Just us" settings, CSV export, a Units setting, manually
  entered Last/First frost dates.** These appear in the handoff's Settings
  screen but have no real backing in this app (no auth/multi-tenancy per
  ADR 0002; frost is already derived from `GardenLocation` +
  `FrostAlertService`, not hand-entered). Settings keeps its current real
  sections, restyled.

## Design tokens

New `GreenhouseTheme` — a **static namespace**, not an enum/environment
value like the old `GardenTheme`, since there is now exactly one visual
style:

- `GreenhouseTheme.Color.*` — the 9 roles + supporting text/border/tint
  values from the handoff's color table, as `Color(hex:)` statics (reusing
  `ColorHex.swift`).
- `GreenhouseTheme.Font.*` — Work Sans (400/500/600) + IBM Plex Mono
  (400/500), bundled in `Resources/Fonts/` and registered via
  `UIAppFonts` in Info.plist (never loaded from a CDN — this is a native
  app). Exposes the full type scale (display/screenTitle/section/
  cardTitle/body/listItem/small/label/mono).
- `GreenhouseTheme.Radius` / `.Spacing` / `.Elevation` — the numeric scale
  and the flat/raised shadow styles as `ViewModifier`s.
- Shared components: `GHButton` (primary/secondary/ghost/disabled),
  `GHChip`, `GHBadge` (sowing/harvest/overdue/dormant), `GHCheckbox`,
  a custom `ToggleStyle`, `GHProgressBar`, `GHEmptyState`, `GHAlertRow`.

`GardenTheme.swift` and its environment key are deleted. Every call site
that read `\.gardenTheme` switches to the static tokens instead.

## App icon

Replace `GardenApp/Resources/Assets.xcassets/AppIcon.appiconset`'s image
with `garden-logo-c-leaf.png`, resized to 1024×1024 and flattened to no
alpha channel (App Store requires an opaque icon; the source PNG carries
an alpha channel even though it's visually opaque).

## Navigation

`RootTabView` grows to 5 tabs in the handoff's order: **Today · Garden ·
Wiki · Calendar · Settings**. Tab icons use SF Symbol approximations of
the handoff's placeholder glyphs (rounded square / diamond / book /
calendar / sliders) — not final art.

## New data

```swift
@Model final class GardenTask: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var locationText: String = ""   // free text, e.g. "Bed 1", "Glass"
    var dueDate: Date = .now
    var isDone: Bool = false
    var placedPlant: PlacedPlant?   // optional link
    var bed: Bed?                   // optional link
    var notes: String = ""
    var createdAt: Date = .now
}
// isLate is computed: !isDone && dueDate < startOfToday. Not stored.
```

```swift
@Model final class PlantNote: Identifiable {
    var id: UUID = UUID()
    var date: Date = .now
    var text: String = ""
    var placedPlant: PlacedPlant?
}
```

`PlantNote` is deliberately separate from `HarvestLog` — harvest keeps its
own quantity/unit shape; notes are freeform journal entries backing Plant
detail's "Log" section and its "Add note" action.

## Screen-by-screen

**Today (new).** Greeting + weather line (reuses `SMHIWeatherService`,
not static copy) + alert row for overdue tasks. No avatar — this app has
no per-user accounts (ADR 0002), so the handoff's avatar circle is
dropped rather than faked. Tasks grouped by day (today, tomorrow, then
named weekdays through +6 days, empty days collapsed). Task card:
checkbox + title + location line + Late badge (suppressed once done, per
the handoff's stated behavior). `+` opens an add-task sheet (title, due
date, optional location text, optional bed/plant picker) — the handoff
leaves "add task" undesigned; this is the minimal form that fits
`GardenTask`.

**Garden.** Canvas keeps all current interaction (drag/resize
beds/structures/plant zones, pinch-zoom, triangle beds). Grid lines →
`line` token, hairline solid (the old per-theme dash patterns have no
handoff equivalent and are dropped). Bed fill → `mist`, tinted `leaf`/
`green` when actively planted. Selection ring → solid 2px `green`,
replacing the per-theme selection style. `BedDetailSheet` rebuilt to the
handoff's card: header (name + meta + status badge) → one row per
`PlacedPlant` (art-placeholder thumb · name + meta · mono water-frequency
line derived from `species.waterRequirement`) → "+ Plant something here".
Header above the map: "The garden" + live plant/area counts.

**Plant detail.** Hero placeholder (390×196, captioned) + back. Title +
location badge + scientific name. Three stat tiles: Sown (`datePlanted`)
/ Water (`waterRequirement`) / Picked (lifetime `HarvestLog` total,
already built). "Its year" 12-month strip from `plantingMonths`/
`harvestMonths`. Log section backed by `PlantNote`. Footer: primary
button **"Log harvest"** opens the existing `LogHarvestSheet` (the
handoff's "Log a task" label is relabeled to avoid colliding with the new
`GardenTask` concept — harvest logging is the more directly useful action
for a plant you're looking at) + secondary "Wiki" cross-link (existing).

**Wiki list.** Search field (`.searchable`, styled to match). Filter chips:
"In my garden" (species with ≥1 non-removed `PlacedPlant`) + category
chips from `PlantCategory`. Flat row list (thumb · name + summary ·
"Growing" badge) replacing the current per-category sectioned list.

**Wiki entry.** Hero + back, title + latin name, four fact tiles (Sow/
Harvest from `plantingMonths`/`harvestMonths` as ranges, Spacing from
`spacingNotes`, Water from `waterRequirement`), prose sections from
`careNotes`/`soilNotes`. Footer cross-link to the in-garden planting when
one exists (existing wiki↔plant relationship, now visually surfaced).

**Calendar.** Segmented control ("This month"/"Whole year") replaces the
month `Picker`. This month keeps `CareCalendarView`'s existing groups
(frost risk, plant-now, harvest-now, tasks), restyled as job cards —
not forced into the handoff's exact 4 category names, since that needs
task categorization the model doesn't have. Whole year is new: a
13-column grid over all in-garden species, sow/harvest bands from
existing month arrays (no separate "grow" data exists; grow is inferred
as the span between sow and harvest, or omitted if that reads badly once
built) with harvest > grow > sow precedence.

**Settings.** Restyled to the handoff's grouped-card pattern. Keeps
current real sections (Garden size steppers, Location + frost-alerts
toggle). Drops the Garden style section (theme is fixed now). No
Just-us/export/units sections (no backing).

## Documentation

- This file.
- `docs/decisions/0018-greenhouse-design-system.md` records the token/
  theme-architecture decision and the freeform-map-vs-plot-tile-map
  decision.
