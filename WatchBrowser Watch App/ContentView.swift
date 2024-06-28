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
import DarockKit
import Alamofire
import SwiftyJSON
import AuthenticationServices

struct ContentView: View {
    public static var bingSearchingText = ""
    @AppStorage("LabTabBrowsingEnabled") var labTabBrowsingEnabled = false
    @AppStorage("IsHistoryTransferNeeded") var isHistoryTransferNeeded = true
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
                        .containerBackground(Color(hex: 0x13A4FF).gradient, for: .navigation)
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
        }
    }
}

struct MainView: View {
    var withSetting: Bool = false
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("ModifyKeyboard") var ModifyKeyboard = false
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
                Group {
                    if !ModifyKeyboard {
                        TextField("Home.search-or-URL", text: $textOrURL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .privacySensitive()
                            .onSubmit({
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
                            })
                    } else {
                        if #available(watchOS 10, *) {
                            CepheusKeyboard(input: $textOrURL, prompt: "Home.search-or-URL") {
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
                            .privacySensitive()
                        } else {
                            Button(action: {
                                isKeyboardPresented = true
                            }, label: {
                                HStack {
                                    Text(!textOrURL.isEmpty ? textOrURL : String(localized: "Home.search-or-URL"))
                                        .foregroundColor(textOrURL.isEmpty ? Color.gray : Color.white)
                                        .privacySensitive()
                                    Spacer()
                                }
                            })
                            .sheet(isPresented: $isKeyboardPresented, content: {
                                ExtKeyboardView(startText: textOrURL) { ott in
                                    textOrURL = ott
                                }
                            })
                            .onChange(of: textOrURL, perform: { value in
                                if value.isURL() {
                                    goToButtonLabelText = "Home.go"
                                } else {
                                    if isSearchEngineShortcutEnabled {
                                        if value.hasPrefix("bing") {
                                            goToButtonLabelText = "Home.search.bing"
                                        } else if value.hasPrefix("baidu") {
                                            goToButtonLabelText = "Home.search.baidu"
                                        } else if value.hasPrefix("google") {
                                            goToButtonLabelText = "Home.search.google"
                                        } else if value.hasPrefix("sogou") {
                                            goToButtonLabelText = "Home.search.sogou"
                                        } else {
                                            goToButtonLabelText = "Home.search"
                                        }
                                    } else {
                                        goToButtonLabelText = "Home.search"
                                    }
                                }
                            })
                        }
                    }
                }
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
                        Button(action: {
                            textOrURL = ""
                            goToButtonLabelText = "Home.go"
                        }, label: {
                            Image(systemName: "xmark.bin.fill")
                        })
                        .tint(.red)
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
                    } else if textOrURL.hasSuffix(".png") || textOrURL.hasSuffix(".jpg") || textOrURL.hasSuffix(".webp") {
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
        if self.contains(".com") || self.contains(".org") || self.contains(".net") || self.contains(".int") || self.contains(".edu") || self.contains(".gov") || self.contains(".mil") || self.contains(".arpa") || self.contains(".ac") || self.contains(".ae") || self.contains(".af") || self.contains(".ag") || self.contains(".ai") || self.contains(".al") || self.contains(".am") || self.contains(".ao") || self.contains(".aq") || self.contains(".ar") || self.contains(".as") || self.contains(".at") || self.contains(".au") || self.contains(".aw") || self.contains(".ax") || self.contains(".az") || self.contains(".ba") || self.contains(".bb") || self.contains(".bd") || self.contains(".be") || self.contains(".bf") || self.contains(".bg") || self.contains(".bh") || self.contains(".bi") || self.contains(".bj") || self.contains(".bm") || self.contains(".bn") || self.contains(".bo") || self.contains(".br") || self.contains(".bs") || self.contains(".bt") || self.contains(".bw") || self.contains(".by") || self.contains(".bz") || self.contains(".ca") || self.contains(".cc") || self.contains(".cd") || self.contains(".cf") || self.contains(".cg") || self.contains(".ch") || self.contains(".ci") || self.contains(".ck") || self.contains(".cl") || self.contains(".cm") || self.contains(".cn") || self.contains(".co") || self.contains(".cr") || self.contains(".cu") || self.contains(".cv") || self.contains(".cw") || self.contains(".cx") || self.contains(".cy") || self.contains(".cz") || self.contains(".de") || self.contains(".dj") || self.contains(".dk") || self.contains(".dm") || self.contains(".do") || self.contains(".dz") || self.contains(".ec") || self.contains(".ee") || self.contains(".eg") || self.contains(".er") || self.contains(".es") || self.contains(".et") || self.contains(".eu") || self.contains(".fi") || self.contains(".fk") || self.contains(".fm") || self.contains(".fo") || self.contains(".fr") || self.contains(".ga") || self.contains(".gd") || self.contains(".ge") || self.contains(".gf") || self.contains(".gg") || self.contains(".gh") || self.contains(".gi") || self.contains(".gl") || self.contains(".gm") || self.contains(".gn") || self.contains(".gp") || self.contains(".gq") || self.contains(".gr") || self.contains(".gs") || self.contains(".gt") || self.contains(".gu") || self.contains(".gw") || self.contains(".gy") || self.contains(".hk") || self.contains(".hm") || self.contains(".hn") || self.contains(".hr") || self.contains(".ht") || self.contains(".hu") || self.contains(".id") || self.contains(".ie") || self.contains(".il") || self.contains(".im") || self.contains(".in") || self.contains(".io") || self.contains(".iq") || self.contains(".ir") || self.contains(".is") || self.contains(".it") || self.contains(".je") || self.contains(".jm") || self.contains(".jo") || self.contains(".jp") || self.contains(".ke") || self.contains(".kg") || self.contains(".kh") || self.contains(".ki") || self.contains(".km") || self.contains(".kn") || self.contains(".kp") || self.contains(".kr") || self.contains(".kw") || self.contains(".ky") || self.contains(".kz") || self.contains(".la") || self.contains(".lb") || self.contains(".lc") || self.contains(".li") || self.contains(".lk") || self.contains(".lr") || self.contains(".ls") || self.contains(".lt") || self.contains(".lu") || self.contains(".lv") || self.contains(".ly") || self.contains(".ma") || self.contains(".mc") || self.contains(".md") || self.contains(".me") || self.contains(".mg") || self.contains(".mh") || self.contains(".mk") || self.contains(".ml") || self.contains(".mm") || self.contains(".mn") || self.contains(".mo") || self.contains(".mp") || self.contains(".mq") || self.contains(".mr") || self.contains(".ms") || self.contains(".mt") || self.contains(".mu") || self.contains(".mv") || self.contains(".mw") || self.contains(".mx") || self.contains(".my") || self.contains(".mz") || self.contains(".na") || self.contains(".mil") || self.contains(".gov") || self.contains(".mil") || self.contains(".gov") || self.contains(".mil") || self.contains(".gov") || self.contains(".nc") || self.contains(".ne") || self.contains(".nf") || self.contains(".ng") || self.contains(".ni") || self.contains(".nl") || self.contains(".no") || self.contains(".np") || self.contains(".nr") || self.contains(".nu") || self.contains(".nz") || self.contains(".om") || self.contains(".pa") || self.contains(".pe") || self.contains(".pf") || self.contains(".pg") || self.contains(".ph") || self.contains(".pk") || self.contains(".pl") || self.contains(".pm") || self.contains(".pn") || self.contains(".pr") || self.contains(".ps") || self.contains(".pt") || self.contains(".pw") || self.contains(".py") || self.contains(".qa") || self.contains(".re") || self.contains(".ro") || self.contains(".rs") || self.contains(".ru") || self.contains(".rw") || self.contains(".sa") || self.contains(".sb") || self.contains(".sc") || self.contains(".sd") || self.contains(".se") || self.contains(".sg") || self.contains(".sh") || self.contains(".si") || self.contains(".sk") || self.contains(".sl") || self.contains(".sm") || self.contains(".sn") || self.contains(".so") || self.contains(".sr") || self.contains(".ss") || self.contains(".st") || self.contains(".su") || self.contains(".sv") || self.contains(".sx") || self.contains(".sy") || self.contains(".sz") || self.contains(".tc") || self.contains(".td") || self.contains(".tf") || self.contains(".tg") || self.contains(".th") || self.contains(".tj") || self.contains(".tk") || self.contains(".tl") || self.contains(".tm") || self.contains(".tn") || self.contains(".to") || self.contains(".tr") || self.contains(".tt") || self.contains(".tv") || self.contains(".tw") || self.contains(".tz") || self.contains(".ua") || self.contains(".ug") || self.contains(".uk") || self.contains(".us") || self.contains(".uy") || self.contains(".uz") || self.contains(".va") || self.contains(".vc") || self.contains(".ve") || self.contains(".vg") || self.contains(".vi") || self.contains(".vn") || self.contains(".vu") || self.contains(".wf") || self.contains(".ws") || self.contains(".ye") || self.contains(".yt") || self.contains(".za") || self.contains(".zm") || self.contains(".zw") || self.contains(".xyz") || self.contains(".ltd") || self.contains(".top") || self.contains(".cc") || self.contains(".group") || self.contains(".shop") || self.contains(".vip") || self.contains(".site") || self.contains(".art") || self.contains(".club") || self.contains(".wiki") || self.contains(".online") || self.contains(".cloud") || self.contains(".fun") || self.contains(".store") || self.contains(".wang") || self.contains(".tech") || self.contains(".pro") || self.contains(".biz") || self.contains(".space") || self.contains(".link") || self.contains(".info") || self.contains(".team") || self.contains(".mobi") || self.contains(".city") || self.contains(".life") || self.contains(".life") || self.contains(".zone") || self.contains(".asia") || self.contains(".host") || self.contains(".website") || self.contains(".world") || self.contains(".center") || self.contains(".cool") || self.contains(".ren") || self.contains(".company") || self.contains(".plus") || self.contains(".video") || self.contains(".pub") || self.contains(".email") || self.contains(".live") || self.contains(".run") || self.contains(".love") || self.contains(".show") || self.contains(".work") || self.contains(".ink") || self.contains(".fund") || self.contains(".red") || self.contains(".chat") || self.contains(".today") || self.contains(".press") || self.contains(".social") || self.contains(".gold") || self.contains(".design") || self.contains(".auto") || self.contains(".guru") || self.contains(".black") || self.contains(".blue") || self.contains(".green") || self.contains(".pink") || self.contains(".poker") || self.contains(".news") {
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
