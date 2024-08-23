//
//  AudioListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 7/8/24.
//

import SwiftUI
import Dynamic
import Combine
import DarockKit
import MediaPlayer
import AVFoundation
import SDWebImageSwiftUI

let globalAudioPlayer = AVPlayer()
var globalAudioLooper: Any?
var globalAudioCurrentPlaylist = ""
var nowPlayingAudioId = ""

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
                                DarockKit.Network.shared
                                    .requestJSON("https://music.\(0b10100011).com/api/song/detail/?id=\(mid)&ids=%5B\(mid)%5D".compatibleUrlEncoded()) { respJson, isSuccess in
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
                                DarockKit.Network.shared
                                    .requestJSON("https://music.\(0b10100011).com/api/song/lyric?id=\(mid)&lv=1&kv=1&tv=-1".compatibleUrlEncoded()) { respJson, isSuccess in
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
                                        DarockKit.Network.shared
                                            .requestJSON("https://music.\(0b10100011).com/api/song/detail/?id=\(mid)&ids=%5B\(mid)%5D".compatibleUrlEncoded()) { respJson, isSuccess in
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
            .onDisappear {
                if dismissListsShouldRepresentWebView {
                    safePresent(AdvancedWebViewController.shared.vc)
                }
            }
        } else {
            Text("空音频列表")
        }
    }
}

struct AudioControllerView: View {
    @AppStorage("MPIsShowTranslatedLyrics") var isShowTranslatedLyrics = true
    @Namespace var coverScaleNamespace
    @State var lyrics = [Double: String]()
    @State var isLyricsAvailable = true
    @State var currentPlaybackTime = globalAudioPlayer.currentTime().seconds
    @State var currentItemTotalTime = 0.0
    @State var currentScrolledId = 0.0
    @State var isShowingControls = false
    @State var isPlaying = false
    @State var isProgressDraging = false
    @State var progressDragingNewTime = 0.0
    @State var playbackBehavior = PlaybackBehavior.pause
    @State var controlMenuDismissTimer: Timer?
    @State var backgroundImageUrl: URL?
    @State var audioName = ""
    @State var audioHumanNameChart = [String: String]()
    @State var currentPlaylistContent = [String]()
    var body: some View {
        NavigationStack {
            TabView {
                ZStack {
                    if isLyricsAvailable {
                        if !lyrics.isEmpty {
                            ScrollViewReader { scrollProxy in
                                let lyricKeys = Array<Double>(lyrics.keys).sorted(by: { lhs, rhs in lhs < rhs })
                                ScrollView {
                                    VStack(alignment: .leading) {
                                        if let firstKey = lyricKeys.first {
                                            if firstKey >= 2.0 {
                                                WaitingDotView(startTime: 0.0, endTime: firstKey, currentTime: $currentPlaybackTime)
                                            }
                                        }
                                        if #available(watchOS 10, *) {
                                            lyricsMainView
                                                .scrollTransition { content, phase in
                                                    content
                                                        .scaleEffect(phase.isIdentity ? 1 : 0.98)
                                                        .opacity(phase.isIdentity ? 1 : 0.5)
                                                        .offset(y: phase == .bottomTrailing ? 10 : 0)
                                                }
                                        } else {
                                            lyricsMainView
                                        }
                                    }
                                }
                                .scrollIndicators(.never)
                                .onReceive(globalAudioPlayer.periodicTimePublisher()) { _ in
                                    var newScrollId = 0.0
                                    var isUpdatedScrollId = false
                                    for i in 0..<lyricKeys.count where currentPlaybackTime < lyricKeys[i] {
                                        if let newKey = lyricKeys[from: i - 1] {
                                            newScrollId = newKey
                                        } else {
                                            newScrollId = lyricKeys[i]
                                        }
                                        isUpdatedScrollId = true
                                        break
                                    }
                                    if _slowPath(!isUpdatedScrollId && !lyricKeys.isEmpty) {
                                        newScrollId = lyricKeys.last!
                                    }
                                    if _slowPath(newScrollId != currentScrolledId) {
                                        currentScrolledId = newScrollId
                                        debugPrint("Scrolling to \(newScrollId)")
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            scrollProxy.scrollTo(newScrollId, anchor: .init(x: 0.5, y: 0.25))
                                        }
                                    }
                                }
                            }
                        } else {
                            ProgressView()
                        }
                    } else {
                        Text("歌词不可用")
                            .offset(y: -20)
                    }
                    // Audio Controls
                    VStack {
                        Spacer()
                        VStack {
                            VStack {
                                ProgressView(value: isProgressDraging ? progressDragingNewTime : currentPlaybackTime, total: currentItemTotalTime)
                                    .progressViewStyle(.linear)
                                    .shadow(radius: isProgressDraging ? 2 : 0)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                isProgressDraging = true
                                                let newTime = currentPlaybackTime + value.translation.width
                                                if newTime >= 0 && newTime <= currentItemTotalTime {
                                                    progressDragingNewTime = newTime
                                                }
                                            }
                                            .onEnded { _ in
                                                globalAudioPlayer.seek(to: CMTime(seconds: progressDragingNewTime, preferredTimescale: 60000),
                                                                       toleranceBefore: .zero,
                                                                       toleranceAfter: .zero)
                                                isProgressDraging = false
                                            }
                                    )
                                    .frame(height: 20)
                                HStack {
                                    Text(formattedTime(from: currentPlaybackTime))
                                        .font(.system(size: 11))
                                        .opacity(0.6)
                                    Spacer()
                                    Text(formattedTime(from: currentItemTotalTime))
                                        .font(.system(size: 11))
                                        .opacity(0.6)
                                }
                                .padding(.vertical, -8)
                            }
                            .scaleEffect(isProgressDraging ? 1.05 : 1)
                            .padding(.horizontal, 5)
                            .animation(.easeOut(duration: 0.2), value: isProgressDraging)
                            HStack {
                                Button(action: {
                                    switch playbackBehavior {
                                    case .pause:
                                        playbackBehavior = .singleLoop
                                    case .singleLoop:
                                        if !currentPlaylistContent.isEmpty {
                                            playbackBehavior = .listLoop
                                        } else {
                                            playbackBehavior = .pause
                                        }
                                    case .listLoop:
                                        playbackBehavior = .singleLoop
                                    }
                                    UserDefaults.standard.set(playbackBehavior.rawValue, forKey: "MPPlaybackBehavior")
                                    resetMenuDismissTimer()
                                }, label: {
                                    Group {
                                        switch playbackBehavior {
                                        case .pause:
                                            Image(systemName: "pause.circle")
                                        case .singleLoop:
                                            Image(systemName: "repeat.1")
                                        case .listLoop:
                                            Image(systemName: "repeat")
                                        }
                                    }
                                    .font(.system(size: 20))
                                })
                                .buttonStyle(ControlButtonStyle())
                                .frame(width: 35, height: 35)
                                Spacer()
                                Button(action: {
                                    if isPlaying {
                                        globalAudioPlayer.pause()
                                    } else {
                                        globalAudioPlayer.play()
                                    }
                                    resetMenuDismissTimer()
                                }, label: {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 26))
                                })
                                .buttonStyle(ControlButtonStyle())
                                .frame(width: 40, height: 40)
                                Spacer()
                                VolumeControlView()
                                    .scaleEffect(0.7)
                                    .frame(width: 35, height: 35)
                            }
                            .padding(.horizontal, 5)
                        }
                        .background {
                            if #available(watchOS 10, *) {
                                Color.clear.background(Material.ultraThin)
                                    .opacity(0.8)
                                    .brightness(0.1)
                                    .saturation(2.5)
                                    .frame(width: WKInterfaceDevice.current().screenBounds.width + 100, height: 100)
                                    .blur(radius: 10)
                                    .offset(y: 20)
                            }
                        }
                        .opacity(isShowingControls || !isLyricsAvailable ? 1.0 : 0.0)
                        .offset(y: isShowingControls || !isLyricsAvailable ? 0 : 10)
                        .animation(.easeOut(duration: 0.2), value: isShowingControls)
                        .animation(.easeOut(duration: 0.2), value: isLyricsAvailable)
                    }
                    .ignoresSafeArea()
                }
                .navigationTitle(audioName)
                .onTapGesture { location in
                    if location.y > WKInterfaceDevice.current().screenBounds.height / 2 {
                        isShowingControls = true
                        resetMenuDismissTimer()
                    } else {
                        isShowingControls = false
                    }
                }
                .tag(1)
                // MARK: --- Tab View Divider ---
                List {
                    if !currentPlaylistContent.isEmpty {
                        Section {
                            ForEach(0..<currentPlaylistContent.count, id: \.self) { i in
                                Button(action: {
                                    playAudio(url: currentPlaylistContent[i], presentController: false)
                                }, label: {
                                    HStack {
                                        if let currentUrl = (globalAudioPlayer.currentItem?.asset as? AVURLAsset)?.url {
                                            if currentUrl.absoluteString == currentPlaylistContent[i].replacingOccurrences(
                                                of: "%DownloadedContent@=", with: "file://\(NSHomeDirectory())/Documents/DownloadedAudios/"
                                            ) {
                                                AudioVisualizerView()
                                            }
                                        }
                                        Text(audioHumanNameChart[
                                            String(currentPlaylistContent[i].split(separator: "/").last!.split(separator: "=").last!)
                                        ] ?? currentPlaylistContent[i])
                                    }
                                })
                            }
                        }
                    } else {
                        Text("不在播放列表")
                    }
                }
                .navigationTitle("播放列表")
            }
            .modifier(BlurBackground(imageUrl: backgroundImageUrl))
        }
        .onAppear {
            isPlaying = globalAudioPlayer.timeControlStatus == .playing
            currentItemTotalTime = globalAudioPlayer.currentItem?.duration.seconds ?? 0.0
            playbackBehavior = .init(rawValue: UserDefaults.standard.string(forKey: "MPPlaybackBehavior") ?? "pause") ?? .pause
            updateMetadata()
            isShowingControls = true
            resetMenuDismissTimer()
            resetGlobalAudioLooper()
            pIsAudioControllerAvailable = true
            extendScreenIdleTime(3600)
            audioHumanNameChart = (UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]) ?? [String: String]()
            if !globalAudioCurrentPlaylist.isEmpty
                && FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/Playlists/\(globalAudioCurrentPlaylist)") {
                do {
                    let fileStr = try String(contentsOfFile: NSHomeDirectory() + "/Documents/Playlists/\(globalAudioCurrentPlaylist)", encoding: .utf8)
                    currentPlaylistContent = getJsonData([String].self, from: fileStr) ?? [String]()
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
        .onDisappear {
            recoverNormalIdleTime()
        }
        .onReceive(globalAudioPlayer.publisher(for: \.timeControlStatus)) { status in
            isPlaying = status == .playing
            if status != .waitingToPlayAtSpecifiedRate {
                currentItemTotalTime = globalAudioPlayer.currentItem?.duration.seconds ?? 0.0
                debugPrint(currentItemTotalTime)
            }
        }
        .onReceive(globalAudioPlayer.publisher(for: \.currentItem)) { item in
            if let item {
                currentItemTotalTime = item.duration.seconds
                updateMetadata()
            }
        }
        .onReceive(globalAudioPlayer.periodicTimePublisher()) { time in
            // Code in this closure runs at nearly each frame, optimizing for speed is important.
            if time.seconds - currentPlaybackTime >= 0.3 || time.seconds < currentPlaybackTime {
                currentPlaybackTime = time.seconds
            }
        }
    }
    @ViewBuilder var lyricsMainView: some View {
        let lyricKeys = Array<Double>(lyrics.keys).sorted(by: { lhs, rhs in lhs < rhs })
        ForEach(0..<lyricKeys.count, id: \.self) { i in
            HStack {
                if !lyrics[lyricKeys[i]]!.isEmpty {
                    VStack(alignment: .leading) {
                        if lyrics[lyricKeys[i]]!.contains("%tranlyric@"),
                           let src = lyrics[lyricKeys[i]]!.components(separatedBy: "%tranlyric@")[from: 0],
                           let trans = lyrics[lyricKeys[i]]!.components(separatedBy: "%tranlyric@")[from: 1] {
                            Text(src)
                                .font(.system(size: 16, weight: .semibold))
                            Text(trans)
                                .font(.system(size: 14, weight: .medium))
                                .opacity(0.85)
                        } else {
                            Text(lyrics[lyricKeys[i]]!)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .opacity(currentScrolledId == lyricKeys[i] ? 1.0 : 0.6)
                } else {
                    if let endTime = lyricKeys[from: i &+ 1], endTime - lyricKeys[i] > 2.0 {
                        WaitingDotView(startTime: lyricKeys[i], endTime: endTime, currentTime: $currentPlaybackTime)
                    }
                }
                Spacer(minLength: 20)
            }
            .padding(.vertical, 5)
            .id(lyricKeys[i])
        }
    }
    
    func updateMetadata() {
        isLyricsAvailable = true
        lyrics.removeAll()
        if !nowPlayingAudioId.isEmpty {
            DarockKit.Network.shared
                .requestJSON("https://music.\(0b10100011).com/api/song/lyric?id=\(nowPlayingAudioId)&lv=1&kv=1&tv=-1".compatibleUrlEncoded()) { respJson, isSuccess in
                    if isSuccess {
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
                                               let time = lineText.components(separatedBy: "[")[from: 1]?.components(separatedBy: "]")[from: 0],
                                               let dTime = lyricTimeStringToSeconds(String(time)),
                                               let sourceLyric = lyrics[dTime],
                                               !sourceLyric.isEmpty && !text.isEmpty {
                                                lyrics.updateValue("\(sourceLyric)%tranlyric@\(text.removePrefix(" "))", forKey: dTime)
                                            }
                                        }
                                    }
                                }
                            }
                            if lyrics.isEmpty {
                                isLyricsAvailable = false
                            }
                        } else {
                            isLyricsAvailable = false
                        }
                    } else {
                        // Offline Lyrics
                        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/OfflineLyrics/\(nowPlayingAudioId).drkdatal") {
                            do {
                                let lrcFileStr = try String(
                                    contentsOfFile: NSHomeDirectory() + "/Documents/OfflineLyrics/\(nowPlayingAudioId).drkdatal",
                                    encoding: .utf8
                                )
                                if let lrcData = getJsonData([Double: String].self, from: lrcFileStr) {
                                    lyrics = lrcData
                                } else {
                                    isLyricsAvailable = false
                                }
                            } catch {
                                isLyricsAvailable = false
                                globalErrorHandler(error)
                            }
                        } else {
                            isLyricsAvailable = false
                        }
                    }
                }
            DarockKit.Network.shared
                .requestJSON("https://music.\(0b10100011).com/api/song/detail/?id=\(nowPlayingAudioId)&ids=%5B\(nowPlayingAudioId)%5D".compatibleUrlEncoded()) { respJson, isSuccess in
                    if isSuccess {
                        if let imageUrl = respJson["songs"][0]["album"]["picUrl"].string {
                            backgroundImageUrl = URL(string: imageUrl)
                        }
                        audioName = respJson["songs"][0]["name"].string ?? ""
                    }
                }
        } else {
            isLyricsAvailable = false
        }
    }
    
    struct WaitingDotView: View {
        var startTime: Double
        var endTime: Double
        @Binding var currentTime: Double
        @State var dot1Opacity = 0.2
        @State var dot2Opacity = 0.2
        @State var dot3Opacity = 0.2
        @State var scale = CGFloat(1)
        var body: some View {
            HStack {
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.white)
                        .opacity(dot1Opacity)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.white)
                        .opacity(dot2Opacity)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.white)
                        .opacity(dot3Opacity)
                        .frame(width: 8, height: 8)
                }
                .padding()
                .scaleEffect(scale)
                Spacer(minLength: 5)
            }
            .opacity(currentTime >= startTime && currentTime <= endTime ? 1.0 : 0.0100000002421438702673861521)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                    if scale > 1.0 {
                        scale = 1.0
                    } else {
                        scale = 1.15
                    }
                }
            }
            .onChange(of: currentTime) { value in
                if value >= startTime && value <= endTime
                    && dot1Opacity == 0.2 && dot2Opacity == 0.2 && dot3Opacity == 0.2 {
                    if #available(watchOS 10, *) {
                        let pieceTime = (endTime - startTime - 1.0) / 3.0
                        withAnimation(.linear(duration: pieceTime)) {
                            dot1Opacity = 1.0
                        } completion: {
                            withAnimation(.linear(duration: pieceTime)) {
                                dot2Opacity = 1.0
                            } completion: {
                                withAnimation(.linear(duration: pieceTime)) {
                                    dot3Opacity = 1.0
                                } completion: {
                                    withAnimation(.easeInOut(duration: 0.6)) {
                                        scale = 1.3
                                    } completion: {
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            scale = 0.1
                                            dot1Opacity = 0.2
                                            dot2Opacity = 0.2
                                            dot3Opacity = 0.2
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        withAnimation(.linear(duration: endTime - startTime)) {
                            dot1Opacity = 1.0
                            dot2Opacity = 1.0
                            dot3Opacity = 1.0
                        }
                    }
                } else if value < startTime || value > endTime {
                    dot1Opacity = 0.2
                    dot2Opacity = 0.2
                    dot3Opacity = 0.2
                    scale = 1
                }
            }
        }
    }
    struct ControlButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            ZStack {
                Circle()
                    .fill(Color.gray)
                    .scaleEffect(configuration.isPressed ? 0.9 : 1)
                    .opacity(configuration.isPressed ? 0.4 : 0.0100000002421438702673861521)
                configuration.label
                    .scaleEffect(configuration.isPressed ? 0.9 : 1)
            }
        }
    }
    
    func resetMenuDismissTimer() {
        controlMenuDismissTimer?.invalidate()
        controlMenuDismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            if !isProgressDraging {
                isShowingControls = false
            } else {
                resetMenuDismissTimer()
            }
        }
    }
}

@_effects(readnone)
func lyricTimeStringToSeconds(_ timeString: String) -> Double? {
    let components = timeString.split(separator: ":")
    guard components.count == 2,
          let minutes = Double(components[0]),
          let seconds = Double(components[1]) else {
        return nil
    }
    return minutes * 60 + seconds
}
@_effects(readnone)
func formattedTime(from seconds: Double) -> String {
    if seconds.isNaN {
        return "00:00"
    }
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
}
func setForAudioPlaying() {
    if UserDefaults.standard.bool(forKey: "MPBackgroundPlay") {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSession.Category.playback,
                mode: .default,
                policy: .longFormAudio
            )
            AVAudioSession.sharedInstance().activate { _, _ in }
        } catch {
            globalErrorHandler(error)
        }
    }
}

enum PlaybackBehavior: String {
    case pause
    case singleLoop
    case listLoop
}

struct LocalAudiosView: View {
    var selectHandler: ((String) -> Void)?
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLocalAudios") var usePasscodeForLocalAudios = false
    @AppStorage("IsThisClusterInstalled") var isThisClusterInstalled = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var audioNames = [String]()
    @State var audioHumanNameChart = [String: String]()
    @State var isEditNamePresented = false
    @State var editNameAudioName = ""
    @State var editNameInput = ""
    @State var deleteItemIndex = 0
    @State var isDeleteItemAlertPresented = false
    var body: some View {
        if isLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLocalAudios {
            PasswordInputView(text: $passcodeInputCache, placeholder: "输入密码", dismissAfterComplete: false) { pwd in
                if pwd.md5 == userPasscodeEncrypted {
                    isLocked = false
                } else {
                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                }
                passcodeInputCache = ""
            }
            .navigationBarBackButtonHidden()
        } else {
            List {
                Section {
                    if !audioNames.isEmpty {
                        ForEach(0..<audioNames.count, id: \.self) { i in
                            Button(action: {
                                if let selectHandler {
                                    selectHandler("%DownloadedContent@=\(audioNames[i])")
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    setForAudioPlaying()
                                    let audioPathPrefix = URL(filePath: NSHomeDirectory() + "/Documents/DownloadedAudios")
                                    globalAudioPlayer.replaceCurrentItem(with: AVPlayerItem(url: audioPathPrefix.appending(path: audioNames[i])))
                                    if let noSuffix = audioNames[i].split(separator: ".").first, let mid = Int(noSuffix) {
                                        nowPlayingAudioId = String(mid)
                                    } else {
                                        nowPlayingAudioId = ""
                                    }
                                    pShouldPresentAudioController = true
                                    globalAudioPlayer.play()
                                }
                            }, label: {
                                Text(audioHumanNameChart[audioNames[i]] ?? audioNames[i])
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    deleteItemIndex = i
                                    isDeleteItemAlertPresented = true
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                                Button(action: {
                                    editNameAudioName = audioNames[i]
                                    editNameInput = audioHumanNameChart[audioNames[i]] ?? audioNames[i]
                                    isEditNamePresented = true
                                }, label: {
                                    Image(systemName: "pencil.line")
                                })
                            }
                            .swipeActions(edge: .leading) {
                                if isThisClusterInstalled {
                                    Button(action: {
                                        do {
                                            let containerFilePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.darockst")!.path + "/TransferFile.drkdatat"
                                            if FileManager.default.fileExists(atPath: containerFilePath) {
                                                try FileManager.default.removeItem(atPath: containerFilePath)
                                            }
                                            try FileManager.default.copyItem(
                                                atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/" + audioNames[i],
                                                toPath: containerFilePath
                                            )
                                            WKExtension.shared().openSystemURL(URL(string: "https://darock.top/cluster/add/\(audioNames[i])")!)
                                        } catch {
                                            globalErrorHandler(error)
                                        }
                                    }, label: {
                                        Image(systemName: "square.grid.3x1.folder.badge.plus")
                                    })
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("本地音频")
            .alert("删除项目", isPresented: $isDeleteItemAlertPresented, actions: {
                Button(role: .cancel, action: {}, label: {
                    Text("取消")
                })
                Button(role: .destructive, action: {
                    do {
                        // Delete this in all playlists
                        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/Playlists") {
                            let playlistFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/Playlists")
                            for file in playlistFiles {
                                let content = try String(contentsOfFile: NSHomeDirectory() + "/Documents/Playlists/\(file)")
                                if var data = getJsonData([String].self, from: content) {
                                    data.removeAll(where: { element in
                                        element == "%DownloadedContent@=\(audioNames[deleteItemIndex])"
                                    })
                                    if let newStr = jsonString(from: data) {
                                        try newStr.write(
                                            toFile: NSHomeDirectory() + "/Documents/Playlists/\(file)",
                                            atomically: true,
                                            encoding: .utf8
                                        )
                                    }
                                }
                            }
                        }
                        try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/" + audioNames[deleteItemIndex])
                        audioNames.remove(at: deleteItemIndex)
                    } catch {
                        globalErrorHandler(error)
                    }
                }, label: {
                    Text("删除")
                })
            }, message: {
                Text("确定要删除此项目吗\n此操作不可撤销")
            })
            .sheet(isPresented: $isEditNamePresented) {
                NavigationStack {
                    List {
                        Section {
                            TextField("名称", text: $editNameInput, style: "field-page")
                            Button(action: {
                                audioHumanNameChart.updateValue(editNameInput, forKey: editNameAudioName)
                                UserDefaults.standard.set(audioHumanNameChart, forKey: "AudioHumanNameChart")
                                isEditNamePresented = false
                            }, label: {
                                Label("保存", systemImage: "arrow.down.doc")
                            })
                        }
                    }
                    .navigationTitle("自定名称")
                    .navigationBarTitleDisplayMode(.large)
                }
                .onDisappear {
                    editNameInput = ""
                }
            }
            .onAppear {
                do {
                    audioNames = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios")
                    audioHumanNameChart = (UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]) ?? [String: String]()
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
    }
}

struct PlaylistsView: View {
    var selectHandler: ((String) -> Void)?
    @Environment(\.presentationMode) var presentationMode
    @State var listFileNames = [String]()
    @State var isCreateListPresented = false
    @State var createListNameInput = ""
    @State var deletingIndex = 0
    @State var isConfirmDeletePresented = false
    @State var renameSourceName = ""
    @State var isRenamePresented = false
    @State var renameInput = ""
    var body: some View {
        List {
            if #unavailable(watchOS 10.5) {
                Section {
                    Button(action: {
                        isCreateListPresented = true
                    }, label: {
                        HStack {
                            Spacer()
                            Label("新建播放列表", systemImage: "plus")
                            Spacer()
                        }
                    })
                }
            }
            if !listFileNames.isEmpty {
                Section {
                    ForEach(0..<listFileNames.count, id: \.self) { i in
                        Group {
                            if let selectHandler {
                                Button(action: {
                                    selectHandler(listFileNames[i])
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Text(listFileNames[i].dropLast(9))
                                })
                            } else {
                                NavigationLink(destination: { ListDetailView(fileName: listFileNames[i]) }, label: {
                                    Text(listFileNames[i].dropLast(9))
                                })
                            }
                        }
                        .swipeActions {
                            Button(action: {
                                deletingIndex = i
                                isConfirmDeletePresented = true
                            }, label: {
                                Image(systemName: "xmark.bin.fill")
                            })
                            .tint(.red)
                            Button(action: {
                                renameSourceName = String(listFileNames[i].dropLast(9))
                                isRenamePresented = true
                            }, label: {
                                Image(systemName: "pencil.line")
                            })
                        }
                    }
                }
            } else {
                Text("无播放列表")
            }
        }
        .navigationTitle("\(selectHandler != nil ? "添加到" : "")播放列表")
        .sheet(isPresented: $isCreateListPresented) {
            NavigationStack {
                List {
                    Section {
                        TextField("名称", text: $createListNameInput, style: "field-page")
                        Button(action: {
                            let listStr = jsonString(from: [String]())!
                            do {
                                try listStr.write(toFile: NSHomeDirectory() + "/Documents/Playlists/\(createListNameInput).drkdatap",
                                                  atomically: true,
                                                  encoding: .utf8)
                            } catch {
                                globalErrorHandler(error)
                            }
                            createListNameInput = ""
                            getPlaylistFiles()
                            isCreateListPresented = false
                        }, label: {
                            Label("创建", systemImage: "plus")
                        })
                    }
                }
                .navigationTitle("创建播放列表")
            }
        }
        .sheet(isPresented: $isRenamePresented) {
            NavigationStack {
                List {
                    HStack {
                        Spacer()
                        Text("修改名称")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    TextField("名称", text: $renameInput, style: "field-page")
                    Button(action: {
                        do {
                            try FileManager.default.moveItem(
                                atPath: NSHomeDirectory() + "/Documents/Playlists/\(renameSourceName).drkdatap",
                                toPath: NSHomeDirectory() + "/Documents/Playlists/\(renameInput).drkdatap"
                            )
                            getPlaylistFiles()
                            isRenamePresented = false
                        } catch {
                            globalErrorHandler(error)
                        }
                    }, label: {
                        HStack {
                            Spacer()
                            Label("完成", systemImage: "checkmark")
                            Spacer()
                        }
                    })
                    .disabled(renameInput.isEmpty)
                }
            }
            .onDisappear {
                renameInput = ""
            }
        }
        .alert("删除播放列表", isPresented: $isConfirmDeletePresented, actions: {
            Button(role: .cancel, action: {
                
            }, label: {
                Text("取消")
            })
            Button(role: .destructive, action: {
                do {
                    try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/Playlists/\(listFileNames[deletingIndex])")
                    listFileNames.remove(at: deletingIndex)
                } catch {
                    globalErrorHandler(error)
                }
            }, label: {
                Text("确认")
            })
        }, message: {
            Text("这将删除播放列表中的所有内容\n确定吗？")
        })
        .toolbar {
            if #available(watchOS 10.5, *) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isCreateListPresented = true
                    }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
        }
        .onAppear {
            getPlaylistFiles()
        }
    }
    
    func getPlaylistFiles() {
        do {
            if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/Playlists") {
                listFileNames = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/Playlists")
            } else {
                try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/Playlists", withIntermediateDirectories: true)
            }
        } catch {
            globalErrorHandler(error)
        }
    }
    
    struct ListDetailView: View {
        var fileName: String
        @State var listContent = [String]()
        @State var isAddMusicPresented = false
        @State var renameContentIndex = 0
        @State var isRenamePresented = false
        @State var renameInput = ""
        @State var audioHumanNameChart = [String: String]()
        var body: some View {
            List {
                if #unavailable(watchOS 10.5) {
                    Button(action: {
                        isAddMusicPresented = true
                    }, label: {
                        HStack {
                            Spacer()
                            Label("添加歌曲", systemImage: "plus")
                            Spacer()
                        }
                    })
                }
                if !listContent.isEmpty {
                    Section {
                        ForEach(0..<listContent.count, id: \.self) { i in
                            Button(action: {
                                setForAudioPlaying()
                                globalAudioCurrentPlaylist = fileName
                                playAudio(url: listContent[i])
                            }, label: {
                                Text(audioHumanNameChart[String(listContent[i].split(separator: "/").last!.split(separator: "=").last!)] ?? listContent[i])
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    listContent.remove(at: i)
                                    saveCurrentContent()
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                                Button(action: {
                                    renameContentIndex = i
                                    isRenamePresented = true
                                }, label: {
                                    Image(systemName: "pencil.line")
                                })
                            }
                        }
                        .onMove { source, destination in
                            listContent.move(fromOffsets: source, toOffset: destination)
                            saveCurrentContent()
                        }
                    }
                } else {
                    Text("空播放列表")
                }
            }
            .navigationTitle(fileName.dropLast(9))
            .sheet(isPresented: $isAddMusicPresented, onDismiss: { saveCurrentContent() }, content: { AddMusicToListView(listContent: $listContent) })
            .sheet(isPresented: $isRenamePresented) {
                NavigationStack {
                    List {
                        Section {
                            TextField("新名称", text: $renameInput, style: "field-page")
                            Button(action: {
                                audioHumanNameChart.updateValue(
                                    renameInput,
                                    forKey: String(listContent[renameContentIndex].split(separator: "/").last!.split(separator: "=").last!)
                                )
                                UserDefaults.standard.set(audioHumanNameChart, forKey: "AudioHumanNameChart")
                                saveCurrentContent()
                                isRenamePresented = false
                            }, label: {
                                Label("完成", systemImage: "checkmark")
                            })
                        }
                    }
                    .navigationTitle("重命名")
                }
                .onDisappear {
                    renameInput = ""
                }
            }
            .toolbar {
                if #available(watchOS 10.5, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isAddMusicPresented = true
                        }, label: {
                            Image(systemName: "plus")
                        })
                    }
                }
            }
            .onAppear {
                do {
                    let fileContent = try String(contentsOfFile: NSHomeDirectory() + "/Documents/Playlists/\(fileName)", encoding: .utf8)
                    listContent = getJsonData([String].self, from: fileContent) ?? [String]()
                } catch {
                    globalErrorHandler(error)
                }
                audioHumanNameChart = (UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]) ?? [String: String]()
            }
        }
        
        func saveCurrentContent() {
            if let content = jsonString(from: listContent) {
                do {
                    try content.write(toFile: NSHomeDirectory() + "/Documents/Playlists/\(fileName)", atomically: true, encoding: .utf8)
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
        
        struct AddMusicToListView: View {
            @Binding var listContent: [String]
            @Environment(\.presentationMode) var presentationMode
            @State var linkInput = ""
            @State var isAddLinkInvalid = false
            var body: some View {
                NavigationStack {
                    List {
                        Section {
                            NavigationLink(destination: {
                                LocalAudiosView { url in
                                    listContent.append(url)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }, label: {
                                Text("从离线歌曲选择")
                            })
                            TextField("输入歌曲链接", text: $linkInput, style: "field-page")
                                .onSubmit {
                                    if !linkInput.hasSuffix(".mp3") {
                                        isAddLinkInvalid = true
                                        return
                                    }
                                    if !linkInput.hasPrefix("http://") && !linkInput.hasPrefix("https://") {
                                        linkInput = "http://" + linkInput
                                    }
                                    listContent.append(linkInput)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            if isAddLinkInvalid {
                                HStack {
                                    Image(systemName: "xmark.octagon.fill")
                                        .foregroundStyle(Color.red)
                                    Text("歌曲链接无效")
                                }
                            }
                        }
                        Section {
                            Label("可在解析的音频列表页左滑项目以添加到列表", systemImage: "lightbulb.max")
                        }
                    }
                    .navigationTitle("添加歌曲")
                }
            }
        }
    }
}

struct AudioVisualizerView: View {
    @State private var drawingHeight = true
    @State var isAudioPlaying = globalAudioPlayer.timeControlStatus == .playing
    var animation: Animation {
        return .linear(duration: 0.5).repeatForever()
    }
    var body: some View {
        Group {
            if isAudioPlaying {
                HStack {
                    bar(low: 0.4)
                        .animation(animation.speed(1.8), value: drawingHeight)
                    bar(low: 0.3)
                        .animation(animation.speed(2.4), value: drawingHeight)
                    bar(low: 0.5)
                        .animation(animation.speed(2.0), value: drawingHeight)
                    bar(low: 0.3)
                        .animation(animation.speed(3.0), value: drawingHeight)
                    bar(low: 0.5)
                        .animation(animation.speed(2.0), value: drawingHeight)
                }
                .frame(width: 22)
                .onAppear {
                    drawingHeight.toggle()
                }
            } else {
                HStack {
                    bar(low: 0.2, high: 0.2)
                    bar(low: 0.2, high: 0.2)
                    bar(low: 0.2, high: 0.2)
                    bar(low: 0.2, high: 0.2)
                    bar(low: 0.2, high: 0.2)
                }
                .frame(width: 22)
            }
        }
        .onReceive(globalAudioPlayer.publisher(for: \.timeControlStatus)) { status in
            isAudioPlaying = status == .playing
        }
    }
    
    func bar(low: CGFloat = 0.0, high: CGFloat = 1.0) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.white)
            .frame(height: (drawingHeight ? high : low) * 18)
            .frame(height: 18)
            .padding(.horizontal, -1.5)
    }
}

/// 播放音频
/// - Parameters:
///   - url: 音频URL
///   - presentController: 是否同时显示播放控件
func playAudio(url: String, presentController: Bool = true) {
    if url.contains(/music\..*\.com/) && url.contains(/(\?|&)id=[0-9]*\.mp3($|&)/),
       let mid = url.split(separator: "id=")[from: 1]?.split(separator: ".mp3").first {
        nowPlayingAudioId = String(mid)
    } else if let noSuffix = url.split(separator: "/").last?
        .split(separator: "=").last?
        .split(separator: ".").first,
              let mid = Int(noSuffix) {
        nowPlayingAudioId = String(mid)
    } else {
        nowPlayingAudioId = ""
    }
    globalAudioPlayer.replaceCurrentItem(
        with: AVPlayerItem(
            url: URL(
                string: url
                    .replacingOccurrences(of: "%DownloadedContent@=",
                                          with: "file://\(NSHomeDirectory())/Documents/DownloadedAudios/")
            )!
        )
    )
    resetGlobalAudioLooper()
    if presentController {
        pShouldPresentAudioController = true
    }
    globalAudioPlayer.play()
    updateNowPlaying()
}
/// 获取当前播放列表内容
/// - Returns: 歌曲名
@_effects(readonly)
func getCurrentPlaylistContents() -> [String]? {
    if !globalAudioCurrentPlaylist.isEmpty
        && FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/Playlists/\(globalAudioCurrentPlaylist)") {
        do {
            let fileStr = try String(contentsOfFile: NSHomeDirectory() + "/Documents/Playlists/\(globalAudioCurrentPlaylist)", encoding: .utf8)
            return getJsonData([String].self, from: fileStr)
        } catch {
            globalErrorHandler(error)
        }
    }
    return nil
}
func updateNowPlaying() {
    var nowPlayingInfo = [String: Any]()
    if !nowPlayingAudioId.isEmpty {
        DarockKit.Network.shared
            .requestJSON("https://music.\(0b10100011).com/api/song/detail/?id=\(nowPlayingAudioId)&ids=%5B\(nowPlayingAudioId)%5D".compatibleUrlEncoded()) { respJson, isSuccess in
                if isSuccess {
                    if let imageUrlString = respJson["songs"][0]["album"]["picUrl"].string,
                       let imageUrl = URL(string: imageUrlString),
                       let imageData = try? Data(contentsOf: imageUrl),
                       let image = UIImage(data: imageData) {
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    }
                    nowPlayingInfo[MPMediaItemPropertyTitle] = respJson["songs"][0]["name"].string ?? String(localized: "暗礁浏览器 - 音频播放")
                    nowPlayingInfo[MPMediaItemPropertyArtist] = respJson["songs"][0]["artists"][0]["name"].string ?? ""
                    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = respJson["songs"][0]["album"]["name"].string ?? ""
                    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = globalAudioPlayer.currentItem?.duration
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }
    } else {
        nowPlayingInfo[MPMediaItemPropertyTitle] = String(localized: "暗礁浏览器 - 音频播放")
        nowPlayingInfo[MPMediaItemPropertyArtist] = ""
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = ""
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = globalAudioPlayer.currentItem?.duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    let commandCenter = MPRemoteCommandCenter.shared()
    commandCenter.playCommand.addTarget { _ in
        globalAudioPlayer.play()
        return .success
    }
    commandCenter.pauseCommand.addTarget { _ in
        globalAudioPlayer.pause()
        return .success
    }
    commandCenter.skipForwardCommand.addTarget { _ in
        globalAudioPlayer.seek(
            to: CMTime(seconds: globalAudioPlayer.currentTime().seconds + 15, preferredTimescale: 60000),
            toleranceBefore: .zero,
            toleranceAfter: .zero)
        return .success
    }
    commandCenter.skipBackwardCommand.addTarget { _ in
        globalAudioPlayer.seek(
            to: CMTime(seconds: globalAudioPlayer.currentTime().seconds - 15, preferredTimescale: 60000),
            toleranceBefore: .zero,
            toleranceAfter: .zero)
        return .success
    }
}

extension String {
    func removePrefix(_ c: String) -> Self {
        var selfCopy = self
        while selfCopy.hasPrefix(c) {
            selfCopy.removeFirst()
        }
        return selfCopy
    }
}

// Extensions for periodicTimePublisher
extension AVPlayer {
    func periodicTimePublisher(forInterval interval: CMTime = CMTime(seconds: 0.5,
                                                                     preferredTimescale: CMTimeScale(NSEC_PER_SEC))) -> AnyPublisher<CMTime, Never> {
        Publisher(self, forInterval: interval)
            .eraseToAnyPublisher()
    }
}
fileprivate extension AVPlayer {
    private struct Publisher: Combine.Publisher {
        typealias Output = CMTime
        typealias Failure = Never
        
        var player: AVPlayer
        var interval: CMTime
        
        init(_ player: AVPlayer, forInterval interval: CMTime) {
            self.player = player
            self.interval = interval
        }
        
        func receive<S>(subscriber: S) where S: Subscriber, Publisher.Failure == S.Failure, Publisher.Output == S.Input {
            let subscription = CMTime.Subscription(subscriber: subscriber, player: player, forInterval: interval)
            subscriber.receive(subscription: subscription)
        }
    }
}
fileprivate extension CMTime {
    final class Subscription<SubscriberType: Subscriber>: Combine.Subscription where SubscriberType.Input == CMTime, SubscriberType.Failure == Never {
        var player: AVPlayer?
        var observer: Any?
        
        init(subscriber: SubscriberType, player: AVPlayer, forInterval interval: CMTime) {
            self.player = player
            observer = player.addPeriodicTimeObserver(forInterval: interval, queue: nil) { time in
                _ = subscriber.receive(time)
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            // We do nothing here as we only want to send events when they occur.
            // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
        }
        
        func cancel() {
            if let observer = observer {
                player?.removeTimeObserver(observer)
            }
            observer = nil
            player = nil
        }
    }
}
