//
//  UserDefinedBackground.swift
//  WatchBrowser
//
//  Created by memz233 on 10/27/24.
//

import SwiftUI

@available(watchOS 10.0, *)
struct UserDefinedBackground: ViewModifier {
    @AppStorage("TQCIsOverrideAccentColor") var isOverrideAccentColor = false
    @AppStorage("TQCOverrideAccentColorRed") var overrideAccentColorRed = 0.0
    @AppStorage("TQCOverrideAccentColorGreen") var overrideAccentColorGreen = 0.0
    @AppStorage("TQCOverrideAccentColorBlue") var overrideAccentColorBlue = 0.0
    @AppStorage("TQCHomeBackgroundOverrideType") var overrideType = "color"
    @AppStorage("TQCIsHomeBackgroundImageBlured") var isBackgroundImageBlured = true
    @State var isLowPowerReducingBackground = false
    
    func body(content: Content) -> some View {
        Group {
            if overrideType == "image" && isOverrideAccentColor,
               let imageData = NSData(contentsOfFile: NSHomeDirectory() + "/Documents/CustomHomeBackground.drkdatac") as? Data,
               let image = UIImage(data: imageData) {
                content
                    .containerBackground(for: .navigation) {
                        if !isLowPowerReducingBackground {
                            ZStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: WKInterfaceDevice.current().screenBounds.width, height: WKInterfaceDevice.current().screenBounds.height)
                                    .blur(radius: isBackgroundImageBlured ? 20 : 0)
                                if isBackgroundImageBlured {
                                    Color.black
                                        .opacity(0.4)
                                }
                            }
                        }
                    }
            } else {
                content
                    .containerBackground(
                        !isLowPowerReducingBackground
                        ? (isOverrideAccentColor
                           ? Color(red: overrideAccentColorRed, green: overrideAccentColorGreen, blue: overrideAccentColorBlue).gradient
                           : Color(hex: 0x13A4FF).gradient)
                        : Color.black.gradient,
                        for: .navigation
                    )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { processInfo in
            if let processInfo = processInfo.object as? ProcessInfo {
                isLowPowerReducingBackground = processInfo.isLowPowerModeEnabled
            }
        }
    }
}
