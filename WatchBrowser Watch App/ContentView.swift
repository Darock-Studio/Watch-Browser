//
//  ContentView.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//

import UIKit
import SwiftUI
import Dynamic
import Cepheus
import EFQRCode
import Punycode
import DarockKit
import Alamofire
import SwiftyJSON
import SaltUICore
import AuthenticationServices

var pIsAudioControllerAvailable = false
var pShouldPresentAudioController = false

struct ContentView: View {
    @AppStorage("LabTabBrowsingEnabled") var labTabBrowsingEnabled = false
    @AppStorage("IsHistoryTransferNeeded") var isHistoryTransferNeeded = true
    @AppStorage("DarockAccount") var darockAccount = ""
    @AppStorage("DCSaveHistory") var isSaveHistoryToCloud = false
    @AppStorage("TQCIsOverrideAccentColor") var isOverrideAccentColor = false
    @AppStorage("TQCOverrideAccentColorRed") var overrideAccentColorRed = 0.0
    @AppStorage("TQCOverrideAccentColorGreen") var overrideAccentColorGreen = 0.0
    @AppStorage("TQCOverrideAccentColorBlue") var overrideAccentColorBlue = 0.0
    @AppStorage("TQCHomeBackgroundOverrideType") var overrideType = "color"
    @AppStorage("TQCIsHomeBackgroundImageBlured") var isBackgroundImageBlured = true
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
    @AppStorage("IsProPurchased") var isProPurchased = false
    @State var currentToolbar: HomeScreenToolbar?
    @State var mainTabSelection = 2
    @State var isVideoListPresented = false
    @State var isImageListPresented = false
    @State var isAudioListPresented = false
    @State var isBookListPresented = false
    @State var isSettingsPresented = false
    @State var isTabsPresented = false
    @State var isAudioControllerPresented = false
    @State var toolbarNavigationDestination: HomeScreenNavigationType?
    @State var showSettingsButtonInList = false
    @State var isLowPowerReducingBackground = false
    var body: some View {
        Group {
            if #available(watchOS 10.0, *) {
                NavigationStack {
                    mainWithBackground
                        .toolbar {
                            if let currentToolbar {
                                getFullToolbar(by: currentToolbar, with: .main) { type, position, obj in
                                    if labTabBrowsingEnabled && position == .topTrailing {
                                        isTabsPresented = true
                                    } else {
                                        switch type {
                                        case .searchField, .searchButton:
                                            if var content = obj as? String {
                                                if content.isURL() {
                                                    if !content.hasPrefix("http://") && !content.hasPrefix("https://") {
                                                        content = "http://" + content
                                                    }
                                                    AdvancedWebViewController.shared.present(content.urlEncoded())
                                                } else {
                                                    AdvancedWebViewController.shared.present(
                                                        getWebSearchedURL(content,
                                                                          webSearch: webSearch,
                                                                          isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled)
                                                    )
                                                }
                                            }
                                        case .spacer, .pinnedBookmarks, .text:
                                            break
                                        case .navigationLink(let navigation):
                                            toolbarNavigationDestination = navigation
                                        }
                                    }
                                }
                            } else {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button(action: {
                                        isSettingsPresented = true
                                    }, label: {
                                        Image(systemName: "gear")
                                    })
                                }
                                if labTabBrowsingEnabled {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        Button(action: {
                                            isTabsPresented = true
                                        }, label: {
                                            Image(systemName: "square.on.square.dashed")
                                                .symbolRenderingMode(.hierarchical)
                                                .foregroundColor(.white)
                                        })
                                    }
                                }
                            }
                        }
                        .navigationDestination(isPresented: $isVideoListPresented, destination: { VideoListView() })
                        .navigationDestination(isPresented: $isImageListPresented, destination: { ImageListView() })
                        .navigationDestination(isPresented: $isAudioListPresented, destination: { AudioListView() })
                        .navigationDestination(isPresented: $isBookListPresented, destination: { BookListView() })
                        .navigationDestination(isPresented: $isSettingsPresented, destination: { SettingsView() })
                        .navigationDestination(isPresented: $isTabsPresented, destination: { BrowsingTabsView() })
                        .navigationDestination(item: $toolbarNavigationDestination) { destination in
                            switch destination {
                            case .bookmark:
                                BookmarkView()
                            case .history:
                                HistoryView()
                            case .webarchive:
                                WebArchiveListView()
                            case .musicPlaylist:
                                PlaylistsView()
                            case .localMedia:
                                MediaListView()
                            case .userscript:
                                UserScriptsView()
                            case .chores:
                                EmptyView()
                            case .feedbackAssistant:
                                FeedbackView()
                            case .tips:
                                TipsView()
                            case .settings:
                                SettingsView()
                            }
                        }
                        .onAppear {
                            if let currentPref = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/MainToolbar.drkdatam", encoding: .utf8),
                               let data = getJsonData(HomeScreenToolbar.self, from: currentPref) {
                                currentToolbar = data
                            } else {
                                currentToolbar = HomeScreenToolbar.default
                            }
                            if let currentToolbar {
                                if currentToolbar.topLeading == .navigationLink(.settings)
                                    || currentToolbar.topTrailing == .navigationLink(.settings)
                                    || currentToolbar.bottomLeading == .navigationLink(.settings)
                                    || currentToolbar.bottomTrailing == .navigationLink(.settings) {
                                    showSettingsButtonInList = false
                                } else {
                                    showSettingsButtonInList = true
                                }
                            }
                        }
                }
            } else {
                NavigationView {
                    MainView(withSetting: .constant(true))
                        ._navigationDestination(isPresented: $isVideoListPresented, content: { VideoListView() })
                        ._navigationDestination(isPresented: $isImageListPresented, content: { ImageListView() })
                        ._navigationDestination(isPresented: $isAudioListPresented, content: { AudioListView() })
                        ._navigationDestination(isPresented: $isBookListPresented, content: { BookListView() })
                }
            }
        }
        .sheet(isPresented: $isAudioControllerPresented, content: { AudioControllerView() })
        .onAppear {
            if _slowPath(isHistoryTransferNeeded) {
                if (UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()).isEmpty {
                    isHistoryTransferNeeded = false
                }
            }
            
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                if _slowPath(pShouldPresentVideoList) {
                    pShouldPresentVideoList = false
                    isVideoListPresented = true
                }
                if _slowPath(pShouldPresentImageList) {
                    pShouldPresentImageList = false
                    isImageListPresented = true
                }
                if _slowPath(pShouldPresentAudioList) {
                    pShouldPresentAudioList = false
                    isAudioListPresented = true
                }
                if _slowPath(pShouldPresentBookList) {
                    pShouldPresentBookList = false
                    isBookListPresented = true
                }
                if _slowPath(pShouldPresentAudioController) {
                    pShouldPresentAudioController = false
                    isAudioControllerPresented = true
                }
            }
            
            // Cloud
            if !darockAccount.isEmpty && isSaveHistoryToCloud && !ProcessInfo.processInfo.isLowPowerModeEnabled {
                Task {
                    if let cloudHistories = await getWebHistoryFromCloud(with: darockAccount) {
                        let currentHistories = getWebHistory()
                        let mergedHistories = mergeWebHistoriesBetween(primary: currentHistories, secondary: cloudHistories)
                        if mergedHistories != currentHistories {
                            writeWebHistory(from: mergedHistories)
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { processInfo in
            if let processInfo = processInfo.object as? ProcessInfo {
                isLowPowerReducingBackground = processInfo.isLowPowerModeEnabled
            }
        }
    }
    
    @available(watchOS 10.0, *) @ViewBuilder var mainWithBackground: some View {
        if overrideType == "image" && isOverrideAccentColor,
           let imageData = NSData(contentsOfFile: NSHomeDirectory() + "/Documents/CustomHomeBackground.drkdatac") as? Data,
           let image = UIImage(data: imageData) {
            MainView(withSetting: $showSettingsButtonInList)
                .containerBackground(for: .navigation) {
                    if !isLowPowerReducingBackground {
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: WKInterfaceDevice.current().screenBounds.width, height: WKInterfaceDevice.current().screenBounds.height)
                                .blur(radius: isBackgroundImageBlured ? 20 : 0)
                            if isBackgroundImageBlured {
                                Color.black
                                    .opacity(0.4)
                            }
                        }
                    }
                }
        } else {
            MainView(withSetting: $showSettingsButtonInList)
                .containerBackground(
                    !isLowPowerReducingBackground
                    ? (isOverrideAccentColor
                    ? Color(red: overrideAccentColorRed, green: overrideAccentColorGreen, blue: overrideAccentColorBlue).gradient
                    : Color(hex: 0x13A4FF).gradient)
                    : Color.black.gradient,
                    for: .navigation
                )
        }
    }
}



struct MainView: View {
    @Binding var withSetting: Bool
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("IsLongPressAlternativeSearch") var isLongPressAlternativeSearch = false
    @AppStorage("AlternativeSearch") var alternativeSearch = "必应"
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("IsShowJoinGroup") var isShowJoinGroup = true
    @AppStorage("IsShowClusterAd") var isShowClusterAd = true
    @AppStorage("IsBetaJoinAvailable") var isBetaJoinAvailable = false
    @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
    @AppStorage("PreloadSearchContent") var preloadSearchContent = true
    @AppStorage("isUseOldWebView") var isUseOldWebView = false
    @AppStorage("LabTabBrowsingEnabled") var labTabBrowsingEnabled = false
    @AppStorage("ShouldShowRatingRequest") var shouldShowRatingRequest = false
    @AppStorage("MainPageShowCount") var mainPageShowCount = 0
    @State var customControls = [HomeScreenControlType]()
    @State var textOrURL = ""
    @State var goToButtonLabelText: LocalizedStringKey = "Home.search"
    @State var isKeyboardPresented = false
    @State var isCookieTipPresented = false
    @State var pinnedBookmarkIndexs = [Int]()
    @State var webArchiveLinks = [String]()
    @State var newFeedbackCount = 0
    @State var isNewVerAvailable = false
    @State var isHaveDownloadedVideo = false
    @State var isHaveDownloadedAudio = false
    @State var isHaveLocalImage = false
    @State var isPreloadedSearchWeb = false
    @State var isOfflineBooksAvailable = false
    @State var isAudioControllerAvailable = false
    var body: some View {
        List {
            if isAudioControllerAvailable {
                Button(action: {
                    pShouldPresentAudioController = true
                }, label: {
                    HStack {
                        Spacer()
                        AudioVisualizerView()
                        Text("播放中")
                        Spacer()
                    }
                })
            }
            if !customControls.isEmpty {
                getMainView(by: customControls)
            } else {
                getMainView(by: HomeScreenControlType.defaultScreen)
            }
        }
        .navigationTitle("Home.title")
        .navigationBarTitleDisplayMode(.large)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            if let url = userActivity.webpageURL, var openUrl = url.absoluteString.split(separator: "darock.top/darockbrowser/open/", maxSplits: 1)[from: 1] {
                if !openUrl.hasPrefix("http://") && !openUrl.hasPrefix("https://") {
                    openUrl = "http://" + openUrl
                }
                AdvancedWebViewController.shared.present(String(openUrl).urlEncoded())
            }
        }
        .onAppear {
            if let currentPref = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/HomeScreen.drkdatah", encoding: .utf8),
               var data = getJsonData([HomeScreenControlType].self, from: currentPref) {
                if !data.contains(.navigationLink(.musicPlaylist)) {
                    data.append(.navigationLink(.musicPlaylist))
                }
                if !data.contains(.navigationLink(.localMedia)) {
                    data.append(.navigationLink(.localMedia))
                }
                if let newPref = jsonString(from: data) {
                    do {
                        try newPref.write(toFile: NSHomeDirectory() + "/Documents/HomeScreen.drkdatah", atomically: true, encoding: .utf8)
                    } catch {
                        globalErrorHandler(error)
                    }
                }
                customControls = data
            } else {
                customControls = HomeScreenControlType.defaultScreen
            }
            
            pinnedBookmarkIndexs = (UserDefaults.standard.array(forKey: "PinnedBookmarkIndex") as! [Int]?) ?? [Int]()
            webArchiveLinks = UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()
            if !ProcessInfo.processInfo.isLowPowerModeEnabled {
                let feedbackIds = UserDefaults.standard.stringArray(forKey: "RadarFBIDs") ?? [String]()
                newFeedbackCount = 0
                for id in feedbackIds {
                    DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/details/Darock Browser/\(id)".compatibleUrlEncoded()) { respStr, isSuccess in
                        if isSuccess {
                            let repCount = respStr.apiFixed().components(separatedBy: "---").count - 1
                            let lastViewCount = UserDefaults.standard.integer(forKey: "RadarFB\(id)ReplyCount")
                            if repCount > lastViewCount {
                                newFeedbackCount++
                            }
                        }
                    }
                }
            }
            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/drkbs/newver".compatibleUrlEncoded()) { respStr, isSuccess in
                if isSuccess {
                    let spdVer = respStr.apiFixed().split(separator: ".")
                    if spdVer.count == 3 {
                        if let x = Int(spdVer[0]), let y = Int(spdVer[1]), let z = Int(spdVer[2]) {
                            let currVerSpd = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).split(separator: ".")
                            if currVerSpd.count == 3 {
                                if let cx = Int(currVerSpd[0]), let cy = Int(currVerSpd[1]), let cz = Int(currVerSpd[2]) {
                                    if x > cx {
                                        isNewVerAvailable = true
                                    } else if x == cx && y > cy {
                                        isNewVerAvailable = true
                                    } else if x == cx && y == cy && z > cz {
                                        isNewVerAvailable = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/tf/get/DarockBrowser") { respStr, isSuccess in
                if isSuccess {
                    isBetaJoinAvailable = respStr.apiFixed() != "[None]"
                }
            }
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos") {
                    isHaveDownloadedVideo = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos").isEmpty
                }
            } catch {
                globalErrorHandler(error)
            }
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios") {
                    isHaveDownloadedAudio = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios").isEmpty
                }
            } catch {
                globalErrorHandler(error)
            }
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/LocalImages") {
                    isHaveLocalImage = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/LocalImages").isEmpty
                }
            } catch {
                globalErrorHandler(error)
            }
            isOfflineBooksAvailable = !(UserDefaults.standard.stringArray(forKey: "EPUBFlieFolders") ?? [String]()).isEmpty
            isAudioControllerAvailable = pIsAudioControllerAvailable
            mainPageShowCount++
            if mainPageShowCount == 10 {
                shouldShowRatingRequest = true
            }
        }
    }
    
    @ViewBuilder var searchField: some View {
        TextField("Home.search-or-URL", text: $textOrURL) {
            if textOrURL.isURL() {
                goToButtonLabelText = "Home.go"
                if preloadSearchContent && !isUseOldWebView {
                    var tmpUrl = textOrURL
                    if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
                        if !textOrURL.contains("://") {
                            tmpUrl = "http://" + textOrURL
                        } else {
                            return
                        }
                    }
                    AdvancedWebViewController.shared.present(tmpUrl.urlEncoded(), presentController: false)
                    isPreloadedSearchWeb = true
                }
            } else {
                if isSearchEngineShortcutEnabled {
                    if textOrURL.hasPrefix("bing") {
                        goToButtonLabelText = "Home.search.bing"
                    } else if textOrURL.hasPrefix("baidu") {
                        goToButtonLabelText = "Home.search.baidu"
                    } else if textOrURL.hasPrefix("google") {
                        goToButtonLabelText = "Home.search.google"
                    } else if textOrURL.hasPrefix("sogou") {
                        goToButtonLabelText = "Home.search.sogou"
                    } else {
                        goToButtonLabelText = "Home.search"
                    }
                } else {
                    goToButtonLabelText = "Home.search"
                }
                if preloadSearchContent && !isUseOldWebView {
                    AdvancedWebViewController.shared.present(
                        getWebSearchedURL(textOrURL, webSearch: webSearch, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled),
                        presentController: false
                    )
                    isPreloadedSearchWeb = true
                }
            }
        }
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .privacySensitive()
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if textOrURL != "" {
                Button(action: {
                    let userdefault = UserDefaults.standard
                    let total = userdefault.integer(forKey: "BookmarkTotal") &+ 1
                    let markName = { () -> String in
                        if textOrURL.isURL() {
                            if textOrURL.hasPrefix("https://") || textOrURL.hasPrefix("http://") {
                                let ped = textOrURL.split(separator: "://")[1]
                                let sed = ped.split(separator: "/")[0]
                                let ded = sed.split(separator: ".")
                                return String(ded[ded.count - 2])
                            } else {
                                let sed = textOrURL.split(separator: "/")[0]
                                let ded = sed.split(separator: ".")
                                return String(ded[ded.count - 2])
                            }
                        } else {
                            return textOrURL
                        }
                    }()
                    userdefault.set(markName, forKey: "BookmarkName\(total)")
                    if textOrURL.isURL() {
                        userdefault.set(
                            (textOrURL.hasPrefix("https://") || textOrURL.hasPrefix("http://"))
                            ? textOrURL
                            : "http://" + textOrURL,
                            forKey: "BookmarkLink\(total)"
                        )
                    } else {
                        userdefault.set(
                            getWebSearchedURL(textOrURL, webSearch: webSearch, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled),
                            forKey: "BookmarkLink\(total)"
                        )
                    }
                    userdefault.set(total, forKey: "BookmarkTotal")
                }, label: {
                    Image(systemName: "bookmark.fill")
                })
            }
        }
        .swipeActions {
            if !textOrURL.isEmpty {
                Button(action: {
                    textOrURL = ""
                    goToButtonLabelText = "Home.search"
                }, label: {
                    Image(systemName: "xmark.bin.fill")
                })
            }
        }
    }
    @ViewBuilder var searchButton: some View {
        Button(action: {
            startSearch(textOrURL, with: webSearch, allowPreload: isPreloadedSearchWeb)
            isPreloadedSearchWeb = false
        }, label: {
            HStack {
                Spacer()
                Label(goToButtonLabelText, systemImage: goToButtonLabelText == "Home.search" ? "magnifyingglass" : "globe")
                    .font(.system(size: 18))
                Spacer()
            }
        })
        .onTapGesture {
            startSearch(textOrURL, with: webSearch, allowPreload: isPreloadedSearchWeb)
            isPreloadedSearchWeb = false
        }
        .onLongPressGesture {
            if isLongPressAlternativeSearch {
                startSearch(textOrURL, with: alternativeSearch, allowPreload: false)
            }
        }
    }
    
    @ViewBuilder
    func getMainView(by controls: [HomeScreenControlType]) -> some View {
        let dividedControls = controls.split(separator: .spacer).map { Array<HomeScreenControlType>($0) }
        ForEach(0..<dividedControls.count, id: \.self) { i in
            Section {
                ForEach(0..<dividedControls[i].count, id: \.self) { j in
                    switch dividedControls[i][j] {
                    case .searchField:
                        searchField
                    case .searchButton:
                        searchButton
                    case .spacer:
                        EmptyView()
                    case .pinnedBookmarks:
                        if pinnedBookmarkIndexs.count != 0 {
                            ForEach(0..<pinnedBookmarkIndexs.count, id: \.self) { i in
                                Button(action: {
                                    AdvancedWebViewController.shared.present(UserDefaults.standard.string(forKey: "BookmarkLink\(pinnedBookmarkIndexs[i])")!)
                                }, label: {
                                    Text(UserDefaults.standard.string(forKey: "BookmarkName\(pinnedBookmarkIndexs[i])") ?? "")
                                        .privacySensitive()
                                })
                            }
                        }
                    case .text(let text):
                        Text(text)
                            .listRowBackground(Color.clear)
                    case .navigationLink(let navigation):
                        switch navigation {
                        case .bookmark:
                            NavigationLink(destination: {
                                BookmarkView()
                            }, label: {
                                Label("Home.bookmarks", systemImage: "bookmark")
                                    .centerAligned()
                            })
                        case .history:
                            NavigationLink(destination: {
                                HistoryView()
                            }, label: {
                                Label("Home.history", systemImage: "clock")
                                    .centerAligned()
                            })
                        case .webarchive:
                            if !webArchiveLinks.isEmpty {
                                NavigationLink(destination: { WebArchiveListView() }, label: {
                                    VStack {
                                        Label("网页归档", systemImage: "archivebox")
                                        if isUseOldWebView {
                                            Text("使用旧版引擎时，网页归档不可用")
                                                .font(.system(size: 12))
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    .centerAligned()
                                })
                                .disabled(isUseOldWebView)
                            }
                        case .musicPlaylist:
                            NavigationLink(destination: { PlaylistsView() }, label: {
                                Label("播放列表", systemImage: "music.note.list")
                                    .centerAligned()
                            })
                        case .localMedia:
                            if isHaveDownloadedAudio || isHaveLocalImage || isOfflineBooksAvailable || isHaveDownloadedVideo {
                                NavigationLink(destination: { MediaListView() }, label: {
                                    Label("媒体列表", systemImage: "play.square.stack")
                                        .centerAligned()
                                })
                            }
                        case .userscript:
                            NavigationLink(destination: { UserScriptsView() }, label: {
                                VStack {
                                    Label("用户脚本", systemImage: "applescript")
                                    if isUseOldWebView {
                                        Text("使用旧版引擎时，用户脚本不可用")
                                            .font(.system(size: 12))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .centerAligned()
                            })
                            .disabled(isUseOldWebView)
                        case .chores:
                            if shouldShowRatingRequest {
                                Button(action: {
                                    shouldShowRatingRequest = false
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text("喜欢暗礁浏览器？前往 iPhone 上的 App Store 为我们评分！")
                                        Text("轻触以隐藏")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.gray)
                                    }
                                })
                            }
                            if isBetaJoinAvailable {
                                NavigationLink(destination: { BetaJoinView() }, label: {
                                    Label("参与 Beta 测试", systemImage: "person.badge.clock")
                                        .centerAligned()
                                })
                            }
                            if #available(watchOS 10, *), isShowClusterAd {
                                NavigationLink(destination: { ClusterAdView() }, label: {
                                    Label("推荐 - 暗礁文件", systemImage: "sparkles")
                                        .centerAligned()
                                })
                            }
                            if isShowJoinGroup {
                                NavigationLink(destination: { JoinGroupView() }, label: {
                                    Label("欢迎加入群聊", systemImage: "bubble.left.and.bubble.right")
                                        .centerAligned()
                                })
                            }
                        case .feedbackAssistant:
                            NavigationLink(destination: { FeedbackView() }, label: {
                                VStack {
                                    HStack {
                                        ZStack(alignment: .topTrailing) {
                                            Image(systemName: "exclamationmark.bubble")
                                                .font(.system(size: 20))
                                            if newFeedbackCount > 0 {
                                                Text("\(newFeedbackCount)")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .background(Circle().fill(Color.red).frame(width: 15, height: 15).opacity(1.0))
                                                    .offset(x: 3, y: -5)
                                                    .truncationMode(.head)
                                            }
                                        }
                                        Text("反馈助理")
                                    }
                                    if isNewVerAvailable {
                                        Text("“反馈助理”不可用，因为暗礁浏览器有更新可用")
                                            .font(.system(size: 12))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            })
                            .disabled(isNewVerAvailable)
                        case .tips:
                            NavigationLink(destination: { TipsView() }, label: {
                                Label("提示", privateSystemImage: "tips")
                            })
                        case .settings:
                            if withSetting {
                                NavigationLink(destination: {
                                    SettingsView()
                                }, label: {
                                    Label("Home.settings", systemImage: "gear")
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}

func startSearch(_ textOrURL: String, with engine: String, allowPreload: Bool = true) {
    var textOrURL = textOrURL
    if textOrURL.hasSuffix(".mp4") {
        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
            textOrURL = "http://" + textOrURL
        }
        videoLinkLists = [textOrURL]
        pShouldPresentVideoList = true
        dismissListsShouldRepresentWebView = false
        recordHistory(textOrURL, webSearch: engine)
        return
    } else if textOrURL.hasSuffix(".mp3") {
        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
            textOrURL = "http://" + textOrURL
        }
        audioLinkLists = [textOrURL]
        pShouldPresentAudioList = true
        dismissListsShouldRepresentWebView = false
        recordHistory(textOrURL, webSearch: engine)
        return
    } else if textOrURL.hasSuffix(".png")
                || textOrURL.hasSuffix(".jpg")
                || textOrURL.hasSuffix(".webp")
                || textOrURL.hasSuffix(".pdf") {
        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
            textOrURL = "http://" + textOrURL
        }
        imageLinkLists = [textOrURL]
        pShouldPresentImageList = true
        dismissListsShouldRepresentWebView = false
        recordHistory(textOrURL, webSearch: engine)
        return
    } else if textOrURL.hasSuffix(".epub") {
        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
            textOrURL = "http://" + textOrURL
        }
        bookLinkLists = [textOrURL]
        pShouldPresentBookList = true
        dismissListsShouldRepresentWebView = false
        recordHistory(textOrURL, webSearch: engine)
        return
    }
    let preloadSearchContent = UserDefaults.standard.bool(forKey: "PreloadSearchContent")
    let isUseOldWebView = UserDefaults.standard.bool(forKey: "isUseOldWebView")
    let isSearchEngineShortcutEnabled = UserDefaults.standard.bool(forKey: "IsSearchEngineShortcutEnabled")
    if #available(watchOS 10, *), preloadSearchContent && !isUseOldWebView && allowPreload {
        AdvancedWebViewController.shared.present()
        return
    }
    if textOrURL.isURL() {
        if !textOrURL.contains("://") {
            textOrURL = "http://" + textOrURL
        }
        AdvancedWebViewController.shared.present(textOrURL.urlEncoded())
    } else {
        AdvancedWebViewController.shared.present(
            getWebSearchedURL(textOrURL, webSearch: engine, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled)
        )
    }
}

/// 获取网页搜索链接
///
/// 没有匹配的可用搜索引擎时，此方法会返回空字符串。
///
/// - Parameters:
///   - content: 搜索内容
///   - webSearch: 搜索引擎
///   - isSearchEngineShortcutEnabled: 是否启用搜索引擎快捷方式
/// - Returns: 对应的搜索链接
@_effects(readnone)
func getWebSearchedURL(_ content: String, webSearch: String, isSearchEngineShortcutEnabled: Bool) -> String {
    var wisu = ""
    if isSearchEngineShortcutEnabled {
        if content.hasPrefix("bing") {
            return "https://www.bing.com/search?q=\(content.urlEncoded().dropFirst(4).replacingOccurrences(of: "&", with: "%26"))"
        } else if content.hasPrefix("baidu") {
            return "https://www.baidu.com/s?wd=\(content.urlEncoded().dropFirst(5).replacingOccurrences(of: "&", with: "%26"))"
        } else if content.hasPrefix("google") {
            return "https://www.google.com/search?q=\(content.urlEncoded().dropFirst(6).replacingOccurrences(of: "&", with: "%26"))"
        } else if content.hasPrefix("sogou") {
            return "https://www.sogou.com/web?query=\(content.urlEncoded().dropFirst(5).replacingOccurrences(of: "&", with: "%26"))"
        }
    }
    switch webSearch {
    case "必应":
        wisu = "https://www.bing.com/search?q=\(content.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
    case "百度":
        wisu = "https://www.baidu.com/s?wd=\(content.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
    case "谷歌":
        wisu = "https://www.google.com/search?q=\(content.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
    case "搜狗":
        wisu = "https://www.sogou.com/web?query=\(content.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
    default:
        wisu = webSearch.replacingOccurrences(of: "%lld", with: content.urlEncoded().replacingOccurrences(of: "&", with: "%26"))
    }
    return wisu
}

/// 获取URL的顶级域名称
/// - Parameter url: 要处理的URL
/// - Returns: 顶级域名称，e.g. com
func getTopLevel(from url: String) -> String? {
    if !url.contains(".") {
        return nil
    }
    let noScheme: String
    if url.hasPrefix("http://")
        || url.hasPrefix("https://")
        || url.hasPrefix("file://"),
       let spd = url.split(separator: "://")[from: 1] {
        noScheme = String(spd)
    } else {
        noScheme = url
    }
    if let dotSpd = noScheme.split(separator: "/").first {
        let specialCharacters: [Character] = ["/", "."]
        if let splashSpd = dotSpd.split(separator: ".").last, let colonSpd = splashSpd.split(separator: ":").first {
            if !colonSpd.contains(specialCharacters) {
                return String(colonSpd)
            }
        }
    }
    return nil
}

extension String {
    /// 将原始的url编码为合法的url
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return encodeUrlString ?? ""
    }
     
    /// 将编码后的url转换回原始的url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
    
    /// 仅为要求手动编码URL的系统编码URL
    func compatibleUrlEncoded() -> String {
        if #available(watchOS 10.0, *) {
            return self
        } else {
            return self.urlEncoded()
        }
    }
    
    /// 是否为URL
    func isURL() -> Bool {
        let dotSplited = self.split(separator: ".")
        if dotSplited.count == 4 {
            ip: do {
                for p in dotSplited {
                    if let i = Int(p), i < 256 && i >= 0 {
                        continue
                    } else {
                        break ip
                    }
                }
                return true
            }
        }
        var topLevelDomainList = (try! String(contentsOf: Bundle.main.url(forResource: "TopLevelDomainList", withExtension: "drkdatat")!, encoding: .utf8))
            .split(separator: "\n")
            .map { String($0) }
        topLevelDomainList.removeAll(where: { str in str.hasPrefix("#") || str.isEmpty })
        if let topLevel = getTopLevel(from: self)?.idnaEncoded, topLevelDomainList.contains(topLevel.uppercased().replacingOccurrences(of: " ", with: "")) {
            return true
        } else if self.split(separator: ".").first?.contains("://") ?? false {
            return true
        } else {
            return false
        }
    }
}

#Preview {
    ContentView()
}
