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
import AVFoundation

struct VideoListView: View {
    @State var willPlayVideoLink = ""
    @State var isPlayerPresented = false
    @State var willDownloadVideoLink = ""
    @State var isVideoDownloadPresented = false
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
                    }
                }
            }
            .navigationTitle("视频列表")
            .sheet(isPresented: $isPlayerPresented, content: { VideoPlayingView(link: $willPlayVideoLink) })
            .sheet(isPresented: $isVideoDownloadPresented, content: { VideoDownloadView(videoLink: $willDownloadVideoLink) })
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
    @State var player: AVPlayer!
    @State var playbackSpeed = 1.0
    @State var isFullScreen = false
    @State var mainTabViewSelection = 1
    @State var jumpToInput = ""
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
                .onChange(of: player?.timeControlStatus) { value in
                    if value == .playing {
                        player.rate = Float(playbackSpeed)
                    }
                }
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
//                    Button(action: {
//                        player.seek(to: CMTime(seconds: currentTime + 10, preferredTimescale: 1))
//                    }, label: {
//                        Label("快进 10 秒", systemImage: "goforward.10")
//                    })
//                    Button(action: {
//                        player.seek(to: CMTime(seconds: currentTime - 10, preferredTimescale: 1))
//                    }, label: {
//                        Label("快退 10 秒", systemImage: "gobackward.10")
//                    })
                } header: {
                    Text("播放")
                }
            }
            .tag(2)
        }
        .navigationBarHidden(true)
        .scrollIndicators(.never)
        .onAppear {
            player = AVPlayer(url: URL(string: link)!)
            if ((UserDefaults.standard.object(forKey: "CCIsContinuityMediaEnabled") as? Bool) ?? true) && (link.hasPrefix("http://") || link.hasPrefix("https://")) {
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
    }
}

struct VideoDownloadView: View {
    @Binding var videoLink: String
    @Environment(\.dismiss) var dismiss
    @State var downloadProgress = ValuedProgress(completedUnitCount: 0, totalUnitCount: 0)
    @State var isFinishedDownload = false
    @State var isTerminateDownloadingAlertPresented = false
    @State var errorText = ""
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
                            ProgressView(value: Double(downloadProgress.completedUnitCount), total: Double(downloadProgress.totalUnitCount))
                            Text("\(String(format: "%.2f", Double(downloadProgress.completedUnitCount) / Double(downloadProgress.totalUnitCount) * 100))%")
                            Text("\(String(format: "%.2f", Double(downloadProgress.completedUnitCount) / 1024 / 1024))MB / \(String(format: "%.2f", Double(downloadProgress.totalUnitCount) / 1024 / 1024))MB")
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                            if let eta = downloadProgress.estimatedTimeRemaining {
                                Text("预计时间：\(Int(eta))s")
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
            .navigationTitle("下载视频")
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
            extendScreenIdleTime(600)
            do {
                if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos") {
                    try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos", withIntermediateDirectories: true)
                }
                let destination: DownloadRequest.Destination = { _, _ in
                    return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/DownloadedVideos/\(String(videoLink.split(separator: "/").last!.split(separator: ".mp4?")[0])).mp4"),
                            [.removePreviousFile, .createIntermediateDirectories])
                }
                AF.download(videoLink, to: destination)
                    .downloadProgress { progress in
                        downloadProgress = ValuedProgress(completedUnitCount: progress.completedUnitCount,
                                                          totalUnitCount: progress.totalUnitCount,
                                                          estimatedTimeRemaining: progress.estimatedTimeRemaining)
                    }
                    .response { result in
                        if result.error == nil, let filePath = result.fileURL?.path {
                            debugPrint(filePath)
                            isFinishedDownload = true
                        } else {
                            if let et = result.error?.localizedDescription {
                                errorText = String(localized: "下载时出错：") + et
                            }
                        }
                    }
            } catch {
                globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
            }
        }
        .onDisappear {
            recoverNormalIdleTime()
        }
    }
}

struct LocalVideosView: View {
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLocalVideos") var usePasscodeForLocalVideos = false
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
                                        globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
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
                            TextField("名称", text: $editNameInput)
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
                    globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
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
