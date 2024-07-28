//
//  VideoListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/21.
//

import AVKit
import SwiftUI
import Dynamic
import Alamofire
import DarockKit
import AVFoundation

struct VideoListView: View {
    @State var willPlayVideoLink = ""
    @State var isPlayerPresented = false
    @State var willDownloadVideoLink = ""
    @State var downloadVideoSaveName: String?
    @State var isVideoDownloadPresented = false
    @State var shareVideoLink = ""
    @State var isSharePresented = false
    var body: some View {
        if !videoLinkLists.isEmpty {
            List {
                ForEach(0..<videoLinkLists.count, id: \.self) { i in
                    Button(action: {
                        willPlayVideoLink = videoLinkLists[i]
                        isPlayerPresented = true
                    }, label: {
                        Text(videoLinkLists[i])
                    })
                    .swipeActions {
                        Button(action: {
                            willDownloadVideoLink = videoLinkLists[i]
                            isVideoDownloadPresented = true
                        }, label: {
                            Image(systemName: "square.and.arrow.down")
                        })
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
            Text("空视频列表")
        }
    }
}

struct VideoPlayingView: View {
    @Binding var link: String
    @State var player: AVPlayer! = AVPlayer()
    @State var playbackSpeed = 1.0
    @State var isFullScreen = false
    @State var mainTabViewSelection = 1
    @State var jumpToInput = ""
    @State var currentTime = 0.0
    @State var cachedPlayerTimeControlStatus = AVPlayer.TimeControlStatus.paused
    var body: some View {
        TabView(selection: $mainTabViewSelection) {
            VideoPlayer(player: player)
                .rotationEffect(.degrees(isFullScreen ? 90 : 0))
                .frame(
                    width: isFullScreen ? WKInterfaceDevice.current().screenBounds.height : nil,
                    height: isFullScreen ? WKInterfaceDevice.current().screenBounds.width : nil
                )
                .offset(y: isFullScreen ? 20 : 0)
                .ignoresSafeArea()
                .tag(1)
            List {
                Section {
                    Button(action: {
                        isFullScreen.toggle()
                        mainTabViewSelection = 1
                    }, label: {
                        Label(
                            isFullScreen ? "恢复" : "全屏",
                            systemImage: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.down.left.and.arrow.up.right"
                        )
                    })
                } header: {
                    Text("画面")
                }
                Section {
                    HStack {
                        VolumeControlView()
                        Text("轻触后滑动数码表冠")
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("声音")
                }
                Section {
                    Picker("播放倍速", selection: $playbackSpeed) {
                        Text("0.5x").tag(0.5)
                        Text("0.75x").tag(0.75)
                        Text("1x").tag(1.0)
                        Text("1.5x").tag(1.5)
                        Text("2x").tag(2.0)
                        Text("3x").tag(3.0)
                        Text("5x").tag(5.0)
                    }
                    .onChange(of: playbackSpeed) { value in
                        player.rate = Float(value)
                    }
                    // rdar://FB26800207937
                    TextField("跳转到...(秒)", text: $jumpToInput) {
                        if let jt = Double(jumpToInput) {
                            player.seek(to: CMTime(seconds: jt, preferredTimescale: 1))
                        }
                        jumpToInput = ""
                    }
                    Button(action: {
                        player.seek(to: CMTime(seconds: currentTime + 10, preferredTimescale: 60000))
                    }, label: {
                        Label("快进 10 秒", systemImage: "goforward.10")
                    })
                    Button(action: {
                        player.seek(to: CMTime(seconds: currentTime - 10, preferredTimescale: 60000))
                    }, label: {
                        Label("快退 10 秒", systemImage: "gobackward.10")
                    })
                } header: {
                    Text("播放")
                }
            }
            .tag(2)
        }
        .navigationBarHidden(true)
        .scrollIndicators(.never)
        .onAppear {
            let asset = AVURLAsset(
                url: URL(string: link)!,
                options: [
                    "AVURLAssetHTTPHeaderFieldsKey": [
                        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
                    ]
                ]
            )
            let item = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: item)
            if ((UserDefaults.standard.object(forKey: "CCIsContinuityMediaEnabled") as? Bool) ?? true)
                && (link.hasPrefix("http://") || link.hasPrefix("https://")) {
                globalMediaUserActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                globalMediaUserActivity?.isEligibleForHandoff = true
                globalMediaUserActivity?.webpageURL = URL(string: link)!
                globalMediaUserActivity?.becomeCurrent()
            }
        }
        .onDisappear {
            player.pause()
            if (UserDefaults.standard.object(forKey: "CCIsContinuityMediaEnabled") as? Bool) ?? true {
                globalMediaUserActivity?.invalidate()
            }
        }
        .onReceive(player.periodicTimePublisher()) { time in
            currentTime = time.seconds
        }
        .onReceive(player.publisher(for: \.timeControlStatus)) { status in
            if _slowPath(status != cachedPlayerTimeControlStatus) {
                if status == .playing {
                    player.rate = Float(playbackSpeed)
                }
                cachedPlayerTimeControlStatus = status
            }
        }
    }
}

struct MediaDownloadView: View {
    @Binding var mediaLink: String
    var mediaTypeName: LocalizedStringKey
    var saveFolderName: String
    @Binding var saveFileName: String?
    @Environment(\.dismiss) var dismiss
    @AppStorage("DLIsFeedbackWhenFinish") var isFeedbackWhenFinish = false
    @State var downloadProgress = ValuedProgress(completedUnitCount: 0, totalUnitCount: 0)
    @State var isFinishedDownload = false
    @State var isTerminateDownloadingAlertPresented = false
    @State var errorText = ""
    @State var m3u8DownloadObservation: NSKeyValueObservation?
    @State var m3u8DownloadTimer: Timer?
    @State var m3u8DownloadedSize = 0.0
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Button(action: {
                            if !isFinishedDownload {
                                isTerminateDownloadingAlertPresented = true
                            } else {
                                dismiss()
                            }
                        }, label: {
                            Image(systemName: "xmark")
                                .bold()
                                .foregroundColor(.white)
                        })
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: 100))
                        .frame(width: 50, height: 50)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                Section {
                    if !isFinishedDownload {
                        VStack {
                            Text("正在下载...")
                                .font(.system(size: 20, weight: .bold))
                            if mediaLink.hasSuffix(".m3u8"), #available(watchOS 10, *) {
                                ProgressView()
                                Text("已下载 \(m3u8DownloadedSize ~ 2)MB")
                                Text("正在下载 M3U8 媒体，这可能需要较长时间，且暗礁浏览器无法报告进度。")
                            } else {
                                ProgressView(value: Double(downloadProgress.completedUnitCount), total: Double(downloadProgress.totalUnitCount))
                                Text("\((Double(downloadProgress.completedUnitCount) / Double(downloadProgress.totalUnitCount) * 100) ~ 2)%")
                                Text("\((Double(downloadProgress.completedUnitCount) / 1024 / 1024) ~ 2)MB / \((Double(downloadProgress.totalUnitCount) / 1024 / 1024) ~ 2)MB")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.1)
                                if let eta = downloadProgress.estimatedTimeRemaining {
                                    Text("预计时间：\(Int(eta))s")
                                }
                            }
                        }
                    } else {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("下载已完成")
                            Spacer()
                        }
                    }
                }
                if !errorText.isEmpty {
                    Section {
                        Text(errorText)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("下载\(mediaTypeName)")
            .toolbar(.hidden, for: .navigationBar)
            .alert("未完成的下载", isPresented: $isTerminateDownloadingAlertPresented, actions: {
                Button(role: .destructive, action: {
                    dismiss()
                }, label: {
                    Text("退出")
                })
                Button(role: .cancel, action: {
                    
                }, label: {
                    Text("取消")
                })
            }, message: {
                Text("退出下载页将中断下载\n确定吗？")
            })
        }
        .onAppear {
            extendScreenIdleTime(3600)
            do {
                if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)") {
                    try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)", withIntermediateDirectories: true)
                }
                if mediaLink.hasSuffix(".m3u8"), #available(watchOS 10, *) {
                    let configuration = URLSessionConfiguration.background(withIdentifier: "com.darock.WatchBrowser.download.m3u8")
                    let session = AVAssetDownloadURLSession(
                        configuration: configuration,
                        assetDownloadDelegate: M3U8DownloadDelegate.shared,
                        delegateQueue: .main
                    )
                    let asset = AVURLAsset(url: URL(string: mediaLink)!)
                    let downloadTask = session.makeAssetDownloadTask(downloadConfiguration: .init(asset: asset, title: ""))
                    M3U8DownloadDelegate.shared.finishDownloadingHandler = { _, _, location in
                        print(location)
                        do {
                            if let saveFileName {
                                if _fastPath(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName)")) {
                                    try FileManager.default.moveItem(atPath: location.path, toPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName)")
                                } else {
                                    var duplicateMarkNum = 1
                                    while FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName) (\(duplicateMarkNum))") {
                                        duplicateMarkNum++
                                    }
                                    try FileManager.default.moveItem(atPath: location.path, toPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName) (\(duplicateMarkNum))")
                                }
                            } else {
                                if _fastPath(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: ".")[0])).movpkg")) {
                                    try FileManager.default.moveItem(
                                        atPath: location.path,
                                        toPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: ".")[0])).movpkg"
                                    )
                                } else {
                                    var duplicateMarkNum = 1
                                    while FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: ".")[0])).movpkg (\(duplicateMarkNum))") {
                                        duplicateMarkNum++
                                    }
                                    try FileManager.default.moveItem(
                                        atPath: location.path,
                                        toPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: ".")[0])).movpkg (\(duplicateMarkNum))"
                                    )
                                }
                            }
                            isFinishedDownload = true
                            if isFeedbackWhenFinish {
                                WKInterfaceDevice.current().play(.success)
                            }
                        } catch {
                            errorText = String(localized: "下载时出错：") + error.localizedDescription
                            if isFeedbackWhenFinish {
                                WKInterfaceDevice.current().play(.failure)
                            }
                            globalErrorHandler(error)
                        }
                    }
                    downloadTask.priority = 1.0
                    
                    let libFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Library")
                    var libMediaFolderName = ""
                    for file in libFiles where file.hasPrefix("com.apple.UserManagedAssets.") {
                        libMediaFolderName = file
                        break
                    }
                    if !libMediaFolderName.isEmpty {
                        let previousFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Library/\(libMediaFolderName)")
                        m3u8DownloadTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                            do {
                                let currentFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Library/\(libMediaFolderName)")
                                if _fastPath(currentFiles.count > previousFiles.count) {
                                    if let newFlie = currentFiles.filter({ !previousFiles.contains($0) }).first {
                                        let newFileSize = Double(try folderSize(
                                            atPath: NSHomeDirectory() + "/Library/\(libMediaFolderName)/\(newFlie)"
                                        ) ?? 0) / 1024.0 / 1024.0
                                        m3u8DownloadedSize = newFileSize
                                    }
                                }
                            } catch {
                                // Don't insert globalErrorHandler because it's in a timer.
                                print(error)
                            }
                        }
                    }
                    
                    downloadTask.resume()
                    m3u8DownloadObservation = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
                        downloadProgress = ValuedProgress(completedUnitCount: progress.completedUnitCount,
                                                          totalUnitCount: progress.totalUnitCount,
                                                          estimatedTimeRemaining: progress.estimatedTimeRemaining)
                    }
                } else {
                    let destination: DownloadRequest.Destination = { _, _ in
                        if let saveFileName {
                            if _fastPath(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName)")) {
                                return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName)"),
                                        [.removePreviousFile, .createIntermediateDirectories])
                            } else {
                                var duplicateMarkNum = 1
                                while FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName) (\(duplicateMarkNum))") {
                                    duplicateMarkNum++
                                }
                                return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName) (\(duplicateMarkNum))"),
                                        [.removePreviousFile, .createIntermediateDirectories])
                            }
                        } else {
                            if _fastPath(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: "?")[0]))")) {
                                return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: "?")[0]))"),
                                        [.removePreviousFile, .createIntermediateDirectories])
                            } else {
                                var duplicateMarkNum = 1
                                while FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: "?")[0])) (\(duplicateMarkNum))") {
                                    duplicateMarkNum++
                                }
                                return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: "?")[0])) (\(duplicateMarkNum))"),
                                        [.removePreviousFile, .createIntermediateDirectories])
                            }
                        }
                    }
                    AF.download(mediaLink, to: destination)
                        .downloadProgress { progress in
                            downloadProgress = ValuedProgress(completedUnitCount: progress.completedUnitCount,
                                                              totalUnitCount: progress.totalUnitCount,
                                                              estimatedTimeRemaining: progress.estimatedTimeRemaining)
                        }
                        .response { result in
                            if result.error == nil, let filePath = result.fileURL?.path {
                                debugPrint(filePath)
                                isFinishedDownload = true
                                if isFeedbackWhenFinish {
                                    WKInterfaceDevice.current().play(.success)
                                }
                            } else {
                                if let et = result.error?.localizedDescription {
                                    errorText = String(localized: "下载时出错：") + et
                                }
                                if isFeedbackWhenFinish {
                                    WKInterfaceDevice.current().play(.failure)
                                }
                            }
                        }
                }
            } catch {
                globalErrorHandler(error)
            }
        }
        .onDisappear {
            recoverNormalIdleTime()
            m3u8DownloadObservation?.invalidate()
            m3u8DownloadTimer?.invalidate()
        }
    }
    
    func folderSize(atPath path: String) throws -> UInt64? {
        let fileManager = FileManager.default
        guard let files = fileManager.enumerator(atPath: path) else {
            return nil
        }
        
        var totalSize: UInt64 = 0
        
        for case let file as String in files {
            let filePath = "\(path)/\(file)"
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            if let fileSize = attributes[.size] as? UInt64 {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
}

struct LocalVideosView: View {
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLocalVideos") var usePasscodeForLocalVideos = false
    @AppStorage("IsThisClusterInstalled") var isThisClusterInstalled = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var videoNames = [String]()
    @State var videoHumanNameChart = [String: String]()
    @State var isPlayerPresented = false
    @State var willPlayVideoLink = ""
    @State var isEditNamePresented = false
    @State var editNameVideoName = ""
    @State var editNameInput = ""
    var body: some View {
        if isLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLocalVideos {
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
                    if !videoNames.isEmpty {
                        ForEach(0..<videoNames.count, id: \.self) { i in
                            Button(action: {
                                willPlayVideoLink = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/DownloadedVideos/" + videoNames[i]).absoluteString
                                isPlayerPresented = true
                            }, label: {
                                Text(videoHumanNameChart[videoNames[i]] ?? videoNames[i])
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    do {
                                        try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/" + videoNames[i])
                                        videoNames.remove(at: i)
                                    } catch {
                                        globalErrorHandler(error)
                                    }
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                                Button(action: {
                                    editNameVideoName = videoNames[i]
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
                                                atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/" + videoNames[i],
                                                toPath: containerFilePath
                                            )
                                            let saveFileName = videoNames[i].hasSuffix(".mp4") ? videoNames[i] : videoNames[i] + ".mp4"
                                            WKExtension.shared().openSystemURL(URL(string: "https://darock.top/cluster/add/\(saveFileName)")!)
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
            .navigationTitle("本地视频")
            .sheet(isPresented: $isPlayerPresented, content: { VideoPlayingView(link: $willPlayVideoLink) })
            .sheet(isPresented: $isEditNamePresented) {
                NavigationStack {
                    List {
                        Section {
                            TextField("名称", text: $editNameInput, style: "field-page")
                            Button(action: {
                                videoHumanNameChart.updateValue(editNameInput, forKey: editNameVideoName)
                                UserDefaults.standard.set(videoHumanNameChart, forKey: "VideoHumanNameChart")
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
                    videoNames = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos")
                    videoHumanNameChart = (UserDefaults.standard.dictionary(forKey: "VideoHumanNameChart") as? [String: String]) ?? [String: String]()
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
    }
}

struct ValuedProgress {
    var completedUnitCount: Int64
    var totalUnitCount: Int64
    var estimatedTimeRemaining: TimeInterval?
}

@available(watchOS 10.0, *)
private class M3U8DownloadDelegate: NSObject, AVAssetDownloadDelegate {
    static let shared = M3U8DownloadDelegate(finishDownloadingHandler: { _, _, _ in })
    
    var finishDownloadingHandler: (URLSession, AVAssetDownloadTask, URL) -> Void
    
    init(finishDownloadingHandler: @escaping (URLSession, AVAssetDownloadTask, URL) -> Void) {
        self.finishDownloadingHandler = finishDownloadingHandler
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        finishDownloadingHandler(session, assetDownloadTask, location)
    }
}
