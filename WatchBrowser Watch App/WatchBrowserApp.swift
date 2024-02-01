//
//  WatchBrowserApp.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//

import SwiftUI
import WatchKit

@main
struct WatchBrowser_Watch_AppApp: App {
    let device = WKInterfaceDevice.current()
    @AppStorage("first_run") public var first_run = false
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
//    if first_run {
//        
//    }
}
