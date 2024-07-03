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

struct ContentView: View {
    public static var bingSearchingText = ""
    @AppStorage("LabTabBrowsingEnabled") var labTabBrowsingEnabled = false
    @AppStorage("IsHistoryTransferNeeded") var isHistoryTransferNeeded = true
    @AppStorage("DarockAccount") var darockAccount = ""
    @AppStorage("DCSaveHistory") var isSaveHistoryToCloud = false
    @AppStorage("TQCIsOverrideAccentColor") var isOverrideAccentColor = false
    @AppStorage("TQCOverrideAccentColorRed") var overrideAccentColorRed = 0.0
    @AppStorage("TQCOverrideAccentColorGreen") var overrideAccentColorGreen = 0.0
    @AppStorage("TQCOverrideAccentColorBlue") var overrideAccentColorBlue = 0.0
    @State var mainTabSelection = 2
    @State var isVideoListPresented = false
    @State var isImageListPresented = false
    @State var isBookListPresented = false
    @State var isSettingsPresented = false
    @State var isTabsPresented = false
    var body: some View {
        NavigationStack {
            if #available(watchOS 10.0, *) {
                ZStack {
                    NavigationLink("", isActive: $isVideoListPresented, destination: { VideoListView() })
                        .frame(width: 0, height: 0)
                        .hidden()
                    NavigationLink("", isActive: $isImageListPresented, destination: { ImageListView() })
                        .frame(width: 0, height: 0)
                        .hidden()
                    NavigationLink("", isActive: $isBookListPresented, destination: { BookListView() })
                        .frame(width: 0, height: 0)
                        .hidden()
                    NavigationLink("", isActive: $isSettingsPresented, destination: { SettingsView() })
                        .frame(width: 0, height: 0)
                        .hidden()
                    NavigationLink("", isActive: $isTabsPresented, destination: { BrowsingTabsView() })
                        .frame(width: 0, height: 0)
                        .hidden()
                    MainView()
                        .containerBackground(isOverrideAccentColor ? Color(red: overrideAccentColorRed, green: overrideAccentColorGreen, blue: overrideAccentColorBlue).gradient : Color(hex: 0x13A4FF).gradient, for: .navigation)
                        .toolbar {
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
            } else {
                ZStack {
                    NavigationLink("", isActive: $isVideoListPresented, destination: { VideoListView() })
                        .frame(width: 0, height: 0)
                        .hidden()
                    NavigationLink("", isActive: $isImageListPresented, destination: { ImageListView() })
                        .frame(width: 0, height: 0)
                        .hidden()
                    NavigationLink("", isActive: $isBookListPresented, destination: { BookListView() })
                        .frame(width: 0, height: 0)
                        .hidden()
                    MainView(withSetting: true)
                }
            }
        }
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
                if _slowPath(pShouldPresentBookList) {
                    pShouldPresentBookList = false
                    isBookListPresented = true
                }
            }
            
            // Cloud
            if !darockAccount.isEmpty && isSaveHistoryToCloud {
                Task {
                    if let cloudHistories = await GetWebHistoryFromCloud(with: darockAccount) {
                        let currentHistories = GetWebHistory()
                        let mergedHistories = MergeWebHistoriesBetween(primary: currentHistories, secondary: cloudHistories)
                        if mergedHistories != currentHistories {
                            WriteWebHistory(from: mergedHistories)
                        }
                    }
                }
            }
        }
    }
}

struct MainView: View {
    var withSetting: Bool = false
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("IsShowBetaTest1") var isShowBetaTest = true
    @AppStorage("IsShowDAssistantAd") var isShowDAssistantAd = true
    @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
    @AppStorage("PreloadSearchContent") var preloadSearchContent = true
    @AppStorage("isUseOldWebView") var isUseOldWebView = false
    @AppStorage("LabTabBrowsingEnabled") var labTabBrowsingEnabled = false
    @State var textOrURL = ""
    @State var goToButtonLabelText: LocalizedStringKey = "Home.search"
    @State var isKeyboardPresented = false
    @State var isCookieTipPresented = false
    @State var pinnedBookmarkIndexs = [Int]()
    @State var webArchiveLinks = [String]()
    @State var newFeedbackCount = 0
    @State var isNewVerAvailable = false
    @State var isHaveDownloadedVideo = false
    @State var isPreloadedSearchWeb = false
    @State var isOfflineBooksAvailable = false
    var body: some View {
        List {
            Section {
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
                                GetWebSearchedURL(textOrURL, webSearch: webSearch, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled),
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
                    if #available(watchOS 9, *), textOrURL != "" {
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
                                    GetWebSearchedURL(textOrURL, webSearch: webSearch, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled)
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
                        Button(role: .destructive, action: {
                            textOrURL = ""
                            goToButtonLabelText = "Home.go"
                        }, label: {
                            Image(systemName: "xmark.bin.fill")
                        })
                    }
                }
                Button(action: {
                    if textOrURL.hasSuffix(".mp4") {
                        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
                            textOrURL = "http://" + textOrURL
                        }
                        videoLinkLists = [textOrURL]
                        pShouldPresentVideoList = true
                        dismissListsShouldRepresentWebView = false
                        RecordHistory(textOrURL, webSearch: webSearch)
                        return
                    } else if textOrURL.hasSuffix(".png") || textOrURL.hasSuffix(".jpg") || textOrURL.hasSuffix(".webp") || textOrURL.hasSuffix(".pdf") {
                        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
                            textOrURL = "http://" + textOrURL
                        }
                        imageLinkLists = [textOrURL]
                        pShouldPresentImageList = true
                        dismissListsShouldRepresentWebView = false
                        RecordHistory(textOrURL, webSearch: webSearch)
                        return
                    } else if textOrURL.hasSuffix(".epub") {
                        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
                            textOrURL = "http://" + textOrURL
                        }
                        bookLinkLists = [textOrURL]
                        pShouldPresentBookList = true
                        dismissListsShouldRepresentWebView = false
                        RecordHistory(textOrURL, webSearch: webSearch)
                        return
                    }
                    if #available(watchOS 10, *), preloadSearchContent && !isUseOldWebView && isPreloadedSearchWeb {
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
                            GetWebSearchedURL(textOrURL, webSearch: webSearch, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled)
                        )
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Label(goToButtonLabelText, systemImage: goToButtonLabelText == "Home.search" ? "magnifyingglass" : "globe")
                            .font(.system(size: 18))
                        Spacer()
                    }
                })
                .accessibilityIdentifier("MainSearchButton")
            }
            Section {
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
                if isOfflineBooksAvailable {
                    NavigationLink(destination: { LocalBooksView() }, label: {
                        HStack {
                            Spacer()
                            Label("本地图书", systemImage: "book.pages")
                            Spacer()
                        }
                    })
                }
                if isHaveDownloadedVideo {
                    NavigationLink(destination: { LocalVideosView() }, label: {
                        HStack {
                            Spacer()
                            Label("本地视频", systemImage: "tray.and.arrow.down")
                            Spacer()
                        }
                    })
                }
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
            }
            if pinnedBookmarkIndexs.count != 0 {
                Section {
                    ForEach(0..<pinnedBookmarkIndexs.count, id: \.self) { i in
                        Button(action: {
                            AdvancedWebViewController.shared.present(UserDefaults.standard.string(forKey: "BookmarkLink\(pinnedBookmarkIndexs[i])")!)
                        }, label: {
                            Text(UserDefaults.standard.string(forKey: "BookmarkName\(pinnedBookmarkIndexs[i])") ?? "")
                                .privacySensitive()
                        })
                    }
                } header: {
                    Text("Home.bookmarks.pinned")
                }
            }
            Section {
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
                NavigationLink(destination: { TipsView() }, label: {
                    Label("提示", systemImage: "lightbulb")
                })
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
            isOfflineBooksAvailable = !(UserDefaults.standard.stringArray(forKey: "EPUBFlieFolders") ?? [String]()).isEmpty
        }
    }
}

func GetWebSearchedURL(_ iUrl: String, webSearch: String, isSearchEngineShortcutEnabled: Bool) -> String {
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
        break
    case "百度":
        wisu = "https://www.baidu.com/s?wd=\(iUrl.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
        break
    case "谷歌":
        wisu = "https://www.google.com/search?q=\(iUrl.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
        break
    case "搜狗":
        wisu = "https://www.sogou.com/web?query=\(iUrl.urlEncoded().replacingOccurrences(of: "&", with: "%26"))"
        break
    default:
        wisu = webSearch.replacingOccurrences(of: "%lld", with: iUrl.urlEncoded().replacingOccurrences(of: "&", with: "%26"))
        break
    }
    return wisu
}

func GetTopLevel(from url: String) -> String? {
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
        if let topLevel = GetTopLevel(from: self)?.idnaEncoded, topLevelDomainList.contains(topLevel.uppercased()) {
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
