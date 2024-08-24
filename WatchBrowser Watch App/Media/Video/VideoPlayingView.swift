//
//  VideoPlayingView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import AVKit
import SwiftUI
import DarockKit
import AVFoundation

struct VideoPlayingView: View {
    @Binding var link: String
    @State var player: AVPlayer! = AVPlayer()
    @State var playbackSpeed = 1.0
    @State var isFullScreen = false
    @State var mainTabViewSelection = 1
    @State var jumpToInput = ""
    @State var currentTime = 0.0
    @State var playerScale: CGFloat = 1.0
    @State var __playerScale = 1.0
    @State var playerScaledOffset = CGSizeZero
    @State var playerScaledLastOffset = CGSizeZero
    @State var cachedPlayerTimeControlStatus = AVPlayer.TimeControlStatus.paused
    @State var videoMarks = [[String: String]]()
    @State var editVideoMarkNameIndex: Int?
    @State var editVideoMarkNameInput = ""
    var body: some View {
        TabView(selection: $mainTabViewSelection) {
            ZStack {
                VideoPlayer(player: player)
                    .rotationEffect(.degrees(isFullScreen ? 90 : 0))
                    .frame(
                        width: isFullScreen ? WKInterfaceDevice.current().screenBounds.height : nil,
                        height: isFullScreen ? WKInterfaceDevice.current().screenBounds.width : nil
                    )
                    .offset(y: isFullScreen ? 20 : 0)
                    .scaleEffect(playerScale)
                    .ignoresSafeArea()
                    .offset(playerScaledOffset)
                    .dragGestureByPlayerScale($playerScale, offset: $playerScaledOffset, lastOffset: $playerScaledLastOffset)
                if cachedPlayerTimeControlStatus == .paused {
                    VStack {
                        ZStack {
                            Color.accentColor // For tap gesture
                                .frame(width: 60, height: 40)
                                .opacity(0.0100000002421438702673861521)
                            HStack(spacing: 2) {
                                Image(systemName: "rectangle.portrait.arrowtriangle.2.outward")
                                    .shadow(color: .accentColor, radius: 1)
                                Text(String(__playerScale))
                                    .shadow(color: .accentColor, radius: 1)
                            }
                            .font(.system(size: 14))
                        }
                        .onTapGesture {
                            if __playerScale < 10.0 {
                                __playerScale += 1.0
                                playerScale += 1.0
                            } else {
                                __playerScale = 1.0
                                playerScale = 1.0
                                playerScaledOffset = CGSizeZero
                                playerScaledLastOffset = CGSizeZero
                            }
                        }
                        Spacer()
                    }
                    .ignoresSafeArea()
                }
            }
            .animation(.smooth, value: cachedPlayerTimeControlStatus)
            .animation(.smooth, value: playerScale)
            .animation(.smooth, value: __playerScale)
            .scrollIndicators(.never)
            ._statusBarHidden(true)
            .tag(1)
            List {
                Section {
                    Button(action: {
                        isFullScreen.toggle()
                        mainTabViewSelection = 1
                    }, label: {
                        Label(
                            isFullScreen ? "恢复" : "全屏",
                            systemImage: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
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
                        player.play()
                    }, label: {
                        Label("快进 10 秒", systemImage: "goforward.10")
                    })
                    Button(action: {
                        player.seek(to: CMTime(seconds: currentTime - 10, preferredTimescale: 60000))
                        player.play()
                    }, label: {
                        Label("快退 10 秒", systemImage: "gobackward.10")
                    })
                } header: {
                    Text("播放")
                }
                Section {
                    Button(action: {
                        videoMarks.append(["Time": "\(Int(currentTime))"])
                        
                    }, label: {
                        Label("在当前播放时间添加", systemImage: "bookmark.fill")
                    })
                    if !videoMarks.isEmpty {
                        ForEach(0..<videoMarks.count, id: \.self) { i in
                            Button(action: {
                                player.seek(to: CMTime(seconds: Double(Int(videoMarks[i]["Time"]!)!), preferredTimescale: 60000))
                                player.play()
                                mainTabViewSelection = 1
                            }, label: {
                                VStack(alignment: .leading) {
                                    Text("跳转到")
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                    Text(videoMarks[i]["Name"] ?? String(localized: "\(Int(videoMarks[i]["Time"]!)!)秒"))
                                }
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    videoMarks.remove(at: i)
                                }, label: {
                                    Image(systemName: "xmark.circle.fill")
                                })
                                Button(action: {
                                    editVideoMarkNameIndex = i
                                }, label: {
                                    Image(systemName: "pencil.line")
                                })
                            }
                        }
                        .onMove { source, destination in
                            videoMarks.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                } header: {
                    Text("视频书签")
                }
                .onChange(of: videoMarks) { _ in
                    UserDefaults.standard.set(videoMarks, forKey: "VideoMarkForLink\(link.md5.prefix(16))")
                }
            }
            .tag(2)
            .sheet(item: $editVideoMarkNameIndex) { index in
                NavigationStack {
                    List {
                        HStack {
                            Spacer()
                            Text("自定义名称")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        TextField("名称", text: $editVideoMarkNameInput, style: "field-page")
                        Button(action: {
                            videoMarks[index].updateValue(editVideoMarkNameInput, forKey: "Name")
                            editVideoMarkNameIndex = nil
                        }, label: {
                            HStack {
                                Spacer()
                                Label("完成", systemImage: "checkmark")
                                Spacer()
                            }
                        })
                    }
                }
                .onAppear {
                    editVideoMarkNameInput = videoMarks[index]["Name"] ?? ""
                }
            }
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
            player.seek(
                to: CMTime(seconds: Double(UserDefaults.standard.integer(forKey: "VideoProgressForLink\(link.md5.prefix(16))")), preferredTimescale: 60000)
            )
            setForAudioPlaying()
            videoMarks = (UserDefaults.standard.array(forKey: "VideoMarkForLink\(link.md5.prefix(16))") as? [[String: String]]) ?? []
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
            UserDefaults.standard.set(Int(currentTime), forKey: "VideoProgressForLink\(link.md5.prefix(16))")
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

private extension View {
    @ViewBuilder
    func dragGestureByPlayerScale(_ scale: Binding<CGFloat>, offset: Binding<CGSize>, lastOffset: Binding<CGSize>) -> some View {
        if scale.wrappedValue != 1.0 {
            self.gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset.wrappedValue = CGSize(
                            width: gesture.translation.width + lastOffset.wrappedValue.width,
                            height: gesture.translation.height + lastOffset.wrappedValue.height
                        )
                    }
                    .onEnded { _ in
                        lastOffset.wrappedValue = offset.wrappedValue
                    }
            )
        } else {
            self
        }
    }
}
