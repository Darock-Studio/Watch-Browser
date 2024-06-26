//
//  WESwiftDelegate.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//

import SwiftUI
import Dynamic
import Foundation

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
public class WESwiftDelegate: NSObject {
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("WebSearch") var webSearch = "必应"
    
    public func webView(_ view: Any, didStartProvisionalNavigation navigation: Any) {
        debugPrint("Start Navigation")
        errorLabel.removeFromSuperview()
        AdvancedWebViewController.shared.loadProgressView.hidden = false
        if let url = Dynamic(webViewObject).URL.asObject {
            let curl = (url as! NSURL).absoluteString!
            if _fastPath(isHistoryRecording) {
                RecordHistory(curl, webSearch: webSearch, showName: Dynamic(webViewObject).title.asString)
            }
            if curl.hasSuffix(".mp4") {
                videoLinkLists = [curl]
                WebExtension.presentVideoList()
                return
            }
            if curl.hasSuffix(".epub") {
                bookLinkLists = [curl]
                WebExtension.presentBookList()
                return
            }
        }
    }
    
    public func webView(_ view: Any, didFinishNavigation navigation: Any) {
        debugPrint("Finish Navigation")
        AdvancedWebViewController.shared.loadProgressView.hidden = true
        // Dark Mode
        if UserDefaults.standard.bool(forKey: "ForceApplyDarkMode") {
            DispatchQueue(label: "com.darock.WatchBrowser.wt.run-fit-dark-mode", qos: .userInitiated).async {
                Dynamic(webViewObject).evaluateJavaScript("""
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
                """, completionHandler: nil)
            }
        }
        let userScriptNames = UserDefaults.standard.stringArray(forKey: "UserScriptNames") ?? [String]()
        DispatchQueue(label: "com.darock.WatchBrowser.wt.run-user-script", qos: .userInitiated).async {
            for userScriptName in userScriptNames {
                do {
                    let jsStr = String(
                        data: try Data(
                            contentsOf: URL(
                                fileURLWithPath: NSHomeDirectory()
                                + "/Documents/UserScripts/\(userScriptName.replacingOccurrences(of: "/", with: "{slash}")).js"
                            )
                        ),
                        encoding: .utf8
                    ) ?? ""
                    Dynamic(webViewObject).evaluateJavaScript(jsStr, completionHandler: nil)
                } catch {
                    globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
                }
            }
        }
        
        let curl = Dynamic(webViewObject).URL.asObject as? URL
        if curl?.absoluteString.hasPrefix("http") ?? false || curl?.absoluteString.hasPrefix("https") ?? false {
            // User Activity
            let nsActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
            nsActivity.title = Dynamic(webViewObject).title.asString
            nsActivity.isEligibleForHandoff = true
            nsActivity.webpageURL = Dynamic(webViewObject).URL.asObject as? URL
            nsActivity.becomeCurrent()
        }
    }
    
    public func webView(_ view: Any, didFailNavigation navigation: Any, withError error: NSError) {
        debugPrint("Failed Navigation")
        debugPrint(error)
    }
    
    public func webView(_ view: Any, didFailProvisionalNavigation navigation: Any, withError error: NSError) {
        debugPrint("Failed Early Navigation")
        AdvancedWebViewController.shared.loadProgressView.hidden = true
        debugPrint(error)
        errorLabel.text = "载入页面时出错\n\(error.localizedDescription)"
        AdvancedWebViewController.shared.webViewHolder.addSubview(errorLabel)
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: Any) {
        if UserDefaults.standard.bool(forKey: "AlwaysReloadWebPageAfterCrash") {
            Dynamic(webViewObject).reload()
        }
    }
    
    // MARK: UI Delegate
    public func webView(_ webView: Any, createWebViewWith configuration: Any, for navigationAction: Any, windowFeatures: Any) -> Any? {
        if Dynamic(navigationAction).targetFrame == nil {
            Dynamic(webViewObject).loadRequest(Dynamic(navigationAction).request)
        }
        return nil
    }
    
    // MARK: ScriptMessageHandler
    public func userContentController(_ userContentController: Any, didReceive message: Any) {
        if _fastPath(Dynamic(message).name == "logHandler") {
            print("LOG: \(Dynamic(message).body.asString!)")
        }
    }
}
