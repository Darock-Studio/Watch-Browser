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
    var body: some View {
        Group {
            if useDigitalCrownFor == "zoom" {
                WebImage(url: URL(string: url), options: [.progressiveLoad], isAnimating: .constant(true))
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFit()
                    .frame(width: CGFloat(100), height: CGFloat(100), alignment: .center)
                    .modifier(Zoomable())
            } else {
                WebImage(url: URL(string: url), options: [.progressiveLoad], isAnimating: .constant(true))
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFit()
            }
        }
        .onAppear {
            if ((UserDefaults.standard.object(forKey: "CCIsContinuityMediaEnabled") as? Bool) ?? true)
                && (url.hasPrefix("http://") || url.hasPrefix("https://")) {
                globalMediaUserActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                globalMediaUserActivity?.isEligibleForHandoff = true
                globalMediaUserActivity?.webpageURL = URL(string: url)!
                globalMediaUserActivity?.becomeCurrent()
            }
        }
    }
}
