//
//  SwiftWebView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/18.
//

import SwiftUI
import Dynamic

struct SwiftWebView: View {
    var webView: WKWebView
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("WebViewLayout") var webViewLayout = "MaximumViewport"
    @AppStorage("HideDigitalTime") var hideDigitalTime = false
    @State var isQuickAvoidanceShowingEmpty = false
    @State var isBrowsingMenuPresented = false
    @State var isHidingDistractingItems = false
    @State var webCanGoBack = false
    var body: some View {
        ZStack {
            DoubleTapActionButton(forType: .inWeb, presentationModeForExitWeb: presentationMode) {
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
                                        webViewObject.configuration.userContentController.removeAllScriptMessageHandlers()
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
                        ToolbarItem(placement: .cancellationAction) {
                            Button(action: {
                                if webCanGoBack {
                                    webView.goBack()
                                } else {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }, label: {
                                if #available(watchOS 10, *) {
                                    Image(systemName: webCanGoBack ? "chevron.backward" : "escape")
                                        .foregroundStyle(webCanGoBack ? .accent : .red)
                                        .contentTransition(.symbolEffect(.replace))
                                } else {
                                    Image(systemName: webCanGoBack ? "chevron.backward" : "escape")
                                        .foregroundStyle(webCanGoBack ? .accent : .red)
                                }
                            })
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(action: {
                                isBrowsingMenuPresented = true
                            }, label: {
                                Image(systemName: "ellipsis")
                            })
                        }
                    }
                }
                .wrapIf(webViewLayout != "MaximumViewport") { content in
                    NavigationStack { content }
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
            BrowsingMenuView(webViewPresentationMode: presentationMode, isHidingDistractingItems: $isHidingDistractingItems)
        }
        .onDisappear {
            WEBackSwift.storeWebTab()
            globalWebBrowsingUserActivity?.invalidate()
        }
        .onReceive(AdvancedWebViewController.presentBrowsingMenuPublisher) { _ in
            isBrowsingMenuPresented = true
        }
        .onReceive(AdvancedWebViewController.dismissWebViewPublisher) { _ in
            presentationMode.wrappedValue.dismiss()
        }
        .onReceive(webView.publisher(for: \.canGoBack)) { value in
            webCanGoBack = value
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
