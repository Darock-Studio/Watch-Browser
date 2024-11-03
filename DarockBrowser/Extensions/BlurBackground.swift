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
    var meshGradientForUnavailable: Any?
    @State private var backgroundPicOpacity: CGFloat = 0.0
    @State private var isFailedToLoadImage = false
    
    init(imageUrl: URL? = nil) {
        self.imageUrl = imageUrl
    }
    #if compiler(>=6)
    @available(watchOS 11.0, *)
    init(imageUrl: URL? = nil, meshForUnavailable: Mesh) {
        self.imageUrl = imageUrl
        self.meshGradientForUnavailable = switch meshForUnavailable {
        case .none: nil
        case .autoGradient:
            MeshGradient(width: 3, height: 3, points: [
                .init(0, 0), .init(0.5, 0), .init(1, 0),
                .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                .init(0, 1), .init(0.5, 1), .init(1, 1)
            ], colors: [
                .red, .purple, .indigo,
                .orange, .white, .blue,
                .yellow, .green, .mint
            ])
        case .spicificedGradient(let meshGradient): meshGradient
        }
    }
    #endif
    
    func body(content: Content) -> some View {
        if #available(watchOS 10, *) {
            content
                .containerBackground(for: .navigation) {
                    if let imageUrl {
                        ZStack {
                            Group {
                                if !isFailedToLoadImage {
                                    WebImage(url: imageUrl)
                                        .onSuccess { _, _, _ in
                                            backgroundPicOpacity = 1.0
                                        }
                                        .onFailure { _ in
                                            isFailedToLoadImage = true
                                            backgroundPicOpacity = 1.0
                                        }
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    #if compiler(>=6)
                                    if #available(watchOS 11.0, *), let gradient = meshGradientForUnavailable as? MeshGradient {
                                        gradient
                                    }
                                    #endif
                                }
                            }
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
    
    #if compiler(>=6)
    @available(watchOS 11.0, *)
    enum Mesh {
        case none
        case autoGradient
        case spicificedGradient(MeshGradient)
    }
    #endif
}
