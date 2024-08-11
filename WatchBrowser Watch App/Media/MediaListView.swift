//
//  LocalMediaView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 7/13/24.
//

import SwiftUI

struct MediaListView: View {
    @State var isHaveDownloadedVideo = false
    @State var isHaveDownloadedAudio = false
    @State var isHaveLocalImage = false
    @State var isOfflineBooksAvailable = false
    var body: some View {
        List {
            Section {
                if isHaveDownloadedAudio {
                    NavigationLink(destination: { LocalAudiosView() }, label: {
                        Label("音频", systemImage: "music.quarternote.3")
                    })
                }
                if isOfflineBooksAvailable {
                    NavigationLink(destination: { LocalBooksView() }, label: {
                        Label("图书", systemImage: "book.pages")
                    })
                }
                if isHaveLocalImage {
                    NavigationLink(destination: { LocalImageView() }, label: {
                        Label("图片", systemImage: "photo.stack")
                    })
                }
                if isHaveDownloadedVideo {
                    NavigationLink(destination: { LocalVideosView() }, label: {
                        Label("视频", systemImage: "play.square")
                    })
                }
            }
        }
        .navigationTitle("媒体列表")
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
