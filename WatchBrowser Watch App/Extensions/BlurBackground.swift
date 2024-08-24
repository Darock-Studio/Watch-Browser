//
//  BlurBackground.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct BlurBackground: ViewModifier {
    var imageUrl: URL?
    @State private var backgroundPicOpacity: CGFloat = 0.0
    func body(content: Content) -> some View {
        if #available(watchOS 10, *) {
            content
                .containerBackground(for: .navigation) {
                    if let imageUrl {
                        ZStack {
                            WebImage(url: imageUrl)
                                .onSuccess { _, _, _ in
                                    backgroundPicOpacity = 1.0
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(width: WKInterfaceDevice.current().screenBounds.width, height: WKInterfaceDevice.current().screenBounds.height)
                                .blur(radius: 20)
                                .opacity(backgroundPicOpacity)
                                .animation(.easeOut(duration: 1.2), value: backgroundPicOpacity)
                            Color.black
                                .opacity(0.4)
                        }
                    }
                }
        } else {
            content
        }
    }
}
