//
//  WebViewDelegate.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//
//  Renamed WESwiftDelegate.swift -> WebViewDelegate on 2024/8/14
//

import SwiftUI
import Dynamic
import Foundation

var pWebDelegateStartNavigationAutoViewport = false

fileprivate var errorLabel = { () -> Dynamic in
    let errorLabel = Dynamic.UILabel()
    errorLabel.setFrame(getMiddleRect(y: 30, height: 60))
    errorLabel.setFont(UIFont(name: "Helvetica", size: 13))
    errorLabel.setNumberOfLines(4)
    errorLabel.setTextColor(UIColor.black)
    errorLabel.setTextAlignment(NSTextAlignment.center)
    return errorLabel
}()

@objcMembers
public final class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    public static let shared = WebViewNavigationDelegate()
    
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("WebSearch") var webSearch = "必应"
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        debugPrint("Start Navigation")
        errorLabel.removeFromSuperview()
        AdvancedWebViewController.shared.loadProgressView.hidden = false
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
            if _fastPath(isHistoryRecording) {
                recordHistory(curl, webSearch: webSearch, showName: webView.title)
            }
            if _slowPath(curl.hasSuffix(".mp3")) {
                audioLinkLists = [curl]
                AdvancedWebViewController.shared.dismissWebView()
                pShouldPresentAudioList = true
                dismissListsShouldRepresentWebView = true
                return
            }
            if _slowPath(curl.hasSuffix(".mp4")) {
                videoLinkLists = [curl]
                AdvancedWebViewController.shared.dismissWebView()
                pShouldPresentVideoList = true
                dismissListsShouldRepresentWebView = true
                return
            }
            if _slowPath(curl.hasSuffix(".epub")) {
                bookLinkLists = [curl]
                AdvancedWebViewController.shared.dismissWebView()
                pShouldPresentBookList = true
                dismissListsShouldRepresentWebView = true
                return
            }
            if _slowPath(curl.contains("bilibili.com/")) && (UserDefaults(suiteName: "group.darockst")?.bool(forKey: "DCIsMeowBiliInstalled") ?? false) {
                if let bvid = curl.split(separator: "bilibili.com/video/")[from: 1], bvid.hasPrefix("BV") {
                    WKExtension.shared().openSystemURL(URL(string: "https://darock.top/meowbili/video/\(bvid)")!)
                }
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        debugPrint("Finish Navigation")
        AdvancedWebViewController.shared.loadProgressView.hidden = true
        // Dark Mode
        if UserDefaults.standard.bool(forKey: "ForceApplyDarkMode") {
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
            if _fastPath(curl?.absoluteString.hasPrefix("http") ?? false || curl?.absoluteString.hasPrefix("https") ?? false) {
                // User Activity
                globalWebBrowsingUserActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                globalWebBrowsingUserActivity.title = Dynamic(webViewObject).title.asString
                globalWebBrowsingUserActivity.isEligibleForHandoff = true
                globalWebBrowsingUserActivity.webpageURL = Dynamic(webViewObject).URL.asObject as? URL
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
        AdvancedWebViewController.shared.loadProgressView.hidden = true
        debugPrint(error)
        errorLabel.text = "\(String(localized: "载入页面时出错"))\n\(error.localizedDescription)"
        AdvancedWebViewController.shared.webViewHolder.addSubview(errorLabel)
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if UserDefaults.standard.bool(forKey: "AlwaysReloadWebPageAfterCrash") {
            webView.reload()
        }
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
            webViewObject.changeCSSVisibility(elementID: content, isVisible: false, elementType: .id)
        } else if message.name == "HDClassCallback", let content = message.body as? String {
            debugPrint("Hiding Class: \(content)")
            webViewObject.changeCSSVisibility(elementID: content, isVisible: false, elementType: .class)
//            webViewObject.evaluateJavaScript("""
//            [].forEach.call(document.querySelectorAll('.\(content)'), function(el) {
//                el.style.filter = 'blur(20px)';
//                el.style.outline = '5px solid #66ccff';
//            });
//            """)
        }
    }
}

public final class SafariViewDelegate: NSObject, SFSafariViewControllerDelegate {
    public static let shared = SafariViewDelegate()
    
    public func safariViewController(_ controller: Any, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        debugPrint("SF Complete Load")
    }
    
    public func safariViewController(_ controller: Any, initialLoadDidRedirectTo URL: URL) {
        debugPrint("Redirect to: \(URL)")
    }
}
