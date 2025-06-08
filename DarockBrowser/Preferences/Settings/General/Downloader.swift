//
//  Downloader.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import DarockUI

extension SettingsView.GeneralSettingsView {
    struct DownloaderView: View {
        @AppStorage("DLIsFeedbackWhenFinish") var isFeedbackWhenFinish = false
        var body: some View {
            List {
                Section {
                    Toggle("完成后提醒", isOn: $isFeedbackWhenFinish)
                }
            }
            .navigationTitle("下载器")
        }
    }
}
