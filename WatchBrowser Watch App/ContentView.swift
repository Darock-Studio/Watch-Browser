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
import WatchKit
import Punycode
import DarockKit
import Alamofire
import SwiftyJSON
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
                                    .accessibilityIdentifier("MainSettingsButton")
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
                                LocalMediaView()
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
                    ZStack {
                        NavigationLink("", isActive: $isVideoListPresented, destination: { VideoListView() })
                            .frame(width: 0, height: 0)
                            .hidden()
                        NavigationLink("", isActive: $isImageListPresented, destination: { ImageListView() })
                            .frame(width: 0, height: 0)
                            .hidden()
                        NavigationLink("", isActive: $isAudioListPresented, destination: { AudioListView() })
                            .frame(width: 0, height: 0)
                            .hidden()
                        NavigationLink("", isActive: $isBookListPresented, destination: { BookListView() })
                            .frame(width: 0, height: 0)
                            .hidden()
                        MainView(withSetting: .constant(true))
                    }
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
            if !darockAccount.isEmpty && isSaveHistoryToCloud {
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
    }
    
    @available(watchOS 10.0, *) @ViewBuilder var mainWithBackground: some View {
        if overrideType == "image" && isOverrideAccentColor,
           let imageData = NSData(contentsOfFile: NSHomeDirectory() + "/Documents/CustomHomeBackground.drkdatac") as? Data,
           let image = UIImage(data: imageData) {
            MainView(withSetting: $showSettingsButtonInList)
                .containerBackground(for: .navigation) {
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
        } else {
            MainView(withSetting: $showSettingsButtonInList)
                .containerBackground(
                    isOverrideAccentColor
                    ? Color(red: overrideAccentColorRed, green: overrideAccentColorGreen, blue: overrideAccentColorBlue).gradient
                    : Color(hex: 0x13A4FF).gradient,
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
    @AppStorage("IsShowBetaTest1") var isShowBetaTest = true
    @AppStorage("IsShowDAssistantAd") var isShowDAssistantAd = true
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
        .onContinueUserActivity(NSStringFromClass(SearchIntent.self)) { userActivity in
            debugPrint(userActivity)
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
                        globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
                    }
                }
                customControls = data
            } else {
                customControls = HomeScreenControlType.defaultScreen
            }
            
            pinnedBookmarkIndexs = (UserDefaults.standard.array(forKey: "PinnedBookmarkIndex") as! [Int]?) ?? [Int]()
            webArchiveLinks = UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()
            let feedbackIds = UserDefaults.standard.stringArray(forKey: "RadarFBIDs") ?? [String]()
            newFeedbackCount = 0
            for id in feedbackIds {
                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/details/Darock Browser/\(id)") { respStr, isSuccess in
                    if isSuccess {
                        let repCount = respStr.apiFixed().components(separatedBy: "---").count - 1
                        let lastViewCount = UserDefaults.standard.integer(forKey: "RadarFB\(id)ReplyCount")
                        if repCount > lastViewCount {
                            newFeedbackCount++
                        }
                    }
                }
            }
            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/drkbs/newver") { respStr, isSuccess in
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
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos") {
                    isHaveDownloadedVideo = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos").isEmpty
                }
            } catch {
                globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
            }
            do {
                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios") {
                    isHaveDownloadedAudio = try !FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios").isEmpty
                }
            } catch {
                globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
            }
            isOfflineBooksAvailable = !(UserDefaults.standard.stringArray(forKey: "EPUBFlieFolders") ?? [String]()).isEmpty
            isAudioControllerAvailable = pIsAudioControllerAvailable
            mainPageShowCount++
            if mainPageShowCount == 10 {
                shouldShowRatingRequest = true
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
                        TextField("Home.search-or-URL", text: $textOrURL) {
                            if textOrURL.isURL() {
                                goToButtonLabelText = "Home.go"
                                if preloadSearchContent && !isUseOldWebView {
                                    var tmpUrl = textOrURL
                                    if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
                                        tmpUrl = "http://" + textOrURL
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
                                    let total = userdefault.integer(forKey: "BookmarkTotal") + 1
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
                                            ? textOrURL.urlEncoded()
                                            : "http://" + textOrURL.urlEncoded(),
                                            forKey: "BookmarkLink\(total)"
                                        )
                                    } else {
                                        userdefault.set(
                                            getWebSearchedURL(textOrURL, webSearch: webSearch, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled)
                                                .urlEncoded(),
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
                            if textOrURL != "" {
                                Button(action: {
                                    textOrURL = ""
                                    goToButtonLabelText = "Home.search"
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                            }
                        }
                    case .searchButton:
                        Button(action: {
                            startSearch(with: webSearch)
                        }, label: {
                            HStack {
                                Spacer()
                                Label(goToButtonLabelText, systemImage: goToButtonLabelText == "Home.search" ? "magnifyingglass" : "globe")
                                    .font(.system(size: 18))
                                Spacer()
                            }
                        })
                        .onTapGesture {
                            startSearch(with: webSearch)
                        }
                        .onLongPressGesture {
                            if isLongPressAlternativeSearch {
                                startSearch(with: alternativeSearch, allowPreload: false)
                            }
                        }
                        .accessibilityIdentifier("MainSearchButton")
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
                                HStack {
                                    Spacer()
                                    Label("Home.bookmarks", systemImage: "bookmark")
                                    Spacer()
                                }
                            })
                            .accessibilityIdentifier("MainBookmarkButton")
                        case .history:
                            NavigationLink(destination: {
                                HistoryView()
                            }, label: {
                                HStack {
                                    Spacer()
                                    Label("Home.history", systemImage: "clock")
                                    Spacer()
                                }
                            })
                            .accessibilityIdentifier("MainHistoryButton")
                        case .webarchive:
                            if !webArchiveLinks.isEmpty {
                                NavigationLink(destination: { WebArchiveListView() }, label: {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Label("网页归档", systemImage: "archivebox")
                                            Spacer()
                                        }
                                        if isUseOldWebView {
                                            HStack {
                                                Spacer()
                                                Text("使用旧版引擎时，网页归档不可用")
                                                    .font(.system(size: 12))
                                                    .multilineTextAlignment(.center)
                                                Spacer()
                                            }
                                        }
                                    }
                                })
                                .disabled(isUseOldWebView)
                            }
                        case .musicPlaylist:
                            NavigationLink(destination: { PlaylistsView() }, label: {
                                HStack {
                                    Spacer()
                                    Label("播放列表", systemImage: "music.note.list")
                                    Spacer()
                                }
                            })
                        case .localMedia:
                            if isHaveDownloadedAudio || isOfflineBooksAvailable || isHaveDownloadedVideo {
                                NavigationLink(destination: { LocalMediaView() }, label: {
                                    HStack {
                                        Spacer()
                                        Label("本地媒体", systemImage: "play.square.stack")
                                        Spacer()
                                    }
                                })
                            }
                        case .userscript:
                            NavigationLink(destination: { UserScriptsView() }, label: {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Label("用户脚本", systemImage: "applescript")
                                        Spacer()
                                    }
                                    if isUseOldWebView {
                                        HStack {
                                            Spacer()
                                            Text("使用旧版引擎时，用户脚本不可用")
                                                .font(.system(size: 12))
                                                .multilineTextAlignment(.center)
                                            Spacer()
                                        }
                                    }
                                }
                            })
                            .disabled(isUseOldWebView)
                            .accessibilityIdentifier("MainUserScriptButton")
                        case .chores:
                            if shouldShowRatingRequest {
                                Button(action: {
                                    shouldShowRatingRequest = false
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text("喜欢暗礁浏览器？前往 iPhone 上的 App Store 为我们评分！")
                                        Text("轻触以隐藏")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.gray)
                                    }
                                })
                            }
                            if #available(watchOS 10, *), isShowDAssistantAd {
                                NavigationLink(destination: { DAssistAdView() }, label: {
                                    HStack {
                                        Spacer()
                                        Label("推荐 - 暗礁助手", systemImage: "sparkles")
                                        Spacer()
                                    }
                                })
                            }
                            if isShowBetaTest {
                                NavigationLink(destination: { MLTestsView() }, label: {
                                    HStack {
                                        Spacer()
                                        Label("Home.invatation", systemImage: "megaphone")
                                        Spacer()
                                    }
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
                            .accessibilityIdentifier("MainFeedbackButton")
                        case .tips:
                            NavigationLink(destination: { TipsView() }, label: {
                                Label("提示", systemImage: "lightbulb")
                            })
                        case .settings:
                            if withSetting {
                                NavigationLink(destination: {
                                    SettingsView()
                                }, label: {
                                    HStack {
                                        Spacer()
                                        Label("Home.settings", systemImage: "gear")
                                        Spacer()
                                    }
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    func startSearch(with engine: String, allowPreload: Bool = true) {
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
        if #available(watchOS 10, *), preloadSearchContent && !isUseOldWebView && isPreloadedSearchWeb && allowPreload {
            AdvancedWebViewController.shared.present()
            isPreloadedSearchWeb = false
            return
        }
        if textOrURL.isURL() {
            if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
                textOrURL = "http://" + textOrURL
            }
            AdvancedWebViewController.shared.present(textOrURL.urlEncoded())
        } else {
            AdvancedWebViewController.shared.present(
                getWebSearchedURL(textOrURL, webSearch: engine, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled)
            )
        }
    }
}

func getWebSearchedURL(_ iUrl: String, webSearch: String, isSearchEngineShortcutEnabled: Bool) -> String {
    var wisu = ""
    if isSearchEngineShortcutEnabled {
        if iUrl.hasPrefix("bing") {
            return "https://www.bing.com/search?q=\(iUrl.urlEncoded().dropFirst(4).replacingOccurrences(of: "&", with: "%26"))"
        } else if iUrl.hasPrefix("baidu") {
            return "https://www.baidu.com/s?wd=\(iUrl.urlEncoded().dropFirst(5).replacingOccurrences(of: "&", with: "%26"))"
        } else if iUrl.hasPrefix("google") {
            return "https://www.google.com/search?q=\(iUrl.urlEncoded().dropFirst(6).replacingOccurrences(of: "&", with: "%26"))"
        } else if iUrl.hasPrefix("sogou") {
            return "https://www.sogou.com/web?query=\(iUrl.urlEncoded().dropFirst(5).replacingOccurrences(of: "&", with: "%26"))"
        }
    }
    switch webSearch {
    case "必应":
        wisu = "https://www.bing.com/search?q=\(iUrl.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
    case "百度":
        wisu = "https://www.baidu.com/s?wd=\(iUrl.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
    case "谷歌":
        wisu = "https://www.google.com/search?q=\(iUrl.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
    case "搜狗":
        wisu = "https://www.sogou.com/web?query=\(iUrl.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
    default:
        wisu = webSearch.replacingOccurrences(of: "%lld", with: iUrl.urlEncoded().replacingOccurrences(of: "&", with: "%26"))
    }
    return wisu
}

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
    //将原始的url编码为合法的url
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }
     
    //将编码后的url转换回原始的url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
    
    //是否为URL
    func isURL() -> Bool {
        var topLevelDomainList = (try! String(contentsOf: Bundle.main.url(forResource: "TopLevelDomainList", withExtension: "drkdatat")!, encoding: .utf8))
            .split(separator: "\n")
            .map { String($0) }
        topLevelDomainList.removeAll(where: { str in str.hasPrefix("#") || str.isEmpty })
        if let topLevel = getTopLevel(from: self)?.idnaEncoded, topLevelDomainList.contains(topLevel.uppercased().replacingOccurrences(of: " ", with: "")) {
            return true
        } else if self.hasPrefix("http://") || self.hasPrefix("https://") {
            return true
        } else {
            return false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
