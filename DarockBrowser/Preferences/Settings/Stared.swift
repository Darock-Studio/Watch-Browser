//
//  Stared.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import DarockUI

extension SettingsView {
    struct StaredSettingsView: View {
        @AppStorage("RequestDesktopWeb") var requestDesktopWeb = false
        @AppStorage("ForceApplyDarkMode") var forceApplyDarkMode = false
        var body: some View {
            List {
                Section {
                    Toggle(isOn: $forceApplyDarkMode) {
                        HStack {
                            Image(systemName: "rectangle.inset.filled")
                                .foregroundStyle(.gray.gradient)
                            Text("强制深色模式")
                        }
                    }
                    Toggle(isOn: $requestDesktopWeb) {
                        HStack {
                            Image(systemName: "desktopcomputer")
                                .foregroundStyle(.blue.gradient)
                            Text("请求桌面网站")
                        }
                    }
                }
            }
            .navigationTitle("常用设置")
        }
    }
}
