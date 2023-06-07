//
//  SettingsView.swift
//  WatchBrowser Watch App
//
//  Created by WindowsMEMZ on 2023/6/6.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("IsUseModifyKeyboard") var isUseModifyKeyboard = true
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @State var isKeyboardPresented = false
    @State var isCookieTipPresented = false
    @Namespace var namespace
    enum EngineNames: String, CaseIterable {
        case bing = "必应"
        case baidu = "百度"
        case google = "谷歌"
        case sougou = "搜狗"
    }
    var body: some View {
        if #available(watchOS 10.0, *) {
            NavigationStack {
                #if FOR_NEW_OS
                TabView {
                    Group {
                        List {
                            Section {
                                Picker(selection: $webSearch, label: Text(webSearch)) {
                                    ForEach(EngineNames.allCases, id: \.self) {EngineNames in
                                        Text(EngineNames.rawValue).tag(EngineNames.rawValue)
                                    }
                                }
                                .navigationTitle("搜索引擎")
                                .navigationBarTitleDisplayMode(.inline)
                            }
                            Section {
                                HStack {
                                    Image(systemName: "magnifyingglass.circle.fill")
                                    Text("任意挑选适合的搜索引擎")
                                }
                            }
                        }
                    }
                    .tag(1)
                    Group {
                        List {
                            Section {
                                Toggle(isOn: $isUseModifyKeyboard) {
                                    Text("使用自定义键盘")
                                }
                            }
                            Section {
                                HStack {
                                    Image(systemName: "keyboard")
                                    Text("Darock 为您提供了由我们开发的键盘，即使您的 Apple Watch 不支持使用键盘输入也能轻松键入网址")
                                }
                                Button(action: {
                                    isKeyboardPresented = true
                                }, label: {
                                    Text("尝试一下？")
                                })
                                .sheet(isPresented: $isKeyboardPresented, content: {
                                    ExtKeyboardView(startText: "") { _ in }
                                })
                            }
                        }
                        .navigationTitle("自定义键盘")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .tag(2)
                    Group {
                        List {
                            Section {
                                Toggle(isOn: $isAllowCookie) {
                                    Text("使用 Cookie")
                                }
                            }
                            Section {
                                Text("网站使用 Cookie 保存账号登录信息等数据，但开启后每次访问网页前会出现提示")
                                Text("Darock 以及暗礁浏览器不会收集您的 Cookie 信息，所有信息均由 watchOS 处理")
                            }
                        }
                        .navigationTitle("Cookie")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .tag(3)
                }
                .tabViewStyle(.verticalPage)
                #else
                List {
                    Picker(selection: $webSearch, label: Text("搜索引擎")) {
                        ForEach(EngineNames.allCases, id: \.self) {EngineNames in
                            Text(EngineNames.rawValue).tag(EngineNames.rawValue)
                        }
                    }
                    Toggle(isOn: $isUseModifyKeyboard) {
                        Text("使用自定义键盘")
                    }
                    Toggle(isOn: $isAllowCookie) {
                        Text("使用Cookie")
                    }
                    .onChange(of: isAllowCookie) { value in
                        if value {
                            isCookieTipPresented = true
                        }
                    }
                    .sheet(isPresented: $isCookieTipPresented, content: {
                        CookieTip()
                    })
                }
                #endif
            }
        } else {
            NavigationView {
                List {
                    Picker(selection: $webSearch, label: Text("搜索引擎")) {
                        ForEach(EngineNames.allCases, id: \.self) {EngineNames in
                            Text(EngineNames.rawValue).tag(EngineNames.rawValue)
                        }
                    }
                    Toggle(isOn: $isUseModifyKeyboard) {
                        Text("使用自定义键盘")
                    }
                    Toggle(isOn: $isAllowCookie) {
                        Text("使用Cookie")
                    }
                    .onChange(of: isAllowCookie) { value in
                        if value {
                            isCookieTipPresented = true
                        }
                    }
                    .sheet(isPresented: $isCookieTipPresented, content: {
                        CookieTip()
                    })
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

