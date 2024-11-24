//
//  MediaMainView.swift
//  DarockBrowser
//
//  Created by memz233 on 11/16/24.
//

import SwiftUI
import DarockKit

struct MediaMainView: View {
    @State var hasDownloadedVideo = false
    @State var hasDownloadedAudio = false
    @State var hasLocalImage = false
    @State var isOfflineBooksAvailable = false
    @State var isAudioControllerAvailable = false
    var body: some View {
        List {
            if isAudioControllerAvailable {
                Section {
                    Button(action: {
                        pShouldPresentAudioController = true
                    }, label: {
                        HStack {
                            Spacer()
                            AudioVisualizerView()
                            Text("播放中")
                            Spacer()
                        }
                    })
                }
            }
            Section {
                NavigationLink(destination: { PlaylistsView() }, label: {
                    Label("播放列表", systemImage: "music.note.list")
                        .centerAligned()
                })
            }
            Section {
                if hasDownloadedAudio {
                    NavigationLink(destination: { LocalAudiosView() }, label: {
                        Label("音频", systemImage: "music.quarternote.3")
                            .centerAligned()
                    })
                }
                if isOfflineBooksAvailable {
                    NavigationLink(destination: { LocalBooksView() }, label: {
                        Label("图书", systemImage: "book.pages")
                            .centerAligned()
                    })
                }
                if hasLocalImage {
                    NavigationLink(destination: { LocalImageView() }, label: {
                        Label("图片", systemImage: "photo.stack")
                            .centerAligned()
                    })
                }
                if hasDownloadedVideo {
                    NavigationLink(destination: { LocalVideosView() }, label: {
                        Label("视频", systemImage: "play.square")
                            .centerAligned()
                    })
                }
            } header: {
                Text("本地")
            }
        }
        .navigationTitle({ if #available(watchOS 10.0, *) { true } else { false } }() ? String(localized: "媒体起始页") : String(localized: "媒体"))
        .navigationBarTitleDisplayMode(.large)
        .wrapIf({ if #available(watchOS 10.0, *) { true } else { false } }()) { content in
            if #available(watchOS 10.0, *) {
                content
                    .modifier(UserDefinedBackground())
            }
        }
        .onAppear {
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos") {
                    hasDownloadedVideo = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos").isEmpty
                }
            } catch {
                globalErrorHandler(error)
            }
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios") {
                    hasDownloadedAudio = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios").isEmpty
                }
            } catch {
                globalErrorHandler(error)
            }
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/LocalImages") {
                    hasLocalImage = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/LocalImages").isEmpty
                }
            } catch {
                globalErrorHandler(error)
            }
            isOfflineBooksAvailable = !(UserDefaults.standard.stringArray(forKey: "EPUBFlieFolders") ?? [String]()).isEmpty
            isAudioControllerAvailable = pIsAudioControllerAvailable
        }
    }
}
