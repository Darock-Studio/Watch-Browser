//
//  ScrollView+WithScrollOffset.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/26.
//

import SwiftUI

// rdar://af?650312
extension ScrollView {
    @ViewBuilder
    func withScrollOffsetUpdate() -> some View {
        ScrollView<ZStack> {
            ZStack {
                content
                GeometryReader { proxy in
                    Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: -proxy.frame(in: .named("scroll")).minY)
                }
            }
        }
        .coordinateSpace(name: "scroll")
    }
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
