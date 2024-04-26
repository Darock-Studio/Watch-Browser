//
//  WatchBrowserApp.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//

import SwiftUI
import WatchKit

var pShowTipText = ""
var pShowTipSymbol = ""
var pTipBoxOffset: CGFloat = 80

@main
struct WatchBrowser_Watch_AppApp: App {
    let device = WKInterfaceDevice.current()
    @AppStorage("ShouldTipNewFeatures") var shouldTipNewFeatures = true
    @State var showTipText = ""
    @State var showTipSymbol = ""
    @State var tipBoxOffset: CGFloat = 80
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .sheet(isPresented: $shouldTipNewFeatures, content: {NewFeaturesView()})
                VStack {
                    Spacer()
                    if #available(watchOS 10, *) {
                        HStack {
                            Image(systemName: showTipSymbol)
                            Text(showTipText)
                        }
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 110, height: 40)
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .offset(y: tipBoxOffset)
                        .animation(.easeOut(duration: 0.4), value: tipBoxOffset)
                    } else {
                        HStack {
                            Image(systemName: showTipSymbol)
                            Text(showTipText)
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 110, height: 40)
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .background {
                            Color.white
                                .ignoresSafeArea()
                                .frame(width: 120, height: 40)
                                .cornerRadius(8)
                                .foregroundColor(Color(hex: 0xF5F5F5))
                                .opacity(0.95)
                        }
                        .offset(y: tipBoxOffset)
                        .animation(.easeOut(duration: 0.4), value: tipBoxOffset)
                    }
                }
            }
        }
    }

}

public func tipWithText(_ text: String, symbol: String = "", time: Double = 3.0) {
    pShowTipText = text
    pShowTipSymbol = symbol
    pTipBoxOffset = 7
    Timer.scheduledTimer(withTimeInterval: time, repeats: false) { timer in
        pTipBoxOffset = 80
        timer.invalidate()
    }
}
