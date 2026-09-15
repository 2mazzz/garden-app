import XCTest

/// Smoke test exercising the main navigation flows: entering the
/// greenhouse from the garden map, and switching between all three tabs.
final class GardenAppUITests: XCTestCase {
    func testGardenShowsGreenhouseAndTabsSwitch() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertTrue(tabBar.buttons["Garden"].exists)
        XCTAssertTrue(tabBar.buttons["Calendar"].exists)
        XCTAssertTrue(tabBar.buttons["Wiki"].exists)
        XCTAssertTrue(tabBar.buttons["Settings"].exists)

        // Garden tab is the home screen and shows the greenhouse structure.
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 5))
        let greenhouseButton = app.buttons["Greenhouse"]
        XCTAssertTrue(greenhouseButton.waitForExistence(timeout: 5))

        // Tapping it enters the greenhouse's own map, with a back button to Garden.
        greenhouseButton.tap()
        XCTAssertTrue(app.navigationBars["Greenhouse"].waitForExistence(timeout: 5))
        app.navigationBars["Greenhouse"].buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 5))

        // Calendar tab shows the month picker and at least one seeded task.
        tabBar.buttons["Calendar"].tap()
        XCTAssertTrue(app.navigationBars["Care Calendar"].waitForExistence(timeout: 5))

        // Wiki tab shows the Swedish starter catalog, grouped alphabetically
        // by category — "Flower" sorts first, so "Tulpan" is guaranteed to
        // be on-screen without scrolling (List only realizes visible rows).
        tabBar.buttons["Wiki"].tap()
        XCTAssertTrue(app.navigationBars["Plant Wiki"].waitForExistence(timeout: 5))
        let tulpanPredicate = NSPredicate(format: "label CONTAINS[c] %@", "Tulpan")
        let tulpanElement = app.descendants(matching: .any).matching(tulpanPredicate).firstMatch
        XCTAssertTrue(tulpanElement.waitForExistence(timeout: 5))
    }

    /// Exercises the direct-manipulation bed flow: create (no popup), drag
    /// to move, tap to open the compact edit menu, and delete.
    func testBedCreateDragEditDelete() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 5))

        // Creating a bed shows it immediately with no popup.
        app.navigationBars["Garden"].buttons["Add Bed"].tap()
        let bed = app.buttons["New bed"]
        XCTAssertTrue(bed.waitForExistence(timeout: 5))
        let originalFrame = bed.frame

        // Dragging the bed's body moves it (verified by its frame changing).
        let start = bed.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = bed.coordinate(withNormalizedOffset: CGVector(dx: 3.0, dy: 2.0))
        start.press(forDuration: 0.1, thenDragTo: end)

        let movedBed = app.buttons["New bed"]
        XCTAssertTrue(movedBed.waitForExistence(timeout: 5))
        XCTAssertNotEqual(movedBed.frame.origin.x, originalFrame.origin.x,
                           "Expected the bed's on-screen position to change after dragging it")

        // A plain tap (negligible movement) opens the compact edit menu, not a move.
        movedBed.tap()
        XCTAssertTrue(app.navigationBars["Edit Bed"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Delete bed"].waitForExistence(timeout: 2))

        app.buttons["Delete bed"].tap()
        XCTAssertFalse(app.buttons["New bed"].waitForExistence(timeout: 3))
    }

    /// Regression test: picking a bed from the general "Add Plant" sheet's
    /// picker used to leave the plant at the stepper default (0,0) instead
    /// of inside the chosen bed's rectangle — see AddPlantSheet's
    /// onChange(of: selectedBed).
    func testAddPlantViaBedPickerPositionsInsideBed() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 5))

        app.navigationBars["Garden"].buttons["Add Bed"].tap()
        let bed = app.buttons["New bed"]
        XCTAssertTrue(bed.waitForExistence(timeout: 5))
        let bedFrame = bed.frame

        app.navigationBars["Garden"].buttons["Add Plant"].tap()
        XCTAssertTrue(app.navigationBars["Place Plant"].waitForExistence(timeout: 5))

        // The Form's Picker rows present their options as a popover menu
        // (a CollectionView of buttons), not a pushed list — scope the
        // query to collectionViews so this doesn't collide with the
        // same-named bed/plant buttons already on the map underneath.
        app.buttons["Species, Choose one"].tap()
        let speciesOption = app.collectionViews.buttons["Potatis"]
        XCTAssertTrue(speciesOption.waitForExistence(timeout: 5))
        speciesOption.tap()

        app.buttons["Bed, None"].tap()
        let bedOption = app.collectionViews.buttons["New bed"]
        XCTAssertTrue(bedOption.waitForExistence(timeout: 5))
        bedOption.tap()

        app.buttons["Add"].tap()

        let plantMarker = app.buttons["Potatis"]
        XCTAssertTrue(plantMarker.waitForExistence(timeout: 5))
        XCTAssertTrue(
            bedFrame.insetBy(dx: -1, dy: -1).contains(plantMarker.frame.origin),
            "Expected the plant to be positioned inside the bed's rectangle, not the sheet's stepper default"
        )

        // Clean up so later tests in the suite don't see leftover data —
        // the persistent store survives across app launches.
        plantMarker.tap()
        XCTAssertTrue(app.buttons["Remove from map"].waitForExistence(timeout: 5))
        app.buttons["Remove from map"].tap()

        XCTAssertTrue(bed.waitForExistence(timeout: 5))
        bed.tap()
        XCTAssertTrue(app.navigationBars["Edit Bed"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Delete bed"].waitForExistence(timeout: 5))
        app.buttons["Delete bed"].tap()
        XCTAssertFalse(bed.waitForExistence(timeout: 3), "Expected the bed created by this test to be cleaned up")
    }

    /// Exercises adding a non-functional structure (a driveway), dragging
    /// it, editing it via the pencil icon (not the tap-to-navigate path,
    /// which only applies to linked structures like the greenhouse), and
    /// deleting it.
    func testAddStructureCanBeDraggedAndEdited() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Garden"].waitForExistence(timeout: 5))

        app.navigationBars["Garden"].buttons["Add Structure"].tap()
        XCTAssertTrue(app.navigationBars["Add Structure"].waitForExistence(timeout: 5))
        app.buttons["Driveway"].tap()
        app.buttons["Add"].tap()

        let driveway = app.buttons["Driveway"]
        XCTAssertTrue(driveway.waitForExistence(timeout: 5))
        let originalFrame = driveway.frame

        // Dragging the structure's body moves it — this used to be
        // impossible (structures had no gesture code at all).
        let start = driveway.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = driveway.coordinate(withNormalizedOffset: CGVector(dx: 3.0, dy: 2.0))
        start.press(forDuration: 0.1, thenDragTo: end)

        let movedDriveway = app.buttons["Driveway"]
        XCTAssertTrue(movedDriveway.waitForExistence(timeout: 5))
        XCTAssertNotEqual(movedDriveway.frame.origin.x, originalFrame.origin.x,
                           "Expected the structure's on-screen position to change after dragging it")

        // The pencil icon opens the edit sheet directly (a plain tap would
        // try to navigate for a linked structure, but a driveway has none).
        let editIcon = movedDriveway.images["Edit"]
        XCTAssertTrue(editIcon.waitForExistence(timeout: 5))
        editIcon.tap()
        XCTAssertTrue(app.navigationBars["Edit Structure"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Delete structure"].waitForExistence(timeout: 2))

        app.buttons["Delete structure"].tap()
        XCTAssertFalse(app.buttons["Driveway"].waitForExistence(timeout: 3))
    }
}
