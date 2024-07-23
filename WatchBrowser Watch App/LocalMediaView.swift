//
//  LocalMediaView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 7/13/24.
//

import SwiftUI

struct LocalMediaView: View {
    @State var isHaveDownloadedVideo = false
    @State var isHaveDownloadedAudio = false
    @State var isHaveLocalImage = false
    @State var isOfflineBooksAvailable = false
    var body: some View {
        List {
            Section {
                if isHaveDownloadedAudio {
                    NavigationLink(destination: { LocalAudiosView() }, label: {
                        Label("本地音频", systemImage: "music.quarternote.3")
                    })
                }
                if isOfflineBooksAvailable {
                    NavigationLink(destination: { LocalBooksView() }, label: {
                        Label("本地图书", systemImage: "book.pages")
                    })
                }
                if isHaveLocalImage {
                    NavigationLink(destination: { LocalImageView() }, label: {
                        Label("本地图片", systemImage: "photo.stack")
                    })
                }
                if isHaveDownloadedVideo {
                    NavigationLink(destination: { LocalVideosView() }, label: {
                        Label("本地视频", systemImage: "tray.and.arrow.down")
                    })
                }
            }
        }
        .navigationTitle("本地媒体")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos") {
                    isHaveDownloadedVideo = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos").isEmpty
                }
            } catch {
                globalErrorHandler(error)
            }
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios") {
                    isHaveDownloadedAudio = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios").isEmpty
                }
            } catch {
                globalErrorHandler(error)
            }
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/LocalImages") {
                    isHaveLocalImage = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/LocalImages").isEmpty
                }
            } catch {
                globalErrorHandler(error)
            }
            isOfflineBooksAvailable = !(UserDefaults.standard.stringArray(forKey: "EPUBFlieFolders") ?? [String]()).isEmpty
        }
    }
}
