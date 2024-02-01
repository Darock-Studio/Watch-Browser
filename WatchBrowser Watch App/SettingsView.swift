//
//  SettingsView.swift
//  WatchBrowser Watch App
//
//  Created by WindowsMEMZ on 2023/6/6.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("Bing_API") var isUsingBingAPI = false
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("AllowCookies") var AllowCookies = false
    @AppStorage("ModifyKeyboard") var ModifyKeyboard = false
    @State var KeyboardChanged = false
    @State var isKeyboardPresented = false
    @State var isCookieTipPresented = false
    @Namespace var namespace
    @Environment(\.dismiss) var Dismiss
    enum EngineNames: String, CaseIterable {
        case bing = "必应"
        case baidu = "百度"
        case google = "谷歌"
        case sougou = "搜狗"
    }
    let engineTitle = [String(localized: "Search.bing"), String(localized: "Search.baidu"), String(localized: "Search.google"), String(localized: "Search.sougou")]
    var body: some View {
        if #available(watchOS 10.0, *) {
            NavigationStack {
                Form {
                    Section {
//                        Toggle(isOn: $isUsingBingAPI) {
//                            Text("使用Bing API搜索")
//                        }
                        Picker(selection: $webSearch, label: Text("Settings.search.engine")) {
                            ForEach(EngineNames.allCases, id:
                                        \.self) {EngineNames in
                                Text(EngineNames.rawValue).tag(EngineNames.rawValue)
                            }
                        }
                        //.disabled(isUsingBingAPI)
                    } header: {
                        Text("Settings.search")
                    }
                    .navigationTitle("Settings.search")
                    .navigationBarTitleDisplayMode(.inline)
                    
                    
                    
                    Section {
                        Toggle(isOn: $ModifyKeyboard) {
                            Text("Settings.keyboard.third-party")
                        }
                        Button(action: {
                            isKeyboardPresented = true
                        }, label: {
                            Label("Settings.keyboard.preview", systemImage: "keyboard.badge.eye")
                        })
                        .sheet(isPresented: $isKeyboardPresented, content: {
                            ExtKeyboardView(startText: "") { _ in }
                        })
                    } header: {
                        Text("Settings.keyboard")
                    } footer: {
                        Text("Settings.keyboard.discription")
                    }
                    .navigationTitle("Settings.keyboard")
                    .navigationBarTitleDisplayMode(.inline)
                    .onChange(of: ModifyKeyboard) {
//                        KeyboardChanged = true
                    }
                    .alert(isPresented: $KeyboardChanged) {
                        Alert(
                            title: Text("Settings.keyboard.alert.title"),
                            message: Text("Settings.keyboard.alert.details"),
                            primaryButton: .destructive(
                                Text("Settings.keyboard.alert.close-now"),
                                action: {
                                    exit(0)
                                }
                            ),
                            secondaryButton: .cancel(
                                Text("Settings.keyboard.alert.later"),
                                action: {
                                    Dismiss()
                                }
                            )
                        )
                    }
                    
                    
                    
                    Section {
                        Toggle(isOn: $AllowCookies) {
                            VStack(alignment: .leading) {
                                Text("Settings.cookies.allow")
                                Text("Settings.cookies.description")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                            }
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "hand.raised.fill")
                            Text("Settings.cookies.privacy")
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Settings.cookies.pop-up")
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "minus.diamond")
                            Text("Settings.cookies.limitation")
                        }
                    } header: {
                        Text("Settings.cookies")
                    }
                    .navigationTitle("Settings.cookies")
                    .navigationBarTitleDisplayMode(.inline)
                }
//                .tabViewStyle(.verticalPage)
            }
        } else {
            NavigationView {
                Form {
                    Section {
//                        Toggle(isOn: $isUsingBingAPI) {
//                            Text("使用Bing API搜索")
//                        }
                        Picker(selection: $webSearch, label: Text("Settings.search.engine")) {
                            ForEach(EngineNames.allCases, id: \.self) {EngineNames in
                                Text(EngineNames.rawValue).tag(EngineNames.rawValue)
                            }
                        }
                        .disabled(isUsingBingAPI)
                    } header: {
                        Text("Settings.search")
                    }
                    .navigationTitle("Settings.search")
                    .navigationBarTitleDisplayMode(.inline)
                    
                    
                    
                    Section {
                        Toggle(isOn: $ModifyKeyboard) {
                            Text("Settings.keyboard.third-party")
                        }
                        Button(action: {
                            isKeyboardPresented = true
                        }, label: {
                            Label("Settings.keyboard.preview", systemImage: "keyboard.badge.eye")
                        })
                        .sheet(isPresented: $isKeyboardPresented, content: {
                            ExtKeyboardView(startText: "") { _ in }
                        })
                    } header: {
                        Text("Settings.keyboard")
                    } footer: {
                        Text("Settings.keyboard.discription")
                    }
                    .navigationTitle("Settings.keyboard")
                    .navigationBarTitleDisplayMode(.inline)
//                    .onChange(of: ModifyKeyboard) {
//                        KeyboardChanged = true
//                    }
                    .alert(isPresented: $KeyboardChanged) {
                        Alert(
                            title: Text("Settings.keyboard.alert.title"),
                            message: Text("Settings.keyboard.alert.details"),
                            primaryButton: .destructive(
                                Text("Settings.keyboard.alert.close-now"),
                                action: {
                                    exit(0)
                                }
                            ),
                            secondaryButton: .cancel(
                                Text("Settings.keyboard.alert.later"),
                                action: {
                                    Dismiss()
                                }
                            )
                        )
                    }
                    
                    
                    
                    Section {
                        Toggle(isOn: $AllowCookies) {
                            VStack(alignment: .leading) {
                                Text("Settings.cookies.allow")
                                Text("Settings.cookies.description")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                            }
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "hand.raised.fill")
                            Text("Settings.cookies.privacy")
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Settings.cookies.pop-up")
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "minus.diamond")
                            Text("Settings.cookies.limitation")
                        }
                    } header: {
                        Text("Settings.cookies")
                    }
                    .navigationTitle("Settings.cookies")
                    .navigationBarTitleDisplayMode(.inline)
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

