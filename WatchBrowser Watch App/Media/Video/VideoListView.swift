//
//  VideoListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/21.
//

import SwiftUI
import DarockKit

struct VideoListView: View {
    @State var willPlayVideoLink = ""
    @State var isPlayerPresented = false
    @State var willDownloadVideoLink = ""
    @State var downloadVideoSaveName: String?
    @State var isVideoDownloadPresented = false
    @State var shareVideoLink = ""
    @State var isSharePresented = false
    @State var cachedVideoLinkLists = [String]() // Resolve crash if global list changes after this view rendered
    var body: some View {
        if !cachedVideoLinkLists.isEmpty {
            List {
                ForEach(0..<cachedVideoLinkLists.count, id: \.self) { i in
                    Button(action: {
                        willPlayVideoLink = cachedVideoLinkLists[i]
                        isPlayerPresented = true
                    }, label: {
                        Text(cachedVideoLinkLists[i])
                    })
                    .swipeActions {
                        Button(action: {
                            willDownloadVideoLink = cachedVideoLinkLists[i]
                            isVideoDownloadPresented = true
                        }, label: {
                            Image(systemName: "square.and.arrow.down")
                        })
                        Button(action: {
                            do {
                                let linkFilePath = NSHomeDirectory() + "/Documents/SavedVideoLinks.drkdatas"
                                if !FileManager.default.fileExists(atPath: linkFilePath) {
                                    try jsonString(from: [String]())!.write(toFile: linkFilePath, atomically: true, encoding: .utf8)
                                }
                                if let fileStr = try? String(contentsOfFile: linkFilePath, encoding: .utf8),
                                   var links = getJsonData([String].self, from: fileStr) {
                                    links.append(cachedVideoLinkLists[i])
                                    try jsonString(from: links)!.write(toFile: linkFilePath, atomically: true, encoding: .utf8)
                                    tipWithText("已添加到列表", symbol: "checkmark.circle.fill")
                                }
                            } catch {
                                globalErrorHandler(error)
                            }
                        }, label: {
                            Image(systemName: "rectangle.stack.badge.plus")
                        })
                    }
                    .swipeActions(edge: .leading) {
                        Button(action: {
                            shareVideoLink = videoLinkLists[i]
                            isSharePresented = true
                        }, label: {
                            Image(systemName: "square.and.arrow.up")
                        })
                    }
                }
            }
            .navigationTitle("视频列表")
            .sheet(isPresented: $isPlayerPresented, content: { VideoPlayingView(link: $willPlayVideoLink) })
            .sheet(isPresented: $isSharePresented, content: { ShareView(linkToShare: $shareVideoLink) })
            .sheet(isPresented: $isVideoDownloadPresented) {
                MediaDownloadView(
                    mediaLink: $willDownloadVideoLink,
                    mediaTypeName: "视频",
                    saveFolderName: "DownloadedVideos",
                    saveFileName: $downloadVideoSaveName
                )
            }
            .onDisappear {
                if dismissListsShouldRepresentWebView {
                    safePresent(AdvancedWebViewController.shared.vc)
                }
            }
        } else {
            Text("空视频列表")
                .onAppear {
                    cachedVideoLinkLists = videoLinkLists
                }
        }
    }
}
