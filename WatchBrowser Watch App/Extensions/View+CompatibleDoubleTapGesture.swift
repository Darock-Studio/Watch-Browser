//
//  View+CompatibleDoubleTapGesture.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/27.
//

import SwiftUI

extension View {
    @ViewBuilder
    func compatibleDoubleTapGesture(followsUserSetting: Bool = true) -> some View {
        #if compiler(>=6)
        if !followsUserSetting || UserDefaults.standard.bool(forKey: "GSIsDoubleTapEnabled") {
            if #available(watchOS 11.0, *), WKInterfaceDevice.supportsDoubleTapGesture {
                handGestureShortcut(.primaryAction)
            } else {
                accessibilityQuickAction(style: .prompt) {
                    self
                }
            }
        } else {
            self
        }
        #else
        self
        #endif
    }
}

extension WKInterfaceDevice {
    static let supportsDoubleTapGesture: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        let modelID = WKInterfaceDevice.modelIdentifier
        let supportedIDs = ["Watch7,1", "Watch7,2", "Watch7,3", "Watch7,4", "Watch7,5"]
        return supportedIDs.contains(modelID)
        #endif
    }()
}
