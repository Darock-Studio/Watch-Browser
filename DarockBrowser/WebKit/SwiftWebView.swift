//
//  SwiftWebView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/18.
//

import OSLog
import Combine
import SwiftUI

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
    @AppStorage("ShowFastExitButton") var showFastExitButton = false
    @AppStorage("AlwaysReloadWebPageAfterCrash") var alwaysReloadWebPageAfterCrash = false
    @State var isQuickAvoidanceShowingEmpty = false
    @State var presentingMediaList: WebViewMediaListPresentation?
    @State var isBrowsingMenuPresented = false
    @State var isHidingDistractingItems = false
    @State var webCanGoBack = false
    @State var loadingProgress = 0.0
    @State var isLoadingProgressHidden = true
    @State var webErrorText: String?
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
                                if #available(watchOS 10, *) {
                                    Image(systemName: webCanGoBack ? "chevron.backward" : "list.bullet")
                                        .foregroundStyle(.accent)
                                        .contentTransition(.symbolEffect(.replace))
                                } else {
                                    Image(systemName: webCanGoBack ? "chevron.backward" : "list.bullet")
                                        .foregroundStyle(.accent)
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
                    NavigationView {
                        content
                    }
                    .toolbar(.hidden)
                    .toolbarBackground(.hidden)
                }
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
                    HStack {
                        Button(action: {
                            isBrowsingMenuPresented = true
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 40, height: 40)
                                    .opacity(0.0100000002421438702673861521)
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(Color(hex: 0x00aad7))
                            }
                        })
                        .buttonStyle(.plain)
                        .padding(5)
                        if showFastExitButton {
                            Button(action: {
                                if let customDismissAction {
                                    customDismissAction()
                                } else {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }, label: {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: 40, height: 40)
                                        .opacity(0.0100000002421438702673861521)
                                    Image(systemName: "escape")
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundStyle(.red)
                                }
                            })
                            .buttonStyle(.plain)
                            .padding(.vertical, 5)
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
        ._statusBarHidden(hideDigitalTime || isQuickAvoidanceShowingEmpty)
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
        }
        .onDisappear {
            globalWebBrowsingUserActivity?.invalidate()
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
