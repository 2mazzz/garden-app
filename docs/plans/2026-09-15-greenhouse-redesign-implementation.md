# Greenhouse Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Adopt the "Greenhouse" visual design system from the design handoff across the whole app, add a Today tab backed by a new hand-entered task model, and replace the app icon — while keeping the existing freeform direct-manipulation map exactly as it works today.

**Architecture:** A new static `GreenhouseTheme` namespace (colors/fonts/spacing/radii/elevation as constants, no environment injection, since there's only one style now) plus a small shared component kit (`GHButton`, `GHChip`, `GHBadge`, etc.) in `GardenApp/Theme/`. Every existing screen is restyled in place to use these tokens/components. Two new SwiftData models (`GardenTask`, `PlantNote`) back the new Today tab and Plant detail's note log. `GardenTheme.swift` and the Settings theme picker are deleted.

**Tech Stack:** SwiftUI, SwiftData (+ CloudKit), XcodeGen (`project.yml` → `xcodegen generate`), iOS 17+.

**Reference docs (read before starting):**
- `docs/plans/2026-09-15-greenhouse-redesign-design.md` — the full design, screen-by-screen.
- `docs/decisions/0018-greenhouse-design-system.md` — why one fixed theme, why the freeform map stays.
- `design/design_handoff_garden_app/README.md` — the original design tokens/component spec (source of truth for exact hex values, sizes, spacing).
- `CLAUDE.md` — "Done" means it builds in Xcode AND was exercised in the simulator, not just "looks right." Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` on every `xcodebuild`/`xcrun` call.

**Assets already prepared (do not redo):** `GardenApp/Resources/Fonts/` has `WorkSans-Regular.ttf` (family "Work Sans"), `WorkSans-Medium.ttf` (family "Work Sans Medium"), `WorkSans-SemiBold.ttf` (family "Work Sans SemiBold"), `IBMPlexMono-Regular.ttf` (family "IBM Plex Mono"), `IBMPlexMono-Medium.ttf` (family "IBM Plex Mono Medium") — each renamed to a distinct PostScript name so they can register and be addressed independently via `Font.custom(_:size:)`. The app icon is already replaced.

---

### Task 1: Register bundled fonts

**Files:**
- Modify: `project.yml` (the `GardenApp` target's `info.properties`)

**Step 1: Add `UIAppFonts` to the target's Info.plist properties**

In `project.yml`, under `targets.GardenApp.info.properties`, add:
```yaml
        UIAppFonts:
          - WorkSans-Regular.ttf
          - WorkSans-Medium.ttf
          - WorkSans-SemiBold.ttf
          - IBMPlexMono-Regular.ttf
          - IBMPlexMono-Medium.ttf
```

**Step 2: Regenerate the Xcode project**

Run: `xcodegen generate`
Expected: `Created project at .../GardenApp.xcodeproj` with no errors.

**Step 3: Verify the fonts are registered and usable**

Add a temporary `#Preview` (or check an existing one, e.g. in `SettingsView.swift`) rendering `Text("Aa Sowing 123").font(.custom("Work Sans SemiBold", size: 20))` and `Text("12:34").font(.custom("IBM Plex Mono Medium", size: 15))`. Build for the simulator (Task 1 build command below) and open the preview or run the app — confirm the fonts visibly differ from system San Francisco (Work Sans is more geometric/rounded, IBM Plex Mono has a distinct monospace look). Remove the temporary preview code afterward if you added any — don't leave debug scaffolding behind.

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

**Step 4: Commit**

```bash
git add project.yml
git commit -m "Register bundled Work Sans / IBM Plex Mono fonts via UIAppFonts"
```

---

### Task 2: `GreenhouseTheme` — colors, fonts, spacing, radii

**Files:**
- Create: `GardenApp/Theme/GreenhouseTheme.swift`
- Reference: `ColorHex.swift` for `Color(hex:)` (already exists, reuse it)

**Step 1: Write the theme namespace**

Transcribe every value from the handoff README's "Design Tokens" section exactly — do not approximate hex values. Structure:

```swift
import SwiftUI

/// The app's one fixed visual system, from the "Greenhouse" design handoff
/// (design/design_handoff_garden_app/README.md). See
/// docs/decisions/0018-greenhouse-design-system.md for why this replaced
/// the old switchable GardenTheme.
enum GreenhouseTheme {
    enum Color {
        // Color roles
        static let ink = SwiftUI.Color(hex: "#1F3024")
        static let green = SwiftUI.Color(hex: "#2F5D3A")
        static let leaf = SwiftUI.Color(hex: "#7E9A5C")
        static let lichen = SwiftUI.Color(hex: "#C9D6B3")
        static let clay = SwiftUI.Color(hex: "#A9552C")
        static let paper = SwiftUI.Color(hex: "#FBFAF6")
        static let mist = SwiftUI.Color(hex: "#F1F3EC")
        static let card = SwiftUI.Color(hex: "#FFFFFF")
        static let line = SwiftUI.Color(hex: "#E4E6DE")

        // Supporting text/border/tint values
        static let bodyText = SwiftUI.Color(hex: "#4A5449")
        static let metaText = SwiftUI.Color(hex: "#6A7268")
        static let placeholderText = SwiftUI.Color(hex: "#9BA396")
        static let inputBorder = SwiftUI.Color(hex: "#D7DCCF")
        static let cardDivider = SwiftUI.Color(hex: "#EDEFE8")
        static let disabledFill = SwiftUI.Color(hex: "#E9EBE4")
        static let checkboxStroke = SwiftUI.Color(hex: "#B9C1AF")

        static let greenTint = SwiftUI.Color(hex: "#E8EFDF")
        static let greenTintInk = green
        static let deepTintInk = SwiftUI.Color(hex: "#26402C")

        static let overdueTint = SwiftUI.Color(hex: "#F6E6DC")
        static let overdueInk = SwiftUI.Color(hex: "#8A4320")
        static let overdueSecondaryInk = SwiftUI.Color(hex: "#7A4526")

        static let primaryButtonHover = SwiftUI.Color(hex: "#244A2D")
        static let ghostHoverFill = SwiftUI.Color(hex: "#F1F3EC")
        static let cardHoverBorder = SwiftUI.Color(hex: "#C7CEBD")

        static let plotMapGround = SwiftUI.Color(hex: "#EFEDE2")
        static let plotBorder = SwiftUI.Color(hex: "#DDDACB")
    }

    enum Font {
        static func display() -> SwiftUI.Font { .custom("Work Sans SemiBold", size: 34) }
        static func screenTitle() -> SwiftUI.Font { .custom("Work Sans SemiBold", size: 26) }
        static func section() -> SwiftUI.Font { .custom("Work Sans SemiBold", size: 20) }
        static func cardTitle() -> SwiftUI.Font { .custom("Work Sans SemiBold", size: 17) }
        static func body() -> SwiftUI.Font { .custom("Work Sans", size: 15) }
        static func listItem() -> SwiftUI.Font { .custom("Work Sans Medium", size: 15) }
        static func small() -> SwiftUI.Font { .custom("Work Sans", size: 13) }
        static func label() -> SwiftUI.Font { .custom("Work Sans SemiBold", size: 11) }
        static func mono(_ size: CGFloat = 13) -> SwiftUI.Font { .custom("IBM Plex Mono", size: size) }
        static func monoMedium(_ size: CGFloat = 13) -> SwiftUI.Font { .custom("IBM Plex Mono Medium", size: size) }
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let screenPadding: CGFloat = 20
    }

    enum Radius {
        static let chip: CGFloat = 4
        static let control: CGFloat = 8   // button, input, small tile
        static let card: CGFloat = 10
        static let panel: CGFloat = 12
        static let sheet: CGFloat = 16
        static let pill: CGFloat = 999
    }
}
```

Note: `.label()` in the handoff is also UPPERCASE + 10% tracking — apply `.textCase(.uppercase)` and `.kerning(1.1)` (approximating +10% tracking on 11pt text) at call sites, not baked into the font itself, since `Font` can't carry text-case.

**Step 2: Elevation view modifiers**

Add to the same file:
```swift
extension View {
    /// Flat elevation — lists, rows: hairline border, no shadow.
    func gh_flat() -> some View {
        overlay(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card).stroke(GreenhouseTheme.Color.line, lineWidth: 1))
    }

    /// Raised elevation — cards.
    func gh_raised() -> some View {
        self
            .overlay(RoundedRectangle(cornerRadius: GreenhouseTheme.Radius.card).stroke(GreenhouseTheme.Color.line, lineWidth: 1))
            .shadow(color: GreenhouseTheme.Color.ink.opacity(0.055), radius: 15, x: 0, y: 10)
    }
}
```
(Shadow values approximate the handoff's `0 10px 30px -22px rgba(31,48,36,0.55)` — SwiftUI's shadow model doesn't have a spread/negative-offset equivalent, so this is a reasonable translation, not a pixel match. Note that in the plan.)

**Step 3: Build**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

**Step 4: Commit**

```bash
git add GardenApp/Theme/GreenhouseTheme.swift
git commit -m "Add GreenhouseTheme: colors, fonts, spacing, radii, elevation"
```

---

### Task 3: Shared components

**Files:**
- Create: `GardenApp/Theme/GreenhouseComponents.swift`

**Step 1: Write each component as a small, self-contained SwiftUI view/style**

Follow the handoff README's "Components" section exactly for each (padding, radii, colors, min-height 44 on interactive elements). Required set:

- `GHButtonStyle` (a `ButtonStyle` with a `kind: .primary | .secondary | .ghost` param, disabled state via `@Environment(\.isEnabled)`) — used as `.buttonStyle(GHButtonStyle(kind: .primary))`.
- `GHChip` — a view taking `title: String`, `isSelected: Bool`, `style: .default | .tinted`, tappable via an `action` closure.
- `GHBadge` — a view taking `text: String` and `kind: .sowing | .harvest | .overdue | .dormant`, mapping to the color pairs in the handoff table.
- `GHCheckbox` — a view taking `isChecked: Bool` and toggling via an action closure (20×20, radius 5, per spec).
- `GHToggleStyle` — a custom `ToggleStyle` (40×24 pill) for use as `.toggleStyle(GHToggleStyle())`.
- `GHProgressBar` — a view taking `progress: Double` (0...1) and an optional label row.
- `GHEmptyState` — a view taking `headline: String`, `body: String`, and a primary-button `action`/`buttonTitle`.
- `GHAlertRow` — a view taking `headline: String`, `detail: String` (the `#A9552C` dot + overdue-tinted row).
- `GHArtPlaceholder` — a view taking `caption: String` and a `CGSize`, rendering the 45°-striped placeholder block (`repeating-linear-gradient` equivalent: a `Canvas` or stacked diagonal `Path` strokes) with a small mono caption (`art · <caption>`) — used everywhere the handoff has unbuilt botanical art.

**Step 2: Build**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

**Step 3: Manual check**

Add a throwaway `#Preview` stacking all components together (or check each file's own preview), run in the simulator, and eyeball against the handoff's component section before removing the throwaway preview. This is a visual system — a build success alone doesn't confirm it looks right.

**Step 4: Commit**

```bash
git add GardenApp/Theme/GreenhouseComponents.swift
git commit -m "Add Greenhouse shared components: button, chip, badge, checkbox, toggle, progress bar, empty state, alert row, art placeholder"
```

---

### Task 4: New data models — `GardenTask` and `PlantNote`

**Files:**
- Create: `GardenApp/Models/GardenTask.swift`
- Create: `GardenApp/Models/PlantNote.swift`
- Modify: `GardenApp/App/GardenAppApp.swift:11-20` (schema array)
- Modify: `GardenApp/Seed/PreviewData.swift:8-17` (schema array)
- Modify: `GardenApp/Models/PlacedPlant.swift` (add the inverse relationship for `PlantNote`)

**Step 1: Write `GardenTask.swift`**

```swift
import Foundation
import SwiftData

/// A hand-entered, dated task shown in the Today tab — distinct from
/// MonthlyTaskTemplate (which is a recurring, month-level reminder shown
/// in the Care Calendar, not a checkable dated instance). See
/// docs/plans/2026-09-15-greenhouse-redesign-design.md.
@Model
final class GardenTask: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    /// Freeform "where" line, e.g. "Bed 1", "Glass". Independent of
    /// placedPlant/bed so a task can name a location without a formal link.
    var locationText: String = ""
    var dueDate: Date = Date.now
    var isDone: Bool = false
    var notes: String = ""
    var createdAt: Date = Date.now

    var placedPlant: PlacedPlant?
    var bed: Bed?

    init(
        id: UUID = UUID(),
        title: String,
        locationText: String = "",
        dueDate: Date = .now,
        isDone: Bool = false,
        notes: String = "",
        placedPlant: PlacedPlant? = nil,
        bed: Bed? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.locationText = locationText
        self.dueDate = dueDate
        self.isDone = isDone
        self.notes = notes
        self.placedPlant = placedPlant
        self.bed = bed
        self.createdAt = createdAt
    }

    /// True when overdue and not yet done. Computed, not stored — a stored
    /// flag would need a daily background job to stay correct.
    var isLate: Bool {
        !isDone && dueDate < Calendar.current.startOfDay(for: .now)
    }
}
```

**Step 2: Write `PlantNote.swift`**

```swift
import Foundation
import SwiftData

/// One freeform journal entry for a planting — the "Log" section on Plant
/// detail. Deliberately separate from HarvestLog: harvest keeps its own
/// quantity/unit shape, this is just a dated note.
@Model
final class PlantNote: Identifiable {
    var id: UUID = UUID()
    var date: Date = Date.now
    var text: String = ""
    var placedPlant: PlacedPlant?

    init(id: UUID = UUID(), date: Date = .now, text: String, placedPlant: PlacedPlant?) {
        self.id = id
        self.date = date
        self.text = text
        self.placedPlant = placedPlant
    }
}
```

**Step 3: Add the inverse relationship on `PlacedPlant`**

In `GardenApp/Models/PlacedPlant.swift`, next to the existing `harvestLogs` relationship, add:
```swift
    @Relationship(deleteRule: .cascade, inverse: \PlantNote.placedPlant)
    var notes_log: [PlantNote]? = []
```
Name it `notes_log` (not `notes`) — `PlacedPlant` already has a `var notes: String` field; don't collide with it. (If a better non-colliding name occurs to you while implementing — e.g. `journalEntries` — use that instead; just don't shadow the existing `notes` property.)

**Step 4: Register both models in both schemas**

In `GardenAppApp.swift`'s `Schema([...])` and `PreviewData.swift`'s `Schema([...])`, add `GardenTask.self` and `PlantNote.self` to the list (both places, kept in sync — this has bitten this codebase before, see ADR 0009's CloudKit-default requirement, which both new models already satisfy via declaration-site defaults above).

**Step 5: Build**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

**Step 6: Commit**

```bash
git add GardenApp/Models/GardenTask.swift GardenApp/Models/PlantNote.swift GardenApp/Models/PlacedPlant.swift GardenApp/App/GardenAppApp.swift GardenApp/Seed/PreviewData.swift
git commit -m "Add GardenTask and PlantNote models"
```

---

### Task 5: Remove `GardenTheme` and its call sites

**Files:**
- Delete: `GardenApp/Theme/GardenTheme.swift`
- Modify: every file using `\.gardenTheme` or `GardenTheme` — find them first.

**Step 1: Find every call site**

Run: `grep -rl "GardenTheme\|gardenTheme" GardenApp --include="*.swift"`
Expected: a list including at least `RootTabView.swift`, `SettingsView.swift`, `GardenMapView.swift`, `BedView.swift`, `StructureView.swift`, `PlacedPlantView.swift` (verify against what the grep actually returns — don't assume this list is exhaustive).

**Step 2: For each, replace theme reads with `GreenhouseTheme` equivalents**

This is the bulk of the visual restyle for the map. For each call site:
- Background/grid/fill/border colors → the matching `GreenhouseTheme.Color.*` (grid line → `.line`, canvas background → `.paper` or `.plotMapGround`, bed fill → `.mist` default / `.leaf`+`.greenTint` when planted, selection ring → solid `.green` 2px).
- Fonts → the matching `GreenhouseTheme.Font.*`.
- Remove the `@AppStorage(GardenTheme.storageKey)` / `.environment(\.gardenTheme, theme)` wiring from `RootTabView.swift` entirely.
- Remove the "Garden style" `Section` from `SettingsView.swift` entirely (including `themeRow(_:)` and its `@AppStorage`).

Do this file-by-file, building after each one rather than all at once — a mechanical find-and-replace across 5+ files is exactly where a stray typo hides until the whole thing fails to compile at once.

**Step 3: Delete the old theme file**

Run: `rm GardenApp/Theme/GardenTheme.swift`

**Step 4: Build**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`, zero references to `GardenTheme` left (`grep -rl GardenTheme GardenApp` returns nothing).

**Step 5: Run in the simulator, eyeball the map**

This changes visible colors on the most-used screen in the app. Boot a simulator and actually look at the Garden tab before moving on — per CLAUDE.md, a build succeeding is not the same as the feature working.

**Step 6: Commit**

```bash
git add -A
git commit -m "Replace GardenTheme with GreenhouseTheme across the map, remove theme picker"
```

---

### Task 6: `RootTabView` — add the Today tab

**Files:**
- Modify: `GardenApp/Views/RootTabView.swift`
- Create: `GardenApp/Views/Today/TodayView.swift` (scaffold only — full implementation in Task 7)

**Step 1: Write a minimal `TodayView` scaffold**

```swift
import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            Text("Today")
                .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewData.container)
}
```

**Step 2: Add the tab to `RootTabView`, first position**

Insert before the existing `Garden` tab:
```swift
TodayView()
    .tabItem { Label("Today", systemImage: "square.fill") }
```
(Icon is a placeholder per the design doc — real icon work is out of scope for this pass.)

**Step 3: Build and run**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`. Boot the simulator, confirm 5 tabs appear in order Today/Garden/Wiki/Calendar/Settings.

**Step 4: Commit**

```bash
git add GardenApp/Views/RootTabView.swift GardenApp/Views/Today/TodayView.swift
git commit -m "Add Today tab scaffold as the app's first tab"
```

---

### Task 7: `TodayView` — full implementation

**Files:**
- Modify: `GardenApp/Views/Today/TodayView.swift`
- Create: `GardenApp/Views/Today/AddGardenTaskSheet.swift`

**Step 1: Header + weather line**

Reuse `SMHIWeatherService` (already used by `FrostAlertService`/Calendar) to fetch a current-conditions summary for the `GardenLocation`, if one is set; fall back to just the greeting if no location or the fetch fails — don't block the screen on network. Greeting text: time-of-day based ("Good morning"/"Good afternoon"/"Good evening"), `GreenhouseTheme.Font.screenTitle()`. No avatar (per design doc — this app has no per-user accounts).

**Step 2: Overdue alert row**

`@Query` all `GardenTask` where `!isDone`, filter `isLate` in Swift (computed property, can't express in a SwiftData `#Predicate` directly — fetch not-done tasks and filter client-side, the dataset here is small). If any, show a `GHAlertRow` — "N tasks slipped" style copy, matching the handoff's tone.

**Step 3: Day groups**

Group not-done-or-done-today tasks by day for today through +6 days (empty days collapsed, i.e. don't render a group with zero tasks). Label row: uppercase day label (Today/Tomorrow/weekday name) left, mono date right. Each task as a tappable card: `GHCheckbox` (toggles `isDone`, save via `modelContext`) · title (`listItem`) + `locationText` (`small`, `metaText`) · `GHBadge(kind: .overdue)` when `isLate` (suppressed once `isDone`, which `isLate` already guarantees since it requires `!isDone`).

**Step 4: Add-task sheet**

`AddGardenTaskSheet`: a `Form` with title (`TextField`), due date (`DatePicker`), location text (`TextField`, optional), and optional bed/plant pickers (`Picker` over `@Query` results) that prefill `locationText` when chosen. On save, insert a `GardenTask` and dismiss. Wire a `+` toolbar button on `TodayView` to present it as a sheet. Follow `AddTaskSheet.swift`'s existing pattern (same idea, different model) rather than inventing a new form style.

**Step 5: Empty state**

When there are no tasks at all (not just none for the visible window), show `GHEmptyState` — "No tasks yet" / a short body / a "Add a task" primary button opening the same sheet.

**Step 6: Build and manually verify**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`. In the simulator: add a task due today, confirm it appears under "Today"; add one due yesterday, confirm it shows the Late badge; tap its checkbox, confirm the badge disappears and the card stays in place (no reordering, per the design doc).

**Step 7: Commit**

```bash
git add GardenApp/Views/Today/
git commit -m "Implement Today tab: day-grouped tasks, overdue alert, add-task sheet"
```

---

### Task 8: Garden tab — bed detail card restyle

**Files:**
- Modify: `GardenApp/Views/GardenMap/BedDetailSheet.swift`
- Modify: `GardenApp/Views/GardenMap/GardenMapView.swift` (header row only)

**Step 1: Header row above the map**

Replace the current nav title with "The garden" (`screenTitle`) + a computed subtitle "`N` plants across `M` areas" (count non-removed `PlacedPlant` and `Bed`+`Structure` across the current `MapArea`... decide precisely what "areas" counts as by reading the existing `@Query`s in `GardenMapView` — likely beds + structures on this map, not a cross-map total, since this view is scoped to one `MapArea`). Keep the existing "+" toolbar affordances as-is (add bed/structure/plant) — only the header text and typography change, not the toolbar's function.

**Step 2: Rebuild the bed detail card**

Header: bed name (`cardTitle`) + meta line (`small`, e.g. dimensions or plant count) + a `GHBadge` for overall status if one is derivable (e.g. `.sowing`/`.harvest`/`.dormant` from the mix of `PlantStatus` among its plants — if the mapping feels forced once built, it's fine to drop the badge rather than force a bad fit). Then one row per `PlacedPlant` in the bed: `GHArtPlaceholder` (40×40, captioned with the species name) · species name (`listItem`) + meta (`small`, e.g. status/planted date) · a right-aligned mono line derived from `species.waterRequirement.displayName` (there's no explicit frequency field — use what exists rather than inventing one). Divider between rows: `GreenhouseTheme.Color.cardDivider`. Footer: keep the existing "+ Plant something here" button, restyled with `GHButtonStyle(kind: .secondary)`.

**Step 3: Build and manually verify**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`. In the simulator, select a bed with plants in it and confirm the card renders sensibly (no truncated/overlapping text at typical bed sizes).

**Step 4: Commit**

```bash
git add GardenApp/Views/GardenMap/BedDetailSheet.swift GardenApp/Views/GardenMap/GardenMapView.swift
git commit -m "Restyle Garden tab header and bed detail card to Greenhouse components"
```

---

### Task 9: Plant detail restyle + note log

**Files:**
- Modify: `GardenApp/Views/GardenMap/PlacedPlantDetailSheet.swift`
- Create: `GardenApp/Views/GardenMap/AddPlantNoteSheet.swift`
- Create: `GardenApp/Views/GardenMap/SeasonStripView.swift`

**Step 1: `SeasonStripView` — reusable "its year" component**

A 12-column strip: `HStack(spacing: 3)` of 12 bars (`RoundedRectangle(cornerRadius: 3)`, height 30) each colored `GreenhouseTheme.Color.green` if the month index is in an `activeMonths: Set<Int>` param else `#E7EBE0`-equivalent, with a mono month-initial label below each (`Calendar.current.veryShortMonthSymbols`). Takes `activeMonths: Set<Int>` so it's reusable for both Plant detail (union of `plantingMonths`+`harvestMonths`) and, later, the Calendar year grid.

**Step 2: Rebuild `PlacedPlantDetailSheet`**

Hero: `GHArtPlaceholder` sized 390×196, captioned with the species name. Title block: species common name (`screenTitle`) + location badge (`GHBadge`-style green tint, text = bed name or "Glass" if in the greenhouse `MapArea` with no bed) + scientific name (`small`, `metaText`). Three stat tiles (`HStack`, 1fr each): Sown (`datePlanted`, mono, "—" if nil) / Water (`species.waterRequirement.displayName`) / Picked (existing lifetime `HarvestLog` total — reuse whatever computed property already backs this, don't recompute it differently). `SeasonStripView` with `activeMonths` = union of `species.plantingMonths` and `species.harvestMonths`. Log section: label row ("Log" left, "Add note" button right opening `AddPlantNoteSheet`) + `PlantNote` entries sorted newest-first (dot + text + mono date). Footer: primary `GHButtonStyle(.primary)` "Log harvest" → presents the existing `LogHarvestSheet` (reuse as-is, just restyle the trigger button); secondary "Wiki" → existing cross-link, unchanged behavior.

**Step 3: `AddPlantNoteSheet`**

A single-field sheet (multiline `TextField`/`TextEditor` for the note text, date defaults to now) that inserts a `PlantNote` linked to the current `PlacedPlant` on save. Mirror `LogHarvestSheet.swift`'s existing structure for consistency rather than inventing a new sheet pattern.

**Step 4: Build and manually verify**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`. In the simulator: open a plant with existing harvest logs, confirm the Picked stat still shows the right lifetime total; add a note, confirm it appears in the Log section; tap "Log harvest", confirm the existing sheet still works; tap "Wiki", confirm the cross-link still lands on the right species.

**Step 5: Commit**

```bash
git add GardenApp/Views/GardenMap/PlacedPlantDetailSheet.swift GardenApp/Views/GardenMap/AddPlantNoteSheet.swift GardenApp/Views/GardenMap/SeasonStripView.swift
git commit -m "Restyle Plant detail, add PlantNote-backed log section"
```

---

### Task 10: Wiki list restyle

**Files:**
- Modify: `GardenApp/Views/Wiki/PlantWikiListView.swift`

**Step 1: Filter chips**

Add `@State private var selectedFilter: WikiFilter` (a small local enum: `.inMyGarden`, `.category(PlantCategory)`, or just track `String?` category raw + a separate `inGardenOnly: Bool` — whichever reads cleaner once written) and a horizontal `GHChip` row: "In my garden" + the categories actually present in the current catalog (don't hardcode Veg/Fruit/Herbs — derive from `PlantCategory.allCases` or, better, from what's actually seeded, so the chip row doesn't show empty categories). "In my garden" filters to species with ≥1 `PlacedPlant` where `status != .removed`.

**Step 2: Flat row list**

Replace the current per-`PlantCategory` sectioned `List` with a single flat list of rows (still respecting the search text and the new filter): `GHArtPlaceholder` thumb (46×46) · name (`listItem`) + one-line summary (first sentence of `careNotes`, truncated) · `GHBadge` "Growing" when the species has an in-garden placement. Keep the existing add/delete swipe behavior and the `navigationDestination(for: PlantSpecies.self)` wiring — only the row layout and grouping change.

**Step 3: Build and manually verify**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`. Confirm chip filtering and search both narrow the list correctly, and that tapping a row still navigates to its detail.

**Step 4: Commit**

```bash
git add GardenApp/Views/Wiki/PlantWikiListView.swift
git commit -m "Restyle Wiki list: filter chips, flat row layout, Growing badge"
```

---

### Task 11: Wiki entry restyle

**Files:**
- Modify: `GardenApp/Views/Wiki/PlantWikiDetailView.swift`

**Step 1: Hero + title + fact tiles**

`GHArtPlaceholder` (390×168) + title (`screenTitle`) + latin name (`small`, `metaText`). Four fact tiles in a 2×2 grid: Sow (`plantingMonths` formatted as a month range, e.g. "Mar – Apr" — write a small helper that collapses a `[Int]` of month numbers into a human range; if the months aren't contiguous, list them instead of forcing a range), Harvest (`harvestMonths`, same treatment), Spacing (`spacingNotes`, raw text), Water (`waterRequirement.displayName`).

**Step 2: Prose sections**

Render `careNotes` and `soilNotes` as labeled sections ("Care", "Soil") with `GreenhouseTheme.Font.body()`, skipping either if empty.

**Step 3: Footer cross-link**

If this species has ≥1 in-garden `PlacedPlant` (status != `.removed`), show a `mist`-background footer row: "You're growing this in `<bed name or area name>`" + "Open" → navigates to that `PlacedPlantDetailSheet` (reuse whatever navigation mechanism already exists for this cross-link — check if one does before adding a new one). If there's more than one placement, picking the most recent (`datePlanted`) is a reasonable tiebreak; don't build a picker for this edge case.

**Step 4: Build and manually verify**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`. Confirm the footer only appears for species actually in the garden, and "Open" round-trips correctly (Wiki entry → plant → "Wiki" button → same wiki entry, per the design doc's round-tripping requirement).

**Step 5: Commit**

```bash
git add GardenApp/Views/Wiki/PlantWikiDetailView.swift
git commit -m "Restyle Wiki entry: fact tiles, prose sections, in-garden cross-link"
```

---

### Task 12: Calendar restyle — segmented control + month mode

**Files:**
- Modify: `GardenApp/Views/Calendar/CareCalendarView.swift`

**Step 1: Segmented control**

Replace the month `Picker` with the handoff's segmented control pattern (a custom 2-option `HStack` styled as a track+pill, or `Picker(selection:) { }.pickerStyle(.segmented)` restyled via `UISegmentedControl.appearance()` if that's simpler and close enough — try the native segmented control first before hand-rolling one). Options: "This month" / "Whole year", backed by `@State private var calendarMode: CalendarMode`. Keep the existing prev/next month controls next to the month name header.

**Step 2: Restyle "This month" body**

Keep the existing four groups (frost risk, good-time-to-plant, ready-to-harvest, tasks) and their underlying `@Query`/filter logic entirely as-is — only restyle the row/card rendering to `GHAlertRow` (frost risk) and card-style rows (`cardTitle`/`small`/mono-timing-right) for the rest, per the design doc's explicit call to not force these into the handoff's exact category names.

**Step 3: Build and manually verify**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`. Confirm switching the segmented control swaps content without losing the selected month, and that existing frost-risk/task functionality is unchanged.

**Step 4: Commit**

```bash
git add GardenApp/Views/Calendar/CareCalendarView.swift
git commit -m "Restyle Calendar: segmented This month / Whole year control"
```

---

### Task 13: Calendar — Whole year mode

**Files:**
- Modify: `GardenApp/Views/Calendar/CareCalendarView.swift`
- Create: `GardenApp/Views/Calendar/YearGridView.swift`

**Step 1: `YearGridView`**

Takes the current garden's in-placement species (query `PlacedPlant` where `status != .removed`, dedupe by `species`). Legend row (Sow/Grow/Harvest swatches, per the handoff's three-phase legend). Grid: label column (species name, ellipsised) + 12 month cells per row, 20px tall, radius 3. Phase per cell, precedence harvest > grow > sow:
- Sow = `plantingMonths`.
- Harvest = `harvestMonths`.
- Grow = months strictly between the start of `plantingMonths` and the start of `harvestMonths` that aren't already sow or harvest (a simple inferred band — if this reads badly once rendered for real seeded species, it's fine to drop the grow band and show only sow/harvest, per the design doc's stated fallback).
Empty cell (no phase) → `GreenhouseTheme.Color.mist`.

**Step 2: Wire into `CareCalendarView`**

When `calendarMode == .year`, show `YearGridView()` instead of the month body; keep the month-name header showing the currently selected month for context even though the grid spans the whole year (matches the handoff: "header and month stay").

**Step 3: Build and manually verify**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`. Confirm the grid renders without horizontal overflow on a standard simulator width, and that species with no placements don't appear (only in-garden species should show).

**Step 4: Commit**

```bash
git add GardenApp/Views/Calendar/YearGridView.swift GardenApp/Views/Calendar/CareCalendarView.swift
git commit -m "Add Calendar Whole year mode: season grid across in-garden species"
```

---

### Task 14: Settings restyle

**Files:**
- Modify: `GardenApp/Views/Settings/SettingsView.swift`

(Note: the "Garden style" section was already removed in Task 5 — this task is the remaining visual restyle only.)

**Step 1: Grouped-card sections**

Restyle the existing `Form` sections (Garden size, Garden weather) to the handoff's pattern: uppercase `label` section header + a white `card`-radius container with rows divided by `cardDivider`. SwiftUI's native `Form`/`Section` on iOS already looks close to this on its own (inset grouped style) — evaluate whether a full custom rebuild is worth it or whether adjusting `Section` header font/case + row typography via `.listRowBackground`/`.font` modifiers gets close enough with much less code. Prefer the smaller change if it reads right once built.

**Step 2: Build and manually verify**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`. Confirm every existing control (size steppers, location search, frost toggle) still works exactly as before — this task is styling-only, zero behavior change.

**Step 3: Commit**

```bash
git add GardenApp/Views/Settings/SettingsView.swift
git commit -m "Restyle Settings to Greenhouse grouped-card pattern"
```

---

### Task 15: Full-app pass and UI test run

**Files:** none (verification only)

**Step 1: Full clean build**

Run: `xcodegen generate && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'generic/platform=iOS Simulator' -configuration Debug clean build`
Expected: `** BUILD SUCCEEDED **`

**Step 2: Run the existing UI test suite**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project GardenApp.xcodeproj -scheme GardenApp -destination 'platform=iOS Simulator,name=iPhone 16' test`
Expected: all tests in `GardenAppUITests` pass. If any fail because they asserted on now-removed UI (e.g. the old theme picker, old tab count/order), update the test to match the new UI rather than reverting the redesign — read what each failing test actually checks before changing it.

**Step 3: Install and manually walk every tab**

Boot a simulator, install and launch the app fresh (so `SeedData`/`PreviewData` paths get exercised), and walk: Today (add + complete a task) → Garden (select a bed, open a plant, add a note, log a harvest) → Wiki (search, filter, open an entry, cross-link back to the plant) → Calendar (both modes) → Settings (every control). This is the "actually exercised in the simulator" bar from CLAUDE.md — do this before calling the redesign done.

**Step 4: Fix anything found, commit fixes as you go**

Small, targeted commits per fix rather than one large cleanup commit.

---

### Task 16: Update `CLAUDE.md` and close the loop

**Files:**
- Modify: `CLAUDE.md` (only if the tab list or architecture summary is now stale)

**Step 1: Check "Architecture at a glance"**

`CLAUDE.md`'s "Tabs" line currently reads "Garden (home screen)...Care Calendar, Plant Wiki." Update it to reflect the 5-tab order (Today · Garden · Wiki · Calendar · Settings) and mention `GreenhouseTheme` replacing the old theme system, if that section still describes the old 4-tab/3-theme setup once you re-read it fresh.

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "Update CLAUDE.md for the Greenhouse redesign: 5 tabs, fixed theme"
```
