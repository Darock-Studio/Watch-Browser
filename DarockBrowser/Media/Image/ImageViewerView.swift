//
//  ImageViewerView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI
import DarockUI
import SDWebImageSwiftUI

struct ImageViewerView: View {
    var url: String
    var useExternalControls: Bool = false
    @AppStorage("IVUseDigitalCrownFor") var useDigitalCrownFor = "zoom"
    @State var isFailedToLoad = false
    @State var isControlsHidden = false
    @State var controlsHiddenTimer: Timer?
    var body: some View {
        ZStack {
            if useDigitalCrownFor == "zoom" {
                WebImage(url: URL(string: url), options: [.progressiveLoad], isAnimating: .constant(true))
                    .resizable()
                    .onSuccess { _, _, _ in
                        DispatchQueue.main.async {
                            isFailedToLoad = false
                        }
                    }
                    .onFailure { _ in
                        DispatchQueue.main.async {
                            isFailedToLoad = true
                        }
                    }
                    .transition(.fade(duration: 0.5))
                    .scaledToFit()
                    .frame(width: CGFloat(100), height: CGFloat(100), alignment: .center)
                    .modifier(Zoomable())
            } else {
                WebImage(url: URL(string: url), options: [.progressiveLoad], isAnimating: .constant(true))
                    .resizable()
                    .onSuccess { _, _, _ in
                        DispatchQueue.main.async {
                            isFailedToLoad = false
                        }
                    }
                    .onFailure { _ in
                        DispatchQueue.main.async {
                            isFailedToLoad = true
                        }
                    }
                    .transition(.fade(duration: 0.5))
                    .scaledToFit()
            }
            if isFailedToLoad {
                Text("暗礁浏览器无法载入此图片")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .brightnessReducable()
        .onAppear {
            if ((UserDefaults.standard.object(forKey: "CCIsContinuityMediaEnabled") as? Bool) ?? true)
                && (url.hasPrefix("http://") || url.hasPrefix("https://")), let activityUrl = URL(string: url) {
                globalMediaUserActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                globalMediaUserActivity?.isEligibleForHandoff = true
                globalMediaUserActivity?.webpageURL = activityUrl
                globalMediaUserActivity?.becomeCurrent()
            }
        }
        .wrapIf(!useExternalControls) { content in
            content
                .onTapGesture {
                    resetControlsHiddenTimer()
                }
                .onAppear {
                    resetControlsHiddenTimer()
                }
                ._statusBarHidden(isControlsHidden)
                .toolbar(isControlsHidden ? .hidden : .visible)
        }
    }
    
    func resetControlsHiddenTimer() {
        isControlsHidden = false
        controlsHiddenTimer?.invalidate()
        controlsHiddenTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            isControlsHidden = true
        }
    }
}
