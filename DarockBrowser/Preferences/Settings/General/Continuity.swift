//
//  Continuity.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import DarockUI

extension SettingsView.GeneralSettingsView {
    struct ContinuityView: View {
        @AppStorage("CCIsHandoffEnabled") var isHandoffEnabled = true
        @AppStorage("CCIsContinuityMediaEnabled") var isContinuityMediaEnabled = true
        var body: some View {
            List {
                Section {
                    Toggle("接力", isOn: $isHandoffEnabled)
                } footer: {
                    Text("接力让你能够快速在另一设备上继续浏览暗礁浏览器中的网页。在暗礁浏览器浏览网页时，带有 Apple Watch 角标的 Safari 图标会出现在 iPhone 的 App 切换器或 iPad 和 Mac 的 Dock 栏中。")
                }
                Section {
                    Toggle("连续互通媒体", isOn: $isContinuityMediaEnabled)
                } footer: {
                    Text("在使用暗礁浏览器查看媒体时，可在其他设备上继续查看媒体。")
                }
            }
            .navigationTitle("连续互通")
        }
    }
}
