//
//  DarockBrowserUITests.swift
//  DarockBrowserUITests
//
//  Created by memz233 on 2024/6/8.
//

import XCTest

final class DarockBrowserUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAppMain() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        if _slowPath(app.textViews["NewFeaturesTitle"].exists) {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        // Main Page
        app.navigationBars.buttons["MainSettingsButton"].firstMatch.tap()
        // Settings View
        app.swipeUp()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        // Main Page
        // Search Test
        app.buttons["MainSearchButton"].tap()
        sleep(2)
        app.buttons["WebMenuButton"].tap()
        sleep(1)
        app.swipeUp()
        app.buttons["WebViewDismissButton"].tap()
        sleep(3)
        // Main Page
        XCTAssertTrue(app.buttons["MainSearchButton"].exists, "WebView not dismiss after tap dismiss button in web menu.")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
                XCUIApplication().launch()
            }
        }
    }
}
