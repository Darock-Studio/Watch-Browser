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
    @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
    @AppStorage("UserPassword") var userPassword = ""
    @State var KeyboardChanged = false
    @State var isKeyboardPresented = false
    @State var isCookieTipPresented = false
    @State var customSearchEngineList = [String]()
    @State var passwordInputCache = ""
    @State var isPasswordInputPresented = false
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
        Form {
            Section {
                Picker(selection: $webSearch, label: Text(isSearchEngineShortcutEnabled ? "默认搜索引擎" : "Settings.search.engine")) {
                    ForEach(EngineNames.allCases, id: \.self) { engineNames in
                        Text(engineTitle[engineNames.rawValue]!).tag(engineNames.rawValue)
                    }
                    if customSearchEngineList.count != 0 {
                        ForEach(0..<customSearchEngineList.count, id: \.self) { i in
                            Text(customSearchEngineList[i].replacingOccurrences(of: "%lld", with: "[搜索内容]")).tag(customSearchEngineList[i])
                        }
                    }
                }
                NavigationLink(destination: {CustomSearchEngineSettingsView()}, label: {
                    Text("自定搜索引擎")
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
//            Section {
//                VStack {
//                    DigiTextView(placeholder: "", text: $passwordInputCache, presentingModal: isPasswordInputPresented)
//                        .frame(width: 0, height: 0)
//                        .hidden()
//                    Button(action: {
//                        isPasswordInputPresented = true
//                    }, label: {
//                        Label(userPassword == "" ? "创建密码" : "关闭密码", systemImage: userPassword == "" ? "lock.fill" : "lock.slash.fill")
//                    })
//                }
//            } header: {
//                Text("密码")
//            }
//            .navigationTitle("密码")
//            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            customSearchEngineList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
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
                            Label("Settings.search.customize.add", systemImage: "plus")
                        })
                    }
                }
                if customSearchEngineList.count != 0 {
                    ForEach(0..<customSearchEngineList.count, id: \.self) { i in
                        Text(customSearchEngineList[i].replacingOccurrences(of: "%lld", with: String(localized: "Settings.search.customize.search-content")))
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
                        Text("Settings.search.customize.nothing")
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
                        TextField("Settings.search.customize.link", text: $customUrlInput)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } footer: {
                        Text("Settings.search.customize.link.discription")
                    }
                    Section {
                        NavigationLink(destination: {Step2(customUrlInput: customUrlInput, isAddCustomSEPresented: $isAddCustomSEPresented)}, label: {
                            Text("Settings.search.customize.next")
                        })
                    }
                }
                .navigationTitle("Settings.search.customize.link.title")
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
                    Text("Settings.search.customize.cursor")
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
                        if !combinedText.hasPrefix("http://") && !combinedText.hasPrefix("https://") {
                            combinedText = "http://" + combinedText
                        }
                        var newLists = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
                        newLists.append(combinedText)
                        UserDefaults.standard.set(newLists, forKey: "CustomSearchEngineList")
                        isAddCustomSEPresented = false
                    }, label: {
                        Label("Settings.search.customize.done", systemImage: "checkmark")
                    })
                }
                .navigationTitle("Settings.search.customize.cursor.title")
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

