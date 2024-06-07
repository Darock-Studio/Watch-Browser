//
//  VideoListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/21.
//

import AVKit
import SwiftUI
import Dynamic
import AVFoundation

struct VideoListView: View {
    @State var willPlayVideoLink = ""
    @State var isPlayerPresented = false
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
                }
            }
            .navigationTitle("视频列表")
            .sheet(isPresented: $isPlayerPresented, content: { VideoPlayingView(link: $willPlayVideoLink) })
            .onDisappear {
                Dynamic.UIApplication.sharedApplication.keyWindow.rootViewController.presentViewController(
                    AdvancedWebViewController.shared.vc,
                    animated: true,
                    completion: nil
                )
                AdvancedWebViewController.shared.registerVideoCheckTimer()
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
                    TextField("跳转到...(秒)", text: $jumpToInput) // rdar://FB26800207937
                        .onSubmit {
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
        .onAppear {
            player = AVPlayer(url: URL(string: link)!)
        }
    }
}

#Preview {
    VideoListView()
}
