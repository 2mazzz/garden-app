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
}
