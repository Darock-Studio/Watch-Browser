//
//  ImageListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/5/2.
//

import SwiftUI
import Dynamic
import DarockKit
import SDWebImageSwiftUI

struct ImageListView: View {
    @AppStorage("IVUseDigitalCrownFor") var useDigitalCrownFor = "zoom"
    @State var isImageViewerPresented = false
    @State var tabSelection = 0
    var body: some View {
        if !imageLinkLists.isEmpty {
            List {
                ForEach(0..<imageLinkLists.count, id: \.self) { i in
                    Button(action: {
                        tabSelection = i
                        isImageViewerPresented = true
                    }, label: {
                        if let altText = imageAltTextLists[from: 1], !altText.isEmpty {
                            VStack(alignment: .leading) {
                                Text(imageAltTextLists[i])
                                Text(imageLinkLists[i])
                                    .font(.system(size: 14))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .foregroundStyle(Color.gray)
                            }
                        } else {
                            Text(imageLinkLists[i])
                        }
                    })
                }
            }
            .navigationTitle("图片列表 (\(imageLinkLists.count))")
            .sheet(isPresented: $isImageViewerPresented, content: {
                if useDigitalCrownFor == "zoom" {
                    TabView(selection: $tabSelection) {
                        ForEach(0..<imageLinkLists.count, id: \.self) { i in
                            ImageViewerView(url: imageLinkLists[i])
                                .tag(i)
                        }
                    }
                } else {
                    TabView(selection: $tabSelection) {
                        ForEach(0..<imageLinkLists.count, id: \.self) { i in
                            ImageViewerView(url: imageLinkLists[i])
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.carousel)
                }
            })
            .onDisappear {
                if dismissListsShouldRepresentWebView {
                    DispatchQueue.main.async {
                        Dynamic.UIApplication.sharedApplication.keyWindow.rootViewController.presentViewController(
                            AdvancedWebViewController.shared.vc,
                            animated: true,
                            completion: nil
                        )
                    }
                }
                if (UserDefaults.standard.object(forKey: "CCIsContinuityMediaEnabled") as? Bool) ?? true {
                    globalMediaUserActivity?.invalidate()
                }
            }
        } else {
            Text("空图片列表")
        }
    }
}

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
