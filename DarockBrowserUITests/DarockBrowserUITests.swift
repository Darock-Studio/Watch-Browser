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

        if app.staticTexts["NewFeaturesTitle"].exists {
            print(app.debugDescription)
            app.navigationBars.buttons["close-sheet"].firstMatch.tap()
        }
        // Main Page
        app.navigationBars.buttons["gear"].firstMatch.tap()
        // Settings View
        app.swipeUp()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        // Main Page
        // Search Test
        app.buttons["MainSearchButton"].tap()
        sleep(2)
        app.buttons["WebMenuButton"].tap()
        sleep(1)
        let dismissButton = app.buttons["WebViewDismissButton"]
        app.scrollToElement(element: dismissButton)
        dismissButton.tap()
        sleep(3)
        // Main Page
        XCTAssertTrue(app.buttons["MainSearchButton"].exists, "WebView not dismiss after tap dismiss button in web menu.")
    }
}

extension XCUIElement {
    func scrollToElement(element: XCUIElement) {
        while !element.visible() {
            swipeUp()
        }
    }
    
    func visible() -> Bool {
        guard self.exists && !self.frame.isEmpty else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
    }
}
