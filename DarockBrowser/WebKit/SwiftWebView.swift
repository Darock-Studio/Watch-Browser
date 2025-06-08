//
//  SwiftWebView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/18.
//

import OSLog
import Combine
import DarockUI

struct SwiftWebView: View {
    static let loadingProgressHidden = CurrentValueSubject<Bool, Never>(true)
    static let webErrorText = CurrentValueSubject<String?, Never>(nil)
    static let webViewCrashNotification = PassthroughSubject<Void, Never>()
    
    var webView: WKWebView
    var insideTab: Binding<WebViewTab>?
    var customDismissAction: (() -> Void)?
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("WebViewLayout") var webViewLayout = "MaximumViewport"
    @AppStorage("HideDigitalTime") var hideDigitalTime = false
    @AppStorage("KeepDigitalTime") var keepDigitalTime = false
    @AppStorage("IsUseTabBasedBrowsing") var isUseTabBasedBrowsing = true
    @AppStorage("IsProPurchased") var isProPurchased = false
    @AppStorage("AlwaysReloadWebPageAfterCrash") var alwaysReloadWebPageAfterCrash = false
    @State var fastButtons = [WebViewFastButton].getCurrentFastButtons()
    @State var isQuickAvoidanceShowingEmpty = false
    @State var presentingMediaList: WebViewMediaListPresentation?
    @State var isBrowsingMenuPresented = false
    @State var isHidingDistractingItems = false
    @State var webCanGoBack = false
    @State var webCanGoForward = false
    @State var webIsLoading = false
    @State var loadingProgress = 0.0
    @State var isLoadingProgressHidden = true
    @State var webErrorText: String?
    @State var webContentCheckTimer: Timer?
    @State var linksUpdateTimer: Timer?
    @State var videoLinks = [String]()
    @State var imageLinks = [String]()
    @State var imageAltTexts = [String]()
    @State var audioLinks = [String]()
    var body: some View {
        ZStack {
            DoubleTapActionButton(forType: .inWeb, webView: webView, presentationModeForExitWeb: presentationMode) {
                isQuickAvoidanceShowingEmpty = true
            }
            WebView(webView: webView)
                .ignoresSafeArea()
                .overlay {
                    if isHidingDistractingItems {
                        VStack {
                            Spacer()
                            VStack {
                                HStack {
                                    Text("轻触要移除的项目")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Button(action: {
                                        webView.configuration.userContentController.removeAllScriptMessageHandlers()
                                        isHidingDistractingItems = false
                                    }, label: {
                                        Text("完成")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.white)
                                    })
                                    .buttonStyle(.plain)
                                    .padding(5)
                                    .background {
                                        Capsule()
                                            .fill(Color.accentColor)
                                    }
                                }
                                Spacer()
                                    .frame(height: 5)
                            }
                            .font(.system(size: 12))
                            .foregroundStyle(.accent)
                            .padding(.vertical, 5)
                            .background {
                                if #available(watchOS 10, *) {
                                    Color.clear.background(Material.ultraThin)
                                        .brightness(0.1)
                                        .saturation(2.5)
                                        .frame(width: WKInterfaceDevice.current().screenBounds.width + 100, height: 100)
                                        .blur(radius: 10)
                                        .offset(y: 20)
                                }
                            }
                        }
                        .ignoresSafeArea()
                    }
                }
                .toolbar {
                    if webViewLayout == "FastPrevious" {
                        ToolbarItem(placement: {
                            if #available(watchOS 10, *) {
                                ToolbarItemPlacement.topBarLeading
                            } else {
                                ToolbarItemPlacement.cancellationAction
                            }
                        }()) {
                            Button(action: {
                                if webCanGoBack {
                                    webView.goBack()
                                } else {
                                    if let customDismissAction {
                                        customDismissAction()
                                    } else {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }, label: {
                                Group {
                                    if #available(watchOS 10, *) {
                                        Image(systemName: webCanGoBack ? "chevron.backward" : (isUseTabBasedBrowsing ? "list.bullet" : "escape"))
                                            .foregroundStyle(!isUseTabBasedBrowsing && !webCanGoBack ? .red : .accent)
                                            .contentTransition(.symbolEffect(.replace))
                                    } else {
                                        Image(systemName: webCanGoBack ? "chevron.backward" : (isUseTabBasedBrowsing ? "list.bullet" : "escape"))
                                            .foregroundStyle(!isUseTabBasedBrowsing && !webCanGoBack ? .red : .accent)
                                    }
                                }
                            })
                        }
                        ToolbarItem(placement: {
                            if #available(watchOS 10, *) {
                                ToolbarItemPlacement.topBarTrailing
                            } else {
                                ToolbarItemPlacement.confirmationAction
                            }
                        }()) {
                            Button(action: {
                                isBrowsingMenuPresented = true
                            }, label: {
                                Image(systemName: "ellipsis")
                            })
                        }
                    }
                }
                .wrapIf(webViewLayout != "MaximumViewport") { content in
                    if isUseTabBasedBrowsing {
                        NavigationView {
                            content
                        }
                    } else {
                        NavigationStack {
                            content
                        }
                    }
                }
                .toolbar(.hidden)
                .toolbarBackground(.hidden)
            if let errorText = webErrorText {
                Text(errorText)
                    .foregroundStyle(.black)
                    .padding()
                    .allowsHitTesting(false)
            }
            VStack {
                ProgressView(value: loadingProgress)
                    .tint(Color(hex: 0x00aad7))
                    .opacity(isLoadingProgressHidden ? 0 : 1)
                    .animation(.easeOut(duration: 0.2), value: isLoadingProgressHidden)
                    .animation(.smooth, value: loadingProgress)
                    .offset(y: -8)
                Spacer()
            }
            .ignoresSafeArea()
            if webViewLayout != "FastPrevious" {
                if keepDigitalTime {
                    HStack {
                        Spacer()
                        VStack {
                            if #available(watchOS 10.0, *) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Material.thin)
                                    .frame(width: 46, height: 10)
                                    .blur(radius: 5)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 16)
                            } else {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.black)
                                    .frame(width: 60, height: 30)
                                    .offset(y: 8)
                            }
                            Spacer()
                        }
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
                VStack {
                    HStack(spacing: 0) {
                        Button(action: {
                            isBrowsingMenuPresented = true
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 30, height: 40)
                                    .minimumRenderableOpacity()
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(Color(hex: 0x00aad7))
                            }
                            .padding(.leading, 7)
                        })
                        .buttonStyle(.plain)
                        .padding(.vertical, 5)
                        if fastButtons != [.empty, .empty, .empty, .empty] && isProPurchased {
                            ForEach(0..<fastButtons.count, id: \.self) { i in
                                Spacer()
                                Button(action: {
                                    switch fastButtons[i] {
                                    case .previousPage:
                                        webView.goBack()
                                    case .nextPage:
                                        webView.goForward()
                                    case .refresh:
                                        if webIsLoading {
                                            webView.stopLoading()
                                        } else {
                                            webView.reload()
                                        }
                                    case .decodeVideo:
                                        presentingMediaList = .init(.video, links: videoLinks)
                                    case .decodeImage:
                                        presentingMediaList = .init(.image, links: imageLinks, linksAlt: imageAltTexts)
                                    case .decodeMusic:
                                        presentingMediaList = .init(.music, links: audioLinks)
                                    case .exit:
                                        if let customDismissAction {
                                            customDismissAction()
                                        } else {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    case .empty:
                                        break
                                    }
                                }, label: {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(width: 30, height: 40)
                                            .minimumRenderableOpacity()
                                        Image(systemName: {
                                            switch fastButtons[i] {
                                            case .nextPage: "chevron.forward"
                                            case .previousPage: "chevron.backward"
                                            case .refresh: webIsLoading ? "stop.fill" : "arrow.clockwise"
                                            case .decodeVideo: "film.stack"
                                            case .decodeImage: "photo.stack"
                                            case .decodeMusic: "music.quarternote.3"
                                            case .exit: "escape"
                                            case .empty: "ellipsis.circle"
                                            }
                                        }())
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundStyle(fastButtons[i] == .exit ? .red : .blue)
                                    }
                                })
                                .buttonStyle(.plain)
                                .disabled(
                                    (fastButtons[i] == .previousPage && !webCanGoBack)
                                    || (fastButtons[i] == .nextPage && !webCanGoForward)
                                    || (fastButtons[i] == .decodeVideo && videoLinks.isEmpty)
                                    || (fastButtons[i] == .decodeImage && imageLinks.isEmpty)
                                    || (fastButtons[i] == .decodeMusic && audioLinks.isEmpty)
                                )
                                .opacity(fastButtons[i] == .empty || (i == 3 && !hideDigitalTime) ? 0 : 1)
                                .wrapIf(i == 3) { content in
                                    content
                                        .padding(.trailing, 7)
                                }
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
            }
            if isQuickAvoidanceShowingEmpty {
                Color.black
                    .ignoresSafeArea()
                    .onTapGesture(count: 3) {
                        isQuickAvoidanceShowingEmpty = false
                    }
            }
        }
        .brightnessReducable()
        .sheet(isPresented: $isBrowsingMenuPresented) {
            BrowsingMenuView(
                webView: webView,
                webViewPresentationMode: presentationMode,
                presentingMediaList: $presentingMediaList,
                isHidingDistractingItems: $isHidingDistractingItems,
                customDismissAction: customDismissAction
            )
        }
        .sheet(item: $presentingMediaList) { type in
            NavigationStack { type() }
        }
        .onAppear {
            if let load = insideTab?.wrappedValue.shouldLoad {
                switch load {
                case .web(let url):
                    webView.load(URLRequest(url: url))
                case .webArchive(let url):
                    do {
                        webView.load(try Data(contentsOf: url), mimeType: "application/x-webarchive", characterEncodingName: "utf-8", baseURL: url)
                    } catch {
                        globalErrorHandler(error)
                    }
                }
                insideTab?.wrappedValue.shouldLoad = nil
            }
            if hideDigitalTime {
                setMainSceneHideStatusBarSubject.send(true)
            }
            if _fastPath(webContentCheckTimer == nil) {
                webContentCheckTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                    checkWebContent(for: webView)
                }
            }
            if _fastPath(linksUpdateTimer == nil) {
                linksUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                    videoLinks = videoLinkLists
                    imageLinks = imageLinkLists
                    imageAltTexts = imageAltTextLists
                    audioLinks = audioLinkLists
                }
            }
        }
        .onDisappear {
            if hideDigitalTime {
                setMainSceneHideStatusBarSubject.send(false)
            }
            linksUpdateTimer?.invalidate()
            linksUpdateTimer = nil
            webContentCheckTimer?.invalidate()
            webContentCheckTimer = nil
            globalWebBrowsingUserActivity?.invalidate()
        }
        .onChange(of: isQuickAvoidanceShowingEmpty) { _ in
            setMainSceneHideStatusBarSubject.send(isQuickAvoidanceShowingEmpty)
        }
        .onReceive(SwiftWebView.loadingProgressHidden) { isHidden in
            isLoadingProgressHidden = isHidden
        }
        .onReceive(SwiftWebView.webErrorText) { text in
            webErrorText = text
        }
        .onReceive(SwiftWebView.webViewCrashNotification) { _ in
            if alwaysReloadWebPageAfterCrash {
                webView.reload()
            }
        }
        .onReceive(AdvancedWebViewController.presentBrowsingMenuPublisher) { _ in
            isBrowsingMenuPresented = true
        }
        .onReceive(AdvancedWebViewController.dismissWebViewPublisher) { _ in
            if let customDismissAction {
                customDismissAction()
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onReceive(webView.publisher(for: \.canGoBack)) { value in
            webCanGoBack = value
        }
        .onReceive(webView.publisher(for: \.canGoForward), perform: { value in
            webCanGoForward = value
        })
        .onReceive(webView.publisher(for: \.estimatedProgress)) { value in
            loadingProgress = value
        }
        .onReceive(webView.publisher(for: \.url)) { url in
            if let url {
                insideTab?.wrappedValue.metadata?.url = url
            }
        }
        .onReceive(webView.publisher(for: \.title)) { title in
            if let title {
                insideTab?.wrappedValue.metadata?.title = title
            }
        }
        .onReceive(webView.publisher(for: \.isLoading)) { loading in
            webIsLoading = loading
            if !loading, insideTab != nil {
                let snapshotConfiguration = WKSnapshotConfiguration()
                webView.takeSnapshot(with: snapshotConfiguration) { image, _ in
                    DispatchQueue(label: "com.darock.WatchBrowser.tui.Snapshot", qos: .utility).async {
                        if let image {
                            do {
                                if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/tmp/TabSnapshots") {
                                    try FileManager.default.createDirectory(
                                        atPath: NSHomeDirectory() + "/tmp/TabSnapshots",
                                        withIntermediateDirectories: false
                                    )
                                }
                                let snapshotFilePath = insideTab?.wrappedValue.metadata?.snapshotPath ?? "/tmp/TabSnapshots/\(UUID().uuidString).drkdatas"
                                try image.pngData()?.write(to: URL(filePath: NSHomeDirectory() + snapshotFilePath))
                                insideTab?.wrappedValue.metadata?.snapshotPath = snapshotFilePath
                            } catch {
                                os_log(.error, "\(error)")
                            }
                        }
                    }
                }
            }
        }
    }
}
private struct WebView: _UIViewRepresentable {
    var webView: NSObject
    func makeUIView(context: Context) -> some NSObject {
        webView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
