//
//  ImageListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/5/2.
//

import SwiftUI
import Alamofire

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
                    .swipeActions {
                        Button(action: {
                            let destination: DownloadRequest.Destination = { _, _ in
                                return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/LocalImages/\(Date.now.timeIntervalSince1970).png"),
                                        [.removePreviousFile, .createIntermediateDirectories])
                            }
                            AF.download(imageLinkLists[i], to: destination)
                                .response { result in
                                    if result.error == nil, let filePath = result.fileURL?.path {
                                        debugPrint(filePath)
                                        tipWithText("图片已保存", symbol: "checkmark.circle.fill")
                                    } else {
                                        tipWithText("保存图片时出错", symbol: "xmark.circle.fill")
                                    }
                                }
                        }, label: {
                            Image(systemName: "square.and.arrow.down")
                        })
                    }
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
                    safePresent(AdvancedWebViewController.shared.vc)
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
