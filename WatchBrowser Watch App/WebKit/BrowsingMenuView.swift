//
//  BrowsingMenuView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/8/18.
//

import SwiftUI
import Dynamic
import DarockKit
import SwiftSoup
import SDWebImageSwiftUI

struct BrowsingMenuView: View {
    @Binding var webViewPresentationMode: PresentationMode
    @Binding var isHidingDistractingItems: Bool
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("BrowsingMenuLayout") var browsingMenuLayout = "Detailed"
    @AppStorage("LabHideDistractingItemsEnabled") var labHideDistractingItemsEnabled = false
    @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
    @AppStorage("ABIsReduceBrightness") var isReduceBrightness = false
    @AppStorage("ABReduceBrightnessLevel") var reduceBrightnessLevel = 0.2
    @AppStorage("DBIsAutoAppearence") var isAutoAppearence = false
    @AppStorage("DBAutoAppearenceOptionEnableForWebForceDark") var autoAppearenceOptionEnableForWebForceDark = true
    @AppStorage("IsProPurchased") var isProPurchased = false
    @State var webView = webViewObject!
    @State var webLinkInput = ""
    @State var isCheckingWebContent = true
    @State var linksUpdateTimer: Timer?
    @State var videoLinks = [String]()
    @State var imageLinks = [String]()
    @State var imageAltTexts = [String]()
    @State var audioLinks = [String]()
    @State var isLoading = false
    @State var isBackListPresented = false
    @State var isForwardListPresented = false
    @State var isNewBookmarkCreated = false
    @State var isNewBookmarkAnimating = false
    @State var isWebAbstractPresented = false
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    if (webView.url?.absoluteString ?? "").contains("bilibili.com/") {
                        Section {
                            VStack {
                                HStack {
                                    WebImage(url: URL(string: "https://darock.top/meowbili/assetsv2/meow-93aa09e9.png")!)
                                        .resizable()
                                        .placeholder {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray)
                                                .opacity(0.6)
                                        }
                                        .cornerRadius(12)
                                        .frame(width: 50, height: 50)
                                    VStack(alignment: .leading) {
                                        Text("喵哩喵哩")
                                        Text("第三方哔哩哔哩客户端")
                                            .font(.footnote)
                                            .opacity(0.6)
                                    }
                                    Spacer()
                                }
                                Group {
                                    if UserDefaults(suiteName: "group.darockst")?.bool(forKey: "DCIsMeowBiliInstalled") ?? false {
                                        Button(action: {
                                            if let bvid = (webView.url?.absoluteString ?? "").split(separator: "bilibili.com/video/")[from: 1],
                                               bvid.hasPrefix("BV") {
                                                WKExtension.shared().openSystemURL(URL(string: "https://darock.top/meowbili/video/\(bvid)")!)
                                            } else {
                                                WKExtension.shared().openSystemURL(URL(string: "https://darock.top/meowbili/video")!)
                                            }
                                        }, label: {
                                            HStack {
                                                Text("在喵哩喵哩中打开")
                                                Image(systemName: "arrow.up.forward.app")
                                            }
                                            .font(.headline)
                                        })
                                    } else {
                                        Button(action: {
                                            webView.load(URLRequest(url: URL(string: "https://testflight.apple.com/join/skaCe2L2")!))
                                        }, label: {
                                            HStack {
                                                Text("前往 TestFlight")
                                                Image(systemName: "arrow.up.right.square")
                                            }
                                            .font(.headline)
                                        })
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.roundedRectangle(radius: 12))
                            }
                        }
                    }
                    Section {
                        TextField("页面链接", text: $webLinkInput, style: "field-page") {
                            if webLinkInput.isURL() {
                                if let url = URL(string: webLinkInput) {
                                    webView.load(URLRequest(url: url))
                                }
                            } else {
                                webView.load(
                                    URLRequest(url: URL(string: getWebSearchedURL(
                                        webLinkInput,
                                        webSearch: webSearch,
                                        isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled
                                    ))!)
                                )
                            }
                            presentationMode.wrappedValue.dismiss()
                        }
                        .noAutoInput()
                        .submitLabel(.go)
                    }
                    if browsingMenuLayout != "Compact" {
                        Section {
                            if !isCheckingWebContent {
                                if !videoLinks.isEmpty {
                                    Button(action: {
                                        webViewPresentationMode.dismiss()
                                        pShouldPresentVideoList = true
                                        dismissListsShouldRepresentWebView = true
                                    }, label: {
                                        HStack {
                                            Text("播放网页视频")
                                            Spacer()
                                            Image(systemName: "film.stack")
                                        }
                                    })
                                }
                                if !imageLinks.isEmpty {
                                    Button(action: {
                                        webViewPresentationMode.dismiss()
                                        pShouldPresentImageList = true
                                        dismissListsShouldRepresentWebView = true
                                    }, label: {
                                        HStack {
                                            Text("查看网页图片")
                                            Spacer()
                                            Image(systemName: "photo.stack")
                                        }
                                    })
                                }
                                if !audioLinks.isEmpty {
                                    Button(action: {
                                        webViewPresentationMode.dismiss()
                                        pShouldPresentAudioList = true
                                        dismissListsShouldRepresentWebView = true
                                    }, label: {
                                        HStack {
                                            Text("播放网页音频")
                                            Spacer()
                                            Image(systemName: "music.quarternote.3")
                                        }
                                    })
                                }
                            } else {
                                ProgressView()
                            }
                        }
                        Section {
                            Button(action: {
                                if !isLoading {
                                    webView.reload()
                                } else {
                                    webView.stopLoading()
                                }
                                presentationMode.wrappedValue.dismiss()
                            }, label: {
                                HStack {
                                    Text(isLoading ? "停止载入" : "重新载入")
                                    Spacer()
                                    Image(systemName: isLoading ? "stop.fill" : "arrow.clockwise")
                                }
                            })
                            if webView.canGoBack {
                                Button(action: {
                                    webView.goBack()
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    HStack {
                                        Text("上一页")
                                        Color.accentColor
                                            .opacity(0.0100000002421438702673861521)
                                        Image(systemName: "chevron.backward")
                                    }
                                })
                                .onTapGesture {
                                    webView.goBack()
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .onLongPressGesture(minimumDuration: 0.5) {
                                    isBackListPresented = true
                                }
                            }
                            if webView.canGoForward {
                                Button(action: {
                                    webView.goForward()
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    HStack {
                                        Text("下一页")
                                        Color.accentColor
                                            .opacity(0.0100000002421438702673861521)
                                        Image(systemName: "chevron.forward")
                                    }
                                })
                                .onTapGesture {
                                    webView.goForward()
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .onLongPressGesture(minimumDuration: 0.5) {
                                    isForwardListPresented = true
                                }
                            }
                        }
                        Section {
                            Button(role: .destructive, action: {
                                webViewPresentationMode.dismiss()
                                if isAutoAppearence && autoAppearenceOptionEnableForWebForceDark {
                                    AppearenceManager.shared.updateAll()
                                }
                            }, label: {
                                HStack {
                                    Text("退出")
                                    Spacer()
                                    Image(systemName: "escape")
                                }
                            })
                        }
                        if isProPurchased {
                            Section {
                                Button(action: {
                                    isWebAbstractPresented = true
                                }, label: {
                                    HStack {
                                        Text("网页摘要")
                                        Spacer()
                                        Image(systemName: "doc.plaintext")
                                    }
                                })
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(LinearGradient(
                                            colors: [.init(hex: 0xf0aa3d), .init(hex: 0xce96f9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .background {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray)
                                                .opacity(0.3)
                                        }
                                )
                            }
                        }
                        if !isHidingDistractingItems && labHideDistractingItemsEnabled {
                            Section {
                                Button(action: {
                                    webView.evaluateJavaScript("document.documentElement.outerHTML", completionHandler: { obj, error in
                                        DispatchQueue(label: "com.darock.WatchBrowser.wt.test", qos: .userInitiated).async {
                                            if let htmlStr = obj as? String {
                                                do {
                                                    let doc = try SwiftSoup.parse(htmlStr)
                                                    if let divs = try doc.body()?.select("div[class], div[id]") {
                                                        let targetDivs = try divs.filter { div in
                                                            return try div.children().select("div").isEmpty()
                                                        }
                                                        for div in targetDivs {
                                                            if let id = try? div.attr("id"), !id.isEmpty {
                                                                webView.addEventListener(
                                                                    elementID: id,
                                                                    callbackID: "HDIDCallback",
                                                                    elementType: .id,
                                                                    handler: WebViewScriptMessageHandler.shared
                                                                )
                                                            } else if let className = try? div.attr("class"), !className.isEmpty {
                                                                webView.addEventListener(
                                                                    elementID: className,
                                                                    callbackID: "HDClassCallback",
                                                                    elementType: .class,
                                                                    handler: WebViewScriptMessageHandler.shared
                                                                )
                                                            }
                                                        }
                                                    }
                                                    isHidingDistractingItems = true
                                                    presentationMode.wrappedValue.dismiss()
                                                } catch {
                                                    globalErrorHandler(error)
                                                }
                                            }
                                        }
                                    })
                                }, label: {
                                    HStack {
                                        Text("隐藏干扰项目")
                                        Spacer()
                                        Image(systemName: "eye.slash.fill")
                                    }
                                })
                            }
                        }
                        if !AdvancedWebViewController.shared.currentUrl.isEmpty && !AdvancedWebViewController.shared.currentUrl.hasPrefix("file://") {
                            Section {
                                Button(action: {
                                    let userdefault = UserDefaults.standard
                                    let total = userdefault.integer(forKey: "BookmarkTotal") &+ 1
                                    let markLink = AdvancedWebViewController.shared.currentUrl
                                    let markName = webView.title ?? markLink
                                    userdefault.set(markName, forKey: "BookmarkName\(total)")
                                    userdefault.set(markLink, forKey: "BookmarkLink\(total)")
                                    userdefault.set(total, forKey: "BookmarkTotal")
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    HStack {
                                        Text("添加到书签")
                                        Spacer()
                                        Image(systemName: "bookmark")
                                    }
                                })
                                if !(UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]())
                                    .contains(AdvancedWebViewController.shared.currentUrl) {
                                    Button(action: {
                                        WEBackSwift.createWebArchive()
                                        presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        HStack {
                                            Text("存储本页离线归档")
                                            Spacer()
                                            Image(systemName: "archivebox")
                                        }
                                    })
                                }
                            }
                            Section {
                                Button(action: {
                                    AdvancedWebViewController.shared.isOverrideDesktopWeb.toggle()
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    HStack {
                                        Text(AdvancedWebViewController.shared.isOverrideDesktopWeb ? "请求移动网站" : "请求桌面网站")
                                        Spacer()
                                        Image(systemName: AdvancedWebViewController.shared.isOverrideDesktopWeb ? "applewatch" : "desktopcomputer")
                                    }
                                })
                                Button(action: {
                                    webViewPresentationMode.dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                        AdvancedWebViewController.shared.present(AdvancedWebViewController.shared.currentUrl, overrideOldWebView: .alwaysLegacy)
                                    }
                                }, label: {
                                    HStack {
                                        Text("使用旧版引擎打开")
                                        Spacer()
                                        Image(systemName: "globe.badge.chevron.backward")
                                    }
                                })
                            }
                        }
                    } else {
                        Section {
                            Group {
                                if !isCheckingWebContent {
                                    HStack {
                                        Button(action: {
                                            webViewPresentationMode.dismiss()
                                            pShouldPresentVideoList = true
                                            dismissListsShouldRepresentWebView = true
                                        }, label: {
                                            Image(systemName: "film.stack")
                                        })
                                        .disabled(videoLinks.isEmpty)
                                        Button(action: {
                                            webViewPresentationMode.dismiss()
                                            pShouldPresentImageList = true
                                            dismissListsShouldRepresentWebView = true
                                        }, label: {
                                            Image(systemName: "photo.stack")
                                        })
                                        .disabled(imageLinks.isEmpty)
                                        Button(action: {
                                            webViewPresentationMode.dismiss()
                                            pShouldPresentAudioList = true
                                            dismissListsShouldRepresentWebView = true
                                        }, label: {
                                            Image(systemName: "music.quarternote.3")
                                        })
                                        .disabled(audioLinks.isEmpty)
                                    }
                                } else {
                                    ProgressView()
                                        .centerAligned()
                                }
                                HStack {
                                    Button(action: {
                                        if !isLoading {
                                            webView.reload()
                                        } else {
                                            webView.stopLoading()
                                        }
                                        presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        Image(systemName: isLoading ? "stop.fill" : "arrow.clockwise")
                                    })
                                    Button(action: {
                                        webView.goBack()
                                        presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        Image(systemName: "chevron.backward")
                                    })
                                    .onTapGesture {
                                        webView.goBack()
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                    .onLongPressGesture(minimumDuration: 0.5) {
                                        isBackListPresented = true
                                    }
                                    .disabled(!webView.canGoBack)
                                    Button(action: {
                                        webView.goForward()
                                        presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        Image(systemName: "chevron.forward")
                                    })
                                    .onTapGesture {
                                        webView.goForward()
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                    .onLongPressGesture(minimumDuration: 0.5) {
                                        isForwardListPresented = true
                                    }
                                    .disabled(!webView.canGoForward)
                                }
                                Button(role: .destructive, action: {
                                    webViewPresentationMode.dismiss()
                                    if isAutoAppearence && autoAppearenceOptionEnableForWebForceDark {
                                        AppearenceManager.shared.updateAll()
                                    }
                                }, label: {
                                    HStack {
                                        Image(systemName: "escape")
                                        Text("退出")
                                    }
                                })
                                if isProPurchased {
                                    Button(action: {
                                        isWebAbstractPresented = true
                                    }, label: {
                                        HStack {
                                            Text("网页摘要")
                                            Spacer()
                                            Image(systemName: "doc.plaintext")
                                        }
                                    })
                                    .background(
                                        Capsule()
                                            .stroke(LinearGradient(
                                                colors: [.init(hex: 0xf0aa3d), .init(hex: 0xce96f9)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .background {
                                                Capsule()
                                                    .fill(Color.gray)
                                                    .opacity(0.15)
                                            }
                                    )
                                }
                                if !AdvancedWebViewController.shared.currentUrl.isEmpty && !AdvancedWebViewController.shared.currentUrl.hasPrefix("file://") {
                                    HStack {
                                        ZStack {
                                            Button(action: {
                                                if !isNewBookmarkCreated {
                                                    let userdefault = UserDefaults.standard
                                                    let total = userdefault.integer(forKey: "BookmarkTotal") &+ 1
                                                    let markLink = AdvancedWebViewController.shared.currentUrl
                                                    let markName = webView.title ?? markLink
                                                    userdefault.set(markName, forKey: "BookmarkName\(total)")
                                                    userdefault.set(markLink, forKey: "BookmarkLink\(total)")
                                                    userdefault.set(total, forKey: "BookmarkTotal")
                                                    isNewBookmarkCreated = true
                                                    isNewBookmarkAnimating = true
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                        var transaction = Transaction(animation: .easeIn(duration: 0.1))
                                                        transaction.disablesAnimations = true
                                                        withTransaction(transaction) {
                                                            isNewBookmarkAnimating = false
                                                        }
                                                    }
                                                }
                                            }, label: {
                                                Image(systemName: "bookmark")
                                                    .opacity(isNewBookmarkCreated ? 0 : 1)
                                            })
                                            Image(systemName: "bookmark.fill")
                                                .scaleEffect(isNewBookmarkAnimating ? 1.2 : 1)
                                                .animation(.smooth(duration: 1.4), value: isNewBookmarkAnimating)
                                                .shadow(color: isNewBookmarkAnimating ? .white : .clear, radius: 4, x: 1.5, y: 1.5)
                                                .opacity(isNewBookmarkCreated ? 1 : 0)
                                                .allowsHitTesting(false)
                                        }
                                        Button(action: {
                                            AdvancedWebViewController.shared.isOverrideDesktopWeb.toggle()
                                            presentationMode.wrappedValue.dismiss()
                                        }, label: {
                                            Image(systemName: AdvancedWebViewController.shared.isOverrideDesktopWeb ? "applewatch" : "desktopcomputer")
                                        })
                                        Button(action: {
                                            webViewPresentationMode.dismiss()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                AdvancedWebViewController.shared.present(
                                                    AdvancedWebViewController.shared.currentUrl,
                                                    overrideOldWebView: .alwaysLegacy
                                                )
                                            }
                                        }, label: {
                                            Image(systemName: "globe.badge.chevron.backward")
                                        })
                                    }
                                }
                                if !(UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]())
                                    .contains(AdvancedWebViewController.shared.currentUrl) {
                                    Button(action: {
                                        WEBackSwift.createWebArchive()
                                        presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        HStack {
                                            Image(systemName: "archivebox")
                                            Text("存储离线归档")
                                        }
                                    })
                                }
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.roundedRectangle(radius: 1000))
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .navigationTitle(webView.title ?? String(localized: "浏览菜单"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                        })
                    }
                }
            }
            if isReduceBrightness {
                Rectangle()
                    .fill(Color.black)
                    .opacity(reduceBrightnessLevel)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $isBackListPresented, content: { BackForwardListView(type: .back, menuPresentationMode: presentationMode) })
        .sheet(isPresented: $isForwardListPresented, content: { BackForwardListView(type: .forward, menuPresentationMode: presentationMode) })
        .sheet(isPresented: $isWebAbstractPresented, content: { WebAbstractView(webView: webView) })
        .onAppear {
            if webLinkInput.isEmpty {
                webLinkInput = webView.url?.absoluteString ?? ""
            }
            isLoading = webView.isLoading
            linksUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                videoLinks = videoLinkLists
                imageLinks = imageLinkLists
                imageAltTexts = imageAltTextLists
                audioLinks = audioLinkLists
            }
            checkWebContent()
        }
        .onDisappear {
            linksUpdateTimer?.invalidate()
            linksUpdateTimer = nil
        }
        .onReceive(webView.publisher(for: \.isLoading)) { loading in
            isLoading = loading
        }
    }
    
    func checkWebContent() {
        let currentUrl = AdvancedWebViewController.shared.currentUrl
        webView.evaluateJavaScript("document.documentElement.outerHTML", completionHandler: { obj, error in
            DispatchQueue(label: "com.darock.WatchBrowser.wt.media-check", qos: .userInitiated).async {
                if let htmlStr = obj as? String {
                    let webSuffixList = [".html", ".htm", ".php", ".xhtml"]
                    do {
                        let doc = try SwiftSoup.parse(htmlStr)
                        videoLinkLists.removeAll()
                        let videos = try doc.body()?.select("video")
                        if let videos {
                            var srcs = [String]()
                            for video in videos {
                                var src = try video.attr("src")
                                if src.isEmpty, let tagSrc = try? video.select("source") {
                                    src = try tagSrc.attr("src")
                                }
                                if !src.isEmpty {
                                    if src.hasPrefix("/") {
                                        if currentUrl.split(separator: "/").count < 2 {
                                            continue
                                        }
                                        src = "http://" + currentUrl.split(separator: "/")[1] + src
                                    } else if !src.hasPrefix("http://") && !src.hasPrefix("https://") {
                                        var currentUrlCopy = currentUrl
                                        if webSuffixList.contains(where: { element in currentUrlCopy.hasSuffix(element) }) {
                                            if currentUrlCopy.split(separator: "/").count < 2 {
                                                continue
                                            }
                                            currentUrlCopy = currentUrlCopy.components(separatedBy: "/").dropLast().joined(separator: "/")
                                        }
                                        if !currentUrlCopy.hasSuffix("/") {
                                            currentUrlCopy += "/"
                                        }
                                        src = currentUrlCopy + src
                                    }
                                    srcs.append(src)
                                }
                            }
                            videoLinkLists = srcs
                        }
                        let iframeVideos = try doc.body()?.select("iframe")
                        if let iframeVideos {
                            var srcs = [String]()
                            for video in iframeVideos {
                                var src = try video.attr("src")
                                if src != "" && (src.hasSuffix(".mp4") || src.hasSuffix(".m3u8")) {
                                    if src.split(separator: "://").count >= 2 && !src.hasPrefix("http://") && !src.hasPrefix("https://") {
                                        src = "https://" + src.split(separator: "://").last!
                                    } else if src.hasPrefix("/") {
                                        if currentUrl.split(separator: "/").count < 2 {
                                            continue
                                        }
                                        src = "https://" + currentUrl.split(separator: "/")[1] + src
                                    }
                                    srcs.append(src)
                                }
                            }
                            videoLinkLists += srcs
                        }
                        let aLinks = try doc.body()?.select("a")
                        if let aLinks {
                            var srcs = [String]()
                            for video in aLinks {
                                var src = try video.attr("href")
                                if src != "" && (src.hasSuffix(".mp4") || src.hasSuffix(".m3u8")) {
                                    if src.split(separator: "://").count >= 2 && !src.hasPrefix("http://") && !src.hasPrefix("https://") {
                                        src = "https://" + src.split(separator: "://").last!
                                    } else if src.hasPrefix("/") {
                                        if currentUrl.split(separator: "/").count < 2 {
                                            continue
                                        }
                                        src = "https://" + currentUrl.split(separator: "/")[1] + src
                                    }
                                    srcs.append(src)
                                }
                            }
                            videoLinkLists += srcs
                        }
                        let images = try doc.body()?.select("img")
                        if let images {
                            var srcs = [String]()
                            var alts = [String]()
                            for image in images {
                                var src = try image.attr("src")
                                if src != "" {
                                    if src.hasPrefix("/") {
                                        if currentUrl.split(separator: "/").count < 2 {
                                            continue
                                        }
                                        src = "http://" + currentUrl.split(separator: "/")[1] + src
                                    } else if !src.hasPrefix("http://") && !src.hasPrefix("https://") {
                                        var currentUrlCopy = currentUrl
                                        if webSuffixList.contains(where: { element in currentUrlCopy.hasSuffix(element) }) {
                                            if currentUrlCopy.split(separator: "/").count < 2 {
                                                continue
                                            }
                                            currentUrlCopy = currentUrlCopy.components(separatedBy: "/").dropLast().joined(separator: "/")
                                        }
                                        if !currentUrlCopy.hasSuffix("/") {
                                            currentUrlCopy += "/"
                                        }
                                        src = currentUrlCopy + src
                                    }
                                    srcs.append(src)
                                }
                                alts.append((try? image.attr("alt")) ?? "")
                            }
                            imageLinkLists = srcs
                            imageAltTextLists = alts
                        }
                        let audios = try doc.body()?.select("audio")
                        if let audios {
                            var srcs = [String]()
                            for audio in audios {
                                var src = try audio.attr("src")
                                if src != "" {
                                    if src.hasPrefix("/") {
                                        if currentUrl.split(separator: "/").count < 2 {
                                            continue
                                        }
                                        src = "http://" + currentUrl.split(separator: "/")[1] + src
                                    } else if !src.hasPrefix("http://") && !src.hasPrefix("https://") {
                                        var currentUrlCopy = currentUrl
                                        if webSuffixList.contains(where: { element in currentUrlCopy.hasSuffix(element) }) {
                                            if currentUrlCopy.split(separator: "/").count < 2 {
                                                continue
                                            }
                                            currentUrlCopy = currentUrlCopy.components(separatedBy: "/").dropLast().joined(separator: "/")
                                        }
                                        if !currentUrlCopy.hasSuffix("/") {
                                            currentUrlCopy += "/"
                                        }
                                        src = currentUrlCopy + src
                                    }
                                    srcs.append(src)
                                }
                            }
                            audioLinkLists = srcs
                        }
                    } catch {
                        globalErrorHandler(error)
                    }
                }
                if currentUrl.contains(/music\..*\.com/) && currentUrl.contains(/(\?|&)id=[0-9]*($|&)/),
                   let mid = currentUrl.split(separator: "id=")[from: 1]?.split(separator: "&").first {
                    audioLinkLists = ["http://music.\(0b10100011).com/song/media/outer/url?id=\(mid).mp3"]
                }
                DispatchQueue.main.async {
                    isCheckingWebContent = false
                }
            }
        })
    }
}

private struct BackForwardListView: View {
    var type: `Type`
    @Binding var menuPresentationMode: PresentationMode
    @State var list = [WKBackForwardListItem]()
    var body: some View {
        NavigationStack {
            List {
                if !list.isEmpty {
                    ForEach(0..<list.count, id: \.self) { i in
                        Button(action: {
                            webViewObject.go(to: list[i])
                            menuPresentationMode.dismiss()
                        }, label: {
                            if let title = list[i].title {
                                VStack(alignment: .leading) {
                                    Text(title)
                                    Text(list[i].url.absoluteString)
                                        .font(.system(size: 14))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .opacity(0.6)
                                }
                            } else {
                                Text(list[i].url.absoluteString)
                                    .lineLimit(3)
                                    .truncationMode(.middle)
                            }
                        })
                    }
                } else {
                    Text("空列表")
                }
            }
            .navigationTitle(type == .back ? "返回列表" : "前进列表")
        }
        .onAppear {
            if type == .back {
                list = webViewObject.backForwardList.backList
            } else {
                list = webViewObject.backForwardList.forwardList
            }
        }
    }
    
    enum `Type` {
        case back
        case forward
    }
}
