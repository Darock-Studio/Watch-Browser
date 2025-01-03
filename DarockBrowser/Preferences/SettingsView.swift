//
//  SettingsView.swift
//  WatchBrowser Watch App
//
//  Created by WindowsMEMZ on 2023/6/6.
//

import OSLog
import Charts
import Pictor
import SwiftUI
import Cepheus
import EFQRCode
import AVFAudio
import WidgetKit
import StorageUI
import WeatherKit
import CoreLocation
import SwiftyStoreKit
import DarockFoundation
import NetworkExtension
import UserNotifications
import TripleQuestionmarkCore
import AuthenticationServices

struct SettingsView: View {
    @AppStorage("DarockAccount") var darockAccount = ""
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("IsDeveloperModeEnabled") var isDeveloperModeEnabled = false
    @AppStorage("DarockAccountCachedUsername") var accountUsername = ""
    @State var isNewFeaturesPresented = false
    @State var isPasscodeViewPresented = false
    @State var isEnterPasscodeViewInputPresented = false
    @State var passcodeInputTmp = ""
    @State var isDarockAccountLoginPresented = false
    var body: some View {
        List {
            Section {
                if darockAccount.isEmpty {
                    Button(action: {
                        isDarockAccountLoginPresented = true
                    }, label: {
                        HStack {
                            ZStack {
                                Image(systemName: "circle.dotted")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.init(hex: 0x144683))
                                Image(systemName: "circle.dotted")
                                    .font(.system(size: 30, weight: .light))
                                    .rotationEffect(.degrees(8))
                                    .foregroundColor(.init(hex: 0x144683))
                                Text("D")
                                    .font(.custom("HYWenHei-85W", size: 14))
                                    .foregroundColor(.init(hex: 0x0c79ff))
                                    .scaleEffect(1.2)
                            }
                            VStack(alignment: .leading) {
                                Text("Darock 账户")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("登录以为今后账户相关功能做好准备。")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    })
                    .sheet(isPresented: $isDarockAccountLoginPresented, onDismiss: {
                        if !darockAccount.isEmpty {
                            requestString("https://fapi.darock.top:65535/user/name/get/\(darockAccount)".compatibleUrlEncoded()) { respStr, isSuccess in
                                if isSuccess {
                                    accountUsername = respStr.apiFixed()
                                }
                            }
                        }
                    }, content: { DarockAccountLogin() })
                } else {
                    NavigationLink(destination: { DarockAccountManagementMain(username: accountUsername) }, label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Group {
                                    if !accountUsername.isEmpty {
                                        Text(accountUsername)
                                            .lineLimit(1)
                                            .minimumScaleFactor(accountUsername.count <= 20 ? 0.1 : 0.5)
                                    } else {
                                        Text(verbatim: "loading")
                                            .redacted(reason: .placeholder)
                                    }
                                }
                                .font(.system(size: 16, weight: .semibold))
                                Text("Darock 账户以及更多")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    })
                }
            }
            Section {
                NavigationLink(destination: { ProPurchaseView() }, label: { SettingItemLabel(title: "暗礁浏览器 Pro", image: "sparkles", color: .blue) })
                NavigationLink(destination: { DarockIntelligenceView() }, label: {
                    HStack {
                        Image("DarockIntelligenceIcon")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                        Text("Darock 智能")
                    }
                })
                if #available(watchOS 10.0, *) {
                    NavigationLink(destination: { WidgetSettingsView() },
                                   label: { SettingItemLabel(title: "小组件", image: "watchface.applewatch.case", color: .blue) })
                }
            }
            Section {
                NavigationLink(destination: { StaredSettingsView() }, label: { SettingItemLabel(title: "常用设置", image: "star", color: .orange) })
                NavigationLink(destination: { NetworkSettingsView() }, label: { SettingItemLabel(title: "网络", image: "network", color: .blue) })
            }
            Section {
                NavigationLink(destination: { GeneralSettingsView() },
                               label: { SettingItemLabel(title: "通用", image: "gear", color: .gray) })
                NavigationLink(destination: { DisplaySettingsView() },
                               label: { SettingItemLabel(title: "显示与亮度", image: "sun.max.fill", color: .blue) })
                NavigationLink(destination: { BrowsingEngineSettingsView() },
                               label: { SettingItemLabel(title: "浏览引擎", image: "globe", color: .blue) })
                NavigationLink(destination: { SearchSettingsView() },
                               label: { SettingItemLabel(title: "搜索", image: "magnifyingglass", color: .gray) })
                #if compiler(>=6)
                NavigationLink(destination: { GesturesSettingsView() },
                               label: { SettingItemLabel(title: "手势", privateImage: "hand.side.pinch.fill", color: .blue) })
                #endif
            }
            Section {
                Button(action: {
                    if userPasscodeEncrypted.isEmpty {
                        isPasscodeViewPresented = true
                    } else {
                        isEnterPasscodeViewInputPresented = true
                    }
                }, label: {
                    SettingItemLabel(title: "密码", image: "lock.fill", color: .red)
                })
                NavigationLink(destination: { PrivacySettingsView() },
                               label: { SettingItemLabel(title: "隐私与安全性", image: "hand.raised.fill", color: .blue) })
            }
            Section {
                if isDeveloperModeEnabled {
                    NavigationLink(destination: { DeveloperSettingsView() }, label: {
                        SettingItemLabel(title: "开发者", image: "hammer.fill", color: .blue, symbolFontSize: 10)
                    })
                }
                NavigationLink(destination: { LaboratoryView() }, label: {
                    SettingItemLabel(title: "实验室", image: {
                        if #available(watchOS 10, *) {
                            "flask.fill"
                        } else {
                            "hammer.fill"
                        }
                    }(), color: .blue)
                })
                if UserDefaults(suiteName: "group.darockst")!.bool(forKey: "IsDarockInternalTap-to-RadarAvailable") {
                    NavigationLink(destination: { InternalDebuggingView() }, label: {
                        SettingItemLabel(title: "Debugging", image: "ant.fill", color: .purple)
                    })
                }
            }
        }
        .navigationTitle("设置")
        .wrapIf({
            if #available(watchOS 10, *) { true } else { false }
        }()) { content in
            content
                .navigationDestination(isPresented: $isPasscodeViewPresented, destination: { PasswordSettingsView() })
        } else: { content in
            content
                ._navigationDestination(isPresented: $isPasscodeViewPresented, content: { PasswordSettingsView() })
        }
        .sheet(isPresented: $isEnterPasscodeViewInputPresented) {
            PasswordInputView(text: $passcodeInputTmp, placeholder: "输入你的密码") { pwd in
                if pwd.md5 == userPasscodeEncrypted {
                    isPasscodeViewPresented = true
                } else {
                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                }
                passcodeInputTmp = ""
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            if !darockAccount.isEmpty {
                requestString("https://fapi.darock.top:65535/user/name/get/\(darockAccount)".compatibleUrlEncoded()) { respStr, isSuccess in
                    if isSuccess {
                        accountUsername = respStr.apiFixed()
                    }
                }
            }
        }
    }
    
    struct SettingItemLabel: View {
        var title: LocalizedStringKey
        var image: String
        var isPrivateImage: Bool
        var color: Color
        var symbolFontSize: CGFloat
        
        init(title: LocalizedStringKey, image: String, color: Color, symbolFontSize: CGFloat = 12) {
            self.title = title
            self.image = image
            self.isPrivateImage = false
            self.color = color
            self.symbolFontSize = symbolFontSize
        }
        init(title: LocalizedStringKey, privateImage: String, color: Color, symbolFontSize: CGFloat = 12) {
            self.title = title
            self.image = privateImage
            self.isPrivateImage = true
            self.color = color
            self.symbolFontSize = symbolFontSize
        }
        
        var body: some View {
            HStack {
                ZStack {
                    color
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                    Group {
                        if !isPrivateImage {
                            Image(systemName: image)
                        } else {
                            Image(_internalSystemName: image)
                        }
                    }
                    .font(.system(size: symbolFontSize))
                }
                Text(title)
            }
        }
    }
    
    struct DarockIntelligenceView: View {
        @AppStorage("IsProPurchased") var isProPurchased = false
        @AppStorage("DIWebAbstractLangOption") var webAbstractLangOption = "Web"
        @State var isPrivacySplashPresented = false
        var body: some View {
            if isProPurchased {
                List {
                    Section {
                        Picker("摘要语言", selection: $webAbstractLangOption) {
                            Text("网页语言").tag("Web")
                            Text("系统语言").tag("System")
                        }
                    } header: {
                        Text("网页摘要")
                    }
                    Section {
                        Button(action: {
                            isPrivacySplashPresented = true
                        }, label: {
                            Text("关于 Darock 智能与隐私")
                        })
                    }
                }
                .navigationTitle("Darock 智能")
                .sheet(isPresented: $isPrivacySplashPresented) {
                    PrivacyAboutView(
                        title: "关于 Darock 智能与隐私",
                        description: Text("使用 Darock 智能时，部分数据可能会在设备外处理。\(Text("进一步了解...").foregroundColor(.blue))"),
                        detailText: """
                        **Darock 智能与隐私**
                        
                        Darock 智能旨在保护你的信息并可让你选择共享的内容。
                        
                        ### 网页摘要
                        使用网页摘要时，网页中的文本信息会被发送到设备外的 Darock 智能服务进行处理。这些信息不会被存储，且不会关联到个人。
                        """
                    )
                }
            } else {
                ProUnavailableView()
            }
        }
    }
    @available(watchOS 10.0, *)
    struct WidgetSettingsView: View {
        @AppStorage("IsProPurchased") var isProPurchased = false
        var body: some View {
            if isProPurchased {
                List {
                    Section {
                        NavigationLink(destination: { BookmarkWidgetsView() }, label: {
                            Label("书签", systemImage: "bookmark")
                        })
                    }
                }
                .navigationTitle("小组件")
            } else {
                ProUnavailableView()
            }
        }
        
        struct BookmarkWidgetsView: View {
            @State var bookmarks = [SingleWidgetBookmark]()
            @State var isAddBookmarkPresented = false
            var body: some View {
                List {
                    if !bookmarks.isEmpty {
                        Section {
                            ForEach(0..<bookmarks.count, id: \.self) { i in
                                NavigationLink(destination: { ModifyBookmarkView(index: i) }, label: {
                                    VStack(alignment: .leading) {
                                        Text(bookmarks[i].displayName)
                                        Text(bookmarks[i].link)
                                            .font(.system(size: 14))
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                            .foregroundStyle(.gray)
                                    }
                                })
                                .swipeActions {
                                    Button(role: .destructive, action: {
                                        bookmarks.remove(at: i)
                                        let containerPath = FileManager.default.containerURL(
                                            forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets"
                                        )!.path
                                        do {
                                            try jsonString(from: bookmarks)?.write(
                                                toFile: containerPath + "/WidgetBookmarks.drkdataw",
                                                atomically: true,
                                                encoding: .utf8
                                            )
                                        } catch {
                                            globalErrorHandler(error)
                                        }
                                        WidgetCenter.shared.reloadTimelines(ofKind: "BookmarkWidgets")
                                        WidgetCenter.shared.invalidateConfigurationRecommendations()
                                    }, label: {
                                        Image(systemName: "xmark.circle.fill")
                                    })
                                }
                            }
                        }
                    } else {
                        VStack {
                            Image(systemName: "circle.slash")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            VStack {
                                Text("无书签小组件")
                                    .font(.headline)
                                Text("轻触 \(Image(systemName: "plus")) 按钮以添加")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical)
                        }
                        .centerAligned()
                        .listRowBackground(Color.clear)
                    }
                }
                .navigationTitle("书签小组件")
                .sheet(isPresented: $isAddBookmarkPresented, onDismiss: refreshBookmarks, content: { AddBookmarkView() })
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isAddBookmarkPresented = true
                        }, label: {
                            Image(systemName: "plus")
                        })
                    }
                }
                .onAppear {
                    refreshBookmarks()
                }
            }
            
            func refreshBookmarks() {
                let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets")!.path
                if let _bookmarksStr = try? String(contentsOfFile: containerPath + "/WidgetBookmarks.drkdataw", encoding: .utf8),
                   let fileBookmarks = getJsonData([SingleWidgetBookmark].self, from: _bookmarksStr) {
                    bookmarks = fileBookmarks
                }
            }
            
            struct AddBookmarkView: View {
                @Environment(\.presentationMode) var presentationMode
                @State var nameInput = ""
                @State var linkInput = ""
                @State var symbolSelection = "bookmark.fill"
                @State var isHistorySelectorPresented = false
                @State var isBookmarkSelectorPresented = false
                var body: some View {
                    NavigationStack {
                        List {
                            Section {
                                TextField("名称", text: $nameInput)
                                TextField("链接", text: $linkInput) {
                                    if !linkInput.hasPrefix("http://") && !linkInput.hasPrefix("https://") {
                                        linkInput = "http://" + linkInput
                                    }
                                }
                                .noAutoInput()
                                PictorSymbolPicker(symbol: $symbolSelection, presentAsSheet: true, selectionColor: .white, aboutLinkIsHidden: true, label: {
                                    VStack(alignment: .leading) {
                                        Text("符号")
                                        HStack(spacing: 2) {
                                            Image(systemName: symbolSelection)
                                            Text(symbolSelection)
                                                .lineLimit(1)
                                        }
                                        .font(.system(size: 14))
                                        .foregroundStyle(.gray)
                                    }
                                })
                            }
                            Section {
                                Button(action: {
                                    isHistorySelectorPresented = true
                                }, label: {
                                    Label("从历史记录选择", systemImage: "clock")
                                })
                                Button(action: {
                                    isBookmarkSelectorPresented = true
                                }, label: {
                                    Label("从网页书签选择", systemImage: "bookmark")
                                })
                            }
                        }
                        .navigationTitle("添加书签小组件")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    let containerPath = FileManager.default.containerURL(
                                        forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets"
                                    )!.path
                                    var bookmarks = [SingleWidgetBookmark]()
                                    if let _bookmarksStr = try? String(contentsOfFile: containerPath + "/WidgetBookmarks.drkdataw", encoding: .utf8),
                                       let fileBookmarks = getJsonData([SingleWidgetBookmark].self, from: _bookmarksStr) {
                                        bookmarks = fileBookmarks
                                    }
                                    bookmarks.append(.init(displayName: nameInput, displaySymbol: symbolSelection, link: linkInput))
                                    do {
                                        try jsonString(from: bookmarks)?.write(
                                            toFile: containerPath + "/WidgetBookmarks.drkdataw",
                                            atomically: true,
                                            encoding: .utf8
                                        )
                                    } catch {
                                        globalErrorHandler(error)
                                    }
                                    WidgetCenter.shared.reloadTimelines(ofKind: "BookmarkWidgets")
                                    WidgetCenter.shared.invalidateConfigurationRecommendations()
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Image(systemName: "plus")
                                })
                                .disabled(nameInput.isEmpty || linkInput.isEmpty)
                            }
                        }
                    }
                    .sheet(isPresented: $isHistorySelectorPresented) {
                        NavigationStack {
                            HistoryView { sel in
                                linkInput = sel
                                isHistorySelectorPresented = false
                            }
                            .navigationTitle("选取历史记录")
                        }
                    }
                    .sheet(isPresented: $isBookmarkSelectorPresented) {
                        NavigationStack {
                            BookmarkView { name, link in
                                nameInput = name
                                linkInput = link
                                isBookmarkSelectorPresented = false
                            }
                            .navigationTitle("选取书签")
                        }
                    }
                }
            }
            struct ModifyBookmarkView: View {
                var index: Int
                @Environment(\.presentationMode) var presentationMode
                @State var nameInput = ""
                @State var linkInput = ""
                @State var symbolSelection = "bookmark.fill"
                @State var isHistorySelectorPresented = false
                @State var isBookmarkSelectorPresented = false
                var body: some View {
                    List {
                        Section {
                            TextField("名称", text: $nameInput)
                            TextField("链接", text: $linkInput) {
                                if !linkInput.hasPrefix("http://") && !linkInput.hasPrefix("https://") {
                                    linkInput = "http://" + linkInput
                                }
                            }
                            .noAutoInput()
                            PictorSymbolPicker(symbol: $symbolSelection, presentAsSheet: true, selectionColor: .white, aboutLinkIsHidden: true, label: {
                                VStack(alignment: .leading) {
                                    Text("符号")
                                    HStack(spacing: 2) {
                                        Image(systemName: symbolSelection)
                                        Text(symbolSelection)
                                            .lineLimit(1)
                                    }
                                    .font(.system(size: 14))
                                    .foregroundStyle(.gray)
                                }
                            })
                        }
                        Section {
                            Button(action: {
                                isHistorySelectorPresented = true
                            }, label: {
                                Label("从历史记录选择", systemImage: "clock")
                            })
                            Button(action: {
                                isBookmarkSelectorPresented = true
                            }, label: {
                                Label("从网页书签选择", systemImage: "bookmark")
                            })
                        }
                    }
                    .navigationTitle("修改书签")
                    .sheet(isPresented: $isHistorySelectorPresented) {
                        NavigationStack {
                            HistoryView { sel in
                                linkInput = sel
                                isHistorySelectorPresented = false
                            }
                            .navigationTitle("选取历史记录")
                        }
                    }
                    .sheet(isPresented: $isBookmarkSelectorPresented) {
                        NavigationStack {
                            BookmarkView { name, link in
                                nameInput = name
                                linkInput = link
                                isBookmarkSelectorPresented = false
                            }
                            .navigationTitle("选取书签")
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                let containerPath = FileManager.default.containerURL(
                                    forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets"
                                )!.path
                                var bookmarks = [SingleWidgetBookmark]()
                                if let _bookmarksStr = try? String(contentsOfFile: containerPath + "/WidgetBookmarks.drkdataw", encoding: .utf8),
                                   let fileBookmarks = getJsonData([SingleWidgetBookmark].self, from: _bookmarksStr) {
                                    bookmarks = fileBookmarks
                                }
                                bookmarks[index] = .init(displayName: nameInput, displaySymbol: symbolSelection, link: linkInput)
                                do {
                                    try jsonString(from: bookmarks)?.write(
                                        toFile: containerPath + "/WidgetBookmarks.drkdataw",
                                        atomically: true,
                                        encoding: .utf8
                                    )
                                } catch {
                                    globalErrorHandler(error)
                                }
                                WidgetCenter.shared.reloadTimelines(ofKind: "BookmarkWidgets")
                                WidgetCenter.shared.invalidateConfigurationRecommendations()
                                presentationMode.wrappedValue.dismiss()
                            }, label: {
                                Image(systemName: "checkmark")
                            })
                            .disabled(nameInput.isEmpty || linkInput.isEmpty)
                        }
                    }
                    .onAppear {
                        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets")!.path
                        if let _bookmarksStr = try? String(contentsOfFile: containerPath + "/WidgetBookmarks.drkdataw", encoding: .utf8),
                           let fileBookmarks = getJsonData([SingleWidgetBookmark].self, from: _bookmarksStr) {
                            if let bookmark = fileBookmarks[from: index] {
                                nameInput = bookmark.displayName
                                linkInput = bookmark.link
                                symbolSelection = bookmark.displaySymbol
                            } else {
                                presentationMode.wrappedValue.dismiss()
                                tipWithText("载入出错，请提交反馈", symbol: "xmark.circle.fill")
                            }
                        }
                    }
                }
            }
        }
    }
    
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
    
    struct GeneralSettingsView: View {
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { AboutView() },
                                   label: { SettingItemLabel(title: "关于", image: "applewatch", color: .gray) })
                    NavigationLink(destination: { SoftwareUpdateView() },
                                   label: { SettingItemLabel(title: "软件更新", image: "gear.badge", color: .gray) })
                    NavigationLink(destination: {
                        SUIStorageManagementView {
                            SUIStorageListFile(
                                name: "视频",
                                tintColor: .purple,
                                path: NSHomeDirectory() + "/Documents/DownloadedVideos",
                                allowDelete: true,
                                customNameConverter: UserDefaults.standard.dictionary(forKey: "VideoHumanNameChart") as? [String: String]
                            ) { name in
                                if var dic = UserDefaults.standard.dictionary(forKey: "VideoHumanNameChart") as? [String: String] {
                                    dic.removeValue(forKey: name)
                                    UserDefaults.standard.set(dic, forKey: "VideoHumanNameChart")
                                }
                            }
                            SUIStorageListFile(
                                name: "音乐",
                                tintColor: .red,
                                path: NSHomeDirectory() + "/Documents/DownloadedAudios",
                                allowDelete: true,
                                customNameConverter: UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]
                            ) { name in
                                if var dic = UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String] {
                                    dic.removeValue(forKey: name)
                                    UserDefaults.standard.set(dic, forKey: "AudioHumanNameChart")
                                }
                            }
                            SUIStorageListFile(
                                name: "图片",
                                tintColor: .orange,
                                path: NSHomeDirectory() + "/Documents/LocalImages",
                                showFilesInList: false
                            )
                        }
                    },
                                   label: { SettingItemLabel(title: "储存空间", image: "externaldrive.fill", color: .gray) })
                }
                Section {
                    NavigationLink(destination: { ContinuityView() },
                                   label: { SettingItemLabel(title: "连续互通", image: "point.3.filled.connected.trianglepath.dotted", color: .blue) })
                }
                Section {
                    NavigationLink(destination: { KeyboardView() },
                                   label: { SettingItemLabel(title: "键盘", image: "keyboard.fill", color: .gray) })
                    NavigationLink(destination: { MusicPlayerView() },
                                   label: { SettingItemLabel(title: "音乐播放器", image: "music.note.list", color: .red) })
                    NavigationLink(destination: { ImageViewerView() },
                                   label: { SettingItemLabel(title: "图像查看器", image: "photo.fill.on.rectangle.fill", color: .blue) })
                    NavigationLink(destination: { ReaderView() },
                                   label: { SettingItemLabel(title: "阅读器", image: "book.fill", color: .orange) })
                }
                Section {
                    NavigationLink(destination: { LegalView() },
                                   label: { SettingItemLabel(title: "法律与监管", image: {
                        if #available(watchOS 11.0, *) {
                            "checkmark.seal.text.page.fill"
                        } else {
                            "text.justify.left"
                        }
                    }(), color: .gray) })
                }
                Section {
                    NavigationLink(destination: { ResetView() },
                                   label: { SettingItemLabel(title: "还原", image: "arrow.counterclockwise", color: .gray) })
                }
            }
            .navigationTitle("通用")
        }
        
        struct AboutView: View {
            @AppStorage("IsProPurchased") var isProPurchased = false
            @State var songCount = 0
            @State var videoCount = 0
            @State var photoCount = 0
            @State var bookCount = 0
            var body: some View {
                List {
                    Section {
                        HStack {
                            Text("App 版本")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("构建版本")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)
                                .foregroundColor(.gray)
                        }
                        if isAppBetaBuild {
                            HStack {
                                Text("Beta 构建")
                                Spacer()
                                Text("是")
                                    .foregroundColor(.gray)
                            }
                        }
                        HStack {
                            Text("功能")
                            Spacer()
                            Text(isProPurchased ? "Pro" : "标准")
                                .foregroundColor(.gray)
                        }
                    }
                    Section {
                        HStack {
                            Text("音乐")
                            Spacer()
                            Text(String(songCount))
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("视频")
                            Spacer()
                            Text(String(videoCount))
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("图片")
                            Spacer()
                            Text(String(photoCount))
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("图书")
                            Spacer()
                            Text(String(bookCount))
                                .foregroundColor(.gray)
                        }
                        if #available(watchOS 10, *) {
                            TQCAccentColorHiddenButton {
                                requestString("https://fapi.darock.top:65535/analyze/add/DBTQCAccentColor/\(Date.now.timeIntervalSince1970)".compatibleUrlEncoded()) { _, _ in }
                            }
                        }
                    }
                }
                .navigationTitle("关于")
                .onAppear {
                    do {
                        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/") {
                            songCount = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/").count
                        }
                        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/") {
                            videoCount = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/").count
                        }
                        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/LocalImages/") {
                            photoCount = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/LocalImages/").count
                        }
                        let allDocumentFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents")
                        bookCount = 0
                        for file in allDocumentFiles where file.hasPrefix("EPUB") {
                            bookCount++
                        }
                    } catch {
                        globalErrorHandler(error)
                    }
                }
            }
        }
        struct SoftwareUpdateView: View {
            @State var shouldUpdate = false
            @State var isLoading = true
            @State var isFailed = false
            @State var latestVer = ""
            var body: some View {
                ScrollView {
                    VStack {
                        if !isLoading {
                            if shouldUpdate {
                                HStack {
                                    Spacer()
                                        .frame(width: 10)
                                    Image("AppIconImage")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(8)
                                    Spacer()
                                        .frame(width: 10)
                                    VStack {
                                        Text("v\(latestVer)")
                                            .font(.system(size: 14, weight: .medium))
                                        HStack {
                                            Text("Darock Studio")
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                            Spacer()
                                        }
                                    }
                                }
                                Divider()
                                Button(action: {
                                    let session = ASWebAuthenticationSession(
                                        url: URL(string: "https://apps.apple.com/cn/app/darock-browser/id1670065481")!,
                                        callbackURLScheme: nil
                                    ) { _, _ in
                                        return
                                    }
                                    session.prefersEphemeralWebBrowserSession = true
                                    session.start()
                                }, label: {
                                    Text("前往更新")
                                })
                            } else if isFailed {
                                Text("检查更新时出错")
                            } else {
                                Text("暗礁浏览器已是最新版本")
                            }
                        } else {
                            HStack {
                                Text("正在检查更新...")
                                    .lineLimit(1)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: 130)
                                Spacer()
                                    .frame(maxWidth: .infinity)
                                ProgressView()
                            }
                        }
                    }
                }
                .navigationTitle("软件更新")
                .onAppear {
                    requestString("https://fapi.darock.top:65535/drkbs/newver".compatibleUrlEncoded()) { respStr, isSuccess in
                        if isSuccess {
                            let spdVer = respStr.apiFixed().split(separator: ".")
                            if spdVer.count == 3 {
                                if let x = Int(spdVer[0]), let y = Int(spdVer[1]), let z = Int(spdVer[2]) {
                                    let currVerSpd = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).split(separator: ".")
                                    if currVerSpd.count == 3 {
                                        if let cx = Int(currVerSpd[0]), let cy = Int(currVerSpd[1]), let cz = Int(currVerSpd[2]) {
                                            if x > cx {
                                                shouldUpdate = true
                                            } else if x == cx && y > cy {
                                                shouldUpdate = true
                                            } else if x == cx && y == cy && z > cz {
                                                shouldUpdate = true
                                            }
                                            latestVer = respStr.apiFixed()
                                            isLoading = false
                                        } else {
                                            isFailed = true
                                        }
                                    } else {
                                        isFailed = true
                                    }
                                } else {
                                    isFailed = true
                                }
                            } else {
                                isFailed = true
                            }
                        } else {
                            isFailed = true
                        }
                    }
                }
            }
        }
        
        struct ContinuityView: View {
            @AppStorage("CCIsHandoffEnabled") var isHandoffEnabled = true
            @AppStorage("CCIsContinuityMediaEnabled") var isContinuityMediaEnabled = true
            var body: some View {
                List {
                    Section {
                        Toggle("接力", isOn: $isHandoffEnabled)
                    } footer: {
                        Text("接力让你能够快速在另一设备上继续浏览暗礁浏览器中的网页。在暗礁浏览器浏览网页时，带有 Apple Watch 角标的 Safari 图标会出现在 iPhone 的 App 切换器或 iPad 和 Mac 的 Dock 栏中。")
                    }
                    Section {
                        Toggle("连续互通媒体", isOn: $isContinuityMediaEnabled)
                    } footer: {
                        Text("在使用暗礁浏览器查看媒体时，可在其他设备上继续查看媒体。")
                    }
                }
                .navigationTitle("连续互通")
            }
        }
        
        struct KeyboardView: View {
            @AppStorage("ModifyKeyboard") var modifyKeyboard = false
            @State var isKeyboardPresented = false
            var body: some View {
                List {
                    Section {
                        Toggle(isOn: $modifyKeyboard) {
                            Text("Settings.keyboard.third-party")
                        }
                        if #available(watchOS 10, *) {
                            CepheusKeyboard(input: .constant(""), prompt: "Settings.keyboard.preview", CepheusIsEnabled: true)
                        } else {
                            Button(action: {
                                isKeyboardPresented = true
                            }, label: {
                                Label("Settings.keyboard.preview", systemImage: "keyboard.badge.eye")
                            })
                            .sheet(isPresented: $isKeyboardPresented, content: {
                                ExtKeyboardView(startText: "") { _ in }
                            })
                        }
                    } footer: {
                        VStack(alignment: .leading) {
                            Text("Settings.keyboard.discription")
                            if #available(watchOS 10, *) {
                                Text("Powered by Cepheus Keyboard")
                            }
                        }
                    }
                    if #available(watchOS 10, *), modifyKeyboard {
                        NavigationLink(destination: { CepheusSettingsView() }, label: {
                            Text("键盘设置...")
                        })
                    }
                }
                .navigationTitle("Settings.keyboard")
            }
        }
        struct DownloaderView: View {
            @AppStorage("DLIsFeedbackWhenFinish") var isFeedbackWhenFinish = false
            var body: some View {
                List {
                    Section {
                        Toggle("完成后提醒", isOn: $isFeedbackWhenFinish)
                    }
                }
                .navigationTitle("下载器")
            }
        }
        struct MusicPlayerView: View {
            @AppStorage("MPIsShowTranslatedLyrics") var isShowTranslatedLyrics = true
            @AppStorage("MPBackgroundPlay") var isAllowBackgroundPlay = false
            var body: some View {
                List {
                    Section {
                        Toggle("显示翻译歌词", isOn: $isShowTranslatedLyrics)
                    }
                    Section {
                        Toggle("允许后台播放", isOn: $isAllowBackgroundPlay)
                            .onChange(of: isAllowBackgroundPlay) { _ in
                                if !isAllowBackgroundPlay {
                                    try? AVAudioSession.sharedInstance().setActive(false)
                                }
                            }
                    } footer: {
                        if WKInterfaceDevice.modelName != "Apple Watch" {
                            // Apple Watch Series 10
                            if ["Watch7,8", "Watch7,9", "Watch7,10", "Watch7,11"].contains(WKInterfaceDevice.modelIdentifier) {
                                Text("你的设备无需连接蓝牙音频设备即可在后台播放音频。")
                            } else {
                                Text("若要在后台播放，你的设备需要在播放前连接蓝牙音频设备。")
                            }
                        } else {
                            Text("若要在后台播放，你可能需要在播放前连接蓝牙音频设备。")
                        }
                    }
                }
                .navigationTitle("音乐播放器")
            }
        }
        struct ImageViewerView: View {
            @AppStorage("IVUseDigitalCrownFor") var useDigitalCrownFor = "zoom"
            @AppStorage("MaxmiumScale") var maxmiumScale = 6.0
            var body: some View {
                List {
                    Section {
                        Picker("将数码表冠用作", selection: $useDigitalCrownFor) {
                            Text("缩放")
                                .tag("zoom")
                            Text("切换")
                                .tag("switch")
                        }
                        if useDigitalCrownFor == "zoom" {
                            VStack {
                                Text("最大缩放倍数")
                                Slider(value: $maxmiumScale, in: 6.0...50.0, step: 0.5) {
                                    EmptyView()
                                }
                                Text("\(String(format: "%.1f", maxmiumScale))x")
                            }
                        }
                    }
                }
                .navigationTitle("图像查看器")
            }
        }
        struct ReaderView: View {
            @AppStorage("RVReaderType") var readerType = "Scroll"
            @AppStorage("RVFontSize") var fontSize = 14
            @AppStorage("RVIsBoldText") var isBoldText = false
            @AppStorage("RVCharacterSpacing") var characterSpacing = 1.0
            @State var attributedExample = NSMutableAttributedString()
            @State var shouldShowFontDot = false
            var body: some View {
                VStack {
                    if readerType == "Scroll" {
                        Text(AttributedString(attributedExample))
                            .frame(height: 80)
                            .mask {
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black, Color.black, Color.black.opacity(0)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                            .animation(.default, value: attributedExample)
                    }
                    Form {
                        List {
                            Section {
                                Picker("阅读模式", selection: $readerType) {
                                    Text("滚动").tag("Scroll")
                                    Text("按章节划分").tag("Paging")
                                }
                            }
                            Section {
                                HStack {
                                    Button(action: {
                                        if fontSize > 12 {
                                            fontSize--
                                            refreshAttributedExample()
                                        }
                                        shouldShowFontDot = true
                                    }, label: {
                                        Text("A")
                                            .font(.system(size: 18, design: .rounded))
                                            .centerAligned()
                                    })
                                    .buttonStyle(.plain)
                                    Divider()
                                    Button(action: {
                                        if fontSize < 26 {
                                            fontSize++
                                            refreshAttributedExample()
                                        }
                                        shouldShowFontDot = true
                                    }, label: {
                                        Text("A")
                                            .font(.system(size: 26, design: .rounded))
                                            .centerAligned()
                                    })
                                    .buttonStyle(.plain)
                                }
                            } footer: {
                                if shouldShowFontDot {
                                    HStack(spacing: 2) {
                                        ForEach(12...26, id: \.self) { i in
                                            Circle()
                                                .fill(fontSize >= i ? Color.white : .gray.opacity(0.5))
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                    .animation(.easeIn, value: fontSize)
                                }
                            }
                            .animation(.easeOut(duration: 0.2), value: shouldShowFontDot)
                            .disabled(readerType != "Scroll")
                            Section {
                                Toggle("粗体文本", isOn: $isBoldText)
                                    .onChange(of: isBoldText) { _ in
                                        refreshAttributedExample()
                                    }
                            }
                            .disabled(readerType != "Scroll")
                            Section {
                                VStack(alignment: .leading) {
                                    Text("字间距")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.gray)
                                    Slider(value: $characterSpacing, in: 0.8...2.5, step: 0.05)
                                        .onChange(of: characterSpacing) { _ in
                                            refreshAttributedExample()
                                        }
                                    Text(characterSpacing ~ 2)
                                        .centerAligned()
                                }
                            }
                            .disabled(readerType != "Scroll")
                            Section {}
                        }
                    }
                }
                .navigationTitle("阅读器")
                .onAppear {
                    refreshAttributedExample()
                }
            }
            
            func refreshAttributedExample() {
                attributedExample = .init(
                    string: String(
                        localized: "晚饭过后，我沿着海滩散步，想找一个绝佳的位置读完手里的书，再开启一本新书。我发现了一个地方，目之所及，空无一人。这里还有一张吊床，可以阅读和小憩。我躺下来，几经调整，找到一个最舒适的姿势，就此遁入书中，沉浸在最后一个章节。一时间，"
                    ),
                    attributes: [
                        .font: UIFont.systemFont(ofSize: CGFloat(fontSize), weight: isBoldText ? .bold : .regular),
                        .kern: CGFloat(characterSpacing)
                    ]
                )
            }
        }
        
        struct LegalView: View {
            var body: some View {
                List {
                    Section {
                        NavigationLink(destination: {
                            ScrollView {
                                Text(try! String(contentsOf: Bundle.main.url(forResource: "LICENSE", withExtension: nil)!))
                            }
                            .navigationTitle("许可证")
                        }, label: {
                            Text("许可证")
                        })
                        NavigationLink(destination: { OpenSourceView() }, label: {
                            Text("开源协议许可")
                        })
                    } header: {
                        Text("暗礁浏览器")
                    }
                    if NSLocale.current.language.languageCode!.identifier == "zh" {
                        Section {
                            Button(action: {
                                let session = ASWebAuthenticationSession(
                                    url: URL(string: "https://beian.miit.gov.cn")!,
                                    callbackURLScheme: nil
                                ) { _, _ in }
                                session.prefersEphemeralWebBrowserSession = true
                                session.start()
                            }, label: {
                                Text("蜀ICP备2024100233号-1A")
                            })
                        } header: {
                            Text("中国大陆ICP备案号")
                        }
                    }
                }
                .navigationTitle("法律与监管")
            }
            
            struct OpenSourceView: View {
                @State var isTQCView1Presented = false
                var body: some View {
                    List {
                        SinglePackageBlock(name: "AEXML", license: "MIT license")
                        SinglePackageBlock(name: "Alamofire", license: "MIT license")
                        SinglePackageBlock(name: "Cache", license: "MIT license")
                        SinglePackageBlock(name: "Cepheus", license: "Apache License 2.0")
                        SinglePackageBlock(name: "EFQRCode", license: "MIT license")
                        SinglePackageBlock(name: "EPUBKit", license: "MIT license")
                        SinglePackageBlock(name: "libwebp", license: "BSD-3-Clause license")
                        SinglePackageBlock(name: "MarqueeText", license: "MIT license")
                        SinglePackageBlock(name: "NetworkImage", license: "MIT license")
                        SinglePackageBlock(name: "Pictor", license: "Apache License 2.0")
                        SinglePackageBlock(name: "Punycode", license: "MIT license")
                        SinglePackageBlock(name: "SDWebImage", license: "MIT license")
                        SinglePackageBlock(name: "SDWebImagePDFCoder", license: "MIT license")
                        SinglePackageBlock(name: "SDWebImageSVGCoder", license: "MIT license")
                        SinglePackageBlock(name: "SDWebImageSwiftUI", license: "MIT license")
                        SinglePackageBlock(name: "SDWebImageWebPCoder", license: "MIT license")
                        SinglePackageBlock(name: "swift_qrcodejs", license: "MIT license")
                        SinglePackageBlock(name: "swift-markdown-ui", license: "MIT license")
                        SinglePackageBlock(name: "SwiftSoup", license: "MIT license")
                        SinglePackageBlock(name: "SwiftyJSON", license: "MIT license")
                        SinglePackageBlock(name: "Vela", license: "Apache License 2.0")
                        SinglePackageBlock(name: "Vortex", license: "MIT license")
                        SinglePackageBlock(name: "Zip", license: "MIT license")
                        SinglePackageBlock(name: "???Core", license: "???")
                            .onTapGesture {
                                isTQCView1Presented = true
                            }
                    }
                    .navigationTitle("开源协议许可")
                    .sheet(isPresented: $isTQCView1Presented, content: {
                        TQCOnaniiView()
                            .onAppear {
                                requestString("https://fapi.darock.top:65535/analyze/add/DBTQCOnanii/\(Date.now.timeIntervalSince1970)".compatibleUrlEncoded()) { _, _ in }
                            }
                    })
                }
                
                struct SinglePackageBlock: View {
                    var name: String
                    var license: String
                    var body: some View {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(Color(hex: 0xa06f2f))
                            VStack {
                                HStack {
                                    Text(name)
                                    Spacer()
                                }
                                HStack {
                                    Text(license)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        struct ResetView: View {
            @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
            @State var isResetSettingsWarningPresented = false
            @State var isResetAllWarningPresented = false
            @State var isResetSettingsPasscodePresented = false
            @State var passcodeInputTmp = ""
            var body: some View {
                List {
                    Section {
                        Button(action: {
                            if userPasscodeEncrypted.isEmpty {
                                isResetSettingsWarningPresented = true
                            } else {
                                isResetSettingsPasscodePresented = true
                            }
                        }, label: {
                            Text("还原所有设置")
                        })
                        Button(action: {
                            isResetAllWarningPresented = true
                        }, label: {
                            Text("抹掉所有内容和设置")
                        })
                    }
                }
                .navigationTitle("还原")
                .alert("还原所有设置", isPresented: $isResetSettingsWarningPresented, actions: {
                    Button(role: .cancel, action: { }, label: {
                        Text("取消")
                    })
                    Button(role: .destructive, action: {
                        do {
                            try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Library/Preferences/com.darock.WatchBrowser.watchkitapp.plist")
                            tipWithText("已还原", symbol: "checkmark.circle.fill")
                        } catch {
                            tipWithText("还原时出错", symbol: "xmark.circle.fill")
                            globalErrorHandler(error)
                        }
                    }, label: {
                        Text("还原")
                    })
                }, message: {
                    Text("此操作不可逆\n确定吗？")
                })
                .alert("抹掉所有内容和设置", isPresented: $isResetAllWarningPresented, actions: {
                    Button(role: .cancel, action: { }, label: {
                        Text("取消")
                    })
                    Button(role: .destructive, action: {
                        do {
                            let filePaths = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents")
                            for filePath in filePaths {
                                let fullPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(filePath)
                                try FileManager.default.removeItem(atPath: fullPath)
                            }
                            try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Library/Preferences/com.darock.WatchBrowser.watchkitapp.plist")
                            tipWithText("已抹掉", symbol: "checkmark.circle.fill")
                        } catch {
                            tipWithText("抹掉时出错", symbol: "xmark.circle.fill")
                            globalErrorHandler(error)
                        }
                    }, label: {
                        Text("抹掉")
                    })
                }, message: {
                    Text("此操作不可逆\n确定吗？")
                })
                .sheet(isPresented: $isResetSettingsPasscodePresented) {
                    PasswordInputView(text: $passcodeInputTmp, placeholder: "输入密码以继续") { pwd in
                        if pwd.md5 == userPasscodeEncrypted {
                            isResetSettingsWarningPresented = true
                        } else {
                            tipWithText("密码错误", symbol: "xmark.circle.fill")
                        }
                        passcodeInputTmp = ""
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
    }
    struct DisplaySettingsView: View {
        @AppStorage("DBIsAutoAppearence") var isAutoAppearence = false
        @AppStorage("DBAutoAppearenceOptionTrigger") var autoAppearenceOptionTrigger = "CustomTimeRange"
        @AppStorage("DBAutoAppearenceOptionTimeRangeLight") var autoAppearenceOptionTimeRangeLight = "7:00"
        @AppStorage("DBAutoAppearenceOptionTimeRangeDark") var autoAppearenceOptionTimeRangeDark = "22:00"
        @AppStorage("ABIsReduceBrightness") var isReduceBrightness = false
        @AppStorage("ABReduceBrightnessLevel") var reduceBrightnessLevel = 0.2
        @AppStorage("IsWebMinFontSizeStricted") var isWebMinFontSizeStricted = false
        @AppStorage("WebMinFontSize") var webMinFontSize = 10.0
        var body: some View {
            List {
                Section {
                    Toggle("自动", isOn: $isAutoAppearence)
                    if isAutoAppearence {
                        NavigationLink(destination: { AutoAppearenceOptionsView() }, label: {
                            VStack(alignment: .leading) {
                                Text("选项")
                                Text({
                                    if autoAppearenceOptionTrigger == "Sun" {
                                        AppearenceManager.shared.currentAppearence == .light ? "日落前保持浅色外观" : "日出前保持深色外观"
                                    } else {
                                        AppearenceManager.shared.currentAppearence == .light ? "\(autoAppearenceOptionTimeRangeDark)前保持浅色外观"
                                        : "\(autoAppearenceOptionTimeRangeLight)前保持深色外观"
                                    }
                                }())
                                .font(.footnote)
                                .foregroundStyle(.gray)
                                .animation(.default, value: autoAppearenceOptionTrigger)
                            }
                        })
                    }
                    Toggle("降低亮度", isOn: $isReduceBrightness)
                    VStack {
                        Slider(value: $reduceBrightnessLevel, in: 0.0...0.8, step: 0.05) {
                            Text("降低亮度")
                        }
                        Text(String(format: "%.2f", reduceBrightnessLevel))
                    }
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                } header: {
                    Text("外观")
                } footer: {
                    Text("屏幕右上方的时间不会被降低亮度")
                }
                Section {
                    Toggle("限制最小字体大小", isOn: $isWebMinFontSizeStricted)
                    VStack {
                        Slider(value: $webMinFontSize, in: 10...50, step: 1) {
                            Text("字体大小")
                        }
                        Text(String(format: "%.0f", webMinFontSize))
                    }
                    .disabled(!isWebMinFontSizeStricted)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
            .navigationTitle("显示与亮度")
        }
        
        struct AutoAppearenceOptionsView: View {
            @AppStorage("DBAutoAppearenceOptionTrigger") var autoAppearenceOptionTrigger = "CustomTimeRange"
            @AppStorage("DBAutoAppearenceOptionTimeRangeLight") var autoAppearenceOptionTimeRangeLight = "7:00"
            @AppStorage("DBAutoAppearenceOptionTimeRangeDark") var autoAppearenceOptionTimeRangeDark = "22:00"
            @AppStorage("DBAutoAppearenceOptionEnableForReduceBrightness") var autoAppearenceOptionEnableForReduceBrightness = false
            @AppStorage("DBAutoAppearenceOptionEnableForWebForceDark") var autoAppearenceOptionEnableForWebForceDark = true
            @State var isLocationPermissionRequestInfoPresented = false
            @State var isSunPrivacySplashPresented = false
            @State var lightTimeSelectionHour = "7"
            @State var lightTimeSelectionMinute = "00"
            @State var darkTimeSelectionHour = "22"
            @State var darkTimeSelectionMinute = "00"
            var body: some View {
                Form {
                    List {
                        Section {} footer: {
                            Text("设定时间让外观自动更改。暗礁浏览器可能会等到你不使用屏幕时才执行外观切换。")
                        }
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    Picker("定时切换外观", selection: $autoAppearenceOptionTrigger) {
                        Text("日落到日出").tag("Sun")
                        Text("自定义时段").tag("CustomTimeRange")
                    }
                    .pickerStyle(.inline)
                    .onChange(of: autoAppearenceOptionTrigger) { _ in
                        if autoAppearenceOptionTrigger == "Sun" {
                            if CLLocationManager().authorizationStatus != .notDetermined {
                                CachedLocationManager.shared.updateCache {
                                    AppearenceManager.shared.updateAll()
                                }
                            } else {
                                isLocationPermissionRequestInfoPresented = true
                            }
                        }
                    }
                    List {
                        if autoAppearenceOptionTrigger == "Sun" {
                            Section {} footer: {
                                VStack(alignment: .leading) {
                                    HStack(spacing: 2) {
                                        Image(systemName: "apple.logo")
                                        Text("天气")
                                    }
                                    Button(action: {
                                        isSunPrivacySplashPresented = true
                                    }, label: {
                                        Text("关于根据日落与日出切换外观与隐私...")
                                            .foregroundStyle(.blue)
                                    })
                                    .buttonStyle(.plain)
                                }
                            }
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .offset(y: -20)
                        }
                        if autoAppearenceOptionTrigger == "CustomTimeRange" {
                            Section {
                                NavigationLink(destination: {
                                    HourMinuteSelectorView(hour: $lightTimeSelectionHour, minute: $lightTimeSelectionMinute) {
                                        autoAppearenceOptionTimeRangeLight = "\(lightTimeSelectionHour):\(lightTimeSelectionMinute)"
                                    }
                                }, label: {
                                    HStack {
                                        Text("浅色")
                                        Spacer()
                                        Text(autoAppearenceOptionTimeRangeLight)
                                            .foregroundStyle(.gray)
                                    }
                                })
                                NavigationLink(destination: {
                                    HourMinuteSelectorView(hour: $darkTimeSelectionHour, minute: $darkTimeSelectionMinute) {
                                        autoAppearenceOptionTimeRangeDark = "\(darkTimeSelectionHour):\(darkTimeSelectionMinute)"
                                    }
                                }, label: {
                                    HStack {
                                        Text("深色")
                                        Spacer()
                                        Text(autoAppearenceOptionTimeRangeDark)
                                            .foregroundStyle(.gray)
                                    }
                                })
                            }
                        }
                        Section {
                            Toggle("降低屏幕亮度", isOn: $autoAppearenceOptionEnableForReduceBrightness)
                            Toggle("网页强制深色模式", isOn: $autoAppearenceOptionEnableForWebForceDark)
                        } header: {
                            Text("外观作用域")
                        }
                    }
                }
                .navigationTitle("外观选项")
                .sheet(isPresented: $isLocationPermissionRequestInfoPresented, content: { LocationPremissionView() })
                .sheet(isPresented: $isSunPrivacySplashPresented, content: { AboutSunAutoAppearenceAndPrivacy() })
                .onAppear {
                    let lightTimeSplited = autoAppearenceOptionTimeRangeLight.components(separatedBy: ":")
                    let darkTimeSplited = autoAppearenceOptionTimeRangeDark.components(separatedBy: ":")
                    lightTimeSelectionHour = lightTimeSplited[0]
                    lightTimeSelectionMinute = lightTimeSplited[1]
                    darkTimeSelectionHour = darkTimeSplited[0]
                    darkTimeSelectionMinute = darkTimeSplited[1]
                }
            }
            
            struct LocationPremissionView: View {
                @State var isPrivacySplashPresented = false
                var body: some View {
                    ScrollView {
                        VStack {
                            Image(systemName: "location.square.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            Text("需要定位服务权限以根据日落与日出切换外观")
                                .font(.system(size: 22))
                                .multilineTextAlignment(.center)
                                .padding(.vertical)
                            Button(action: {
                                isPrivacySplashPresented = true
                            }, label: {
                                HStack {
                                    Image(systemName: "hand.raised.square.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.blue)
                                    Text("关于根据日落与日出切换外观与隐私")
                                    Spacer()
                                }
                            })
                            Button(action: {
                                CLLocationManager().requestWhenInUseAuthorization()
                            }, label: {
                                Text("使用定位服务")
                            })
                            .tint(.blue)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.roundedRectangle(radius: 14))
                        }
                    }
                    .navigationTitle("定位服务权限")
                    .sheet(isPresented: $isPrivacySplashPresented, content: { AboutSunAutoAppearenceAndPrivacy() })
                    .onDisappear {
                        CachedLocationManager.shared.updateCache()
                    }
                }
            }
            struct AboutSunAutoAppearenceAndPrivacy: View {
                var body: some View {
                    PrivacyAboutView(
                        title: "关于根据日落与日出切换外观与隐私",
                        description: Text("你的位置信息将被发送至 Apple 天气以获取日落与日出时间。\(Text("进一步了解...").foregroundColor(.blue))"),
                        detailText: """
                        **根据日落与日出切换外观与隐私**
                        
                        暗礁浏览器和 Apple 天气旨在保护你的信息并可让你选择要共享的内容。
                        
                        在“定时切换外观”设置为“日落到日出”时，暗礁浏览器会在本地存储你当前的位置信息并向 Apple 天气发送副本以获取天气信息。位置信息仅被发送到 Apple 天气，不会与包括
                         Darock 在内的任何第三方共享。
                        
                        你可以随时在暗礁浏览器的设置中关闭“根据日落与日出切换外观”，一旦此选项关闭，暗礁浏览器将立即停止收集你的位置信息且不会发送到 Apple 天气，直到再次启用。
                        
                        访问 https://www.apple.com/privacy 了解 Apple 对数据的管理方式。
                        """
                    )
                }
            }
            struct HourMinuteSelectorView: View {
                @Binding var hour: String
                @Binding var minute: String
                var completion: () -> Void
                @Environment(\.presentationMode) private var presentationMode
                var body: some View {
                    VStack {
                        Spacer()
                        HStack(spacing: 2) {
                            Picker("小时", selection: $hour) {
                                ForEach(0..<24, id: \.self) { i in
                                    Text(String(i)).tag(String(i))
                                }
                            }
                            Text(":")
                            Picker("分钟", selection: $minute) {
                                ForEach(Array(0..<60).map {
                                    let str = String($0)
                                    if str.count >= 2 {
                                        return str
                                    } else {
                                        return "0" + str
                                    }
                                }, id: \.self) { i in
                                    Text(i).tag(i)
                                }
                            }
                        }
                        .font(.title2)
                        Button(action: {
                            completion()
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Text("完成")
                        })
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
    struct BrowsingEngineSettingsView: View {
        @AppStorage("isUseOldWebView") var isUseOldWebView = false
        @AppStorage("WebViewLayout") var webViewLayout = "MaximumViewport"
        @AppStorage("BrowsingMenuLayout") var browsingMenuLayout = "Detailed"
        @AppStorage("RequestDesktopWeb") var requestDesktopWeb = false
        @AppStorage("UseBackforwardGesture") var useBackforwardGesture = true
        @AppStorage("KeepDigitalTime") var keepDigitalTime = false
        @AppStorage("HideDigitalTime") var hideDigitalTime = false
        @AppStorage("ShowFastExitButton") var showFastExitButton = false
        @AppStorage("AlwaysReloadWebPageAfterCrash") var alwaysReloadWebPageAfterCrash = false
        @AppStorage("PreloadSearchContent") var preloadSearchContent = true
        @AppStorage("ForceApplyDarkMode") var forceApplyDarkMode = false
        @AppStorage("LBIsAutoEnterReader") var isAutoEnterReader = true
        @AppStorage("IsProPurchased") var isProPurchased = false
        var body: some View {
            List {
                Section {
                    Toggle("使用旧版浏览引擎", isOn: $isUseOldWebView)
                }
                if !isUseOldWebView {
                    Section {
                        Picker("网页视图", selection: $webViewLayout) {
                            Label("最大可视区域", systemImage: "applewatch.case.inset.filled").tag("MaximumViewport")
                            Label("模糊顶部", systemImage: "platter.filled.top.applewatch.case").tag("BlurTopBar")
                            Label("快速返回", systemImage: "chevron.backward.circle").tag("FastPrevious")
                        }
                        .disabled(!isProPurchased)
                        Picker("浏览菜单", selection: $browsingMenuLayout) {
                            Label("详细", systemImage: "list.bullet").tag("Detailed")
                            Label("紧凑", systemImage: "circle.grid.3x3.fill").tag("Compact")
                        }
                        .disabled(!isProPurchased)
//                        NavigationLink(destination: { FastButtonsView() }, label: {
//                            VStack(alignment: .leading) {
//                                Text("快捷按钮")
//                                if webViewLayout == "FastPrevious" {
//                                    Text("网页视图布局为“快速返回”时，快捷按钮不可用")
//                                        .font(.footnote)
//                                        .foregroundStyle(.gray)
//                                }
//                            }
//                        })
//                        .disabled(!isProPurchased || webViewLayout == "FastPrevious")
                    } header: {
                        Text("布局")
                    } footer: {
                        if !isProPurchased {
                            NavigationLink(destination: { ProPurchaseView() }, label: {
                                Text("\(Text("激活暗礁浏览器 Pro ").bold().foregroundColor(.blue))以更改布局设置。")
                            })
                            .buttonStyle(.plain)
                        }
                    }
                    Section {
                        Toggle(isOn: $requestDesktopWeb) {
                            HStack {
                                Image(systemName: "desktopcomputer")
                                    .foregroundStyle(.blue.gradient)
                                Text("请求桌面网站")
                            }
                        }
                        Toggle(isOn: $useBackforwardGesture) {
                            HStack {
                                Image(systemName: "hand.draw")
                                    .foregroundStyle(.purple.gradient)
                                Text("使用手势返回上一页")
                            }
                        }
                        Toggle(isOn: $hideDigitalTime) {
                            HStack {
                                Image(systemName: "clock.badge.xmark")
                                    .foregroundStyle(.blue.gradient)
                                Text("隐藏时间")
                            }
                        }
                        .onChange(of: hideDigitalTime) { _ in
                            if hideDigitalTime {
                                keepDigitalTime = false
                            }
                        }
                        Toggle(isOn: $keepDigitalTime) {
                            HStack {
                                Image(systemName: "clock")
                                Text("保持时间可见")
                            }
                        }
                        .disabled(webViewLayout == "FastPrevious")
                        .onChange(of: keepDigitalTime) { _ in
                            if keepDigitalTime {
                                hideDigitalTime = false
                            }
                        }
                        Toggle(isOn: $showFastExitButton) {
                            HStack {
                                Image(systemName: "escape")
                                    .foregroundStyle(.red.gradient)
                                Text("显示“快速退出”按钮")
                            }
                        }
                        .disabled(webViewLayout == "FastPrevious")
                        Toggle(isOn: $alwaysReloadWebPageAfterCrash) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundStyle(.blue.gradient)
                                Text("网页崩溃后总是自动重新载入")
                            }
                        }
                        if #available(watchOS 10, *) {
                            Toggle(isOn: $preloadSearchContent) {
                                HStack {
                                    Image(systemName: "sparkle.magnifyingglass")
                                        .foregroundStyle(.orange.gradient)
                                    Text("预载入搜索内容")
                                }
                            }
                        }
                        Toggle(isOn: $forceApplyDarkMode) {
                            HStack {
                                Image(systemName: "rectangle.inset.filled")
                                    .foregroundStyle(.gray.gradient)
                                Text("强制深色模式")
                            }
                        }
                    }
                } else {
                    Section {
                        Toggle(isOn: $isAutoEnterReader) {
                            HStack {
                                Image(systemName: "doc.plaintext")
                                    .foregroundStyle(.blue.gradient)
                                Text("可用时自动进入阅读器")
                            }
                        }
                    }
                }
            }
            .navigationTitle("浏览引擎")
        }
        
        struct FastButtonsView: View {
            @State var buttons = [WebViewFastButton].getCurrentFastButtons()
            var body: some View {
                List {
                    Section {
                        HStack {
                            Image(systemName: "ellipsis.circle")
                            ForEach(0..<buttons.count, id: \.self) { i in
                                Spacer()
                                Image(systemName: {
                                    switch buttons[i] {
                                    case .nextPage: "chevron.forward"
                                    case .previousPage: "chevron.backward"
                                    case .refresh: "arrow.clockwise"
                                    case .decodeVideo: "film.stack"
                                    case .decodeImage: "photo.stack"
                                    case .decodeMusic: "music.quarternote.3"
                                    case .exit: "escape"
                                    case .empty: "ellipsis.circle"
                                    }
                                }())
                                .opacity(buttons[i] == .empty ? 0.0100000002421438702673861521 : 1)
                                .foregroundStyle(buttons[i] == .exit ? .red : .blue)
                            }
                        }
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                    } header: {
                        Text("预览")
                    }
                    .listRowBackground(Color.clear)
                    Section {
                        ForEach(0..<buttons.count, id: \.self) { i in
                            Picker("按钮 \(i + 1)", selection: $buttons[i]) {
                                Text("无").tag(WebViewFastButton.empty)
                                Text("上一页").tag(WebViewFastButton.previousPage)
                                Text("下一页").tag(WebViewFastButton.nextPage)
                                Text("重新载入").tag(WebViewFastButton.refresh)
                                Text("退出网页").tag(WebViewFastButton.exit)
                                Text("播放网页视频").tag(WebViewFastButton.decodeVideo)
                                Text("查看网页图片").tag(WebViewFastButton.decodeImage)
                                Text("播放网页音频").tag(WebViewFastButton.decodeMusic)
                            }
                        }
                    }
                }
                .navigationTitle("快捷按钮")
            }
        }
    }
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
                        Text("管理自定搜索引擎...")
                    })
                    NavigationLink(destination: { SearchEngineShortcutSettingsView() }, label: {
                        Text("搜索引擎快捷方式...")
                    })
                }
            }
            .navigationTitle("搜索")
            .onAppear {
                customSearchEngineList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
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
                }, content: { AddCustomSearchEngineView(isAddCustomSEPresented: $isAddCustomSEPresented) })
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
                                Text(
                                    customSearchEngineList[i]
                                        .replacingOccurrences(of: "%lld", with: String(localized: "Settings.search.customize.search-content"))
                                )
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
                                NavigationLink(destination: { Step2(customUrlInput: customUrlInput, isAddCustomSEPresented: $isAddCustomSEPresented) }, label: {
                                    Text("Settings.search.customize.next")
                                })
                                .disabled(customUrlInput.isEmpty)
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
                            .digitalCrownRotation(
                                $cursorPosition,
                                from: 0,
                                through: Double(charas.count - 1),
                                by: 1,
                                sensitivity: .medium,
                                isHapticFeedbackEnabled: true
                            )
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
            }
        }
    }
    #if compiler(>=6)
    struct GesturesSettingsView: View {
        @AppStorage("GSIsDoubleTapEnabled") var isDoubleTapEnabled = false
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { DoubleTapSettingsView() }, label: {
                        VStack(alignment: .leading) {
                            Text("互点两下")
                            Text(isDoubleTapEnabled ? "开启" : "关闭")
                                .foregroundStyle(.gray)
                        }
                    })
                }
            }
            .navigationTitle("手势")
        }
        
        struct DoubleTapSettingsView: View {
            @AppStorage("GSIsDoubleTapEnabled") var isDoubleTapEnabled = false
            @AppStorage("GSGlobalAction") var globalAction = "None"
            @AppStorage("GSInWebAction") var inWebAction = "None"
            @AppStorage("GSOpenWebLink") var openWebLink = ""
            @AppStorage("GSQuickAvoidanceAction") var quickAvoidanceAction = "ShowEmpty"
            @State var isHistorySelectorPresented = false
            var body: some View {
                Form {
                    List {
                        Section {
                            Toggle("互点两下", isOn: $isDoubleTapEnabled)
                        } footer: {
                            if #available(watchOS 11.0, *), WKInterfaceDevice.supportsDoubleTapGesture {
                                Text("食指和拇指互点两下以执行指定的操作。互点两下必须已在系统“手势”设置中打开。")
                            } else {
                                Text("食指和拇指互点两下以执行指定的操作。需要先在系统设置→辅助功能中启用“快速操作”。")
                            }
                        }
                    }
                    if isDoubleTapEnabled {
                        Picker("全局操作", selection: $globalAction) {
                            Text("无").tag("None")
                            Text("打开网页").tag("OpenWeb")
                            Text("紧急回避").tag("QuickAvoidance")
                        }
                        .pickerStyle(.inline)
                        Picker("网页内操作", selection: $inWebAction) {
                            Text("无").tag("None")
                            Text("退出网页").tag("ExitWeb")
                            Text("重新载入网页").tag("ReloadWeb")
                            Text("紧急回避").tag("QuickAvoidance")
                        }
                        .pickerStyle(.inline)
                        List {
                            if globalAction == "OpenWeb" {
                                Section {
                                    TextField("链接", text: $openWebLink) {
                                        if !openWebLink.isURL() {
                                            openWebLink = ""
                                            tipWithText("网页链接无效", symbol: "xmark.circle.fill")
                                            return
                                        }
                                        if !openWebLink.hasPrefix("http://") && !openWebLink.hasPrefix("https://") {
                                            openWebLink = "http://" + openWebLink
                                        }
                                    }
                                    Button(action: {
                                        isHistorySelectorPresented = true
                                    }, label: {
                                        Label("从历史记录选择", systemImage: "clock.badge.checkmark")
                                    })
                                } header: {
                                    Text("打开网页行为")
                                }
                            }
                            if globalAction == "QuickAvoidance" || inWebAction == "QuickAvoidance" {
                                Section {
                                    Picker(selection: $quickAvoidanceAction, content: {
                                        Text("显示空屏幕").tag("ShowEmpty")
                                        Text("退出暗礁浏览器").tag("ExitApp")
                                    }, label: {})
                                    .pickerStyle(.inline)
                                    if quickAvoidanceAction == "ShowEmpty" {
                                        NavigationLink(destination: { ShowEmptyPreview(isActionGlobal: globalAction == "QuickAvoidance") }, label: {
                                            Text("预览...")
                                        })
                                    }
                                } header: {
                                    Text("紧急回避行为")
                                } footer: {
                                    if quickAvoidanceAction == "ExitApp" {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.yellow)
                                            Text("如果误触发手势，所有未保存的更改也将丢失！")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("互点两下")
                .sheet(isPresented: $isHistorySelectorPresented) {
                    NavigationStack {
                        HistoryView { sel in
                            openWebLink = sel
                            isHistorySelectorPresented = false
                        }
                        .navigationTitle("选取历史记录")
                    }
                }
            }
            
            struct ShowEmptyPreview: View {
                var isActionGlobal: Bool
                @State var isScreenCleared = false
                var body: some View {
                    ZStack {
                        if !isActionGlobal {
                            Button("") {
                                isScreenCleared = true
                            }
                            .compatibleDoubleTapGesture()
                            .opacity(0.0100000002421438702673861521)
                            .allowsHitTesting(false)
                        }
                        ScrollView {
                            VStack {
                                ZStack {
                                    Color.blue
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                    Image(_internalSystemName: "hand.side.pinch.fill")
                                        .font(.system(size: 22))
                                }
                                Text("使用“互点两下”手势以显示空屏幕")
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical)
                                Text("轻触三下屏幕以恢复，或按下数码表冠以返回表盘。")
                                    .multilineTextAlignment(.center)
                            }
                        }
                        if isScreenCleared {
                            Color.black
                                .ignoresSafeArea()
                                .onTapGesture(count: 3) {
                                    isScreenCleared = false
                                }
                        }
                    }
                    .navigationBarBackButtonHidden(isScreenCleared)
                    ._statusBarHidden(isScreenCleared)
                }
            }
        }
    }
    #endif
    
    struct PasswordSettingsView: View {
        @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
        @AppStorage("UsePasscodeForLockDarockBrowser") var usePasscodeForLockDarockBrowser = false
        @AppStorage("UsePasscodeForLockBookmarks") var usePasscodeForLockBookmarks = false
        @AppStorage("UsePasscodeForLockHistories") var usePasscodeForLockHistories = false
        @AppStorage("UsePasscodeForLocalAudios") var usePasscodeForLocalAudios = false
        @AppStorage("UsePasscodeForLocalImages") var usePasscodeForLocalImages = false
        @AppStorage("UsePasscodeForLocalVideos") var usePasscodeForLocalVideos = false
        @AppStorage("UsePasscodeForWebArchives") var usePasscodeForWebArchives = false
        @AppStorage("UsePasscodeForLocalBooks") var usePasscodeForLocalBooks = false
        @AppStorage("IsSecurityDelayEnabled") var isSecurityDelayEnabled = false
        @AppStorage("LabTabBrowsingEnabled") var labTabBrowsingEnabled = false
        @AppStorage("UsePasscodeForBrowsingTab") var usePasscodeForBrowsingTab = false
        @State var isSetPasswordInputPresented = false
        @State var isSetPasswordConfirmInputPresented = false
        @State var isClosePasswordPresented = false
        @State var isChangePasswordPresented = false
        @State var passcodeInputTmp = ""
        @State var passcodeInputTmp2 = ""
        var body: some View {
            List {
                if !userPasscodeEncrypted.isEmpty {
                    Section {
                        Toggle("锁定暗礁浏览器", isOn: $usePasscodeForLockDarockBrowser)
                        Toggle("锁定书签", isOn: $usePasscodeForLockBookmarks)
                        Toggle("锁定历史记录", isOn: $usePasscodeForLockHistories)
                        Toggle("锁定本地音频", isOn: $usePasscodeForLocalAudios)
                        Toggle("锁定本地图片", isOn: $usePasscodeForLocalImages)
                        Toggle("锁定本地视频", isOn: $usePasscodeForLocalVideos)
                        Toggle("锁定网页归档", isOn: $usePasscodeForWebArchives)
                        Toggle("锁定本地图书", isOn: $usePasscodeForLocalBooks)
                        if labTabBrowsingEnabled {
                            Toggle("锁定标签页", isOn: $usePasscodeForBrowsingTab)
                        }
                    } header: {
                        Text("将密码用于：")
                    }
                }
                Section {
                    if !userPasscodeEncrypted.isEmpty {
                        Button(action: {
                            isClosePasswordPresented = true
                        }, label: {
                            Text("关闭密码")
                        })
                        .sheet(isPresented: $isClosePasswordPresented) {
                            PasswordInputView(text: $passcodeInputTmp, placeholder: "输入当前密码") { pwd in
                                if pwd.md5 == userPasscodeEncrypted {
                                    userPasscodeEncrypted = ""
                                    tipWithText("密码已关闭", symbol: "checkmark.circle.fill")
                                } else {
                                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                                }
                                passcodeInputTmp = ""
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                        Button(action: {
                            isChangePasswordPresented = true
                        }, label: {
                            Text("更改密码")
                        })
                        .sheet(isPresented: $isChangePasswordPresented) {
                            PasswordInputView(text: $passcodeInputTmp, placeholder: "输入当前密码") { pwd in
                                if pwd.md5 == userPasscodeEncrypted {
                                    isSetPasswordInputPresented = true
                                } else {
                                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                                }
                                passcodeInputTmp = ""
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                        .sheet(isPresented: $isSetPasswordInputPresented) {
                            PasswordInputView(text: $passcodeInputTmp, placeholder: "输入新密码") { pwd in
                                passcodeInputTmp = pwd
                                isSetPasswordConfirmInputPresented = true
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                        .sheet(isPresented: $isSetPasswordConfirmInputPresented) {
                            PasswordInputView(text: $passcodeInputTmp2, placeholder: "确认密码") { pwd in
                                if passcodeInputTmp == pwd {
                                    userPasscodeEncrypted = pwd.md5
                                    passcodeInputTmp = ""
                                    tipWithText("密码已设置", symbol: "checkmark.circle.fill")
                                } else {
                                    isSetPasswordConfirmInputPresented = true
                                }
                                passcodeInputTmp2 = ""
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                    } else {
                        Button(action: {
                            isSetPasswordInputPresented = true
                        }, label: {
                            Text("开启密码")
                        })
                        .sheet(isPresented: $isSetPasswordInputPresented) {
                            PasswordInputView(text: $passcodeInputTmp, placeholder: "输入新密码") { pwd in
                                passcodeInputTmp = pwd
                                isSetPasswordConfirmInputPresented = true
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                        .sheet(isPresented: $isSetPasswordConfirmInputPresented) {
                            PasswordInputView(text: $passcodeInputTmp2, placeholder: "确认密码") { pwd in
                                if passcodeInputTmp == pwd {
                                    userPasscodeEncrypted = pwd.md5
                                    passcodeInputTmp = ""
                                    tipWithText("密码已设置", symbol: "checkmark.circle.fill")
                                } else {
                                    isSetPasswordConfirmInputPresented = true
                                }
                                passcodeInputTmp2 = ""
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                    }
                }
            }
            .navigationTitle("密码")
        }
    }
    struct PrivacySettingsView: View {
        @State var isAboutPrivacyPresented = false
        var body: some View {
            List {
                Section {
                    Button(action: {
                        isAboutPrivacyPresented = true
                    }, label: {
                        Text("关于暗礁浏览器与隐私")
                    })
                }
                Section {
                    NavigationLink(destination: { CookieView() },
                                   label: { SettingItemLabel(title: "Cookie", image: "doc.fill", color: .gray) })
                    NavigationLink(destination: { WebsiteSecurityView() },
                                   label: { SettingItemLabel(title: "站点安全", image: "macwindow.on.rectangle", color: .gray) })
                }
                Section {
                    NavigationLink(destination: { DeveloperModeView() }, label: {
                        SettingItemLabel(title: "开发者模式", image: "hammer.fill", color: .gray, symbolFontSize: 10)
                    })
                } header: {
                    Text("安全性")
                }
            }
            .navigationTitle("隐私与安全性")
            .sheet(isPresented: $isAboutPrivacyPresented) {
                PrivacyAboutView(title: "关于暗礁浏览器与隐私", description: Text("\(Text("关于暗礁浏览器与隐私...").foregroundColor(.accentColor))"), detailText: """
                **关于暗礁浏览器与隐私**
                
                暗礁浏览器旨在保护你的信息并可让你选择共享的内容。
                
                ## 数据收集与使用
                本节中列出了暗礁浏览器 App 可能收集个人数据的功能及其对应的数据类别和用途。
                
                ### App
                暗礁浏览器 App 会收集少量的、与隐私信息无关的、不与你身份关联的交互数据（例如 App 启动）。这些数据将与其他人的数据汇总，仅用于 App 分析。
                
                ### Darock 账户
                在注册 Darock 账户时，Darock 会收集你的电子邮件地址。作为 Darock 账户凭据的一部分，电子邮件地址用于识别你的身份，以提供需要账户支持的 Darock 服务。
                
                ### 存储至 Darock Cloud
                #### 历史记录
                如果你选择将历史记录存储至 Darock Cloud，你最近的浏览历史记录将会自动上传至 Darock Cloud。这些信息将在受保护的区域存储，且不会用于向你提供历史记录同步功能以外的用途。
                
                ### 反馈助理
                在通过反馈助理提交反馈时，反馈助理会收集基于 IP 的大致位置。此信息被隔离存储，且不与你的身份关联，并会在合理的时间内被删除。这些信息仅用于保护 Darock 服务器和反馈助理，以及防止欺诈行为。
                
                反馈助理还会收集 App 诊断信息，你可以在每次提交前查看这些信息，并可选择删除。
                
                仅在你在反馈助理中选择“提交”后，这些信息才会被收集和发送。
                """)
            }
        }
        
        struct CookieView: View {
            @AppStorage("AllowCookies") var allowCookies = true
            var body: some View {
                List {
                    Section {
                        Toggle(isOn: $allowCookies) {
                            VStack(alignment: .leading) {
                                Text("Settings.cookies.allow")
                                Text("Settings.cookies.description")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                            }
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "minus.diamond")
                            Text("Settings.cookies.limitation")
                        }
                    }
                }
                .navigationTitle("Cookie")
            }
        }
        struct WebsiteSecurityView: View {
            @AppStorage("IsShowFraudulentWebsiteWarning") var isShowFraudulentWebsiteWarning = true
            @AppStorage("WKJavaScriptEnabled") var isJavaScriptEnabled = true
            var body: some View {
                List {
                    Section {
                        Toggle("显示欺诈性网站警告", isOn: $isShowFraudulentWebsiteWarning)
                        Toggle("JavaScript", isOn: $isJavaScriptEnabled)
                    }
                }
                .navigationTitle("站点安全")
            }
        }
        
        struct DeveloperModeView: View {
            @AppStorage("IsDeveloperModeEnabled") var isDeveloperModeEnabled = false
            var body: some View {
                List {
                    Section {
                        Toggle("开发者模式", isOn: $isDeveloperModeEnabled)
                    } footer: {
                        Text("如果你正在进行网页开发，开发者模式允许你使用开发所需的功能。")
                    }
                }
                .navigationTitle("开发者模式")
            }
        }
    }
    
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
                            Text("Safari 18.0")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15")
                            Text("Safari - iOS 17.4 - iPhone")
                                .tag(
                                    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
                                )
                            Text("Safari - iPadOS 17.4 - iPad mini")
                                .tag(
                                    "Mozilla/5.0 (iPad; CPU OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
                                )
                            Text("Safari - iPadOS 17.4 - iPad")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15")
                        }
                        Section {
                            Text("Microsoft Edge - macOS")
                                .tag(
                                    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
                                )
                            Text("Microsoft Edge - Windows")
                                .tag(
                                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
                                )
                        }
                        Section {
                            Text("Google Chrome - macOS")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                            Text("Google Chrome - Windows")
                                .tag("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                        }
                        Section {
                            Text("Firefox - macOS")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0")
                            Text("Firefox - Windows")
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
    struct InternalDebuggingView: View {
        @AppStorage("SecurityDelayStartTime") var securityDelayStartTime = -1.0
        @AppStorage("TQCIsColorChangeButtonUnlocked") var isColorChangeButtonUnlocked = false
        @AppStorage("TQCIsColorChangeButtonEntered") var isColorChangeButtonEntered = false
        @AppStorage("IsProPurchased") var isProPurchased = false
        @State var isTestAppRemovalWarningPresented = false
        var body: some View {
            List {
                Section {
                    Button(action: {
                        tipWithText("\(String(isDebuggerAttached()))", symbol: "hammer.circle.fill")
                    }, label: {
                        Text("Present Debugger Attach Status")
                    })
                    Button(action: {
                        print(NSHomeDirectory())
                    }, label: {
                        Text("Print NSHomeDirectory")
                    })
                } header: {
                    Text("Debugger")
                }
                Section {
                    Button(action: {
                        tipWithText("\(ProcessInfo.processInfo.thermalState)", symbol: "hammer.circle.fill")
                    }, label: {
                        Text("Present Thermal State")
                    })
                } header: {
                    Text("Energy & Performance")
                }
                Section {
                    Button(action: {
                        tipWithText(String(getWebHistory().count), symbol: "hammer.circle.fill")
                    }, label: {
                        Text("Present History Count")
                    })
                } header: {
                    Text("Data & Cloud")
                }
                Section {
                    Button(action: {
                        isProPurchased = false
                        UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.set(false, forKey: "IsProWidgetsAvailable")
                        WidgetCenter.shared.reloadAllTimelines()
                        WidgetCenter.shared.invalidateConfigurationRecommendations()
                    }, label: {
                        Text("Reset Pro State")
                    })
                    Button(action: {
                        isProPurchased = true
                        UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.set(true, forKey: "IsProWidgetsAvailable")
                        WidgetCenter.shared.reloadAllTimelines()
                        WidgetCenter.shared.invalidateConfigurationRecommendations()
                    }, label: {
                        Text("Active Pro")
                    })
                } header: {
                    Text("Purchasing")
                }
                Section {
                    Button(action: {
                        do {
                            throw NSError(domain: "com.darock.DarockBrowser.TestError", code: 1)
                        } catch {
                            globalErrorHandler(error)
                        }
                    }, label: {
                        Text("Toggle an Internal Error")
                    })
                } header: {
                    Text("Error Handler")
                }
                Section {
                    Button(action: {
                        UserDefaults.standard.removeObject(forKey: "ShouldTipNewFeatures")
                        for i in 1...50 {
                            UserDefaults.standard.removeObject(forKey: "ShouldTipNewFeatures\(i)")
                        }
                    }, label: {
                        Text("Reset All What's New Screen State")
                    })
                    Button(action: {
                        isColorChangeButtonUnlocked = false
                        isColorChangeButtonEntered = false
                    }, label: {
                        Text("Reset TQCAccentColorHiddenButton")
                    })
                } header: {
                    Text("What's New Screen & TQC")
                }
                Section {
                    Button(role: .destructive, action: {
                        fatalError("Internal Debugging Crash")
                    }, label: {
                        Text("Crash This App through Swift fatalError")
                    })
                    Button(role: .destructive, action: {
                        let e = NSException(name: NSExceptionName.mallocException, reason: "Internal Debugging Exception", userInfo: ["Info": "Debug"])
                        e.raise()
                    }, label: {
                        Text("Crash This App through NSException")
                    })
                    Button(role: .destructive, action: {
                        isTestAppRemovalWarningPresented = true
                    }, label: {
                        HStack {
                            Text("Run App Removal Service")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .foregroundColor(.gray)
                        }
                    })
                } header: {
                    Text("Danger Zone")
                }
                Section {
                    NavigationLink(destination: { FeatureFlagsView() }, label: {
                        Label("Feature Flags", systemImage: "flag")
                    })
                }
            }
            .navigationTitle("Debugging")
            .alert("Test Browser App Removal", isPresented: $isTestAppRemovalWarningPresented, actions: {
                Button(role: .cancel, action: {
                    
                }, label: {
                    Text("Cancel")
                        .bold()
                })
                Button(role: .destructive, action: {
                    UserDefaults.standard.removeObject(forKey: "*")
                    try! FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/*")
                    exit(0)
                }, label: {
                    Text("Continue")
                })
            }, message: {
                VStack {
                    Text("This will delete all Darock Browser app data.")
                    Text("All data will be lost!")
                }
            })
            .toolbar {
                if #available(watchOS 10.5, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            WKExtension.shared().openSystemURL(URL(string: "https://darock.top/internal/tap-to-radar/new?ProductName=Darock Browser")!)
                        }, label: {
                            Image(systemName: "ant.fill")
                        })
                    }
                }
            }
        }
        
        func isDebuggerAttached() -> Bool {
            var name = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
            var info = kinfo_proc()
            var infoSize = MemoryLayout<kinfo_proc>.stride
            
            let result = name.withUnsafeMutableBytes {
                sysctl($0.baseAddress!.assumingMemoryBound(to: Int32.self), 4, &info, &infoSize, nil, 0)
            }
            
            assert(result == 0, "sysctl failed")
            
            return (info.kp_proc.p_flag & P_TRACED) != 0
        }
        
        struct FeatureFlagsView: View {
            var body: some View {
                List {
                    
                }
                .navigationTitle("Feature Flags")
            }
        }
    }
}

final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    public var manager = CLLocationManager()
    public var location: CLLocationCoordinate2D?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue = locations.first else { return }
        manager.stopUpdatingLocation()
        location = locValue.coordinate
    }
}
final class CachedLocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = CachedLocationManager()
    
    public var manager: CLLocationManager
    
    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    @AppStorage("CLMCachedLatitude") var cachedLatitude = 0.0
    @AppStorage("CLMCachedLongitude") var cachedLongitude = 0.0
    
    var updateCompletionHandler: () -> Void = {}
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue = locations.first else { return }
        cachedLatitude = locValue.coordinate.latitude
        cachedLongitude = locValue.coordinate.longitude
        updateCompletionHandler()
        os_log(.info, "Cached Location Updated: \(self.cachedLatitude), \(self.cachedLongitude)")
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        globalErrorHandler(error)
    }
    
    public func updateCache(withCompletionHandler completion: @escaping () -> Void = {}) {
        os_log(.info, "Updating Cached Location...")
        updateCompletionHandler = completion
        manager.requestLocation()
    }
    public func getCachedLocation() -> CLLocationCoordinate2D {
        .init(latitude: cachedLatitude, longitude: cachedLongitude)
    }
    public func getCachedLocation() -> CLLocation {
        .init(latitude: cachedLatitude, longitude: cachedLongitude)
    }
}

enum EngineNames: String, CaseIterable {
    case bing = "必应"
    case baidu = "百度"
    case google = "谷歌"
    case sougou = "搜狗"
}

enum WebViewFastButton: Codable {
    case previousPage
    case nextPage
    case refresh
    case decodeVideo
    case decodeImage
    case decodeMusic
    case exit
    case empty
}
extension [WebViewFastButton] {
    static func getCurrentFastButtons() -> Self {
        if let jsonStr = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/WebViewFastButtons.drkdataw", encoding: .utf8),
           let data = getJsonData(Self.self, from: jsonStr) {
            if data.count == 4 {
                return data
            }
        }
        return [.empty, .empty, .empty, .empty]
    }
    
    func updateFastButtons() {
        if let jsonStr = jsonString(from: self) {
            do {
                try jsonStr.write(toFile: NSHomeDirectory() + "/Documents/WebViewFastButtons.drkdataw", atomically: true, encoding: .utf8)
            } catch {
                globalErrorHandler(error)
            }
        }
    }
}
