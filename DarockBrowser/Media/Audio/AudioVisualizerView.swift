//
//  AudioVisualizerView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import DarockUI

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
