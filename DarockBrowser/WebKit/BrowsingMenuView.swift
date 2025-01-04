//
//  BrowsingMenuView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/8/18.
//

import SwiftUI
import SwiftSoup
import MarqueeText
import DarockFoundation
import SDWebImageSwiftUI

struct BrowsingMenuView: View {
    var webView: WKWebView
    @Binding var webViewPresentationMode: PresentationMode
    @Binding var presentingMediaList: WebViewMediaListPresentation?
    @Binding var isHidingDistractingItems: Bool
    var customDismissAction: (() -> Void)?
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
    @State var linkInput = ""
    @State var linkInputOffset: CGFloat = 0
    @State var isHomeViewPresented = false
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
    @State var sharingLink = ""
    @State var isSharePresented = false
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    if (webView.url?.absoluteString ?? "").contains("bilibili.com/") {
                        Section {
                            VStack {
                                HStack {
                                    WebImage(url: URL(string: "https://darock.top/meowbili/assetsv2/meow-93aa09e9.png")!, content: { image in
                                        image.resizable()
                                    }, placeholder: {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray)
                                            .opacity(0.6)
                                    })
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
                        HStack {
                            TextField("", text: $linkInput) {
                                if linkInput.isURL() {
                                    var input = linkInput
                                    if !(input.split(separator: ".").first?.contains("://") ?? false) {
                                        input = "http://" + input
                                    }
                                    if let url = URL(string: input) {
                                        webView.load(URLRequest(url: url))
                                    }
                                } else {
                                    webView.load(
                                        URLRequest(url: URL(string: getWebSearchedURL(
                                            linkInput,
                                            webSearch: webSearch,
                                            isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled
                                        ))!)
                                    )
                                }
                                presentationMode.wrappedValue.dismiss()
                            }
                            .noAutoInput()
                            .submitLabel(.go)
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.roundedRectangle(radius: 14))
                            .opacity(0.0100000002421438702673861521)
                            .overlay {
                                Button(action: {}, label: {
                                    HStack {
                                        if webSearchString(from: webView.url?.absoluteString ?? "") != nil {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 13))
                                        }
                                        MarqueeText(
                                            text: linkInput,
                                            font: .systemFont(ofSize: 14),
                                            leftFade: 5,
                                            rightFade: 5,
                                            startDelay: 1.5,
                                            alignment: .leading
                                        )
                                    }
                                })
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.roundedRectangle(radius: 14))
                                .allowsHitTesting(false)
                            }
                            if #available(watchOS 10.0, *) {
                                Button(action: {
                                    isHomeViewPresented = true
                                }, label: {
                                    Image(systemName: "star.fill")
                                })
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.roundedRectangle(radius: 14))
                                .frame(width: 55)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    if browsingMenuLayout != "Compact" {
                        Section {
                            if !isCheckingWebContent {
                                if !videoLinks.isEmpty {
                                    Button(action: {
                                        presentationMode.wrappedValue.dismiss()
                                        presentingMediaList = .video
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
                                        presentationMode.wrappedValue.dismiss()
                                        presentingMediaList = .image
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
                                        presentationMode.wrappedValue.dismiss()
                                        presentingMediaList = .music
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
                            Button(action: {
                                if let customDismissAction {
                                    customDismissAction()
                                } else {
                                    webViewPresentationMode.dismiss()
                                }
                                if isAutoAppearence && autoAppearenceOptionEnableForWebForceDark {
                                    AppearenceManager.shared.updateAll()
                                }
                            }, label: {
                                HStack {
                                    if #available(watchOS 10.0, *) {
                                        Text("返回标签页列表")
                                        Spacer()
                                        Image(systemName: "list.bullet")
                                    } else {
                                        Text("退出")
                                        Spacer()
                                        Image(systemName: "escape")
                                    }
                                }
                            })
                            .tint({ if #available(watchOS 10.0, *) { true } else { false } }() ? .accentColor : .red)
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
                        if let currentUrl = webView.url?.absoluteString, !currentUrl.hasPrefix("file://") {
                            Section {
                                Button(action: {
                                    let userdefault = UserDefaults.standard
                                    let total = userdefault.integer(forKey: "BookmarkTotal") &+ 1
                                    let markLink = currentUrl
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
                                if !(UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()).contains(currentUrl) {
                                    Button(action: {
                                        WEBackSwift.createWebArchive(for: webView)
                                        presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        HStack {
                                            Text("存储本页离线归档")
                                            Spacer()
                                            Image(systemName: "archivebox")
                                        }
                                    })
                                }
                                Button(action: {
                                    sharingLink = currentUrl
                                    isSharePresented = true
                                }, label: {
                                    HStack {
                                        Text("共享")
                                        Spacer()
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                })
                            }
                            Section {
                                Button(action: {
                                    if webView.customUserAgent?.contains("Macintosh; Intel Mac OS X") ?? false {
                                        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1 DarockBrowser/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)"
                                    } else {
                                        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 DarockBrowser/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)"
                                    }
                                    webView.reload()
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    HStack {
                                        Text((webView.customUserAgent?.contains("Macintosh; Intel Mac OS X") ?? false) ? "请求移动网站" : "请求桌面网站")
                                        Spacer()
                                        Image(systemName: (webView.customUserAgent?.contains("Mac OS X") ?? false) ? "applewatch" : "desktopcomputer")
                                    }
                                })
                                Button(action: {
                                    if let customDismissAction {
                                        customDismissAction()
                                    } else {
                                        webViewPresentationMode.dismiss()
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                        AdvancedWebViewController.shared.present(currentUrl, overrideOldWebView: .alwaysLegacy)
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
                                            presentationMode.wrappedValue.dismiss()
                                            presentingMediaList = .video
                                        }, label: {
                                            Image(systemName: "film.stack")
                                        })
                                        .disabled(videoLinks.isEmpty)
                                        Button(action: {
                                            presentationMode.wrappedValue.dismiss()
                                            presentingMediaList = .image
                                        }, label: {
                                            Image(systemName: "photo.stack")
                                        })
                                        .disabled(imageLinks.isEmpty)
                                        Button(action: {
                                            presentationMode.wrappedValue.dismiss()
                                            presentingMediaList = .music
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
                                Button(action: {
                                    if let customDismissAction {
                                        customDismissAction()
                                    } else {
                                        webViewPresentationMode.dismiss()
                                    }
                                    if isAutoAppearence && autoAppearenceOptionEnableForWebForceDark {
                                        AppearenceManager.shared.updateAll()
                                    }
                                }, label: {
                                    HStack {
                                        if #available(watchOS 10.0, *) {
                                            Image(systemName: "list.bullet")
                                            Text("返回标签页列表")
                                        } else {
                                            Image(systemName: "escape")
                                            Text("退出")
                                        }
                                    }
                                })
                                .tint({ if #available(watchOS 10.0, *) { true } else { false } }() ? .accentColor : .red)
                                if isProPurchased {
                                    Button(action: {
                                        isWebAbstractPresented = true
                                    }, label: {
                                        HStack {
                                            Image(systemName: "doc.plaintext")
                                            Text("网页摘要")
                                            
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
                                if let currentUrl = webView.url?.absoluteString, !currentUrl.hasPrefix("file://") {
                                    HStack {
                                        ZStack {
                                            Button(action: {
                                                if !isNewBookmarkCreated {
                                                    let userdefault = UserDefaults.standard
                                                    let total = userdefault.integer(forKey: "BookmarkTotal") &+ 1
                                                    let markLink = currentUrl
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
                                            if webView.customUserAgent?.contains("Macintosh; Intel Mac OS X") ?? false {
                                                webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1 DarockBrowser/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)"
                                            } else {
                                                webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 DarockBrowser/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)"
                                            }
                                            webView.reload()
                                            presentationMode.wrappedValue.dismiss()
                                        }, label: {
                                            Image(systemName:
                                                    (webView.customUserAgent?.contains("Macintosh; Intel Mac OS X") ?? false)
                                                  ? "applewatch"
                                                  : "desktopcomputer")
                                        })
                                        Button(action: {
                                            if let customDismissAction {
                                                customDismissAction()
                                            } else {
                                                webViewPresentationMode.dismiss()
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                AdvancedWebViewController.shared.present(currentUrl, overrideOldWebView: .alwaysLegacy)
                                            }
                                        }, label: {
                                            Image(systemName: "globe.badge.chevron.backward")
                                        })
                                    }
                                    HStack {
                                        if !(UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()).contains(currentUrl) {
                                            Button(action: {
                                                WEBackSwift.createWebArchive(for: webView)
                                                presentationMode.wrappedValue.dismiss()
                                            }, label: {
                                                Image(systemName: "archivebox")
                                            })
                                        }
                                        Button(action: {
                                            sharingLink = currentUrl
                                            isSharePresented = true
                                        }, label: {
                                            HStack {
                                                Image(systemName: "square.and.arrow.up")
                                                if (UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()).contains(currentUrl) {
                                                    Text("共享")
                                                }
                                            }
                                        })
                                    }
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
        .sheet(isPresented: $isBackListPresented, content: { BackForwardListView(webView: webView, type: .back, menuPresentationMode: presentationMode) })
        .sheet(isPresented: $isForwardListPresented, content: { BackForwardListView(webView: webView, type: .forward, menuPresentationMode: presentationMode) })
        .sheet(isPresented: $isWebAbstractPresented, content: { WebAbstractView(webView: webView) })
        .sheet(isPresented: $isSharePresented, content: { ShareView(linkToShare: $sharingLink) })
        .sheet(isPresented: $isHomeViewPresented) {
            NavigationStack {
                MainView { configuration in
                    if let url = URL(string: configuration.url) {
                        if !configuration.isWebArchive {
                            webView.load(URLRequest(url: url))
                        } else {
                            do {
                                webView.load(try Data(contentsOf: url), mimeType: "application/x-webarchive", characterEncodingName: "utf-8", baseURL: url)
                            } catch {
                                globalErrorHandler(error)
                            }
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onAppear {
            isLoading = webView.isLoading
            linkInput = webSearchString(from: webView.url?.absoluteString ?? "") ?? webView.url?.absoluteString ?? ""
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
    
    private func checkWebContent() {
        guard let currentUrl = webView.url?.absoluteString else {
            videoLinkLists.removeAll()
            imageLinkLists.removeAll()
            imageAltTextLists.removeAll()
            audioLinkLists.removeAll()
            isCheckingWebContent = false
            return
        }
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
    private func webSearchString(from url: String) -> String? {
        var searchPrefixes = [
            "https://www.bing.com/search?q=",
            "https://www.baidu.com/s?wd=",
            "https://www.google.com/search?q=",
            "https://www.sogou.com/web?query="
        ]
        if let customList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") {
            searchPrefixes.append(contentsOf: customList.map {
                if let range = $0.range(of: "%lld") {
                    return String($0[..<range.lowerBound])
                } else {
                    return $0
                }
            })
        }
        for searchPrefix in searchPrefixes where url.hasPrefix(searchPrefix) {
            if let dropped = url.dropFirst(searchPrefix.count).split(separator: "&").first {
                return String(dropped).urlDecoded()
            }
        }
        return nil
    }
}

private struct BackForwardListView: View {
    var webView: WKWebView
    var type: `Type`
    @Binding var menuPresentationMode: PresentationMode
    @State var list = [WKBackForwardListItem]()
    var body: some View {
        NavigationStack {
            List {
                if !list.isEmpty {
                    ForEach(0..<list.count, id: \.self) { i in
                        Button(action: {
                            webView.go(to: list[i])
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
                list = webView.backForwardList.backList
            } else {
                list = webView.backForwardList.forwardList
            }
        }
    }
    
    enum `Type` {
        case back
        case forward
    }
}

struct WebViewMediaListPresentation: Identifiable {
    static let video = WebViewMediaListPresentation(.video)
    static let image = WebViewMediaListPresentation(.image)
    static let music = WebViewMediaListPresentation(.music)
    
    let id: String
    private let underlyingType: UnderlyingPresentationType
    
    private init(_ underlyingType: UnderlyingPresentationType) {
        self.id = underlyingType.rawValue
        self.underlyingType = underlyingType
    }
    
    @ViewBuilder
    func callAsFunction() -> some View {
        switch underlyingType {
        case .video:
            VideoListView()
        case .image:
            ImageListView()
        case .music:
            AudioListView()
        }
    }
    
    private enum UnderlyingPresentationType: String {
        case video
        case image
        case music
    }
}
