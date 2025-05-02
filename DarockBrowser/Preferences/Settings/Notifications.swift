//
//  Notifications.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/5/2.
//

import SwiftUI

extension SettingsView {
    struct NotificationsSettingsView: View {
        @AppStorage("NFIsNotificationsFromDarockAllowed") var isNotificationsFromDarockAllowed = true
        var body: some View {
            List {
                Section {} footer: {
                    Text("在系统设置中允许来自暗礁浏览器的通知，随后在此处管理。")
                }
                Section {
                    Toggle("接收来自 Darock 的通知推送", isOn: $isNotificationsFromDarockAllowed)
                        .onChange(of: isNotificationsFromDarockAllowed) { _ in
                            WKApplication.shared().registerForRemoteNotifications()
                        }
                }
            }
            .navigationTitle("通知")
        }
    }
}
