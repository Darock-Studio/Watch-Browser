//
//  AdvancedWebView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/20.
//

import UIKit
import SwiftUI
import Combine
import Network
import SwiftSoup
import DarockFoundation
import AuthenticationServices

var videoLinkLists = [String]()
var imageLinkLists = [String]()
var imageAltTextLists = [String]()
var audioLinkLists = [String]()
var bookLinkLists = [String]()

@objc
final class AdvancedWebViewController: NSObject {
    @objc public static let shared = AdvancedWebViewController()
    
    // FIXME: Less publisher for better future
    static let presentBrowsingMenuPublisher = PassthroughSubject<Void, Never>()
    static let dismissWebViewPublisher = PassthroughSubject<Void, Never>()
    
    var currentTabIndex: Int?
    
    var vc = NSObject()
    
    @AppStorage("AllowCookies") var allowCookies = true
    @AppStorage("WebViewLayout") var webViewLayout = "MaximumViewport"
    @AppStorage("RequestDesktopWeb") var requestDesktopWeb = false
    @AppStorage("UseBackforwardGesture") var useBackforwardGesture = true
    @AppStorage("ForceApplyDarkMode") var forceApplyDarkMode = false
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("isUseOldWebView") var isUseOldWebView = false
    @AppStorage("CustomUserAgent") var customUserAgent = ""
    @AppStorage("DTIsAllowWebInspector") var isAllowWebInspector = false
    @AppStorage("IsWebMinFontSizeStricted") var isWebMinFontSizeStricted = false
    @AppStorage("WebMinFontSize") var webMinFontSize = 10.0
    @AppStorage("IsShowFraudulentWebsiteWarning") var isShowFraudulentWebsiteWarning = true
    @AppStorage("WKJavaScriptEnabled") var isJavaScriptEnabled = true
    @AppStorage("LBIsAutoEnterReader") var isAutoEnterReader = true
    
    func newWebView(_ url: URL?, archiveURL: URL? = nil, loadMimeType: String = "application/x-webarchive") -> WKWebView {
        let wkWebView = WKWebView(frame: WKInterfaceDevice.current().screenBounds)
        if _fastPath(customUserAgent.isEmpty) {
            if _slowPath(requestDesktopWeb) {
                wkWebView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 DarockBrowser/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)"
            } else {
                wkWebView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1 DarockBrowser/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)"
            }
        } else {
            wkWebView.customUserAgent = customUserAgent
        }
        wkWebView.allowsBackForwardNavigationGestures = useBackforwardGesture
        if #available(watchOS 10.0, *) {
            wkWebView.configuration.websiteDataStore.httpCookieStore.setCookiePolicy(allowCookies ? .allow : .disallow)
        }
        if _slowPath(isWebMinFontSizeStricted) {
            wkWebView.configuration.preferences.minimumFontSize = CGFloat(webMinFontSize)
        }
        if forceApplyDarkMode {
            wkWebView.underPageBackgroundColor = UIColor(Color(hex: 0x121212))
        }
        wkWebView.configuration.preferences.javaScriptEnabled = isJavaScriptEnabled
        wkWebView.configuration.preferences.isFraudulentWebsiteWarningEnabled = isShowFraudulentWebsiteWarning
        
        if let archiveURL {
            do {
                wkWebView.load(try Data(contentsOf: archiveURL), mimeType: loadMimeType, characterEncodingName: "utf-8", baseURL: archiveURL)
            } catch {
                globalErrorHandler(error)
            }
        } else if let url {
            wkWebView.load(URLRequest(url: url))
        }
        
        wkWebView.navigationDelegate = WebViewNavigationDelegate.shared
        wkWebView.uiDelegate = WebViewUIDelegate.shared
        
        // Disable WebGL to prevent web view from crashing
        let _webGLDisableScript = """
        (function() {
            var getContext = HTMLCanvasElement.prototype.getContext;
            HTMLCanvasElement.prototype.getContext = function(type) {
                if (type === 'webgl2' || type === 'experimental-webgl') {
                    return null;
                }
                return getContext.apply(this, arguments);
            };
        })();
        """
        let webGLDisableScript = WKUserScript(source: _webGLDisableScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        wkWebView.configuration.userContentController.addUserScript(webGLDisableScript)
        
        if #available(watchOS 9.4, *) {
            if _slowPath(isAllowWebInspector) {
                wkWebView.isInspectable = true
            }
        }
        
        return wkWebView
    }
    
    func swiftWebView(from wkWebView: WKWebView, inside tab: Binding<WebViewTab>? = nil, customDismissAction: (() -> Void)? = nil) -> AnyView {
        let vc = _makeUIHostingController(AnyView(SwiftWebView(webView: wkWebView, insideTab: tab, customDismissAction: customDismissAction)))
        return AnyView(GeneralUIViewControllerRepresenting(viewController: vc))
    }
    
    /// 显示 WebView 视图
    /// - Parameters:
    ///   - iurl: 网页 URL
    ///   - archiveUrl: 网页归档 URL
    ///   - presentController: 是否将 WebView 推送到屏幕
    ///   - loadMimeType: 载入内容的 Mime Type
    ///   - overrideOldWebView: 覆盖使用旧版引擎设置
    /// - Returns: WebView Object
    @discardableResult
    func present(_ iurl: String = "",
                 archiveUrl: URL? = nil,
                 presentController: Bool = true,
                 loadMimeType: String = "application/x-webarchive",
                 overrideOldWebView: OverrideLegacyViewOptions = .default) -> WKWebView? {
        if iurl.isEmpty && archiveUrl == nil {
            safePresent(self.vc)
            return WKWebView()
        }
        
        let url = URL(string: iurl) ?? archiveUrl!

        if _slowPath((isUseOldWebView && overrideOldWebView != .alwaysAdvanced) || overrideOldWebView == .alwaysLegacy && archiveUrl == nil) {
            // rdar://FB268002071845
            if _fastPath(presentController) {
                let legacyConfiguration = SFSafariViewController.Configuration()
                legacyConfiguration.entersReaderIfAvailable = isAutoEnterReader
                let legacyViewController = SFSafariViewController(url: url, configuration: legacyConfiguration)
                legacyViewController.delegate = SafariViewDelegate.shared
                safePresent(legacyViewController)
                
                if _fastPath(isHistoryRecording) {
                    recordHistory(iurl, webSearch: webSearch)
                }
            }
            
            return WKWebView()
        }
        
        let wkWebView = newWebView(URL(string: iurl), archiveURL: archiveUrl, loadMimeType: loadMimeType)
        
        vc = _makeUIHostingController(AnyView(SwiftWebView(webView: wkWebView)))

        if _fastPath(presentController) {
            safePresent(vc)
        }
        
        return wkWebView
    }
    
    func dismissController(_ controller: NSObject, animated: Bool = true) {
        controller.perform(NSSelectorFromString("dismissModalViewControllerAnimated:"), with: animated)
    }
    func dismissControllersOnWebView(animated: Bool = true) {
        vc.perform(NSSelectorFromString("dismissViewControllerAnimated:completion:"), with: animated, with: nil)
    }
    
    enum OverrideLegacyViewOptions {
        case `default`
        case alwaysLegacy
        case alwaysAdvanced
    }
    
    @objc
    func presentBrowsingMenu() {
        AdvancedWebViewController.presentBrowsingMenuPublisher.send()
    }
    @objc
    func dismissWebView() {
        AdvancedWebViewController.dismissWebViewPublisher.send()
    }
}

@_effects(readnone)
func getMiddleRect(y: CGFloat, height: CGFloat) -> CGRect {
    let sb = WKInterfaceDevice.current().screenBounds
    return CGRect(x: (sb.width - (sb.width - 40)) / 2, y: y, width: sb.width - 40, height: height)
}

struct GeneralUIViewControllerRepresenting: _UIViewControllerRepresentable {
    var viewController: NSObject
    func makeUIViewController(context: Context) -> some NSObject {
        viewController
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
