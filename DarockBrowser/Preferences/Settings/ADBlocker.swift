//
//  ADBlocker.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/4/3.
//

import DarockUI

extension SettingsView {
    struct ADBlockerSettingsView: View {
        @AppStorage("IsProPurchased") var isProPurchased = false
        @AppStorage("ADBIsAdBlockEnabled") var isAdBlockEnabled = false
        var body: some View {
            if isProPurchased {
                List {
                    Section {} footer: {
                        Text("暗礁浏览器能够自动屏蔽网页中的广告，所有内容均在本地处理。")
                    }
                    Section {
                        Toggle("广告屏蔽", isOn: $isAdBlockEnabled)
                    }
                }
                .navigationTitle("广告屏蔽")
            } else {
                ProUnavailableView()
            }
        }
    }
}
