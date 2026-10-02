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

    /// Drags the stick toward an idle opponent and taps Light: they take damage.
    func testTouchControlsLandBlows() {
        let app = XCUIApplication()
        app.launchEnvironment["AETHERIA_START"] = "spar:marcus_varro:gaius:forum"
        app.launch()
        let fight = app.otherElements["fight"]
        XCTAssertTrue(fight.waitForExistence(timeout: 10))
        sleep(4) // round intro
        let window = app.windows.firstMatch
        // Hold the stick to the right for a second and a half.
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.75))
        let right = window.coordinate(withNormalizedOffset: CGVector(dx: 0.28, dy: 0.75))
        start.press(forDuration: 0.05, thenDragTo: right, withVelocity: .fast, thenHoldForDuration: 1.6)
        // Light sits low on the right.
        let light = window.coordinate(withNormalizedOffset: CGVector(dx: 0.83, dy: 0.86))
        for _ in 0..<8 { light.tap() }
        sleep(1)
        let value = (fight.value as? String) ?? ""
        snapshot(app, "09-touch")
        XCTAssertTrue(value.contains("Gaius Aurelius") && !value.contains("Gaius Aurelius 100 percent"), "opponent took no damage: \(value)")
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
