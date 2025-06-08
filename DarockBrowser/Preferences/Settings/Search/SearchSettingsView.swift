//
//  SearchSettingsView.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import DarockUI

extension SettingsView {
    struct SearchSettingsView: View {
        @AppStorage("WebSearch") var webSearch = "必应"
        @AppStorage("IsLongPressAlternativeSearch") var isLongPressAlternativeSearch = false
        @AppStorage("AlternativeSearch") var alternativeSearch = "必应"
        @AppStorage("AllowCookies") var allowCookies = true
        @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
        @State var customSearchEngineList = [String]()
        let engineTitle = [
            "必应": String(localized: "Search.bing"),
            "百度": String(localized: "Search.baidu"),
            "谷歌": String(localized: "Search.google"),
            "搜狗": String(localized: "Search.sougou")
        ]
        var body: some View {
            List {
                Section {
                    Picker(selection: $webSearch, label: Text(isSearchEngineShortcutEnabled ? "默认搜索引擎" : "Settings.search.engine")) {
                        ForEach(EngineNames.allCases, id: \.self) { engineNames in
                            Text(engineTitle[engineNames.rawValue]!).tag(engineNames.rawValue)
                        }
                        if customSearchEngineList.count != 0 {
                            ForEach(0..<customSearchEngineList.count, id: \.self) { i in
                                Text(
                                    customSearchEngineList[i]
                                        .replacingOccurrences(of: "%lld", with: String(localized: "Settings.search.customize.search-content"))
                                )
                                .tag(customSearchEngineList[i])
                            }
                        }
                    }
                    Toggle("长按搜索按钮使用次要搜索引擎", isOn: $isLongPressAlternativeSearch)
                    if isLongPressAlternativeSearch {
                        Picker(selection: $alternativeSearch, label: Text("次要搜索引擎")) {
                            ForEach(EngineNames.allCases, id: \.self) { engineNames in
                                Text(engineTitle[engineNames.rawValue]!).tag(engineNames.rawValue)
                            }
                            if customSearchEngineList.count != 0 {
                                ForEach(0..<customSearchEngineList.count, id: \.self) { i in
                                    Text(
                                        customSearchEngineList[i]
                                            .replacingOccurrences(of: "%lld", with: String(localized: "Settings.search.customize.search-content"))
                                    )
                                    .tag(customSearchEngineList[i])
                                }
                            }
                        }
                    }
                    if webSearch == "谷歌" && !allowCookies {
                        NavigationLink(destination: { PrivacySettingsView() }, label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("可能需要允许 Cookies 以使“谷歌”搜索引擎正常工作")
                                        .font(.system(size: 14))
                                    Text("前往“隐私与安全性”设置")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.forward")
                                    .foregroundColor(.gray)
                            }
                        })
                    }
                }
                Section {
                    NavigationLink(destination: { CustomSearchEngineSettingsView() }, label: {
                        Text("管理自定搜索引擎…")
                    })
                    NavigationLink(destination: { SearchEngineShortcutSettingsView() }, label: {
                        Text("搜索引擎快捷方式…")
                    })
                }
            }
            .navigationTitle("搜索")
            .onAppear {
                customSearchEngineList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
            }
        }
    }
}

private enum EngineNames: String, CaseIterable {
    case bing = "必应"
    case baidu = "百度"
    case google = "谷歌"
    case sougou = "搜狗"
}
