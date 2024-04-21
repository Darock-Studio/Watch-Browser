//
//  VideoListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/21.
//

import AVKit
import SwiftUI
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
        } else {
            Text("空视频列表")
        }
    }
}

struct VideoPlayingView: View {
    @Binding var link: String
    var body: some View {
        VideoPlayer(player: AVPlayer(url: URL(string: link)!))
            .ignoresSafeArea()
    }
}

#Preview {
    VideoListView()
}
