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

let globalAudioPlayer = AVPlayer()
var globalAudioLooper: Any?
var nowPlayingAudioId = ""

struct AudioListView: View {
    @State var willDownloadAudioLink = ""
    @State var downloadFileName: String?
    @State var isAudioDownloadPresented = false
    var body: some View {
        if !audioLinkLists.isEmpty {
            List {
                ForEach(0..<audioLinkLists.count, id: \.self) { i in
                    Button(action: {
                        setForAudioPlaying()
                        globalAudioPlayer.replaceCurrentItem(with: AVPlayerItem(url: URL(string: audioLinkLists[i])!))
                        if audioLinkLists[i].contains(/music\..*\.com/) && audioLinkLists[i].contains(/(\?|&)id=[0-9]*\.mp3($|&)/),
                           let mid = audioLinkLists[i].split(separator: "id=")[from: 1]?.split(separator: ".mp3").first {
                            nowPlayingAudioId = String(mid)
                        } else {
                            nowPlayingAudioId = ""
                        }
                        pShouldPresentAudioController = true
                        globalAudioPlayer.play()
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
                                    .requestJSON("https://music.\(0b10100011).com/api/song/detail/?id=\(mid)&ids=%5B\(mid)%5D") { respJson, isSuccess in
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
                            } else {
                                downloadFileName = "\(audioLinkLists[i].split(separator: "/").last!.split(separator: ".mp3")[0]).mp3"
                            }
                            isAudioDownloadPresented = true
                        }, label: {
                            Image(systemName: "square.and.arrow.down")
                        })
                    }
                }
            }
            .navigationTitle("音频列表")
            .sheet(isPresented: $isAudioDownloadPresented) {
                MediaDownloadView(mediaLink: $willDownloadAudioLink, mediaTypeName: "音频", saveFolderName: "DownloadedAudios", saveFileName: $downloadFileName)
            }
            .onDisappear {
                if dismissListsShouldRepresentWebView {
                    DispatchQueue.main.async {
                        Dynamic.UIApplication.sharedApplication.keyWindow.rootViewController.presentViewController(
                            AdvancedWebViewController.shared.vc,
                            animated: true,
                            completion: nil
                        )
                    }
                }
            }
        } else {
            Text("空音频列表")
        }
    }
}

struct AudioControllerView: View {
    @AppStorage("MPIsShowTranslatedLyrics") var isShowTranslatedLyrics = true
    @State var lyrics = [Double: String]()
    @State var isLyricsAvailable = true
    @State var currentPlaybackTime = 0.0
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
    var body: some View {
        NavigationStack {
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
                            .onReceive(globalAudioPlayer.periodicTimePublisher()) { time in
                                // Code in this closure runs at nearly each frame, optimizing for speed is important.
                                if time.seconds - currentPlaybackTime >= 0.3 || time.seconds < currentPlaybackTime {
                                    currentPlaybackTime = time.seconds
                                }
                                var newScrollId = 0.0
                                for i in 0..<lyricKeys.count where currentPlaybackTime < lyricKeys[i] {
                                    if let newKey = lyricKeys[from: i - 1] {
                                        newScrollId = newKey
                                    } else {
                                        newScrollId = lyricKeys[i]
                                    }
                                    break
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
                }
                // Audio Controls
                VStack {
                    Spacer()
                    if isShowingControls {
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
                                        playbackBehavior = .pause
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
                        .transition(
                            AnyTransition
                                .opacity
                                .animation(.easeOut(duration: 0.2))
                        )
                    }
                }
                .ignoresSafeArea()
            }
            .navigationTitle(audioName)
            .modifier(BlurBackground(imageUrl: backgroundImageUrl))
            .onTapGesture { location in
                if location.y > WKInterfaceDevice.current().screenBounds.height / 2 {
                    isShowingControls = true
                    resetMenuDismissTimer()
                } else {
                    isShowingControls = false
                }
            }
        }
        .onAppear {
            isPlaying = globalAudioPlayer.timeControlStatus == .playing
            currentItemTotalTime = globalAudioPlayer.currentItem?.duration.seconds ?? 0.0
            playbackBehavior = .init(rawValue: UserDefaults.standard.string(forKey: "MPPlaybackBehavior") ?? "pause") ?? .pause
            if !nowPlayingAudioId.isEmpty {
                DarockKit.Network.shared
                    .requestJSON("https://music.\(0b10100011).com/api/song/lyric?id=\(nowPlayingAudioId)&lv=1&kv=1&tv=-1") { respJson, isSuccess in
                        if isSuccess {
                            if let lyric = respJson["lrc"]["lyric"].string {
                                let lineSpd = lyric.components(separatedBy: "\n")
                                for lineText in lineSpd {
                                    // swiftlint:disable:next for_where
                                    if lineText.contains(/\[[0-9]*:[0-9]*.[0-9]*\].*/) {
                                        if let text = lineText.components(separatedBy: "]")[from: 1],
                                           let time = lineText.components(separatedBy: "[")[from: 1]?.components(separatedBy: "]")[from: 0],
                                           let dTime = lyricTimeStringToSeconds(String(time)) {
                                            lyrics.updateValue(String(text), forKey: dTime)
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
                                                    lyrics.updateValue("\(sourceLyric)%tranlyric@\(text)", forKey: dTime)
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                isLyricsAvailable = false
                            }
                        } else {
                            isLyricsAvailable = false
                        }
                    }
                DarockKit.Network.shared
                    .requestJSON("https://music.\(0b10100011).com/api/song/detail/?id=\(nowPlayingAudioId)&ids=%5B\(nowPlayingAudioId)%5D") { respJson, isSuccess in
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
            resetGlobalAudioLooper()
            pIsAudioControllerAvailable = true
            extendScreenIdleTime(3600)
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
                    if let endTime = lyricKeys[from: i + 1], endTime - lyricKeys[i] > 1.0 {
                        WaitingDotView(startTime: lyricKeys[i], endTime: endTime, currentTime: $currentPlaybackTime)
                    }
                }
                Spacer(minLength: 20)
            }
            .padding(.vertical, 5)
            .id(lyricKeys[i])
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
                    scale = 1.15
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

func lyricTimeStringToSeconds(_ timeString: String) -> Double? {
    let components = timeString.split(separator: ":")
    guard components.count == 2,
          let minutes = Double(components[0]),
          let seconds = Double(components[1]) else {
        return nil
    }
    return minutes * 60 + seconds
}
func formattedTime(from seconds: Double) -> String {
    if seconds.isNaN {
        return "00:00"
    }
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
}
func setForAudioPlaying() {
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
    let title = String(localized: "暗礁浏览器 - 音频播放")
    nowPlayingInfo[MPMediaItemPropertyTitle] = title
    nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
}

enum PlaybackBehavior: String {
    case pause
    case singleLoop
}

struct LocalAudiosView: View {
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLocalAudios") var usePasscodeForLocalAudios = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var audioNames = [String]()
    @State var audioHumanNameChart = [String: String]()
    @State var isEditNamePresented = false
    @State var editNameAudioName = ""
    @State var editNameInput = ""
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
                            }, label: {
                                Text(audioHumanNameChart[audioNames[i]] ?? audioNames[i])
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    do {
                                        try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/" + audioNames[i])
                                        audioNames.remove(at: i)
                                    } catch {
                                        globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
                                    }
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                                Button(action: {
                                    editNameAudioName = audioNames[i]
                                    isEditNamePresented = true
                                }, label: {
                                    Image(systemName: "pencil.line")
                                })
                            }
                        }
                    }
                }
            }
            .navigationTitle("本地音频")
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
                    globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
                }
            }
        }
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
