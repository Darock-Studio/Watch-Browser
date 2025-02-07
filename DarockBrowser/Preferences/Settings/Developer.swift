//
//  Developer.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI

extension SettingsView {
    struct DeveloperSettingsView: View {
        @AppStorage("CustomUserAgent") var customUserAgent = ""
        @AppStorage("DTIsAllowWebInspector") var isAllowWebInspector = false
        var body: some View {
            List {
                Section {
                    Picker("User Agent", selection: $customUserAgent) {
                        Section {
                            Text("默认")
                                .tag("")
                        }
                        Section {
                            Text(verbatim: "Safari 18.0")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15")
                            Text(verbatim: "Safari - iOS 17.4 - iPhone")
                                .tag(
                                    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
                                )
                            Text(verbatim: "Safari - iPadOS 17.4 - iPad mini")
                                .tag(
                                    "Mozilla/5.0 (iPad; CPU OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
                                )
                            Text(verbatim: "Safari - iPadOS 17.4 - iPad")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15")
                        }
                        Section {
                            Text(verbatim: "Microsoft Edge - macOS")
                                .tag(
                                    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
                                )
                            Text(verbatim: "Microsoft Edge - Windows")
                                .tag(
                                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
                                )
                        }
                        Section {
                            Text(verbatim: "Google Chrome - macOS")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                            Text(verbatim: "Google Chrome - Windows")
                                .tag("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                        }
                        Section {
                            Text(verbatim: "Firefox - macOS")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0")
                            Text(verbatim: "Firefox - Windows")
                                .tag("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0")
                        }
                    }
                } footer: {
                    Text("除非设置为默认，此处设置的值将覆盖\(Text("浏览引擎->请求桌面网站").bold().foregroundColor(.blue))设置")
                }
                Section {
                    Toggle("网页检查器", isOn: $isAllowWebInspector)
                } footer: {
                    Text("若要使用网页检查器，通过线缆将此 Apple Watch 配对的 iPhone 与 Mac 连接，在 Safari 的“开发”菜单中访问此 Apple Watch。你可以在 Safari 设置中的“高级”选项卡中打开开发菜单。")
                }
            }
            .navigationTitle("开发者")
        }
    }
}
