//
//  TabsListView.swift
//  WatchBrowser
//
//  Created by memz233 on 10/27/24.
//

import OSLog
import SwiftUI
import DarockKit

@available(watchOS 10.0, *)
struct TabsListView<StartPage>: View where StartPage: View {
    var startPage: (@escaping (NewWebTabConfiguration) -> Void) -> StartPage
    @AppStorage("WebViewLayout") var webViewLayout = "MaximumViewport"
    @State var tabs = [WebViewTab]()
    @State var selectedTab: WebViewTab?
    @State var currentColumn = NavigationSplitViewColumn.sidebar
    @State var isAppSettingsPresented = false
    var body: some View {
        NavigationSplitView(preferredCompactColumn: $currentColumn, sidebar: {
            NavigationStack {
                List(selection: $selectedTab) {
                    ForEach(tabs, id: \.id) { tab in
                        TabLink(for: tab)
                    }
                    .onDelete { index in
                        for i in index {
                            tabs[i].webView?.stopLoading()
                        }
                        tabs.remove(atOffsets: index)
                    }
                    .onMove { source, destination in
                        tabs.move(fromOffsets: source, toOffset: destination)
                    }
                }
                .listStyle(.plain)
                .navigationTitle("\(tabs.count) 个标签页")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $isAppSettingsPresented, destination: { SettingsView() })
                .modifier(UserDefinedBackground())
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            isAppSettingsPresented = true
                        }, label: {
                            Image(systemName: "gear")
                        })
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button(action: {
                            tabs.append(.init(metadata: .init(url: nil)))
                            selectedTab = tabs.last
                        }, label: {
                            Image(systemName: "plus")
                        })
                        Spacer()
                    }
                }
            }
        }, detail: {
            if let selectedTab {
                if let webView = selectedTab.webView {
                    AdvancedWebViewController.shared.swiftWebView(from: webView, inside: {
                        if let index = tabs.firstIndex(where: { $0.id == selectedTab.id }) {
                            $tabs[index]
                        } else {
                            nil
                        }
                    }()) {
                        if let index = tabs.firstIndex(where: { $0.id == selectedTab.id }) {
                            tabs[index].shouldLoad = nil
                            if tabs[index].metadata == nil, let url = webView.url {
                                tabs[index].metadata = .init(url: url)
                            }
                            // Take snapshot
                            let snapshotConfiguration = WKSnapshotConfiguration()
                            webView.takeSnapshot(with: snapshotConfiguration) { image, _ in
                                if let image {
                                    do {
                                        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/tmp/TabSnapshots") {
                                            try FileManager.default.createDirectory(
                                                atPath: NSHomeDirectory() + "/tmp/TabSnapshots",
                                                withIntermediateDirectories: false
                                            )
                                        }
                                        let snapshotFilePath = selectedTab.metadata?.snapshotPath ?? "/tmp/TabSnapshots/\(UUID().uuidString).drkdatas"
                                        try image.pngData()?.write(to: URL(filePath: NSHomeDirectory() + snapshotFilePath))
                                        tabs[index].metadata?.snapshotPath = snapshotFilePath
                                    } catch {
                                        os_log(.error, "\(error)")
                                    }
                                }
                            }
                            // Update other metadata
                            if let url = webView.url {
                                tabs[index].metadata?.url = url
                            }
                            tabs[index].metadata?.title = webView.title
                        }
                        // Stop Loading
                        if webView.isLoading {
                            webView.stopLoading()
                        }
                        self.selectedTab = nil
                    }
                    .ignoresSafeArea()
                    .navigationBarBackButtonHidden()
                    .navigationBarHidden(true)
                    .toolbar(.hidden, for: .navigationBar)
                } else {
                    NavigationStack {
                        startPage { configuration in
                            if let url = URL(string: configuration.url), let index = tabs.firstIndex(where: { $0.id == selectedTab.id }) {
                                if !configuration.isWebArchive {
                                    tabs[index].webView = AdvancedWebViewController.shared.newWebView(url)
                                } else {
                                    tabs[index].webView = AdvancedWebViewController.shared.newWebView(nil, archiveURL: url)
                                }
                                tabs[index].metadata = .init(url: url, title: configuration.title, isWebArchive: configuration.isWebArchive)
                                self.selectedTab = tabs[index]
                            }
                        }
                    }
                }
            } else {
                EmptyView()
                    .modifier(UserDefinedBackground())
            }
        })
        .onAppear {
            if tabs.isEmpty {
                do {
                    if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/Tabs") {
                        try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/Tabs", withIntermediateDirectories: false)
                    }
                    if let jsonStr = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/Tabs/Tabs.drkdatat", encoding: .utf8),
                       let metadatas = getJsonData([WebViewTab.Metadata].self, from: jsonStr) {
                        for metadata in metadatas {
                            tabs.append(.init(metadata: metadata))
                        }
                    }
                } catch {
                    globalErrorHandler(error)
                }
                if tabs.isEmpty {
                    tabs.append(.init(metadata: .init(url: nil)))
                } else {
                    if let recoverIndex = UserDefaults.standard.object(forKey: "LastPresentingTabIndex") as? Int,
                       recoverIndex >= 0 && recoverIndex < tabs.count {
                        selectedTab = tabs[recoverIndex]
                    }
                }
            }
        }
        .onChange(of: tabs) { _ in
            if let jsonStr = jsonString(from: tabs.map { $0.metadata }) {
                if getJsonData([WebViewTab.Metadata].self, from: jsonStr) != nil {
                    try? jsonStr.write(toFile: NSHomeDirectory() + "/Documents/Tabs/Tabs.drkdatat", atomically: true, encoding: .utf8)
                }
            }
        }
        .onChange(of: selectedTab) { _ in
            if let tab = selectedTab, let index = tabs.firstIndex(where: { $0.id == tab.id }) {
                UserDefaults.standard.set(index, forKey: "LastPresentingTabIndex")
            } else {
                UserDefaults.standard.removeObject(forKey: "LastPresentingTabIndex")
            }
        }
    }
}
@available(watchOS 10.0, *)
private struct TabLink: View {
    var tab: WebViewTab
    @ObservedObject private var imageLoader: ImageLoader
    
    init(for tab: WebViewTab) {
        self.tab = tab
        imageLoader = ImageLoader(filePath: NSHomeDirectory() + (tab.metadata?.snapshotPath ?? ""))
    }
    
    var body: some View {
        NavigationLink(value: tab, label: {
            ZStack {
                if let image = imageLoader.image {
                    Image(uiImage: image)
                        .resizable()
                        .cornerRadius(10)
                        .scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                }
                VStack {
                    Spacer()
                    Text(tab.metadata?.title ?? tab.metadata?.url?.absoluteString ?? "起始页")
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Material.ultraThin)
                                .blur(radius: 5)
                        }
                }
                .centerAligned()
            }
        })
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

struct WebViewTab: Identifiable, Hashable {
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(metadata)
    }
    
    static func == (lhs: WebViewTab, rhs: WebViewTab) -> Bool {
        lhs.metadata == rhs.metadata && lhs.webView === rhs.webView
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

struct NewWebTabConfiguration {
    var url: String
    var title: String?
    var isWebArchive: Bool = false
}

// MARK: Webpage snapshot auto update
private class FileMonitor {
    private let fileDescriptor: CInt
    private let source: DispatchSourceFileSystemObject
    
    init?(path: String, onChange: @escaping () -> Void) {
        guard let path = path.cString(using: .utf8) else {
            return nil
        }
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            return nil
        }
        
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: .main)
        source.setEventHandler(handler: onChange)
        source.setCancelHandler {
            close(self.fileDescriptor)
        }
        source.resume()
    }
    
    deinit {
        source.cancel()
    }
}
private class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var fileMonitor: FileMonitor?
    
    init(filePath: String) {
        loadImage(from: filePath)
        fileMonitor = FileMonitor(path: filePath) { [weak self] in
            DispatchQueue.main.async {
                self?.loadImage(from: filePath)
            }
        }
    }
    
    private func loadImage(from filePath: String) {
        if let uiImage = UIImage(contentsOfFile: filePath) {
            image = uiImage
        }
    }
}
