//
//  TabsListView.swift
//  WatchBrowser
//
//  Created by memz233 on 10/27/24.
//

import OSLog
import Combine
import SwiftUI
import DarockFoundation

@available(watchOS 10.0, *)
struct TabsListView<StartPage>: View where StartPage: View {
    var startPage: (@escaping (NewWebTabConfiguration) -> Void) -> StartPage
    @AppStorage("WebViewLayout") var webViewLayout = "MaximumViewport"
    @AppStorage("ShouldShowRatingRequest") var shouldShowRatingRequest = false
    @AppStorage("MainPageShowCount") var mainPageShowCount = 0
    @AppStorage("IsShowJoinGroup") var isShowJoinGroup = true
    @AppStorage("IsShowClusterAd") var isShowClusterAd = true
    @AppStorage("IsBetaJoinAvailable") var isBetaJoinAvailable = false
    @State var tabs = [WebViewTab]()
    @State var selectedTab: WebViewTab?
    @State var isAppSettingsPresented = false
    @State var isFeedbackAssistantPresented = false
    @State var isTipsPresented = false
    @State var createButtonVisibilityResetTimer: Timer?
    @State var isCreateButtonVisible = true
    @State var isCreateButtonPressed = false
    @State var wristLocation = WKInterfaceDevice.current().wristLocation
    @State var newFeedbackCount = 0
    @State var isNewVerAvailable = false
    @State var isNewYearCelebrationPresented = false
    var body: some View {
        NavigationSplitView(sidebar: {
            NavigationStack {
                ZStack {
                    List(selection: $selectedTab) {
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
                                }
                                tabs.remove(atOffsets: index)
                            }
                            .onMove { source, destination in
                                tabs.move(fromOffsets: source, toOffset: destination)
                            }
                        }
                        Section {
                            Button(action: {
                                isFeedbackAssistantPresented = true
                            }, label: {
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
                            })
                            .disabled(isNewVerAvailable)
                            Button(action: {
                                isTipsPresented = true
                            }, label: {
                                Label("提示", privateSystemImage: "tips")
                            })
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
                                NavigationLink(destination: { BetaJoinView() }, label: {
                                    Label("参与 Beta 测试", systemImage: "person.badge.clock")
                                        .centerAligned()
                                })
                            }
                            if #available(watchOS 10, *), isShowClusterAd {
                                NavigationLink(destination: { ClusterAdView() }, label: {
                                    Label("推荐 - 暗礁文件", systemImage: "sparkles")
                                        .centerAligned()
                                })
                            }
                            if isShowJoinGroup {
                                NavigationLink(destination: { JoinGroupView() }, label: {
                                    Label("欢迎加入群聊", systemImage: "bubble.left.and.bubble.right")
                                        .centerAligned()
                                })
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
                .navigationDestination(isPresented: $isAppSettingsPresented, destination: { SettingsView() })
                .navigationDestination(isPresented: $isFeedbackAssistantPresented, destination: { FeedbackView() })
                .navigationDestination(isPresented: $isTipsPresented, destination: { TipsView() })
                .modifier(UserDefinedBackground())
                .sheet(isPresented: $isNewYearCelebrationPresented) { CelebrationFireworksView() }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            isAppSettingsPresented = true
                        }, label: {
                            Image(systemName: "gear")
                        })
                    }
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
                                    if !isCreateButtonPressed {
                                        isCreateButtonPressed = true
                                    } else {
                                        tabs.append(.init(metadata: .init(url: nil)))
                                        selectedTab = tabs.last
                                        isCreateButtonPressed = false
                                    }
                                }, label: {
                                    Image(systemName: isCreateButtonPressed ? "macwindow.badge.plus" : "plus")
                                })
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
                    for id in feedbackIds {
                        requestString("https://fapi.darock.top:65535/radar/details/Darock Browser/\(id)".compatibleUrlEncoded()) { respStr, isSuccess in
                            if isSuccess {
                                let repCount = respStr.apiFixed().components(separatedBy: "---").count - 1
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
                if getJsonData([WebViewTab.Metadata?].self, from: jsonStr) != nil {
                    try? jsonStr.write(toFile: NSHomeDirectory() + "/Documents/Tabs/Tabs.drkdatat", atomically: true, encoding: .utf8)
                } else {
                    os_log(.fault, "Failed to store tabs while tabs array changing. Full data below:\n\(tabs.map { $0.metadata })")
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
