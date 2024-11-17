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
    var customDismissAction: (() -> Void)?
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("WebViewLayout") var webViewLayout = "MaximumViewport"
    @AppStorage("HideDigitalTime") var hideDigitalTime = false
    @AppStorage("KeepDigitalTime") var keepDigitalTime = false
    @AppStorage("ShowFastExitButton") var showFastExitButton = false
    @AppStorage("AlwaysReloadWebPageAfterCrash") var alwaysReloadWebPageAfterCrash = false
    @State var isBrowsingMenuPresented = false
    @State var webCanGoBack = false
    @State var loadingProgress = 0.0
    @State var isLoadingProgressHidden = true
    @State var webErrorText: String?
    var body: some View {
        ZStack {
            WebView(webView: webView)
                .ignoresSafeArea()
//                .toolbar {
//                    if webViewLayout == "FastPrevious" {
//                        ToolbarItem(placement: {
//                            if #available(watchOS 10, *) {
//                                ToolbarItemPlacement.topBarLeading
//                            } else {
//                                ToolbarItemPlacement.cancellationAction
//                            }
//                        }()) {
//                            Button(action: {
//                                if webCanGoBack {
//                                    webView.goBack()
//                                } else {
//                                    if let customDismissAction {
//                                        customDismissAction()
//                                    } else {
//                                        presentationMode.wrappedValue.dismiss()
//                                    }
//                                }
//                            }, label: {
//                                if #available(watchOS 10, *) {
//                                    Image(systemName: webCanGoBack ? "chevron.backward" : "escape")
//                                        .foregroundStyle(webCanGoBack ? Color.accentColor : .red)
//                                        .contentTransition(.symbolEffect(.replace))
//                                } else {
//                                    Image(systemName: webCanGoBack ? "chevron.backward" : "escape")
//                                        .foregroundStyle(webCanGoBack ? Color.accentColor : .red)
//                                }
//                            })
//                        }
//                        ToolbarItem(placement: {
//                            if #available(watchOS 10, *) {
//                                ToolbarItemPlacement.topBarTrailing
//                            } else {
//                                ToolbarItemPlacement.confirmationAction
//                            }
//                        }()) {
//                            Button(action: {
//                                isBrowsingMenuPresented = true
//                            }, label: {
//                                Image(systemName: "ellipsis")
//                            })
//                        }
//                    }
//                }
                .wrapIf(webViewLayout != "MaximumViewport") { content in
                    NavigationView {
                        content
                    }
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
                    .tint(.init(red: 0, green: 170 / 255, blue: 215 / 255))
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
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.black)
                                .frame(width: 60, height: 30)
                                .offset(y: 8)
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
                                    .foregroundStyle(Color(red: 0, green: 170 / 255, blue: 215 / 255))
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
        }
        ._statusBarHidden(hideDigitalTime)
        .sheet(isPresented: $isBrowsingMenuPresented) {
            BrowsingMenuView(
                webView: webView,
                webViewPresentationMode: presentationMode,
                customDismissAction: customDismissAction
            )
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
        .onReceive(WWUIWebController.presentBrowsingMenuPublisher) { _ in
            isBrowsingMenuPresented = true
        }
        .onReceive(WWUIWebController.dismissWebViewPublisher) { _ in
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
    }
}
private struct WebView: _UIViewRepresentable {
    var webView: NSObject
    func makeUIView(context: Context) -> some NSObject {
        webView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
