//
//  View+BrightnessReducable.swift
//  WatchBrowser
//
//  Created by memz233 on 10/3/24.
//

import SwiftUI

extension View {
    func brightnessReducable() -> some View {
        self
            .modifier(BrightnessReducable())
    }
}

private struct BrightnessReducable: ViewModifier {
    @AppStorage("ABIsReduceBrightness") private var isReduceBrightness = false
    @AppStorage("ABReduceBrightnessLevel") private var reduceBrightnessLevel = 0.2
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if isReduceBrightness {
                Rectangle()
                    .fill(Color.black)
                    .opacity(reduceBrightnessLevel)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}
