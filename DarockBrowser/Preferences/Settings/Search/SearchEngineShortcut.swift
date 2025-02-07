//
//  SearchEngineShortcut.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI

extension SettingsView.SearchSettingsView {
    struct SearchEngineShortcutSettingsView: View {
        @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
        var body: some View {
            List {
                Section {
                    Toggle(isOn: $isSearchEngineShortcutEnabled, label: {
                        Text("Settings.search.shortcut.enable")
                    })
                } footer: {
                    Text("Settings.search.shortcut.discription")
                }
                if isSearchEngineShortcutEnabled {
                    Section {
                        HStack {
                            Text("Search.bing")
                            Spacer()
                            Text("bing")
                                .font(.system(size: 15).monospaced())
                        }
                        HStack {
                            Text("Search.baidu")
                            Spacer()
                            Text("baidu")
                                .font(.system(size: 15).monospaced())
                        }
                        HStack {
                            Text("Search.google")
                            Spacer()
                            Text("google")
                                .font(.system(size: 15).monospaced())
                        }
                        HStack {
                            Text("Search.sougou")
                            Spacer()
                            Text("sogou")
                                .font(.system(size: 15).monospaced())
                        }
                    }
                }
            }
            .navigationTitle("Settings.search.shorcut")
        }
    }
}
