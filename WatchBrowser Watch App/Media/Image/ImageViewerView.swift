//
//  ImageViewerView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI
import DarockKit
import SDWebImageSwiftUI

struct ImageViewerView: View {
    var url: String
    @AppStorage("IVUseDigitalCrownFor") var useDigitalCrownFor = "zoom"
    @State var isFailedToLoad = false
    var body: some View {
        Group {
            if !isFailedToLoad {
                if useDigitalCrownFor == "zoom" {
                    WebImage(url: URL(string: url), options: [.progressiveLoad], isAnimating: .constant(true))
                        .resizable()
                        .onFailure { _ in
                            isFailedToLoad = true
                        }
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()
                        .frame(width: CGFloat(100), height: CGFloat(100), alignment: .center)
                        .modifier(Zoomable())
                } else {
                    WebImage(url: URL(string: url), options: [.progressiveLoad], isAnimating: .constant(true))
                        .resizable()
                        .onFailure { _ in
                            isFailedToLoad = true
                        }
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()
                }
            } else {
                Text("暗礁浏览器无法载入此图片")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        ._statusBarHidden(true)
        .onAppear {
            if ((UserDefaults.standard.object(forKey: "CCIsContinuityMediaEnabled") as? Bool) ?? true)
                && (url.hasPrefix("http://") || url.hasPrefix("https://")), let activityUrl = URL(string: url) {
                globalMediaUserActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                globalMediaUserActivity?.isEligibleForHandoff = true
                globalMediaUserActivity?.webpageURL = activityUrl
                globalMediaUserActivity?.becomeCurrent()
            }
        }
    }
}
