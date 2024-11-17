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
import DarockKit
import Alamofire
import SwiftyJSON
import AuthenticationServices

var pIsAudioControllerAvailable = false
var pShouldPresentAudioController = false

struct ContentView: View {
    @AppStorage("IsHistoryTransferNeeded") var isHistoryTransferNeeded = true
    @AppStorage("DarockAccount") var darockAccount = ""
    @AppStorage("DCSaveHistory") var isSaveHistoryToCloud = false
    @AppStorage("WebSearch") var webSearch = "必应"
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
                TabsListView { onCreate in
                    MainView(createPageAction: onCreate)
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
    @AppStorage("LabTabBrowsingEnabled") var labTabBrowsingEnabled = false
    @State var textOrURL = ""
    @State var goToButtonLabelText: LocalizedStringKey = "Home.search"
    @State var isKeyboardPresented = false
    @State var isCookieTipPresented = false
    @State var pinnedBookmarkIndexs = [Int]()
    @State var webArchiveLinks = [String]()
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
                                createPageAction(.init(url: link, title: name))
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
            }
            Section {
                if pinnedBookmarkIndexs.count != 0 {
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
        }
        .wrapIf({ if #available(watchOS 10.0, *) { true } else { false } }()) { content in
            if #available(watchOS 10.0, *) {
                content
                    .modifier(UserDefinedBackground())
            }
        }
        .navigationTitle("起始页")
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
            pinnedBookmarkIndexs = (UserDefaults.standard.array(forKey: "PinnedBookmarkIndex") as! [Int]?) ?? [Int]()
            webArchiveLinks = UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()
            isAudioControllerAvailable = pIsAudioControllerAvailable
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
        guard URL(string: self) != nil else { return false }
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
