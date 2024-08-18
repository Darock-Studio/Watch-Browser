//
//  SwiftWebView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/18.
//

import SwiftUI
import Dynamic

struct SwiftWebView: View {
    var webView: NSObject
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("HideDigitalTime") var hideDigitalTime = false
    @State var isBrowsingMenuPresented = false
    var body: some View {
        WebView(webView: webView)
            .ignoresSafeArea()
            ._statusBarHidden(hideDigitalTime)
            .sheet(isPresented: $isBrowsingMenuPresented) {
                BrowsingMenuView(webViewPresentationMode: presentationMode)
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
    }
}
private struct WebView: _UIViewRepresentable {
    var webView: NSObject
    func makeUIView(context: Context) -> some NSObject {
        webView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
