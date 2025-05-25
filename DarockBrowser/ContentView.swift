//
//  ContentView.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//

import UIKit
import SwiftUI
import Cepheus
import EFQRCode
import Punycode
import Alamofire
import SwiftyJSON
import DarockFoundation
import AuthenticationServices

var pIsAudioControllerAvailable = false
var pShouldPresentAudioController = false

struct ContentView: View {
    @AppStorage("IsHistoryTransferNeeded") var isHistoryTransferNeeded = true
    @AppStorage("DarockAccount") var darockAccount = ""
    @AppStorage("DCSaveHistory") var isSaveHistoryToCloud = false
    @AppStorage("isUseOldWebView") var isUseOldWebView = false
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("IsUseTabBasedBrowsing") var isUseTabBasedBrowsing = true
    @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
    @AppStorage("IsProPurchased") var isProPurchased = false
    @State var mainTabSelection = 2
    @State var isVideoListPresented = false
    @State var isImageListPresented = false
    @State var isAudioListPresented = false
    @State var isBookListPresented = false
    @State var isAudioControllerPresented = false
    var body: some View {
        Group {
            if #available(watchOS 10.0, *) {
                Group {
                    if !isUseOldWebView && isUseTabBasedBrowsing {
                        TabsListView { onCreate in
                            MainView(createPageAction: onCreate)
                        }
                    } else {
                        NavigationStack {
                            MainView()
                                .modifier(UserDefinedBackground())
                        }
                    }
                }
                .sheet(isPresented: $isVideoListPresented, content: { NavigationStack { VideoListView() } })
                .sheet(isPresented: $isImageListPresented, content: { NavigationStack { ImageListView() } })
                .sheet(isPresented: $isAudioListPresented, content: { NavigationStack { AudioListView() } })
                .sheet(isPresented: $isBookListPresented, content: { NavigationStack { BookListView() } })
            } else {
                NavigationView {
                    MainView()
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
    }
}

struct MainView: View {
    var createPageAction: ((NewWebTabConfiguration) -> Void)?
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("IsLongPressAlternativeSearch") var isLongPressAlternativeSearch = false
    @AppStorage("AlternativeSearch") var alternativeSearch = "必应"
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
    @AppStorage("isUseOldWebView") var isUseOldWebView = false
    @AppStorage("ShouldShowRatingRequest") var shouldShowRatingRequest = false
    @AppStorage("MainPageShowCount") var mainPageShowCount = 0
    @AppStorage("IsShowJoinGroup2") var isShowJoinGroup = true
    @AppStorage("IsShowClusterAd") var isShowClusterAd = true
    @AppStorage("IsBetaJoinAvailable") var isBetaJoinAvailable = false
    @State var textOrURL = ""
    @State var goToButtonLabelText: LocalizedStringKey = "Home.search"
    @State var isKeyboardPresented = false
    @State var isCookieTipPresented = false
    @State var pinnedBookmarkIndexs = [Int]()
    @State var webArchiveLinks = [String]()
    @State var newFeedbackCount = 0
    @State var isNewVerAvailable = false
    var body: some View {
        List {
            Section {
                searchField
                searchButton
            }
            Section {
                NavigationLink(destination: {
                    if let createPageAction {
                        BookmarkView(showAllControls: true) { name, link in
                            createPageAction(.init(url: link, title: name))
                        }
                    } else {
                        BookmarkView()
                    }
                }, label: {
                    Label("Home.bookmarks", systemImage: "bookmark")
                        .centerAligned()
                })
                NavigationLink(destination: {
                    if let createPageAction {
                        HistoryView(showAllControls: true) { link in
                            createPageAction(.init(url: link))
                        }
                    } else {
                        HistoryView()
                    }
                }, label: {
                    Label("Home.history", systemImage: "clock")
                        .centerAligned()
                })
                if !webArchiveLinks.isEmpty {
                    NavigationLink(destination: {
                        if let createPageAction {
                            WebArchiveListView { name, link in
                                createPageAction(.init(url: link, title: name, isWebArchive: true))
                            }
                        } else {
                            WebArchiveListView()
                        }
                    }, label: {
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
                if createPageAction == nil {
                    NavigationLink(destination: { MediaMainView() }, label: {
                        Label("媒体", systemImage: "rectangle.stack")
                            .centerAligned()
                    })
                }
            }
            if pinnedBookmarkIndexs.count != 0 {
                Section {
                    ForEach(0..<pinnedBookmarkIndexs.count, id: \.self) { i in
                        Button(action: {
                            if let createPageAction {
                                createPageAction(.init(url: UserDefaults.standard.string(forKey: "BookmarkLink\(pinnedBookmarkIndexs[i])")!))
                            } else {
                                AdvancedWebViewController.shared.present(
                                    UserDefaults.standard.string(forKey: "BookmarkLink\(pinnedBookmarkIndexs[i])")!
                                )
                            }
                        }, label: {
                            Text(UserDefaults.standard.string(forKey: "BookmarkName\(pinnedBookmarkIndexs[i])") ?? "")
                                .privacySensitive()
                        })
                    }
                } header: {
                    Text("固定的书签")
                }
            }
            if #unavailable(watchOS 10.0) {
                Section {
                    NavigationLink(destination: {
                        SettingsView()
                    }, label: {
                        Label("Home.settings", systemImage: "gear")
                    })
                }
            }
            if createPageAction == nil {
                Section {
                    NavigationLink(destination: { FeedbackView() }, label: {
                        VStack {
                            Label("反馈助理", systemImage: "exclamationmark.bubble")
                            if isNewVerAvailable {
                                Text("“反馈助理”不可用，因为暗礁浏览器有更新可用")
                                    .font(.system(size: 12))
                                    .multilineTextAlignment(.center)
                            }
                        }
                    })
                    .disabled(isNewVerAvailable)
                    NavigationLink(destination: { TipsView() }, label: {
                        Label("提示", privateSystemImage: "tips")
                    })
                }
                Section {
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
                    if isBetaJoinAvailable && !isAppBetaBuild {
                        NavigationLink(value: TabMainPageSeletion.customView(.betaTesting)) {
                            Label("参与 Beta 测试", systemImage: "person.badge.clock")
                                .centerAligned()
                        }
                    }
                    if #available(watchOS 10, *), isShowClusterAd {
                        NavigationLink(value: TabMainPageSeletion.customView(.clusterAd)) {
                            Label("推荐 - 暗礁文件", systemImage: "sparkles")
                                .centerAligned()
                        }
                    }
                    if isShowJoinGroup {
                        NavigationLink(value: TabMainPageSeletion.customView(.joinGroup)) {
                            Label("欢迎加入群聊", systemImage: "bubble.left.and.bubble.right")
                                .centerAligned()
                        }
                    }
                }
            }
        }
        .wrapIf({ if #available(watchOS 10.0, *) { true } else { false } }()) { content in
            if #available(watchOS 10.0, *) {
                content
                    .modifier(UserDefinedBackground())
            }
        }
        .navigationTitle(createPageAction != nil ? String(localized: "起始页") : String(localized: "暗礁浏览器"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if #available(watchOS 10.0, *), createPageAction == nil {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: {
                        SettingsView()
                    }, label: {
                        Image(systemName: "gear")
                    })
                }
            }
        }
        .onAppear {
            pinnedBookmarkIndexs = (UserDefaults.standard.array(forKey: "PinnedBookmarkIndex") as! [Int]?) ?? [Int]()
            webArchiveLinks = UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()
            
            if createPageAction == nil {
                requestAPI("/drkbs/newver") { respStr, isSuccess in
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
                requestAPI("/tf/get/DarockBrowser") { respStr, isSuccess in
                    if isSuccess {
                        isBetaJoinAvailable = respStr.apiFixed() != "[None]"
                    }
                }
                mainPageShowCount++
                if mainPageShowCount == 10 {
                    shouldShowRatingRequest = true
                }
            }
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            if createPageAction == nil, let url = userActivity.webpageURL, var openUrl = url.absoluteString.split(separator: "darock.top/darockbrowser/open/", maxSplits: 1)[from: 1] {
                if !openUrl.hasPrefix("http://") && !openUrl.hasPrefix("https://") {
                    openUrl = "http://" + openUrl
                }
                AdvancedWebViewController.shared.present(String(openUrl).urlEncoded())
            }
        }
    }
    
    @ViewBuilder var searchField: some View {
        TextField("Home.search-or-URL", text: $textOrURL) {
            if textOrURL.isURL() {
                goToButtonLabelText = "Home.go"
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
            startSearch(textOrURL, with: webSearch, createPageAction: createPageAction)
        }, label: {
            HStack {
                Spacer()
                Label(goToButtonLabelText, systemImage: goToButtonLabelText == "Home.search" ? "magnifyingglass" : "globe")
                    .font(.system(size: 18))
                Spacer()
            }
        })
        .onTapGesture {
            startSearch(textOrURL, with: webSearch, createPageAction: createPageAction)
        }
        .onLongPressGesture {
            if isLongPressAlternativeSearch {
                startSearch(textOrURL, with: alternativeSearch, createPageAction: createPageAction)
            }
        }
    }
}

func startSearch(_ textOrURL: String, with engine: String, createPageAction: ((NewWebTabConfiguration) -> Void)? = nil) {
    var textOrURL = textOrURL
    if textOrURL.hasSuffix(".mp4") {
        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
            textOrURL = "http://" + textOrURL
        }
        videoLinkLists = [textOrURL]
        pShouldPresentVideoList = true
        recordHistory(textOrURL, webSearch: engine)
        return
    } else if textOrURL.hasSuffix(".mp3") {
        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
            textOrURL = "http://" + textOrURL
        }
        audioLinkLists = [textOrURL]
        pShouldPresentAudioList = true
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
        recordHistory(textOrURL, webSearch: engine)
        return
    } else if textOrURL.hasSuffix(".epub") {
        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
            textOrURL = "http://" + textOrURL
        }
        bookLinkLists = [textOrURL]
        pShouldPresentBookList = true
        recordHistory(textOrURL, webSearch: engine)
        return
    }
    let isSearchEngineShortcutEnabled = UserDefaults.standard.bool(forKey: "IsSearchEngineShortcutEnabled")
    if textOrURL.isURL() {
        if !textOrURL.contains(":") {
            textOrURL = "http://" + textOrURL
        }
        if let createPageAction {
            createPageAction(.init(url: textOrURL.urlEncoded()))
        } else {
            AdvancedWebViewController.shared.present(textOrURL.urlEncoded())
        }
    } else {
        if let createPageAction {
            createPageAction(.init(url: getWebSearchedURL(textOrURL, webSearch: engine, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled)))
        } else {
            AdvancedWebViewController.shared.present(
                getWebSearchedURL(textOrURL, webSearch: engine, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled)
            )
        }
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
        guard URL(string: self) != nil else { return false }
        if let topLevel = getTopLevel(from: self)?.idnaEncoded {
            // Xcode organizer shows many sessions crashed here without reason, so use optional binding instead of force unwrapping.
            if let _domainListURL = Bundle.main.url(forResource: "TopLevelDomainList", withExtension: "drkdatat"),
               var topLevelDomainList = (try? String(contentsOf: _domainListURL, encoding: .utf8))?.split(separator: "\n").map({ String($0) }) {
                topLevelDomainList.removeAll(where: { str in str.hasPrefix("#") || str.isEmpty })
                if topLevelDomainList.contains(topLevel.uppercased().replacingOccurrences(of: " ", with: "")) {
                    return true
                }
            } else {
                // Character count as fallback
                return (2...3).contains(topLevel.count)
            }
        }
        if self.split(separator: ".").first?.contains("://") ?? false {
            return true
        } else {
            return false
        }
    }
}

#Preview {
    ContentView()
}
