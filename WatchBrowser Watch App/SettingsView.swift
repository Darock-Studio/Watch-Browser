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
    var body: some View {
        if #available(watchOS 10.0, *) {
            NavigationStack {
                #if swift(>=5.9)
                Form {
                    Section {
//                        Toggle(isOn: $isUsingBingAPI) {
//                            Text("使用Bing API搜索")
//                        }
                        Picker(selection: $webSearch, label: Text("搜索引擎")) {
                            ForEach(EngineNames.allCases, id: \.self) {EngineNames in
                                Text(EngineNames.rawValue).tag(EngineNames.rawValue)
                            }
                        }
                        .disabled(isUsingBingAPI)
                    } header: {
                        Text("搜索")
                    }
                    .navigationTitle("搜索")
                    .navigationBarTitleDisplayMode(.inline)
                    
                    
                    
                    Section {
                        Toggle(isOn: $ModifyKeyboard) {
                            Text("第三方全键盘")
                        }
                        Button(action: {
                            isKeyboardPresented = true
                        }, label: {
                            Label("预览…", systemImage: "keyboard.badge.eye")
                        })
                        .sheet(isPresented: $isKeyboardPresented, content: {
                            ExtKeyboardView(startText: "") { _ in }
                        })
                    } header: {
                        Text("键盘")
                    } footer: {
                        Text("该键盘为不支持系统全键盘的Watch开发了一套全键盘英文输入法")
                    }
                    .navigationTitle("键盘")
                    .navigationBarTitleDisplayMode(.inline)
                    .onChange(of: ModifyKeyboard) {
//                        KeyboardChanged = true
                    }
                    .alert(isPresented: $KeyboardChanged) {
                        Alert(
                            title: Text("直到App关闭前，键盘更改不会生效。"),
                            message: Text("您可以选择现在关闭App，或者稍后自行关闭App。"),
                            primaryButton: .destructive(
                                Text("现在关闭"),
                                action: {
                                    exit(0)
                                }
                            ),
                            secondaryButton: .cancel(
                                Text("稍后"),
                                action: {
                                    Dismiss()
                                }
                            )
                        )
                    }
                    
                    
                    
                    Section {
                        Toggle(isOn: $AllowCookies) {
                            VStack(alignment: .leading) {
                                Text("允许Cookie")
                                Text("Cookie被用来标记登录信息等内容")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                            }
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "hand.raised.fill")
                            Text("Darock无法知晓或查看任何网页信息")
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "exclamationmark.triangle")
                            Text("启用Cookie后，访问网页前可能会出现弹窗")
                        }
                    } header: {
                        Text("Cookie")
                    }
                    .navigationTitle("Cookie")
                    .navigationBarTitleDisplayMode(.inline)
                }
//                .tabViewStyle(.verticalPage)
                #else
                Form {
                    Section {
//                        Toggle(isOn: SettingsView.$Bing_API) {
//                            Text("使用Bing API搜索")
//                        }
                        Picker(selection: $webSearch, label: Text("搜索引擎")) {
                            ForEach(EngineNames.allCases, id: \.self) {EngineNames in
                                Text(EngineNames.rawValue).tag(EngineNames.rawValue)
                            }
                        }
                        .disabled(SettingsView.Bing_API)
                    } header: {
                        Text("搜索")
                    }
                    .navigationTitle("搜索")
                    .navigationBarTitleDisplayMode(.inline)
                    
                    
                    
                    Section {
                        Toggle(isOn: $ModifyKeyboard) {
                            Text("第三方全键盘")
                        }
                        Button(action: {
                            isKeyboardPresented = true
                        }, label: {
                            Label("预览…", systemImage: "keyboard.badge.eye")
                        })
                        .sheet(isPresented: $isKeyboardPresented, content: {
                            ExtKeyboardView(startText: "") { _ in }
                        })
                    } header: {
                        Text("键盘")
                    } footer: {
                        Text("该键盘为不支持系统全键盘的Watch开发了一套全键盘英文输入法")
                    }
                    .navigationTitle("键盘")
                    .navigationBarTitleDisplayMode(.inline)
                    .onChange(of: ModifyKeyboard) {
//                        KeyboardChanged = true
                    }
                    .alert(isPresented: $KeyboardChanged) {
                        Alert(
                            title: Text("直到App关闭前，键盘更改不会生效。"),
                            message: Text("您可以选择现在关闭App，或者稍后自行关闭App。"),
                            primaryButton: .destructive(
                                Text("现在关闭"),
                                action: {
                                    exit(0)
                                }
                            ),
                            secondaryButton: .cancel(
                                Text("稍后"),
                                action: {
                                    Dismiss()
                                }
                            )
                        )
                    }
                    
                    
                    
                    Section {
                        Toggle(isOn: $AllowCookies) {
                            VStack(alignment: .leading) {
                                Text("允许Cookie")
                                Text("Cookie被用来标记登录信息等内容")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                            }
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "hand.raised.fill")
                            Text("Darock无法知晓或查看任何网页信息")
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "exclamationmark.triangle")
                            Text("启用Cookie后，访问网页前可能会出现弹窗")
                        }
                    } header: {
                        Text("Cookie")
                    }
                    .navigationTitle("Cookie")
                    .navigationBarTitleDisplayMode(.inline)
                }
                #endif
            }
        } else {
            NavigationView {
                Form {
                    Section {
                        Toggle(isOn: $isUsingBingAPI) {
                            Text("使用Bing API搜索")
                        }
                        Picker(selection: $webSearch, label: Text("搜索引擎")) {
                            ForEach(EngineNames.allCases, id: \.self) {EngineNames in
                                Text(EngineNames.rawValue).tag(EngineNames.rawValue)
                            }
                        }
                        .disabled(isUsingBingAPI)
                    } header: {
                        Text("搜索")
                    }
                    .navigationTitle("搜索")
                    .navigationBarTitleDisplayMode(.inline)
                    
                    
                    
                    Section {
                        Toggle(isOn: $ModifyKeyboard) {
                            Text("第三方全键盘")
                        }
                        Button(action: {
                            isKeyboardPresented = true
                        }, label: {
                            Label("预览…", systemImage: "keyboard.badge.eye")
                        })
                        .sheet(isPresented: $isKeyboardPresented, content: {
                            ExtKeyboardView(startText: "") { _ in }
                        })
                    } header: {
                        Text("键盘")
                    } footer: {
                        Text("该键盘为不支持系统全键盘的Watch开发了一套全键盘英文输入法")
                    }
                    .navigationTitle("键盘")
                    .navigationBarTitleDisplayMode(.inline)
//                    .onChange(of: ModifyKeyboard) {
//                        KeyboardChanged = true
//                    }
                    .alert(isPresented: $KeyboardChanged) {
                        Alert(
                            title: Text("直到App关闭前，键盘更改不会生效。"),
                            message: Text("您可以选择现在关闭App，或者稍后自行关闭App。"),
                            primaryButton: .destructive(
                                Text("现在关闭"),
                                action: {
                                    exit(0)
                                }
                            ),
                            secondaryButton: .cancel(
                                Text("稍后"),
                                action: {
                                    Dismiss()
                                }
                            )
                        )
                    }
                    
                    
                    
                    Section {
                        Toggle(isOn: $AllowCookies) {
                            VStack(alignment: .leading) {
                                Text("允许Cookie")
                                Text("Cookie被用来标记登录信息等内容")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                            }
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "hand.raised.fill")
                            Text("Darock无法知晓或查看任何网页信息")
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "exclamationmark.triangle")
                            Text("启用Cookie后，访问网页前可能会出现弹窗")
                        }
                    } header: {
                        Text("Cookie")
                    }
                    .navigationTitle("Cookie")
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

