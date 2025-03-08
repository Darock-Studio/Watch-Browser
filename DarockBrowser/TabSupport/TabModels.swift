//
//  TabModels.swift
//  DarockBrowser
//
//  Created by memz233 on 11/16/24.
//

import SwiftUI

struct WebViewTab: Identifiable {
    var id = UUID()
    
    var webView: WKWebView?
    var metadata: Metadata?
    var shouldLoad: LoadResource?
    
    init(metadata: Metadata) {
        if metadata.url == nil {
            return
        }
        self.metadata = metadata
        if !metadata.isWebArchive {
            if let url = metadata.url {
                self.shouldLoad = .web(url)
            }
            self.webView = AdvancedWebViewController.shared.newWebView(nil)
        } else {
            if let url = metadata.url {
                self.shouldLoad = .webArchive(url)
            }
            self.webView = AdvancedWebViewController.shared.newWebView(nil)
        }
    }
    
    struct Metadata: Codable, Hashable, Equatable {
        var url: URL?
        var title: String?
        var snapshotPath: String?
        var isWebArchive: Bool = false
        
        init(url: URL?, title: String? = nil, snapshotPath: String? = nil, isWebArchive: Bool = false) {
            self.url = url
            self.title = title
            self.snapshotPath = snapshotPath
            self.isWebArchive = isWebArchive
        }
        
        static func == (lhs: Metadata, rhs: Metadata) -> Bool {
            lhs.url == rhs.url && lhs.title == rhs.title && lhs.snapshotPath == rhs.snapshotPath && lhs.isWebArchive == rhs.isWebArchive
        }
    }
    
    enum LoadResource {
        case web(URL)
        case webArchive(URL)
    }
}
extension WebViewTab: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(metadata)
    }
    
    static func == (lhs: WebViewTab, rhs: WebViewTab) -> Bool {
        lhs.metadata == rhs.metadata && lhs.webView === rhs.webView
    }
}
extension WebViewTab: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(metadata: try container.decode(Metadata.self))
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(metadata)
    }
}

struct NewWebTabConfiguration {
    var url: String
    var title: String?
    var isWebArchive: Bool = false
}
extension NewWebTabConfiguration {
    init(url: URL, title: String?, isWebArchive: Bool = false) {
        self.url = url.absoluteString
        self.title = title
        self.isWebArchive = isWebArchive
    }
}

struct MediaTab: Identifiable {
    var id = UUID()
    
    
}

enum TabMainPageSeletion: Hashable {
    case webPage(WebViewTab)
    case customView(HashableView)
    
    enum HashableView: Hashable {
        case settings
        case feedbackAssistant
        case tips
        case betaTesting
        case clusterAd
        case joinGroup
    }
}
