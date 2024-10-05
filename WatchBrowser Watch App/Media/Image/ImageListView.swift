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
    @State var isMultiSelecting = false
    @State var selectedIndexs = [Int]()
    var body: some View {
        if !imageLinkLists.isEmpty {
            List {
                ForEach(0..<imageLinkLists.count, id: \.self) { i in
                    Button(action: {
                        if !isMultiSelecting {
                            tabSelection = i
                            isImageViewerPresented = true
                        } else {
                            if selectedIndexs.contains(i) {
                                selectedIndexs.removeAll(where: { $0 == i })
                            } else {
                                selectedIndexs.append(i)
                            }
                        }
                    }, label: {
                        HStack {
                            if isMultiSelecting {
                                Image(systemName: selectedIndexs.contains(i) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(.accent)
                            }
                            if let altText = imageAltTextLists[from: 1], !altText.isEmpty {
                                VStack(alignment: .leading) {
                                    Text(imageAltTextLists[i])
                                    Text(imageLinkLists[i])
                                        .font(.system(size: 14))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .foregroundStyle(.gray)
                                }
                            } else {
                                Text(imageLinkLists[i])
                            }
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
            .toolbar {
                if #available(watchOS 10.5, *), imageLinkLists.count > 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            if isMultiSelecting {
                                selectedIndexs.removeAll()
                            }
                            isMultiSelecting.toggle()
                        }, label: {
                            Image(systemName: isMultiSelecting ? "square.3.layers.3d.down.right.slash" : "square.3.layers.3d.down.right")
                                .contentTransition(.symbolEffect(.replace))
                        })
                    }
                    if isMultiSelecting && !selectedIndexs.isEmpty {
                        ToolbarItemGroup(placement: .bottomBar) {
                            Spacer()
                            Spacer()
                            Button(action: {
                                let baseTimeInterval = Date.now.timeIntervalSince1970
                                for index in selectedIndexs {
                                    let destination: DownloadRequest.Destination = { _, _ in
                                        return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/LocalImages/\(baseTimeInterval + Double(index) / 10).png"),
                                                [.removePreviousFile, .createIntermediateDirectories])
                                    }
                                    AF.download(imageLinkLists[index], to: destination)
                                        .response { result in
                                            if result.error == nil, let filePath = result.fileURL?.path {
                                                debugPrint(filePath)
                                            }
                                        }
                                }
                                tipWithText("正在批量下载 \(selectedIndexs.count) 张图片", symbol: "checkmark.circle.fill")
                                isMultiSelecting = false
                                selectedIndexs.removeAll()
                            }, label: {
                                Image(systemName: "square.and.arrow.down")
                            })
                        }
                    }
                }
            }
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
