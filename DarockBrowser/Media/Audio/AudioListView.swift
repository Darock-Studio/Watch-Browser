//
//  AudioListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 7/8/24.
//

import SwiftUI
import DarockFoundation

struct AudioListView: View {
    @AppStorage("MPIsShowTranslatedLyrics") var isShowTranslatedLyrics = true
    @State var willDownloadAudioLink = ""
    @State var downloadFileName: String?
    @State var isAudioDownloadPresented = false
    @State var addPlaylistUrl = ""
    @State var isAddToPlaylistPresented = false
    var body: some View {
        if !audioLinkLists.isEmpty {
            List {
                ForEach(0..<audioLinkLists.count, id: \.self) { i in
                    Button(action: {
                        setForAudioPlaying()
                        playAudio(url: audioLinkLists[i])
                    }, label: {
                        Text(audioLinkLists[i])
                    })
                    .swipeActions {
                        Button(action: {
                            willDownloadAudioLink = audioLinkLists[i]
                            if audioLinkLists[i].contains(/music\..*\.com/) && audioLinkLists[i].contains(/(\?|&)id=[0-9]*\.mp3($|&)/),
                               let mid = audioLinkLists[i].split(separator: "id=")[from: 1]?.split(separator: ".mp3").first {
                                downloadFileName = "\(mid).mp3"
                                requestJSON("https://music.\(0b10100011).com/api/song/detail/?id=\(mid)&ids=%5B\(mid)%5D".compatibleUrlEncoded()) { respJson, isSuccess in
                                    if isSuccess {
                                        if let audioName = respJson["songs"][0]["name"].string {
                                            var nameChart = (
                                                UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]
                                            ) ?? [String: String]()
                                            nameChart.updateValue(audioName, forKey: "\(mid).mp3")
                                            UserDefaults.standard.set(nameChart, forKey: "AudioHumanNameChart")
                                        }
                                    }
                                }
                                requestJSON("https://music.\(0b10100011).com/api/song/lyric?id=\(mid)&lv=1&kv=1&tv=-1".compatibleUrlEncoded()) { respJson, isSuccess in
                                    if isSuccess {
                                        var lyrics = [Double: String]()
                                        if let lyric = respJson["lrc"]["lyric"].string {
                                            let lineSpd = lyric.components(separatedBy: "\n")
                                            for lineText in lineSpd {
                                                // swiftlint:disable:next for_where
                                                if lineText.contains(/\[[0-9]*:[0-9]*.[0-9]*\].*/) {
                                                    if let text = lineText.components(separatedBy: "]")[from: 1],
                                                       let time = lineText.components(separatedBy: "[")[from: 1]?.components(separatedBy: "]")[from: 0],
                                                       let dTime = lyricTimeStringToSeconds(String(time)) {
                                                        lyrics.updateValue(String(text).removePrefix(" "), forKey: dTime)
                                                    }
                                                }
                                            }
                                            if isShowTranslatedLyrics {
                                                if let tlyric = respJson["tlyric"]["lyric"].string {
                                                    let lineSpd = tlyric.components(separatedBy: "\n")
                                                    for lineText in lineSpd {
                                                        // swiftlint:disable:next for_where
                                                        if lineText.contains(/\[[0-9]*:[0-9]*.[0-9]*\].*/) {
                                                            if let text = lineText.components(separatedBy: "]")[from: 1],
                                                               let time = lineText.components(separatedBy: "[")[from: 1]?
                                                                .components(separatedBy: "]")[from: 0],
                                                               let dTime = lyricTimeStringToSeconds(String(time)),
                                                               let sourceLyric = lyrics[dTime],
                                                               !sourceLyric.isEmpty && !text.isEmpty {
                                                                lyrics.updateValue("\(sourceLyric)%tranlyric@\(text.removePrefix(" "))", forKey: dTime)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            do {
                                                if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/OfflineLyrics") {
                                                    try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/OfflineLyrics",
                                                                                            withIntermediateDirectories: false)
                                                }
                                                if let jsonStr = jsonString(from: lyrics) {
                                                    try jsonStr.write(
                                                        toFile: NSHomeDirectory() + "/Documents/OfflineLyrics/\(mid).drkdatal",
                                                        atomically: true,
                                                        encoding: .utf8
                                                    )
                                                }
                                            } catch {
                                                globalErrorHandler(error)
                                            }
                                        }
                                    }
                                }
                            } else {
                                downloadFileName = "\(audioLinkLists[i].split(separator: "/").last!.split(separator: ".mp3")[0]).mp3"
                            }
                            isAudioDownloadPresented = true
                        }, label: {
                            Image(systemName: "square.and.arrow.down")
                        })
                        Button(action: {
                            addPlaylistUrl = audioLinkLists[i]
                            isAddToPlaylistPresented = true
                        }, label: {
                            Image(systemName: "text.badge.plus")
                        })
                    }
                }
            }
            .navigationTitle("音频列表")
            .sheet(isPresented: $isAudioDownloadPresented) {
                MediaDownloadView(mediaLink: $willDownloadAudioLink, mediaTypeName: "音频", saveFolderName: "DownloadedAudios", saveFileName: $downloadFileName)
            }
            .sheet(isPresented: $isAddToPlaylistPresented) {
                NavigationStack {
                    PlaylistsView { fileName in
                        do {
                            let sourceStr = try String(contentsOfFile: NSHomeDirectory() + "/Documents/Playlists/\(fileName)", encoding: .utf8)
                            if var sourceData = getJsonData([String].self, from: sourceStr) {
                                sourceData.append(addPlaylistUrl)
                                if let newStr = jsonString(from: sourceData) {
                                    try newStr.write(toFile: NSHomeDirectory() + "/Documents/Playlists/\(fileName)", atomically: true, encoding: .utf8)
                                    if addPlaylistUrl.contains(/music\..*\.com/) && addPlaylistUrl.contains(/(\?|&)id=[0-9]*\.mp3($|&)/),
                                       let mid = addPlaylistUrl.split(separator: "id=")[from: 1]?.split(separator: ".mp3").first {
                                        requestJSON("https://music.\(0b10100011).com/api/song/detail/?id=\(mid)&ids=%5B\(mid)%5D".compatibleUrlEncoded()) { respJson, isSuccess in
                                            if isSuccess {
                                                if let audioName = respJson["songs"][0]["name"].string {
                                                    var nameChart = (
                                                        UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]
                                                    ) ?? [String: String]()
                                                    nameChart.updateValue(audioName, forKey: "\(mid).mp3")
                                                    UserDefaults.standard.set(nameChart, forKey: "AudioHumanNameChart")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } catch {
                            globalErrorHandler(error)
                        }
                    }
                }
            }
        } else {
            Text("空音频列表")
        }
    }
}
