import XCTest

/// Walks the menus into a fight and keeps screenshots of each stop, which
/// double as App Store screenshot sources (see docs/RELEASE.md).
final class AetheriaClashUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testMenusIntoAFight() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetProfile"]
        app.launch()
        snapshot(app, "01-title")
        app.tap()

        // The first launch shows how to play.
        let toBattle = app.buttons["Next"]
        XCTAssertTrue(toBattle.waitForExistence(timeout: 5))
        for _ in 0..<4 { app.buttons["Next"].tap() }
        app.buttons["To Battle"].tap()

        XCTAssertTrue(app.buttons["Versus CPU"].waitForExistence(timeout: 5))
        snapshot(app, "02-menu")
        app.buttons["Versus CPU"].tap()

        XCTAssertTrue(app.buttons["Choose"].waitForExistence(timeout: 5))
        snapshot(app, "03-select")
        app.buttons["Choose"].tap()
        XCTAssertTrue(app.buttons["Fight"].waitForExistence(timeout: 5))
        app.buttons["Fight"].tap()

        XCTAssertTrue(app.buttons["Fight Here"].waitForExistence(timeout: 5))
        snapshot(app, "04-stage")
        app.buttons["Fight Here"].tap()

        // The face-off plays, then the fight begins.
        sleep(2)
        snapshot(app, "05-versus")
        sleep(6)
        snapshot(app, "06-fight")
    }

    func testFightRunsAndPauses() {
        let app = XCUIApplication()
        app.launchEnvironment["AETHERIA_START"] = "fight:livia:bardiya:forum"
        app.launch()
        sleep(5)
        snapshot(app, "07-fight-forum")
        // The pause button sits at the top centre.
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        sleep(1)
        if app.buttons["Resume"].exists {
            snapshot(app, "08-pause")
            app.buttons["Resume"].tap()
        }
        XCTAssertTrue(app.state == .runningForeground)
    }
}
