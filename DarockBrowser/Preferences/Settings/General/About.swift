//
//  About.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI
import DarockFoundation
import TripleQuestionmarkCore

extension SettingsView.GeneralSettingsView {
    struct AboutView: View {
        @AppStorage("IsProPurchased") var isProPurchased = false
        @State var songCount = 0
        @State var videoCount = 0
        @State var photoCount = 0
        @State var bookCount = 0
        var body: some View {
            List {
                Section {
                    HStack {
                        Text("App 版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("构建版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)
                            .foregroundColor(.gray)
                    }
                    if isAppBetaBuild {
                        HStack {
                            Text("Beta 构建")
                            Spacer()
                            Text("是")
                                .foregroundColor(.gray)
                        }
                    }
                    HStack {
                        Text("功能")
                        Spacer()
                        Text(isProPurchased ? "Pro" : "标准")
                            .foregroundColor(.gray)
                    }
                }
                Section {
                    HStack {
                        Text("音乐")
                        Spacer()
                        Text(String(songCount))
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("视频")
                        Spacer()
                        Text(String(videoCount))
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("图片")
                        Spacer()
                        Text(String(photoCount))
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("图书")
                        Spacer()
                        Text(String(bookCount))
                            .foregroundColor(.gray)
                    }
                    if #available(watchOS 10, *) {
                        TQCAccentColorHiddenButton {
                            requestAPI("/analyze/add/DBTQCAccentColor/\(Date.now.timeIntervalSince1970)") { _, _ in }
                        }
                    }
                }
            }
            .navigationTitle("关于")
            .onAppear {
                do {
                    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/") {
                        songCount = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/").count
                    }
                    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/") {
                        videoCount = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/").count
                    }
                    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/LocalImages/") {
                        photoCount = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/LocalImages/").count
                    }
                    let allDocumentFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents")
                    bookCount = 0
                    for file in allDocumentFiles where file.hasPrefix("EPUB") {
                        bookCount++
                    }
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
    }
}
