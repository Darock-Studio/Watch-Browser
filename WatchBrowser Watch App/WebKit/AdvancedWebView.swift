//
//  AdvancedWebView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/20.
//

import UIKit
import SwiftUI
import Dynamic
import Combine
import SwiftSoup
import DarockKit
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
    
    var webViewHolder = Dynamic.UIView()
    var vc = Dynamic.UIViewController()
    var loadProgressView = Dynamic.UIProgressView()
    
    var isOverrideDesktopWeb = false {
        didSet {
            if isOverrideDesktopWeb {
                webViewObject?.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 DarockBrowser/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)"
                webViewObject?.reload()
            } else {
                webViewObject?.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1 DarockBrowser/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).\(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)"
                webViewObject?.reload()
            }
        }
    }
    
    @AppStorage("AllowCookies") var allowCookies = true
    @AppStorage("RequestDesktopWeb") var requestDesktopWeb = false
    @AppStorage("UseBackforwardGesture") var useBackforwardGesture = true
    @AppStorage("KeepDigitalTime") var keepDigitalTime = false
    @AppStorage("ShowFastExitButton") var showFastExitButton = false
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("isUseOldWebView") var isUseOldWebView = false
    @AppStorage("CustomUserAgent") var customUserAgent = ""
    @AppStorage("DTIsAllowWebInspector") var isAllowWebInspector = false
    @AppStorage("IsWebMinFontSizeStricted") var isWebMinFontSizeStricted = false
    @AppStorage("WebMinFontSize") var webMinFontSize = 10.0
    @AppStorage("IsShowFraudulentWebsiteWarning") var isShowFraudulentWebsiteWarning = true
    @AppStorage("WKJavaScriptEnabled") var isJavaScriptEnabled = true
    @AppStorage("ABIsReduceBrightness") var isReduceBrightness = false
    @AppStorage("ABReduceBrightnessLevel") var reduceBrightnessLevel = 0.2
    @AppStorage("LBIsAutoEnterReader") var isAutoEnterReader = true
    
    var currentUrl: String {
        if let url = Dynamic(webViewObject).URL.asObject {
            _onFastPath()
            return (url as! NSURL).absoluteString!
        } else {
            return ""
        }
    }
    var isVideoChecking = false
    
    override init() {
        super.init()
        dlopen("/System/Library/Frameworks/SafariServices.framework/SafariServices", RTLD_NOW)
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
            return webViewObject
        }
        
        let url = URL(string: iurl) ?? archiveUrl!

        if _slowPath((isUseOldWebView && overrideOldWebView != .alwaysAdvanced) || overrideOldWebView == .alwaysLegacy) {
            // rdar://FB268002071845
            if _fastPath(presentController) {
                let legacyConfiguration = Dynamic.SFSafariViewControllerConfiguration()
                legacyConfiguration.entersReaderIfAvailable = isAutoEnterReader
                let legacyViewController = Dynamic.SFSafariViewController.initWithURL(url, configuration: legacyConfiguration)
                legacyViewController.delegate = SafariViewDelegate.shared
                safePresent(legacyViewController)
                
                if _fastPath(isHistoryRecording) {
                    recordHistory(iurl, webSearch: webSearch)
                }
            }
            
            return Dynamic.WKWebView()
        }
        
        let moreButton = makeUIButton(title: .image(UIImage(systemName: "ellipsis.circle")!),
                                      frame: CGRect(x: 10, y: 10, width: 30, height: 30),
                                      selector: "menuButtonClicked",
                                      accessibilityIdentifier: "WebMenuButton")
        
        let sb = WKInterfaceDevice.current().screenBounds
        
        let wkWebView = WKWebView()
        wkWebView.frame = sb
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
        wkWebView.configuration.preferences.javaScriptEnabled = isJavaScriptEnabled
        wkWebView.configuration.preferences.isFraudulentWebsiteWarningEnabled = isShowFraudulentWebsiteWarning
        
        // Load Progress Bar
        loadProgressView.frame = CGRect(x: 0, y: 0, width: sb.width, height: 20)
        loadProgressView.progressTintColor = UIColor.blue
        
        webViewHolder = Dynamic.UIView()
        webViewHolder.addSubview(wkWebView)
        
        if _slowPath(keepDigitalTime) {
            let timeBackground = Dynamic.UIView()
            timeBackground.setBackgroundColor(UIColor.black)
            timeBackground.setFrame(CGRect(x: sb.width - 50, y: 0, width: 70, height: 30))
            webViewHolder.addSubview(timeBackground)
        }
        
        if _slowPath(showFastExitButton) {
            let fastExitButton = makeUIButton(title: .image(UIImage(systemName: "escape")!),
                                              frame: CGRect(x: 40, y: 10, width: 30, height: 30),
                                              tintColor: .red,
                                              selector: "DismissWebView")
            webViewHolder.addSubview(fastExitButton)
        }
        webViewHolder.addSubview(moreButton)
        webViewHolder.addSubview(loadProgressView)
        
        if isReduceBrightness {
            let reduceBrightnessView = Dynamic.UIView()
            reduceBrightnessView.backgroundColor = UIColor.black
            reduceBrightnessView.alpha = reduceBrightnessLevel
            reduceBrightnessView.frame = sb
            reduceBrightnessView.isUserInteractionEnabled = false
            webViewHolder.addSubview(reduceBrightnessView)
        }
        
        vc = Dynamic(_makeUIHostingController(AnyView(SwiftWebView(webView: webViewHolder.asObject!))))

        if _fastPath(presentController) {
            safePresent(vc)
        }
        webViewParentController = vc.asObject!
        
        if let archiveUrl {
            do {
                wkWebView.load(try Data(contentsOf: archiveUrl), mimeType: loadMimeType, characterEncodingName: "utf-8", baseURL: archiveUrl)
            } catch {
                globalErrorHandler(error)
            }
        } else {
            _onFastPath()
            wkWebView.load(URLRequest(url: url))
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            if _slowPath(wkWebView.isLoading) {
                self.loadProgressView.setProgress(Float(wkWebView.estimatedProgress), animated: true)
            }
        }
        
        webViewObject = wkWebView
        wkWebView.navigationDelegate = WebViewNavigationDelegate.shared
        wkWebView.uiDelegate = WebViewUIDelegate.shared
        
        if #available(watchOS 9.4, *) {
            if _slowPath(isAllowWebInspector) {
                wkWebView.isInspectable = true
            }
        }
        
        return wkWebView
    }
    func recover(from ref: TabWebKitReference) {
        webViewHolder = ref.webViewHolder
        vc = ref.vc
        loadProgressView = ref.loadProgressView
        webViewObject = ref.webViewObject
        webViewParentController = ref.webViewParentController
        safePresent(vc)
    }
    func storeTab(in allTabs: [String], at index: Int? = nil) {
        let recoverReference = TabWebKitReference(webViewHolder: webViewHolder,
                                                  vc: vc,
                                                  loadProgressView: loadProgressView,
                                                  webViewObject: webViewObject,
                                                  webViewParentController: webViewParentController)
        var updateUrl = currentUrl
        if let index {
            updateUrl = allTabs[index]
        }
        tabCurrentReferences.updateValue(recoverReference, forKey: updateUrl)
        var tabsCopy = allTabs
        if let index {
            tabsCopy[index] = updateUrl
        } else {
            tabsCopy.insert(updateUrl, at: 0)
        }
        UserDefaults.standard.set(tabsCopy, forKey: "CurrentTabs")
        currentTabIndex = nil
    }
    
    @_effects(readonly)
    func makeUIButton(
        title: TextOrImage,
        frame: CGRect,
        backgroundColor: Color? = nil,
        tintColor: Color? = nil,
        cornerRadius: CGFloat = 8,
        selector: String? = nil,
        accessibilityIdentifier: String? = nil
    ) -> Dynamic {
        var resultButton = Dynamic.UIButton.buttonWithType(1)
        switch title {
        case .text(let text):
            resultButton.setTitle(text, forState: 0)
        case .image(let image):
            resultButton.setImage(image, forState: 0)
        }
        resultButton.setFrame(frame)
        if let backgroundColor {
            resultButton.setBackgroundColor(UIColor(backgroundColor))
        }
        if let tintColor {
            resultButton.setTintColor(UIColor(tintColor))
        }
        resultButton.layer.cornerRadius = cornerRadius
        if let selector {
            resultButton = Dynamic(WebExtension.getBindedButton(withSelector: selector, button: resultButton.asObject!))
        }
        if let accessibilityIdentifier {
            resultButton.accessibilityIdentifier = accessibilityIdentifier
        }
        return resultButton
    }
    func dismissController(_ controller: Dynamic, animated: Bool = true) {
        controller.dismissModalViewController(animated: animated)
    }
    func dismissControllersOnWebView(animated: Bool = true) {
        vc.dismissViewControllerAnimated(animated, completion: nil)
    }
    
    enum TextOrImage {
        case text(String)
        case image(UIImage)
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
    func dismissWebView() {
        AdvancedWebViewController.dismissWebViewPublisher.send()
    }
}

@_effects(readnone)
func getMiddleRect(y: CGFloat, height: CGFloat) -> CGRect {
    let sb = WKInterfaceDevice.current().screenBounds
    return CGRect(x: (sb.width - (sb.width - 40)) / 2, y: y, width: sb.width - 40, height: height)
}
