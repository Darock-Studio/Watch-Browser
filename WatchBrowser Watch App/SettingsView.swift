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
    let engineTitle = ["必应": String(localized: "Search.bing"), "百度": String(localized: "Search.baidu"), "谷歌": String(localized: "Search.google"), "搜狗": String(localized: "Search.sougou")]
    var body: some View {
        if #available(watchOS 10.0, *) {
            NavigationStack {
                Form {
                    Section {
                        Picker(selection: $webSearch, label: Text("Settings.search.engine")) {
                            ForEach(EngineNames.allCases, id: \.self) { engineNames in
                                Text(engineTitle[engineNames.rawValue]!).tag(engineNames.rawValue)
                            }
                        }
                        NavigationLink(destination: {CustomSearchEngineSettingsView()}, label: {
                            Text("Setting.search.customize")
                        })
                    } header: {
                        Text("Settings.search")
                    }
                    .navigationTitle("Settings.search")
                    .navigationBarTitleDisplayMode(.inline)
                    Section {
                        NavigationLink(destination: {SearchEngineShortcutSettingsView()}, label: {
                            Text("搜索引擎快捷方式")
                        })
                    }
                    .navigationTitle("快速搜索引擎")
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

struct CustomSearchEngineSettingsView: View {
    @State var isAddCustomSEPresented = false
    @State var customSearchEngineList = [String]()
    var body: some View {
        Group {
            if #available(watchOS 10, *) {
                MainView(isAddCustomSEPresented: $isAddCustomSEPresented, customSearchEngineList: $customSearchEngineList)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                isAddCustomSEPresented = true
                            }, label: {
                                Image(systemName: "plus")
                            })
                        }
                    }
            } else {
                MainView(isAddCustomSEPresented: $isAddCustomSEPresented, customSearchEngineList: $customSearchEngineList)
            }
        }
        .sheet(isPresented: $isAddCustomSEPresented, onDismiss: {
            customSearchEngineList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
        }, content: {AddCustomSearchEngineView(isAddCustomSEPresented: $isAddCustomSEPresented)})
    }
    
    struct MainView: View {
        @Binding var isAddCustomSEPresented: Bool
        @Binding var customSearchEngineList: [String]
        var body: some View {
            List {
                if #unavailable(watchOS 10) {
                    Section {
                        Button(action: {
                            isAddCustomSEPresented = true
                        }, label: {
                            Label("添加自定搜索引擎", systemImage: "plus")
                        })
                    }
                }
                if customSearchEngineList.count != 0 {
                    ForEach(0..<customSearchEngineList.count, id: \.self) { i in
                        Text(customSearchEngineList[i].replacingOccurrences(of: "%lld", with: "[搜索内容]"))
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    customSearchEngineList.remove(at: i)
                                    UserDefaults.standard.set(customSearchEngineList, forKey: "CustomSearchEngineList")
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                            }
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("无自定搜索引擎")
                        Spacer()
                    }
                }
            }
            .onAppear {
                customSearchEngineList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
            }
        }
    }
    
    struct AddCustomSearchEngineView: View {
        @Binding var isAddCustomSEPresented: Bool
        @State var customUrlInput = ""
        var body: some View {
            NavigationView {
                List {
                    Section {
                        TextField("搜索引擎的链接", text: $customUrlInput)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } footer: {
                        Text("输入您要自定的搜索引擎的搜索链接,如“bing.com?q=”.要填充搜索内容的位置请暂时留空")
                    }
                    Section {
                        NavigationLink(destination: {Step2(customUrlInput: customUrlInput, isAddCustomSEPresented: $isAddCustomSEPresented)}, label: {
                            Text("下一步")
                        })
                    }
                }
                .navigationTitle("输入链接")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        
        struct Step2: View {
            var customUrlInput: String
            @Binding var isAddCustomSEPresented: Bool
            @State var charas = [Character]()
            @State var cursorPosition = 0.0
            var body: some View {
                VStack {
                    ScrollViewReader { p in
                        ScrollView(.horizontal) {
                            HStack(spacing: 0) {
                                if charas.count != 0 {
                                    ForEach(0..<charas.count, id: \.self) { i in
                                        Text(String(charas[i]))
                                        if i == Int(cursorPosition) {
                                            Color.accentColor
                                                .frame(width: 3, height: 26)
                                                .cornerRadius(3)
                                                .id("cur")
                                                .onAppear {
                                                    p.scrollTo("cur")
                                                }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .focusable()
                    .digitalCrownRotation($cursorPosition, from: 0, through: Double(charas.count - 1), by: 1, sensitivity: .medium, isHapticFeedbackEnabled: true)
                    Spacer()
                        .frame(height: 15)
                    Text("滚动数码表冠, 将光标移动到应当插入搜索词的位置.")
                        .font(.footnote)
                        .opacity(0.65)
                    Button(action: {
                        var combinedText = ""
                        for i in 0..<charas.count {
                            combinedText += String(charas[i])
                            if i == Int(cursorPosition) {
                                combinedText += "%lld"
                            }
                        }
                        var newLists = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
                        newLists.append(combinedText)
                        UserDefaults.standard.set(newLists, forKey: "CustomSearchEngineList")
                        isAddCustomSEPresented = false
                    }, label: {
                        Label("完成", systemImage: "checkmark")
                    })
                }
                .navigationTitle("选取插入位置")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    for c in customUrlInput {
                        charas.append(c)
                    }
                    cursorPosition = Double(charas.count - 1)
                }
            }
        }
    }
}

struct SearchEngineShortcutSettingsView: View {
    @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
    var body: some View {
        List {
            
        }
        .navigationTitle("搜索引擎快捷方式")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

