import XCTest

/// Smoke test exercising the main navigation flows: entering the
/// greenhouse from the garden map, and switching between tabs.
final class GardenAppUITests: XCTestCase {
    func testGardenShowsGreenhouseAndTabsSwitch() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))
        XCTAssertTrue(tabBar.buttons["Today"].exists)
        XCTAssertTrue(tabBar.buttons["Garden"].exists)
        XCTAssertTrue(tabBar.buttons["Calendar"].exists)
        XCTAssertTrue(tabBar.buttons["Wiki"].exists)
        XCTAssertTrue(tabBar.buttons["Settings"].exists)

        // Today is the home tab on launch; switch to Garden, which shows
        // the greenhouse structure.
        tabBar.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))
        let greenhouseButton = app.buttons["Greenhouse"]
        XCTAssertTrue(greenhouseButton.waitForExistence(timeout: 20))

        // Tapping it enters the greenhouse's own map, with a back button to Garden.
        greenhouseButton.tap()
        XCTAssertTrue(app.navigationBars["Greenhouse"].waitForExistence(timeout: 20))
        app.navigationBars["Greenhouse"].buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))

        // Calendar tab shows the month picker and at least one seeded task.
        tabBar.buttons["Calendar"].tap()
        XCTAssertTrue(app.navigationBars["Care Calendar"].waitForExistence(timeout: 20))

        // Wiki tab shows the Swedish starter catalog. Since Task 10's flat,
        // commonName-sorted list replaced the old category-grouped one,
        // "Tulpan" is no longer guaranteed to be within the initial
        // viewport — search for it instead of assuming scroll position.
        tabBar.buttons["Wiki"].tap()
        XCTAssertTrue(app.navigationBars["Plant Wiki"].waitForExistence(timeout: 20))
        let wikiSearchField = app.searchFields["Search the wiki"]
        XCTAssertTrue(wikiSearchField.waitForExistence(timeout: 20))
        wikiSearchField.tap()
        wikiSearchField.typeText("Tulpan")
        let tulpanPredicate = NSPredicate(format: "label CONTAINS[c] %@", "Tulpan")
        let tulpanElement = app.descendants(matching: .any).matching(tulpanPredicate).firstMatch
        XCTAssertTrue(tulpanElement.waitForExistence(timeout: 20))
        // Dismiss search — while active it replaces the tab bar, which the
        // next step needs to switch to Settings.
        app.buttons["Close"].tap()

        // Settings tab shows the weather/frost-alert section added alongside
        // garden style and size — see docs/plans/2026-09-14-weather-and-harvest-design.md.
        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 20))
        let weatherSectionPredicate = NSPredicate(format: "label CONTAINS[c] %@", "Garden weather")
        let weatherSection = app.descendants(matching: .any).matching(weatherSectionPredicate).firstMatch
        XCTAssertTrue(weatherSection.waitForExistence(timeout: 20))
    }

    /// Exercises the direct-manipulation bed flow: create (no popup), drag
    /// to move, tap to open the compact edit menu, and delete.
    func testBedCreateDragEditDelete() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))
        tabBar.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))

        // Creating a bed shows it immediately with no popup — "Add Bed" is
        // a menu offering a shape (rectangle/triangle) since
        // docs/decisions/0017-bed-shapes-and-plant-zones.md.
        app.navigationBars["Garden"].buttons["Add Bed"].tap()
        app.buttons["Rectangle"].tap()
        let bed = app.buttons["New bed"]
        XCTAssertTrue(bed.waitForExistence(timeout: 20))
        let originalFrame = bed.frame

        // Dragging the bed's body moves it (verified by its frame changing).
        let start = bed.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = bed.coordinate(withNormalizedOffset: CGVector(dx: 3.0, dy: 2.0))
        start.press(forDuration: 0.1, thenDragTo: end)

        let movedBed = app.buttons["New bed"]
        XCTAssertTrue(movedBed.waitForExistence(timeout: 20))
        XCTAssertNotEqual(movedBed.frame.origin.x, originalFrame.origin.x,
                           "Expected the bed's on-screen position to change after dragging it")

        // A plain tap (negligible movement) opens the compact edit menu, not a move.
        movedBed.tap()
        XCTAssertTrue(app.navigationBars["Edit Bed"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Delete bed"].waitForExistence(timeout: 12))

        app.buttons["Delete bed"].tap()
        XCTAssertFalse(app.buttons["New bed"].waitForExistence(timeout: 15))
    }

    /// Regression test: picking a bed from the general "Add Plant" sheet's
    /// picker used to leave the plant at the stepper default (0,0) instead
    /// of inside the chosen bed's rectangle — see AddPlantSheet's
    /// onChange(of: selectedBed).
    func testAddPlantViaBedPickerPositionsInsideBed() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))
        tabBar.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))

        app.navigationBars["Garden"].buttons["Add Bed"].tap()
        app.buttons["Rectangle"].tap()
        let bed = app.buttons["New bed"]
        XCTAssertTrue(bed.waitForExistence(timeout: 20))
        let bedFrame = bed.frame

        app.navigationBars["Garden"].buttons["Add Plant"].tap()
        XCTAssertTrue(app.navigationBars["Place Plant"].waitForExistence(timeout: 20))

        // The Form's Picker rows present their options as a popover menu
        // (a CollectionView of buttons), not a pushed list — scope the
        // query to collectionViews so this doesn't collide with the
        // same-named bed/plant buttons already on the map underneath.
        //
        // Bed must be picked before species: on the outdoor map, only
        // trees are selectable without a bed chosen first — see
        // AddPlantSheet.availableSpecies and
        // docs/decisions/0017-bed-shapes-and-plant-zones.md. The picker's
        // displayed value isn't asserted here (it has no "None" option to
        // start with in this context), so match on the label prefix.
        let bedPickerButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Bed")).firstMatch
        XCTAssertTrue(bedPickerButton.waitForExistence(timeout: 20))
        bedPickerButton.tap()
        let bedOption = app.collectionViews.buttons["New bed"]
        XCTAssertTrue(bedOption.waitForExistence(timeout: 20))
        bedOption.tap()

        app.buttons["Species, Choose one"].tap()
        let speciesOption = app.collectionViews.buttons["Potatis"]
        XCTAssertTrue(speciesOption.waitForExistence(timeout: 20))
        speciesOption.tap()

        app.buttons["Add"].tap()

        let plantMarker = app.buttons["Potatis"]
        XCTAssertTrue(plantMarker.waitForExistence(timeout: 20))
        XCTAssertTrue(
            bedFrame.insetBy(dx: -1, dy: -1).contains(plantMarker.frame.origin),
            "Expected the plant to be positioned inside the bed's rectangle, not the sheet's stepper default"
        )

        // Clean up so later tests in the suite don't see leftover data —
        // the persistent store survives across app launches. "Remove from
        // map" is the last row in the restyled detail sheet's Form, below
        // the fold — scroll to it first.
        plantMarker.tap()
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Remove from map"].waitForExistence(timeout: 20))
        app.buttons["Remove from map"].tap()

        XCTAssertTrue(bed.waitForExistence(timeout: 20))
        bed.tap()
        XCTAssertTrue(app.navigationBars["Edit Bed"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Delete bed"].waitForExistence(timeout: 20))
        app.buttons["Delete bed"].tap()
        XCTAssertFalse(bed.waitForExistence(timeout: 15), "Expected the bed created by this test to be cleaned up")
    }

    /// Exercises adding a non-functional structure (a driveway), dragging
    /// it, editing it via the pencil icon (not the tap-to-navigate path,
    /// which only applies to linked structures like the greenhouse), and
    /// deleting it.
    func testAddStructureCanBeDraggedAndEdited() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))
        tabBar.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))

        app.navigationBars["Garden"].buttons["Add Structure"].tap()
        XCTAssertTrue(app.navigationBars["Add Structure"].waitForExistence(timeout: 20))
        app.buttons["Driveway"].tap()
        app.buttons["Add"].tap()

        let driveway = app.buttons["Driveway"]
        XCTAssertTrue(driveway.waitForExistence(timeout: 20))
        let originalFrame = driveway.frame

        // Dragging the structure's body moves it — this used to be
        // impossible (structures had no gesture code at all).
        let start = driveway.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = driveway.coordinate(withNormalizedOffset: CGVector(dx: 3.0, dy: 2.0))
        start.press(forDuration: 0.1, thenDragTo: end)

        let movedDriveway = app.buttons["Driveway"]
        XCTAssertTrue(movedDriveway.waitForExistence(timeout: 20))
        XCTAssertNotEqual(movedDriveway.frame.origin.x, originalFrame.origin.x,
                           "Expected the structure's on-screen position to change after dragging it")

        // The pencil icon opens the edit sheet directly (a plain tap would
        // try to navigate for a linked structure, but a driveway has none).
        let editIcon = movedDriveway.images["Edit"]
        XCTAssertTrue(editIcon.waitForExistence(timeout: 20))
        editIcon.tap()
        XCTAssertTrue(app.navigationBars["Edit Structure"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Delete structure"].waitForExistence(timeout: 12))

        app.buttons["Delete structure"].tap()
        XCTAssertFalse(app.buttons["Driveway"].waitForExistence(timeout: 15))
    }

    /// Exercises the freeform triangle bed shape — create, drag the whole
    /// shape to move it, and delete. See
    /// docs/decisions/0017-bed-shapes-and-plant-zones.md.
    func testTriangleBedCreateDragDelete() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))
        tabBar.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))

        app.navigationBars["Garden"].buttons["Add Bed"].tap()
        app.buttons["Triangle"].tap()
        let bed = app.buttons["New bed"]
        XCTAssertTrue(bed.waitForExistence(timeout: 20))
        let originalFrame = bed.frame

        // Dragging inside the triangle moves the whole shape.
        let start = bed.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let end = bed.coordinate(withNormalizedOffset: CGVector(dx: 3.5, dy: 2.7))
        start.press(forDuration: 0.1, thenDragTo: end)

        let movedBed = app.buttons["New bed"]
        XCTAssertTrue(movedBed.waitForExistence(timeout: 20))
        XCTAssertNotEqual(movedBed.frame.origin.x, originalFrame.origin.x,
                           "Expected the triangle's on-screen position to change after dragging it")

        // Dragging a corner dot (the apex, at the top-center of the
        // bounding box) reshapes the triangle independently, growing its
        // bounding box — distinct from the whole-shape move above. The
        // default new bed is a 2x2-cell (64x64pt) triangle inside a
        // frame padded 20pt on every side (see BedView.trianglePadding),
        // so the apex sits at normalized (0.5, 20/104 ≈ 0.19), not (0.5, 0).
        let beforeReshapeFrame = movedBed.frame
        let apex = movedBed.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.19))
        let apexTarget = movedBed.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -1.3))
        apex.press(forDuration: 0.1, thenDragTo: apexTarget)

        let reshapedBed = app.buttons["New bed"]
        XCTAssertTrue(reshapedBed.waitForExistence(timeout: 20))
        XCTAssertGreaterThan(reshapedBed.frame.height, beforeReshapeFrame.height,
                              "Expected dragging the apex further away to grow the triangle's bounding box")

        reshapedBed.tap()
        XCTAssertTrue(app.navigationBars["Edit Bed"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Delete bed"].waitForExistence(timeout: 12))

        app.buttons["Delete bed"].tap()
        XCTAssertFalse(app.buttons["New bed"].waitForExistence(timeout: 15))
    }

    /// Enforces the placement rule from
    /// docs/decisions/0017-bed-shapes-and-plant-zones.md: on the outdoor
    /// map, without a bed selected, only trees are offered — a
    /// non-tree species like Potatis must not appear.
    func testOpenGroundSpeciesPickerOnlyOffersTrees() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))
        tabBar.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))

        app.navigationBars["Garden"].buttons["Add Plant"].tap()
        XCTAssertTrue(app.navigationBars["Place Plant"].waitForExistence(timeout: 20))

        app.buttons["Species, Choose one"].tap()
        XCTAssertTrue(app.collectionViews.buttons["Äppelträd"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.collectionViews.buttons["Potatis"].exists,
                        "A non-tree species shouldn't be offered for open-ground placement")

        app.collectionViews.buttons["Äppelträd"].tap()
        app.buttons["Add"].tap()

        let tree = app.buttons["Äppelträd"]
        XCTAssertTrue(tree.waitForExistence(timeout: 20))
        tree.tap()
        // "Remove from map" is the last row in the restyled detail sheet's
        // Form, below the fold — scroll to it first.
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Remove from map"].waitForExistence(timeout: 20))
        app.buttons["Remove from map"].tap()
        XCTAssertFalse(tree.waitForExistence(timeout: 15))
    }

    /// Exercises the Today tab's core flow: add a task via the sheet,
    /// confirm it appears, and toggle its checkbox — the
    /// taskCheckbox-<uuid> accessibility identifier set on
    /// GardenTaskCardRow (GardenApp/Views/Today/TodayView.swift) exists
    /// specifically for this. See
    /// docs/plans/2026-09-15-greenhouse-redesign-design.md ("Today
    /// (new)").
    func testTodayTabAddTaskAndToggleCheckbox() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))
        tabBar.buttons["Today"].tap()

        let addTaskButton = app.buttons["Add Task"]
        XCTAssertTrue(addTaskButton.waitForExistence(timeout: 20))
        addTaskButton.tap()

        XCTAssertTrue(app.navigationBars["New Task"].waitForExistence(timeout: 20))
        let titleField = app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 20))
        titleField.tap()
        // GardenTask has no delete UI yet, so the store accumulates across
        // runs — a unique title avoids colliding with leftovers from
        // earlier runs when matching by static text below.
        let taskTitle = "UI Test Task \(Date().timeIntervalSince1970)"
        titleField.typeText(taskTitle)
        app.buttons["Add"].tap()

        let titleElement = app.staticTexts[taskTitle]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 20))

        // Find the checkbox on the same row as the title we just added —
        // proximity, not "first match", since older leftover tasks may
        // also be on screen with their own taskCheckbox- buttons.
        let checkboxes = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "taskCheckbox-"))
        var checkbox: XCUIElement?
        for i in 0..<checkboxes.count {
            let candidate = checkboxes.element(boundBy: i)
            if abs(candidate.frame.midY - titleElement.frame.midY) < 30 {
                checkbox = candidate
                break
            }
        }
        let taskCheckbox = try XCTUnwrap(checkbox, "Expected to find the new task's checkbox")

        XCTAssertEqual(taskCheckbox.value as? String, "Not checked")
        taskCheckbox.tap()
        XCTAssertEqual(taskCheckbox.value as? String, "Checked")
    }

    /// Regression test for a question raised while reviewing Task 9:
    /// PlacedPlantDetailSheet.deleteHarvestLogs deletes without an explicit
    /// modelContext.save(), the same shape as the insert-path bug in ADR
    /// 0020. Verified against a fresh install (see ADR 0020's addendum):
    /// unlike @Query-backed inserts, this delete updates the UI
    /// immediately, because the row list reads placedPlant.harvestLogs
    /// directly off an @Bindable model rather than through a separate
    /// @Query. This test locks that behavior in.
    func testHarvestLogDeleteUpdatesUIOnFreshInstall() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))
        tabBar.buttons["Garden"].tap()

        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))
        app.navigationBars["Garden"].buttons["Add Plant"].tap()
        XCTAssertTrue(app.navigationBars["Place Plant"].waitForExistence(timeout: 20))
        app.buttons["Species, Choose one"].tap()
        XCTAssertTrue(app.collectionViews.buttons["Äppelträd"].waitForExistence(timeout: 20))
        app.collectionViews.buttons["Äppelträd"].tap()
        app.buttons["Add"].tap()

        let tree = app.buttons["Äppelträd"]
        XCTAssertTrue(tree.waitForExistence(timeout: 20))
        tree.tap()

        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Log harvest"].waitForExistence(timeout: 20))

        // Log two distinguishable harvests.
        app.buttons["Log harvest"].tap()
        XCTAssertTrue(app.navigationBars["Log Harvest"].waitForExistence(timeout: 20))
        var quantityField = app.textFields["Quantity (optional)"]
        XCTAssertTrue(quantityField.waitForExistence(timeout: 20))
        quantityField.tap()
        quantityField.typeText("1")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["1 kg"].waitForExistence(timeout: 20))

        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Log harvest"].waitForExistence(timeout: 20))
        app.buttons["Log harvest"].tap()
        XCTAssertTrue(app.navigationBars["Log Harvest"].waitForExistence(timeout: 20))
        quantityField = app.textFields["Quantity (optional)"]
        XCTAssertTrue(quantityField.waitForExistence(timeout: 20))
        quantityField.tap()
        quantityField.typeText("2")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["2 kg"].waitForExistence(timeout: 20))

        // (The Picked stat tile at the top is scrolled out of view at this
        // point, so it's not checked here.)

        // Swipe-to-delete the "1 kg" harvest log row. Swipe on the row's
        // Cell, not the narrow "1 kg" label itself — a swipeLeft() on a
        // ~31pt-wide text element doesn't drag far enough for the List to
        // recognize a swipe-to-delete gesture.
        let oneKgRow = app.cells.containing(.staticText, identifier: "1 kg").firstMatch
        XCTAssertTrue(oneKgRow.waitForExistence(timeout: 20))
        oneKgRow.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 10))
        deleteButton.tap()

        // Without backgrounding/relaunching: the row should disappear and
        // the remaining "2 kg" entry should still be visible immediately.
        XCTAssertFalse(app.staticTexts["1 kg"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["2 kg"].waitForExistence(timeout: 5))

        // Clean up so later tests in the suite don't see a leftover
        // Äppelträd placement. "Remove from map" is further down, past the
        // harvest log section already in view.
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Remove from map"].waitForExistence(timeout: 20))
        app.buttons["Remove from map"].tap()
        XCTAssertFalse(tree.waitForExistence(timeout: 15))
    }

    /// Covers the Task 10 Wiki list restyle: filter chips, search, and
    /// row-to-detail navigation on the new flat row list.
    func testWikiListFilterSearchAndNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))
        tabBar.buttons["Wiki"].tap()
        XCTAssertTrue(app.navigationBars["Plant Wiki"].waitForExistence(timeout: 20))

        // Category chips are present, derived from the seeded catalog.
        XCTAssertTrue(app.buttons["Vegetable"].waitForExistence(timeout: 10))

        // "In my garden" filters to nothing on a fresh install (no placements yet).
        app.buttons["In my garden"].tap()
        XCTAssertFalse(app.staticTexts["Dill"].waitForExistence(timeout: 5))
        app.buttons["In my garden"].tap() // toggle back off
        XCTAssertTrue(app.staticTexts["Dill"].waitForExistence(timeout: 10))

        // Search narrows the flat list.
        let searchField = app.searchFields["Search the wiki"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("Dill")
        XCTAssertTrue(app.staticTexts["Dill"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Morot"].exists)
        app.buttons["Close"].tap()

        // Tapping a row navigates to its detail, matching navigationDestination.
        let dillRow = app.staticTexts["Dill"]
        XCTAssertTrue(dillRow.waitForExistence(timeout: 10))
        dillRow.tap()
        XCTAssertTrue(app.navigationBars["Dill"].waitForExistence(timeout: 10))
    }

    /// Covers the Task 11 Wiki entry restyle: fact tiles render, and the
    /// in-garden footer cross-link only appears once the species is
    /// actually placed, then round-trips (Wiki entry -> plant -> "Wiki"
    /// button -> a wiki entry for the same species again).
    func testWikiEntryFactTilesAndInGardenCrossLink() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))

        // Before placing it, Äppelträd's wiki entry shows fact tiles but no
        // in-garden footer. Search for it first — the flat list sorts by
        // raw commonName, which doesn't put every entry within the initial
        // viewport.
        tabBar.buttons["Wiki"].tap()
        XCTAssertTrue(app.navigationBars["Plant Wiki"].waitForExistence(timeout: 20))
        var searchField = app.searchFields["Search the wiki"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("Äppelträd")
        let appleRow = app.staticTexts["Äppelträd"]
        XCTAssertTrue(appleRow.waitForExistence(timeout: 10))
        appleRow.tap()
        XCTAssertTrue(app.navigationBars["Äppelträd"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Sow"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Harvest"].exists)
        XCTAssertTrue(app.staticTexts["Spacing"].exists)
        XCTAssertTrue(app.staticTexts["Water"].exists)
        XCTAssertFalse(app.buttons["Open"].exists)

        // Place an Äppelträd on the Garden map.
        tabBar.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))
        app.navigationBars["Garden"].buttons["Add Plant"].tap()
        XCTAssertTrue(app.navigationBars["Place Plant"].waitForExistence(timeout: 20))
        app.buttons["Species, Choose one"].tap()
        XCTAssertTrue(app.collectionViews.buttons["Äppelträd"].waitForExistence(timeout: 20))
        app.collectionViews.buttons["Äppelträd"].tap()
        app.buttons["Add"].tap()
        XCTAssertTrue(app.buttons["Äppelträd"].waitForExistence(timeout: 20))

        // The Wiki tab kept its navigation state (still pushed into the
        // Äppelträd entry) — the footer reads the species' placements
        // relationship live, so it should now show the cross-link without
        // needing to re-navigate.
        tabBar.buttons["Wiki"].tap()
        XCTAssertTrue(app.navigationBars["Äppelträd"].waitForExistence(timeout: 20))
        let openButton = app.buttons["Open"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 10))

        // Tapping it opens the plant's own detail sheet. "Log harvest" is
        // below the fold — scroll to it, same as elsewhere in this file.
        openButton.tap()
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Log harvest"].waitForExistence(timeout: 20))

        // Its "Wiki" button round-trips back to a wiki entry for the same
        // species. Disambiguate from the Wiki *tab* button — both have the
        // label "Wiki", but only the tab bar one carries the "book.fill"
        // accessibility identifier.
        let sheetWikiButton = app.buttons.matching(
            NSPredicate(format: "label == 'Wiki' AND identifier != 'book.fill'")
        ).firstMatch
        XCTAssertTrue(sheetWikiButton.waitForExistence(timeout: 10))
        sheetWikiButton.tap()
        XCTAssertTrue(app.navigationBars["Äppelträd"].waitForExistence(timeout: 20))

        // Clean up so later tests in the suite don't see a leftover
        // Äppelträd placement. Relaunching (not uninstalling) resets the
        // nested sheet/navigation state from the round-trip above without
        // losing the persistent store, so the removal flow below can reuse
        // the same simple pattern every other test uses.
        app.terminate()
        app.launch()
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))
        tabBar.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))
        let treeMarker = app.buttons["Äppelträd"]
        XCTAssertTrue(treeMarker.waitForExistence(timeout: 20))
        treeMarker.tap()
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Remove from map"].waitForExistence(timeout: 20))
        app.buttons["Remove from map"].tap()
        XCTAssertFalse(treeMarker.waitForExistence(timeout: 15))
    }

    /// Covers the Task 12/13 Calendar restyle: month header + prev/next
    /// navigation, the This month/Whole year segmented control, and the
    /// year grid showing a placed species' sow/grow/harvest phases.
    func testCalendarHeaderNavigationAndYearGrid() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20))

        // Place a tree first so the year grid isn't empty.
        tabBar.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))
        app.navigationBars["Garden"].buttons["Add Plant"].tap()
        XCTAssertTrue(app.navigationBars["Place Plant"].waitForExistence(timeout: 20))
        app.buttons["Species, Choose one"].tap()
        XCTAssertTrue(app.collectionViews.buttons["Äppelträd"].waitForExistence(timeout: 20))
        app.collectionViews.buttons["Äppelträd"].tap()
        app.buttons["Add"].tap()
        XCTAssertTrue(app.buttons["Äppelträd"].waitForExistence(timeout: 20))

        tabBar.buttons["Calendar"].tap()
        XCTAssertTrue(app.navigationBars["Care Calendar"].waitForExistence(timeout: 20))

        // The header shows the current month name; the seeded September
        // task cards ("Plantera vårlökar" etc.) confirm "This month" is
        // showing real content, not an empty state.
        let currentMonthName = DateFormatter().monthSymbols[Calendar.current.component(.month, from: .now) - 1]
        XCTAssertTrue(app.staticTexts[currentMonthName].waitForExistence(timeout: 10))

        // Prev/next chevrons step the header's month name.
        let nextButton = app.buttons["Next month"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10))
        nextButton.tap()
        XCTAssertFalse(app.staticTexts[currentMonthName].exists,
                        "Expected the header's month to change after tapping next")

        let prevButton = app.buttons["Previous month"]
        prevButton.tap()
        XCTAssertTrue(app.staticTexts[currentMonthName].waitForExistence(timeout: 10),
                       "Expected tapping prev to return to the original month")

        // The segmented control switches to the year grid, which shows the
        // placed Äppelträd's row.
        app.buttons["Whole year"].tap()
        XCTAssertTrue(app.staticTexts["Äppelträd"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Sow"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Grow"].exists)
        XCTAssertTrue(app.staticTexts["Harvest"].exists)

        // Switching back to "This month" restores the month body.
        app.buttons["This month"].tap()
        XCTAssertTrue(app.staticTexts[currentMonthName].waitForExistence(timeout: 10))

        // Clean up so later tests in the suite don't see a leftover
        // Äppelträd placement.
        tabBar.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 20))
        let treeMarker = app.buttons["Äppelträd"]
        XCTAssertTrue(treeMarker.waitForExistence(timeout: 20))
        treeMarker.tap()
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Remove from map"].waitForExistence(timeout: 20))
        app.buttons["Remove from map"].tap()
        XCTAssertFalse(treeMarker.waitForExistence(timeout: 15))
    }
}
