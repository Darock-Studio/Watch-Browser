//
//  AudioControllerView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI
import DarockKit
import MediaPlayer
import AVFoundation

let globalAudioPlayer = AVPlayer()
var globalAudioLooper: Any?
var globalAudioCurrentPlaylist = ""
var nowPlayingAudioId = ""

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
    @State var isSoftScrolling = true
    @State var softScrollingResetTask: Task<Void, Never>?
    @State var isUserScrolling = false
    @State var userScrollingResetTimer: Timer?
    @State var lyricScrollProxy: ScrollViewProxy?
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
                                                WaitingDotsView(startTime: 0.0, endTime: firstKey, currentTime: $currentPlaybackTime)
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
                                .withScrollOffsetUpdate()
                                .scrollIndicators(.never)
                                .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { _ in
                                    if !isSoftScrolling {
                                        // Scrolled by user (not auto scrolling lyrics)
                                        isUserScrolling = true
                                        userScrollingResetTimer?.invalidate()
                                        userScrollingResetTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                                            isUserScrolling = false
                                        }
                                    }
                                }
                                .onAppear {
                                    lyricScrollProxy = scrollProxy
                                }
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
                                    if _slowPath(newScrollId != currentScrolledId && !isUserScrolling) {
                                        softScrollingResetTask?.cancel()
                                        currentScrolledId = newScrollId
                                        isSoftScrolling = true
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            scrollProxy.scrollTo(newScrollId, anchor: .init(x: 0.5, y: 0.2))
                                        }
                                        softScrollingResetTask = Task {
                                            do {
                                                try await Task.sleep(for: .seconds(0.6)) // Animation may take longer time than duration
                                                guard !Task.isCancelled else { return }
                                                DispatchQueue.main.async {
                                                    isSoftScrolling = false
                                                }
                                            } catch {
                                                // Catch if task was canceled, do nothing.
                                            }
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
            .tabViewStyle(.page(indexDisplayMode: isShowingControls || !isLyricsAvailable ? .always : .never))
            .modifier({ () -> BlurBackground in
                #if compiler(>=6.0)
                if #available(watchOS 11.0, *) {
                    return BlurBackground(imageUrl: backgroundImageUrl, meshForUnavailable: .autoGradient)
                } else {
                    return BlurBackground(imageUrl: backgroundImageUrl)
                }
                #else
                return BlurBackground(imageUrl: backgroundImageUrl)
                #endif
            }())
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
            audioHumanNameChart = (UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]) ?? [:]
            currentPlaylistContent = getCurrentPlaylistContents() ?? []
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
                    HStack {
                        if ({ // swiftlint:disable:this control_statement
                            var singerSplitCount = 0
                            for key in lyricKeys[0...i] {
                                if let src = lyrics[key]!.components(separatedBy: "%tranlyric@")[from: 0], src.hasSuffix("：") {
                                    singerSplitCount++
                                }
                            }
                            return singerSplitCount % 2 == 1
                        }()) {
                            Spacer()
                        }
                        VStack(alignment: .leading) {
                            if lyrics[lyricKeys[i]]!.contains("%tranlyric@"),
                               let src = lyrics[lyricKeys[i]]!.components(separatedBy: "%tranlyric@")[from: 0],
                               let trans = lyrics[lyricKeys[i]]!.components(separatedBy: "%tranlyric@")[from: 1] {
                                Text(src)
                                    .font(.system(size: 16, weight: .semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(trans)
                                    .font(.system(size: 14, weight: .medium))
                                    .opacity(0.85)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text(lyrics[lyricKeys[i]]!)
                                    .font(.system(size: lyrics[lyricKeys[i]]!.hasSuffix("：") ? 14 : 16, weight: .semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.bottom, lyrics[lyricKeys[i]]!.hasSuffix("：") ? -3 : 0)
                            }
                        }
                        .multilineTextAlignment({
                            var singerSplitCount = 0
                            for key in lyricKeys[0...i] {
                                if let src = lyrics[key]!.components(separatedBy: "%tranlyric@")[from: 0], src.hasSuffix("：") {
                                    singerSplitCount++
                                }
                            }
                            return singerSplitCount % 2 == 0 ? .leading : .trailing
                        }())
                        if ({ // swiftlint:disable:this control_statement
                            var singerSplitCount = 0
                            for key in lyricKeys[0...i] {
                                if let src = lyrics[key]!.components(separatedBy: "%tranlyric@")[from: 0], src.hasSuffix("：") {
                                    singerSplitCount++
                                }
                            }
                            return singerSplitCount % 2 == 0
                        }()) {
                            Spacer(minLength: 20)
                        }
                    }
                    .opacity(currentScrolledId == lyricKeys[i] ? 1.0 : 0.6)
                    .blur(radius: currentScrolledId == lyricKeys[i] || isUserScrolling ? 0 : 1)
                    .padding(.vertical, 5)
                    .animation(.smooth, value: currentScrolledId)
                    .modifier(LyricButtonModifier {
                        globalAudioPlayer.seek(to: CMTime(seconds: lyricKeys[i], preferredTimescale: 60000),
                                               toleranceBefore: .zero,
                                               toleranceAfter: .zero)
                        globalAudioPlayer.play()
                        currentScrolledId = lyricKeys[i]
                        isSoftScrolling = true
                        withAnimation(.easeOut(duration: 0.5)) {
                            lyricScrollProxy?.scrollTo(lyricKeys[i], anchor: .init(x: 0.5, y: 0.2))
                        }
                        Task {
                            try? await Task.sleep(for: .seconds(0.6)) // Animation may take longer time than duration
                            DispatchQueue.main.async {
                                isSoftScrolling = false
                            }
                        }
                    })
                    .allowsHitTesting(isUserScrolling)
                } else {
                    if let endTime = lyricKeys[from: i &+ 1], endTime - lyricKeys[i] > 2.0 {
                        WaitingDotsView(startTime: lyricKeys[i], endTime: endTime, currentTime: $currentPlaybackTime)
                        Spacer()
                    }
                }
            }
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
                            if isShowTranslatedLyrics, let tlyric = respJson["tlyric"]["lyric"].string {
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
    
    struct WaitingDotsView: View {
        var startTime: Double
        var endTime: Double
        @Binding var currentTime: Double
        @State var dot1Opacity = 0.2
        @State var dot2Opacity = 0.2
        @State var dot3Opacity = 0.2
        @State var scale: CGFloat = 1
        @State var isVisible = false
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
            .opacity(isVisible ? 1.0 : 0.0100000002421438702673861521)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                    if scale > 1.0 {
                        scale = 1.0
                    } else {
                        scale = 1.2
                    }
                }
            }
            .onChange(of: currentTime) { value in
                if _fastPath(!isVisible) {
                    isVisible = currentTime >= startTime && currentTime <= endTime
                }
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
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            scale = 0.02
                                            dot1Opacity = 0.02
                                            dot2Opacity = 0.02
                                            dot3Opacity = 0.02
                                        } completion: {
                                            isVisible = false
                                            Task {
                                                try? await Task.sleep(for: .seconds(0.5))
                                                dot1Opacity = 0.2
                                                dot2Opacity = 0.2
                                                dot3Opacity = 0.2
                                                scale = 1
                                            }
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
                        Task {
                            try? await Task.sleep(for: .seconds(endTime - startTime))
                            isVisible = false
                            try? await Task.sleep(for: .seconds(0.5))
                            dot1Opacity = 0.2
                            dot2Opacity = 0.2
                            dot3Opacity = 0.2
                            scale = 1
                        }
                    }
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
    struct LyricButtonModifier: ViewModifier {
        var buttonAction: () -> Void
        @State private var isPressed = false
        func body(content: Content) -> some View {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray)
                    .scaleEffect(isPressed ? 0.9 : 1)
                    .opacity(isPressed ? 0.4 : 0.0100000002421438702673861521)
                content
                    .scaleEffect(isPressed ? 0.9 : 1)
            }
            ._onButtonGesture(pressing: { isPressing in
                isPressed = isPressing
            }, perform: buttonAction)
            .onLongPressGesture(minimumDuration: 1.0) {
                
            }
            .animation(.easeOut(duration: 0.2), value: isPressed)
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
    do {
        if globalAudioCurrentPlaylist == "LocalDownloadedAudio" {
            return try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios").map {
                URL(filePath: NSHomeDirectory() + "/Documents/DownloadedAudios").appending(path: $0).absoluteString
            }
        }
        if !globalAudioCurrentPlaylist.isEmpty
            && FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/Playlists/\(globalAudioCurrentPlaylist)") {
            let fileStr = try String(contentsOfFile: NSHomeDirectory() + "/Documents/Playlists/\(globalAudioCurrentPlaylist)", encoding: .utf8)
            return getJsonData([String].self, from: fileStr)
        }
    } catch {
        globalErrorHandler(error)
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
