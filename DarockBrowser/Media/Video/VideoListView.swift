//
//  VideoListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/21.
//

import SwiftUI
import DarockFoundation

struct VideoListView: View {
    var links: [String]
    @State var willPlayVideoLink = ""
    @State var isPlayerPresented = false
    @State var willDownloadVideoLink = ""
    @State var downloadVideoSaveName: String?
    @State var isVideoDownloadPresented = false
    @State var shareVideoLink = ""
    @State var isSharePresented = false
    
    init(links: [String]? = nil) {
        self.links = links ?? videoLinkLists
    }
    
    var body: some View {
        if !links.isEmpty {
            List {
                ForEach(0..<links.count, id: \.self) { i in
                    Button(action: {
                        willPlayVideoLink = links[i]
                        isPlayerPresented = true
                    }, label: {
                        Text(links[i])
                            .lineLimit(3)
                            .truncationMode(.middle)
                    })
                    .swipeActions {
                        Button(action: {
                            willDownloadVideoLink = links[i]
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
                                    links.append(self.links[i])
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
        } else {
            Text("空视频列表")
        }
    }
}
