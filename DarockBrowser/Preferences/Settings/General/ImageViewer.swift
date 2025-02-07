//
//  ImageViewer.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI

extension SettingsView.GeneralSettingsView {
    struct ImageViewerView: View {
        @AppStorage("IVUseDigitalCrownFor") var useDigitalCrownFor = "zoom"
        @AppStorage("MaxmiumScale") var maxmiumScale = 6.0
        var body: some View {
            List {
                Section {
                    Picker("将数码表冠用作", selection: $useDigitalCrownFor) {
                        Text("缩放")
                            .tag("zoom")
                        Text("切换")
                            .tag("switch")
                    }
                    if useDigitalCrownFor == "zoom" {
                        VStack {
                            Text("最大缩放倍数")
                            Slider(value: $maxmiumScale, in: 6.0...50.0, step: 0.5) {
                                EmptyView()
                            }
                            Text("\(String(format: "%.1f", maxmiumScale))x")
                        }
                    }
                }
            }
            .navigationTitle("图像查看器")
        }
    }
}
