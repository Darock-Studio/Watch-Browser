//
//  TabsListView.swift
//  WatchBrowser
//
//  Created by memz233 on 10/27/24.
//

import OSLog
import Combine
import SwiftUI
import DarockUI
import RadarKitCore
import DarockFoundation

let createNewTabSubject = PassthroughSubject<NewWebTabConfiguration, Never>()

@available(watchOS 10.0, *)
struct TabsListView<StartPage>: View where StartPage: View {
    var startPage: (@escaping (NewWebTabConfiguration) -> Void) -> StartPage
    @AppStorage("WebViewLayout") var webViewLayout = "MaximumViewport"
    @AppStorage("PCReopenPreviousWebTab") var reopenPreviousWebTab = true
    @AppStorage("ShouldShowRatingRequest") var shouldShowRatingRequest = false
    @AppStorage("MainPageShowCount") var mainPageShowCount = 0
    @AppStorage("IsShowJoinGroup2") var isShowJoinGroup = true
    @AppStorage("IsShowClusterAd") var isShowClusterAd = true
    @AppStorage("IsBetaJoinAvailable") var isBetaJoinAvailable = false
    @State var tabs = [WebViewTab]()
    @State var selectedTab: TabMainPageSeletion?
    @State var createButtonVisibilityResetTimer: Timer?
    @State var createButtonLongPressTimer: Timer?
    @State var isCreateButtonVisible = true
    @State var isCreateButtonPressed = false
    @State var wristLocation = WKInterfaceDevice.current().wristLocation
    @State var newFeedbackCount = 0
    @State var isNewVerAvailable = false
    @State var isNewYearCelebrationPresented = false
    @State var isTabActionsPresented = false
    @State var tabActionsRecentClosedTabs = [WebViewTab.Metadata]()
    @State var tabActionsIsClearAlertPresented = false
    var body: some View {
        NavigationSplitView(sidebar: {
            NavigationStack {
                ZStack {
                    List(selection: $selectedTab) {
                        Group {
                            if isTodayNewYear() {
                                Button(action: {
                                    isNewYearCelebrationPresented = true
                                }, label: {
                                    HStack {
                                        Image(systemName: "fireworks")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.red, .yellow)
                                        Text("新年快乐！")
                                    }
                                })
                            }
                            Section {
                                ForEach(tabs, id: \.id) { tab in
                                    TabLink(for: tab)
                                }
                                .onDelete { index in
                                    for i in index {
                                        tabs[i].webView?.stopLoading()
                                        guard tabs[i].metadata?.url != nil else { continue }
                                        if let currentString = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/Tabs/RecentClosedTabs.drkdatar") {
                                            if let data = getJsonData([WebViewTab.Metadata].self, from: currentString) {
                                                if let jsonStr = jsonString(from: [tabs[i].metadata] + data) {
                                                    try? jsonStr.write(
                                                        toFile: NSHomeDirectory() + "/Documents/Tabs/RecentClosedTabs.drkdatar",
                                                        atomically: true,
                                                        encoding: .utf8
                                                    )
                                                }
                                            }
                                        } else if let jsonStr = jsonString(from: [tabs[i].metadata]) {
                                            try? jsonStr.write(
                                                toFile: NSHomeDirectory() + "/Documents/Tabs/RecentClosedTabs.drkdatar", atomically: true, encoding: .utf8
                                            )
                                        }
                                    }
                                    tabs.remove(atOffsets: index)
                                    if tabs.isEmpty {
                                        tabs.append(.init(metadata: .init(url: nil)))
                                        selectedTab = .webPage(tabs.last!)
                                    }
                                }
                                .onMove { source, destination in
                                    tabs.move(fromOffsets: source, toOffset: destination)
                                }
                            }
                            Section {
                                NavigationLink(value: TabMainPageSeletion.customView(.feedbackAssistant)) {
                                    VStack {
                                        HStack {
                                            ZStack(alignment: .topTrailing) {
                                                Image(systemName: "exclamationmark.bubble")
                                                    .font(.system(size: 20))
                                                if newFeedbackCount > 0 {
                                                    Text("\(newFeedbackCount)")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .background(Circle().fill(Color.red).frame(width: 15, height: 15).opacity(1.0))
                                                        .offset(x: 3, y: -5)
                                                        .truncationMode(.head)
                                                }
                                            }
                                            Text("反馈助理")
                                        }
                                        if isNewVerAvailable {
                                            Text("“反馈助理”不可用，因为暗礁浏览器有更新可用")
                                                .font(.system(size: 12))
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                }
                                .disabled(isNewVerAvailable)
                                NavigationLink(value: TabMainPageSeletion.customView(.tips)) {
                                    Label("提示", privateSystemImage: "tips")
                                }
                            }
                            Section {
                                if shouldShowRatingRequest {
                                    Button(action: {
                                        shouldShowRatingRequest = false
                                    }, label: {
                                        VStack(alignment: .leading) {
                                            Text("喜欢暗礁浏览器？前往 iPhone 上的 App Store 为我们评分！")
                                            Text("轻触以隐藏")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.gray)
                                        }
                                    })
                                }
                                if isBetaJoinAvailable && !isAppBetaBuild {
                                    NavigationLink(value: TabMainPageSeletion.customView(.betaTesting)) {
                                        Label("参与 Beta 测试", systemImage: "person.badge.clock")
                                            .centerAligned()
                                    }
                                }
                                if #available(watchOS 10, *), isShowClusterAd {
                                    NavigationLink(value: TabMainPageSeletion.customView(.clusterAd)) {
                                        Label("推荐 - 暗礁文件", systemImage: "sparkles")
                                            .centerAligned()
                                    }
                                }
                                if isShowJoinGroup {
                                    NavigationLink(value: TabMainPageSeletion.customView(.joinGroup)) {
                                        Label("欢迎加入群聊", systemImage: "bubble.left.and.bubble.right")
                                            .centerAligned()
                                    }
                                }
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                NavigationLink(value: TabMainPageSeletion.customView(.settings)) {
                                    Image(systemName: "gear")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .wrapIf({ if #available(watchOS 11.0, *) { true } else { false } }()) { content in
                        if #available(watchOS 11.0, *) {
                            content
                                .onScrollPhaseChange { _, after in
                                    if after.isScrolling {
                                        createButtonVisibilityResetTimer?.invalidate()
                                        isCreateButtonVisible = false
                                        isCreateButtonPressed = false
                                    } else {
                                        createButtonVisibilityResetTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                                            isCreateButtonVisible = true
                                        }
                                    }
                                }
                        }
                    }
                    if isCreateButtonPressed {
                        Color.black
                            .opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                isCreateButtonPressed = false
                            }
                    }
                }
                .navigationTitle("\(tabs.count) 个标签页")
                .navigationBarTitleDisplayMode(.inline)
                .modifier(UserDefinedBackground())
                .sheet(isPresented: $isNewYearCelebrationPresented, content: { CelebrationFireworksView() })
                .sheet(isPresented: $isTabActionsPresented, content: { tabActionsBody })
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        ZStack {
                            HStack {
                                if wristLocation == .left {
                                    Spacer()
                                }
                                if isCreateButtonPressed {
                                    ZStack(alignment: wristLocation == .left ? .leading : .trailing) {
                                        Capsule()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 100, height: 32)
                                        NavigationLink(destination: {
                                            MediaMainView()
                                                .onAppear {
                                                    isCreateButtonPressed = false
                                                }
                                        }, label: {
                                            Image(systemName: "movieclapper")
                                                .font(.system(size: 13))
                                        })
                                        .buttonStyle(.plain)
                                        .padding(.horizontal, 8)
                                    }
                                }
                                if wristLocation == .right {
                                    Spacer()
                                }
                            }
                            HStack {
                                if wristLocation == .left {
                                    Spacer()
                                }
                                Button(action: {
                                    if !isTabActionsPresented {
                                        if !isCreateButtonPressed {
                                            isCreateButtonPressed = true
                                        } else {
                                            tabs.append(.init(metadata: .init(url: nil)))
                                            selectedTab = .webPage(tabs.last!)
                                            isCreateButtonPressed = false
                                        }
                                    }
                                }, label: {
                                    Image(systemName: isCreateButtonPressed ? "macwindow.badge.plus" : "plus")
                                })
                                ._onButtonGesture(pressing: { isPressing in
                                    createButtonLongPressTimer?.invalidate()
                                    if isPressing && !isCreateButtonPressed {
                                        createButtonLongPressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
                                            isTabActionsPresented = true
                                        })
                                    }
                                }, perform: {})
                                if wristLocation == .right {
                                    Spacer()
                                }
                            }
                            .opacity(isCreateButtonVisible ? 1 : 0)
                            .animation(.easeIn(duration: 0.2), value: isCreateButtonVisible)
                        }
                    }
                }
                .animation(.easeOut, value: isCreateButtonPressed)
            }
            .onAppear {
                if !ProcessInfo.processInfo.isLowPowerModeEnabled {
                    let feedbackIds = UserDefaults.standard.stringArray(forKey: "RadarFBIDs") ?? [String]()
                    newFeedbackCount = 0
                    Task {
                        let manager = RKCFeedbackManager(projectName: "Darock Browser")
                        for id in feedbackIds {
                            if let feedback = await manager.getFeedback(byId: id) {
                                let formatter = RKCFileFormatter(for: feedback)
                                let repCount = formatter.replies().filter { !$0.isInternalHidden }.count
                                let lastViewCount = UserDefaults.standard.integer(forKey: "RadarFB\(id)ReplyCount")
                                if repCount > lastViewCount {
                                    newFeedbackCount++
                                }
                            }
                        }
                    }
                }
                requestString("https://fapi.darock.top:65535/drkbs/newver".compatibleUrlEncoded()) { respStr, isSuccess in
                    if isSuccess {
                        let spdVer = respStr.apiFixed().split(separator: ".")
                        if spdVer.count == 3 {
                            if let x = Int(spdVer[0]), let y = Int(spdVer[1]), let z = Int(spdVer[2]) {
                                let currVerSpd = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).split(separator: ".")
                                if currVerSpd.count == 3 {
                                    if let cx = Int(currVerSpd[0]), let cy = Int(currVerSpd[1]), let cz = Int(currVerSpd[2]) {
                                        if x > cx {
                                            isNewVerAvailable = true
                                        } else if x == cx && y > cy {
                                            isNewVerAvailable = true
                                        } else if x == cx && y == cy && z > cz {
                                            isNewVerAvailable = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                requestString("https://fapi.darock.top:65535/tf/get/DarockBrowser") { respStr, isSuccess in
                    if isSuccess {
                        isBetaJoinAvailable = respStr.apiFixed() != "[None]"
                    }
                }
                mainPageShowCount++
                if mainPageShowCount == 10 {
                    shouldShowRatingRequest = true
                }
            }
        }, detail: {
            if case let .webPage(selectedTab) = selectedTab {
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
                                        if _fastPath(index < tabs.count) {
                                            tabs[index].metadata?.snapshotPath = snapshotFilePath
                                        }
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
                            loadTab(from: configuration, replacing: selectedTab)
                        }
                    }
                }
            } else if case let .customView(view) = selectedTab {
                mainCustomView(from: view)
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
                       let metadatas = getJsonData([WebViewTab.Metadata?].self, from: jsonStr) {
                        for metadata in metadatas {
                            if let metadata {
                                tabs.append(.init(metadata: metadata))
                            } else {
                                tabs.append(.init(metadata: .init(url: nil)))
                            }
                        }
                    }
                } catch {
                    globalErrorHandler(error)
                }
                if tabs.isEmpty {
                    tabs.append(.init(metadata: .init(url: nil)))
                } else if reopenPreviousWebTab {
                    if let recoverIndex = UserDefaults.standard.object(forKey: "LastPresentingTabIndex") as? Int,
                       recoverIndex >= 0 && recoverIndex < tabs.count {
                        selectedTab = .webPage(tabs[recoverIndex])
                    }
                }
            }
        }
        .onChange(of: tabs) { _ in
            if let jsonStr = jsonString(from: tabs.map { $0.metadata }) {
                if getJsonData([WebViewTab.Metadata?].self, from: jsonStr) != nil {
                    try? jsonStr.write(toFile: NSHomeDirectory() + "/Documents/Tabs/Tabs.drkdatat", atomically: true, encoding: .utf8)
                } else {
                    os_log(.fault, "Failed to store tabs while tabs array changing. Full data below:\n\(tabs.map { $0.metadata })")
                }
            }
        }
        .onChange(of: selectedTab) { _ in
            if case let .webPage(tab) = selectedTab, let index = tabs.firstIndex(where: { $0.id == tab.id }) {
                UserDefaults.standard.set(index, forKey: "LastPresentingTabIndex")
            } else {
                UserDefaults.standard.removeObject(forKey: "LastPresentingTabIndex")
            }
        }
        .onReceive(createNewTabSubject) { configuration in
            loadTab(from: configuration)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            if let url = userActivity.webpageURL, var openUrl = url.absoluteString.split(separator: "darock.top/darockbrowser/open/", maxSplits: 1)[from: 1] {
                if !openUrl.hasPrefix("http://") && !openUrl.hasPrefix("https://") {
                    openUrl = "http://" + openUrl
                }
                loadTab(from: .init(url: String(openUrl).urlEncoded()))
            }
        }
    }
    
    func loadTab(from configuration: NewWebTabConfiguration, replacing selectedTab: WebViewTab? = nil) {
        if let url = URL(string: configuration.url) {
            if let selectedTab, let index = tabs.firstIndex(where: { $0.id == selectedTab.id }) {
                if !configuration.isWebArchive {
                    tabs[index].webView = AdvancedWebViewController.shared.newWebView(url)
                } else {
                    tabs[index].webView = AdvancedWebViewController.shared.newWebView(nil, archiveURL: url)
                }
                tabs[index].metadata = .init(url: url, title: configuration.title, isWebArchive: configuration.isWebArchive)
                self.selectedTab = .webPage(tabs[index])
            } else {
                var newTab = WebViewTab(metadata: .init(url: url, title: configuration.title, isWebArchive: configuration.isWebArchive))
                if !configuration.isWebArchive {
                    newTab.webView = AdvancedWebViewController.shared.newWebView(url)
                } else {
                    newTab.webView = AdvancedWebViewController.shared.newWebView(nil, archiveURL: url)
                }
                tabs.append(newTab)
                if let tab = tabs.last {
                    self.selectedTab = .webPage(tab)
                } else {
                    self.selectedTab = nil
                }
            }
        }
    }
    
    @inlinable
    @ViewBuilder
    func mainCustomView(from hashableView: TabMainPageSeletion.HashableView) -> some View {
        NavigationStack {
            switch hashableView {
            case .settings:
                SettingsView()
            case .feedbackAssistant:
                FeedbackView()
            case .tips:
                TipsView()
            case .betaTesting:
                BetaJoinView()
            case .clusterAd:
                ClusterAdView()
            case .joinGroup:
                JoinGroupView()
            }
        }
    }
    
    var tabActionsBody: some View {
        NavigationStack {
            List {
                Section {
                    if !tabActionsRecentClosedTabs.isEmpty {
                        ForEach(0..<tabActionsRecentClosedTabs.count, id: \.self) { i in
                            if let url = tabActionsRecentClosedTabs[i].url {
                                Button(action: {
                                    loadTab(from: .init(url: url.absoluteString,
                                                        title: tabActionsRecentClosedTabs[i].title,
                                                        isWebArchive: tabActionsRecentClosedTabs[i].isWebArchive))
                                    isTabActionsPresented = false
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text(tabActionsRecentClosedTabs[i].title ?? url.absoluteString)
                                            .font(.caption)
                                            .lineLimit(2)
                                        if tabActionsRecentClosedTabs[i].title != nil {
                                            Text(url.absoluteString)
                                                .font(.footnote)
                                                .opacity(0.6)
                                        }
                                    }
                                })
                            }
                        }
                    }
                } header: {
                    Text("最近关闭")
                }
            }
            .navigationTitle("标签页")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive, action: {
                        tabActionsIsClearAlertPresented = true
                    }, label: {
                        Image(systemName: "clear")
                    })
                    .foregroundStyle(.red)
                }
            }
            .alert("关闭所有标签页？", isPresented: $tabActionsIsClearAlertPresented, actions: {
                Button(role: .destructive, action: {
                    tabs.removeAll()
                    isTabActionsPresented = false
                }, label: {
                    Text("删除")
                })
                Button(role: .cancel, action: {}, label: {
                    Text("取消")
                })
            }, message: {
                Text("此操作无法撤销。")
            })
        }
        .onAppear {
            if let _recentClosedTabsStr = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/Tabs/RecentClosedTabs.drkdatar"),
               let recentClosedTabs = getJsonData([WebViewTab.Metadata].self, from: _recentClosedTabsStr) {
                tabActionsRecentClosedTabs = recentClosedTabs
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
        NavigationLink(value: TabMainPageSeletion.webPage(tab), label: {
            ZStack {
                if let image = imageLoader.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 100)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.15))
                        if tab.metadata?.url == nil {
                            Image(systemName: "star.fill")
                                .font(.system(size: 28))
                                .padding(.vertical)
                        }
                    }
                }
                VStack {
                    Spacer()
                    Text(tab.metadata?.title ?? tab.metadata?.url?.absoluteString ?? String(localized: "起始页"))
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

private func isTodayNewYear() -> Bool {
    let today = Date.now
    let calendar = Calendar.current
    let components = calendar.dateComponents([.month, .day], from: today)
    if components.month == 1 && components.day == 1 {
        return true
    }
    if NSLocale.current.language.languageCode!.identifier == "zh" {
        let chineseCalendar = Calendar(identifier: .chinese)
        let components = chineseCalendar.dateComponents([.month, .day], from: today)
        return components.month == 1 && components.day == 1
    }
    return false
}
