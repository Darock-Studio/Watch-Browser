//
//  MusicPlayer.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import DarockUI
import AVFoundation

extension SettingsView.GeneralSettingsView {
    struct MusicPlayerView: View {
        @AppStorage("MPIsShowTranslatedLyrics") var isShowTranslatedLyrics = true
        @AppStorage("MPBackgroundPlay") var isAllowBackgroundPlay = false
        var body: some View {
            List {
                Section {
                    Toggle("显示翻译歌词", isOn: $isShowTranslatedLyrics)
                }
                Section {
                    Toggle("允许后台播放", isOn: $isAllowBackgroundPlay)
                        .onChange(of: isAllowBackgroundPlay) { _ in
                            if !isAllowBackgroundPlay {
                                try? AVAudioSession.sharedInstance().setActive(false)
                            }
                        }
                } footer: {
                    if WKInterfaceDevice.modelName != "Apple Watch" {
                        // Apple Watch Series 10
                        if ["Watch7,8", "Watch7,9", "Watch7,10", "Watch7,11"].contains(WKInterfaceDevice.modelIdentifier) {
                            Text("你的设备无需连接蓝牙音频设备即可在后台播放音频。")
                        } else {
                            Text("若要在后台播放，你的设备需要在播放前连接蓝牙音频设备。")
                        }
                    } else {
                        Text("若要在后台播放，你可能需要在播放前连接蓝牙音频设备。")
                    }
                }
            }
            .navigationTitle("音乐播放器")
        }
    }
}
