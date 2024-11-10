//
//  WebViewDelegate.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//
//  Renamed WESwiftDelegate.swift -> WebViewDelegate on 2024/8/14
//

import OSLog
import SwiftUI
import Foundation
import DiagnosticsUI

var pWebDelegateStartNavigationAutoViewport = false

@objcMembers
public final class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    public static let shared = WebViewNavigationDelegate()
    
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("DBIsAutoAppearence") var isAutoAppearence = false
    @AppStorage("DBAutoAppearenceOptionEnableForWebForceDark") var autoAppearenceOptionEnableForWebForceDark = true
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        // MARK: Handle Darock Custom URL Schemes
        if let url = navigationAction.request.url?.absoluteString {
            if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
                let schemeSplited = url.split(separator: "://", maxSplits: 1, omittingEmptySubsequences: false).map { String($0) }
                if schemeSplited.count == 2 {
                    switch schemeSplited[0] {
                    case "diags" where schemeSplited[1].isEmpty || Int64(schemeSplited[1]) != nil:
                        DispatchQueue.main.async {
                            AdvancedWebViewController.dismissWebViewPublisher.send()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                DUIDiagnostics.shared.startDiagnostic(withID: schemeSplited[1].isEmpty ? nil : schemeSplited[1])
                            }
                        }
                        return .cancel
                    default: break
                    }
                }
            }
        }
        
        return .allow
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        let nativeSupportedTypes = [".mp3", ".mp4", ".png", ".epub"]
        if let url = navigationResponse.response.url?.absoluteString,
           (url.hasPrefix("http://") || url.hasPrefix("https://"))
            && !nativeSupportedTypes.contains(where: { url.contains($0) })
            && !navigationResponse.canShowMIMEType {
            DispatchQueue.main.async {
                let externalDownloadViewController = _makeUIHostingController(AnyView(DownloadToExternalView(url: url)))
                safePresent(
                    externalDownloadViewController,
                    on: WKApplication.shared().visibleInterfaceController?.value(forKey: "underlyingUIHostingController") as? NSObject
                )
            }
            
            return .cancel
        } else {
            return .allow
        }
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let url = webView.url {
            let curl = url.absoluteString
            if _fastPath(isHistoryRecording) {
                recordHistory(curl, webSearch: webSearch, showName: webView.title)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        debugPrint("Start Navigation")
        SwiftWebView.webErrorText.send(nil)
        SwiftWebView.loadingProgressHidden.send(false)
        if _slowPath(pWebDelegateStartNavigationAutoViewport) {
            pWebDelegateStartNavigationAutoViewport = false
            DispatchQueue(label: "com.darock.WatchBrowser.wt.run-auto-viewport", qos: .userInitiated).async {
                webView.evaluateJavaScript("""
                var meta = document.createElement('meta');
                meta.name = "viewport";
                meta.content = "width=device-width, initial-scale=1.0";
                document.getElementsByTagName('head')[0].appendChild(meta);
                """)
            }
        }
        if let url = webView.url {
            let curl = url.absoluteString
            if _slowPath(curl.hasSuffix(".mp3")) {
                audioLinkLists = [curl]
                AdvancedWebViewController.shared.dismissWebView()
                pShouldPresentAudioList = true
                return
            }
            if _slowPath(curl.hasSuffix(".mp4")) {
                videoLinkLists = [curl]
                AdvancedWebViewController.shared.dismissWebView()
                pShouldPresentVideoList = true
                return
            }
            if _slowPath(curl.hasSuffix(".epub")) {
                bookLinkLists = [curl]
                AdvancedWebViewController.shared.dismissWebView()
                pShouldPresentBookList = true
                return
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        debugPrint("Finish Navigation")
        SwiftWebView.loadingProgressHidden.send(true)
        // Dark Mode
        if UserDefaults.standard.bool(forKey: "ForceApplyDarkMode")
            || (isAutoAppearence && autoAppearenceOptionEnableForWebForceDark && AppearenceManager.shared.currentAppearence == .dark) {
            DispatchQueue(label: "com.darock.WatchBrowser.wt.run-fit-dark-mode", qos: .userInitiated).async {
                webView.evaluateJavaScript("""
                const allElements = document.querySelectorAll('*');
                function applyDarkMode(element) {
                    element.style.backgroundColor = '#121212';
                    element.style.color = '#ffffff';
                }
                allElements.forEach(applyDarkMode);
                const observer = new MutationObserver(mutations => {
                    mutations.forEach(mutation => {
                        if (mutation.type === 'childList') {
                            mutation.addedNodes.forEach(node => {
                                if (node.nodeType === Node.ELEMENT_NODE) {
                                    applyDarkMode(node);
                                    node.querySelectorAll('*').forEach(applyDarkMode);
                                }
                            });
                        }
                    });
                });
                observer.observe(document.documentElement, { childList: true, subtree: true });
                """)
            }
        }
        let userScriptNames = UserDefaults.standard.stringArray(forKey: "UserScriptNames") ?? [String]()
        DispatchQueue(label: "com.darock.WatchBrowser.wt.run-user-script", qos: .userInitiated).async {
            for userScriptName in userScriptNames {
                do {
                    let jsStr = String(
                        decoding: try Data(
                            contentsOf: URL(
                                fileURLWithPath: NSHomeDirectory()
                                + "/Documents/UserScripts/\(userScriptName.replacingOccurrences(of: "/", with: "{slash}")).js"
                            )
                        ),
                        as: UTF8.self
                    )
                    webView.evaluateJavaScript(jsStr)
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
        
        let curl = webView.url
        if (UserDefaults.standard.object(forKey: "CCIsHandoffEnabled") as? Bool) ?? true {
            if _fastPath((curl?.absoluteString.hasPrefix("http") ?? false) || (curl?.absoluteString.hasPrefix("https") ?? false)) {
                // User Activity
                globalWebBrowsingUserActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                globalWebBrowsingUserActivity.title = webView.title
                globalWebBrowsingUserActivity.isEligibleForHandoff = true
                globalWebBrowsingUserActivity.webpageURL = curl
                globalWebBrowsingUserActivity.becomeCurrent()
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        debugPrint("Failed Navigation")
        debugPrint(error)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        debugPrint("Failed Early Navigation")
        SwiftWebView.loadingProgressHidden.send(true)
        os_log(.error, "\(error)")
        SwiftWebView.webErrorText.send(String(localized: "暗礁浏览器打不开该网页。\n错误是：“\(error.localizedDescription)”。"))
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // If always reload enabled and WebView is presenting currently, reload page.
        SwiftWebView.webViewCrashNotification.send()
    }
}

public final class WebViewUIDelegate: NSObject, WKUIDelegate {
    public static let shared = WebViewUIDelegate()
    
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

public final class WebViewScriptMessageHandler: NSObject, WKScriptMessageHandler {
    public static let shared = WebViewScriptMessageHandler()
    
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        debugPrint(message.body)
        if message.name == "HDIDCallback", let content = message.body as? String {
            debugPrint("Hiding ID: \(content)")
//            webViewObject.changeCSSVisibility(elementID: content, isVisible: false, elementType: .id)
        } else if message.name == "HDClassCallback", let content = message.body as? String {
            debugPrint("Hiding Class: \(content)")
//            webViewObject.changeCSSVisibility(elementID: content, isVisible: false, elementType: .class)
//            webViewObject.evaluateJavaScript("""
//            [].forEach.call(document.querySelectorAll('.\(content)'), function(el) {
//                el.style.filter = 'blur(20px)';
//                el.style.outline = '5px solid #66ccff';
//            });
//            """)
        }
    }
}

final class SafariViewDelegate: NSObject, SFSafariViewControllerDelegate {
    static let shared = SafariViewDelegate()
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        debugPrint("SF Complete Load")
    }
    
    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo url: URL) {
        debugPrint("Redirect to: \(url)")
    }
}
