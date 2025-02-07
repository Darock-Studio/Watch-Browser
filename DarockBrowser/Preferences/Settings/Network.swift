//
//  Network.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI

extension SettingsView {
    struct NetworkSettingsView: View {
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { NetworkCheckView() }, label: { SettingItemLabel(title: "网络检查", image: "checkmark", color: .green) })
                }
            }
            .navigationTitle("网络")
        }
    }
}
