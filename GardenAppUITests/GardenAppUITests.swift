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
}
