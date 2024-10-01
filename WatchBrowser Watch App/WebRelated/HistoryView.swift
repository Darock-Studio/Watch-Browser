//
//  HistoryView.swift
//  WatchBrowser Watch App
//
//  Created by WindowsMEMZ on 2023/5/2.
//

import SwiftUI
import DarockKit
import AuthenticationServices

struct HistoryView: View {
    var selectionHandler: ((String) -> Void)?
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("LabTabBrowsingEnabled") var labTabBrowsingEnabled = false
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLockHistories") var usePasscodeForLockHistories = false
    @AppStorage("IsHistoryTransferNeeded") var isHistoryTransferNeeded = true
    @AppStorage("DarockAccount") var darockAccount = ""
    @AppStorage("DCSaveHistory") var isSaveHistoryToCloud = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var isSettingPresented = false
    @State var isStopRecordingPagePresenting = false
    @State var histories = [(dateString: String, histories: [SingleHistoryItem])]()
    @State var isSharePresented = false
    @State var isNewBookmarkPresented = false
    @State var isClearOptionsPresented = false
    @State var shareLink = ""
    @State var searchText = ""
    @State var newBookmarkName = ""
    @State var newBookmarkLink = ""
    @State var selectedEmptyAction = 0
    @State var isAdditionalCloseAllTabs = false
    @State var unfoldedIndexs: Set = [0, 1]
    @State var pinnedTitle = ""
    @State var pinnedTitleOffsetY: CGFloat = 0
    var body: some View {
        if isLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLockHistories {
            PasswordInputView(text: $passcodeInputCache, placeholder: "输入密码", dismissAfterComplete: false) { pwd in
                if pwd.md5 == userPasscodeEncrypted {
                    isLocked = false
                } else {
                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                }
                passcodeInputCache = ""
            }
            .toolbar(.hidden)
        } else {
            List {
                if selectionHandler == nil {
                    if isHistoryTransferNeeded {
                        NavigationLink(destination: { HistoryTransferView() }, label: {
                            VStack {
                                HStack {
                                    Image(systemName: "shippingbox.and.arrow.backward.fill")
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading) {
                                        Text("需要迁移")
                                            .font(.system(size: 16, weight: .bold))
                                        Text("由于一些已知问题，历史记录架构需要更新。完成迁移前，历史记录将暂时不可用，暗礁浏览器也不会记录新的历史记录。")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                }
                                HStack {
                                    Spacer()
                                    Group {
                                        Text("开始迁移 ")
                                        Image(systemName: "chevron.forward")
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                }
                            }
                        })
                    }
                    Section {
                        Toggle("History.record", isOn: $isHistoryRecording)
                            .onChange(of: isHistoryRecording, perform: { e in
                                if !e {
                                    isStopRecordingPagePresenting = true
                                }
                            })
                            .sheet(isPresented: $isStopRecordingPagePresenting, onDismiss: {
                                histories = getWebHistory().dateGrouped()
                            }, content: { CloseHistoryTipView() })
                        if isHistoryRecording && !histories.isEmpty {
                            TextField("搜索...", text: $searchText)
                                .submitLabel(.search)
                                .swipeActions {
                                    if !searchText.isEmpty {
                                        Button(action: {
                                            searchText = ""
                                        }, label: {
                                            Image(systemName: "xmark.bin.fill")
                                        })
                                        .tint(.red)
                                    }
                                }
                        }
                    }
                }
                if isHistoryRecording {
                    if !histories.isEmpty {
                        ForEach(0..<histories.count, id: \.self) { i in
                            if searchText.isEmpty || (!searchText.isEmpty && histories[i].histories.contains(where: {
                                $0.url.lowercased().contains(searchText.lowercased()) || ($0.title?.lowercased().contains(searchText.lowercased()) ?? false)
                            })) {
                                Section {
                                    if unfoldedIndexs.contains(i) || !searchText.isEmpty {
                                        let histories = histories[i].histories
                                        ForEach(0..<histories.count, id: \.self) { j in
                                            if searchText.isEmpty
                                                || histories[j].url.lowercased().contains(searchText.lowercased())
                                                || (histories[j].title?.lowercased().contains(searchText.lowercased()) ?? false) {
                                                Button(action: {
                                                    if let selectionHandler {
                                                        selectionHandler(histories[j].url)
                                                    } else {
                                                        if histories[j].url.hasPrefix("file://") {
                                                            AdvancedWebViewController.shared.present("", archiveUrl: URL(string: histories[j].url)!)
                                                        } else if histories[j].url.hasSuffix(".mp4") {
                                                            videoLinkLists = [histories[j].url]
                                                            pShouldPresentVideoList = true
                                                            dismissListsShouldRepresentWebView = false
                                                        } else if histories[j].url.hasSuffix(".mp3") {
                                                            audioLinkLists = [histories[j].url]
                                                            pShouldPresentAudioList = true
                                                            dismissListsShouldRepresentWebView = false
                                                        } else if histories[j].url.hasSuffix(".png")
                                                                    || histories[j].url.hasSuffix(".jpg")
                                                                    || histories[j].url.hasSuffix(".webp") {
                                                            imageLinkLists = [histories[j].url]
                                                            pShouldPresentImageList = true
                                                            dismissListsShouldRepresentWebView = false
                                                        } else if histories[j].url.hasSuffix(".epub") {
                                                            bookLinkLists = [histories[j].url]
                                                            pShouldPresentBookList = true
                                                            dismissListsShouldRepresentWebView = false
                                                        } else {
                                                            AdvancedWebViewController.shared.present(histories[j].url.urlDecoded().urlEncoded())
                                                        }
                                                    }
                                                }, label: {
                                                    if let showName = histories[j].title, !showName.isEmpty {
                                                        VStack(alignment: .leading) {
                                                            if histories[j].url.hasPrefix("https://www.bing.com/search?q=")
                                                                || histories[j].url.hasPrefix("https://www.baidu.com/s?wd=")
                                                                || histories[j].url.hasPrefix("https://www.google.com/search?q=")
                                                                || histories[j].url.hasPrefix("https://www.sogou.com/web?query=") {
                                                                Label(showName, systemImage: "magnifyingglass")
                                                            } else if histories[j].url.hasPrefix("file://") {
                                                                Label(showName, systemImage: "archivebox")
                                                            } else {
                                                                Label(showName, systemImage: "globe")
                                                            }
                                                            Text(histories[j].url)
                                                                .font(.footnote)
                                                                .lineLimit(1)
                                                                .truncationMode(.middle)
                                                                .foregroundStyle(.gray)
                                                        }
                                                        .font(.caption)
                                                    } else {
                                                        Group {
                                                            if histories[j].url.hasPrefix("https://www.bing.com/search?q=") {
                                                                Label(String(histories[j].url.urlDecoded().dropFirst(30)), systemImage: "magnifyingglass")
                                                            } else if histories[j].url.hasPrefix("https://www.baidu.com/s?wd=") {
                                                                Label(String(histories[j].url.urlDecoded().dropFirst(27)), systemImage: "magnifyingglass")
                                                            } else if histories[j].url.hasPrefix("https://www.google.com/search?q=") {
                                                                Label(String(histories[j].url.urlDecoded().dropFirst(32)), systemImage: "magnifyingglass")
                                                            } else if histories[j].url.hasPrefix("https://www.sogou.com/web?query=") {
                                                                Label(String(histories[j].url.urlDecoded().dropFirst(32)), systemImage: "magnifyingglass")
                                                            } else if histories[j].url.hasPrefix("file://") {
                                                                Label(
                                                                    String(histories[j].url.split(separator: "/").last!.split(separator: ".")[0])
                                                                        .replacingOccurrences(of: "{slash}", with: "/")
                                                                        .base64Decoded() ?? "[解析失败]",
                                                                    systemImage: "archivebox"
                                                                )
                                                            } else if histories[j].url.hasSuffix(".mp4") {
                                                                Label(histories[j].url, systemImage: "film")
                                                            } else if histories[j].url.hasSuffix(".mp3") {
                                                                Label(histories[j].url, systemImage: "music.note")
                                                            } else if histories[j].url.hasSuffix(".png")
                                                                        || histories[j].url.hasSuffix(".jpg")
                                                                        || histories[j].url.hasSuffix(".webp") {
                                                                Label(histories[j].url, systemImage: "photo")
                                                            } else if histories[j].url.hasSuffix(".epub") {
                                                                Label(histories[j].url, systemImage: "book")
                                                            } else {
                                                                Label(histories[j].url, systemImage: "globe")
                                                            }
                                                        }
                                                        .font(.caption)
                                                    }
                                                })
                                                .privacySensitive()
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                    Button(role: .destructive, action: {
                                                        var removedHistories = histories
                                                        removedHistories.remove(at: j)
                                                        self.histories[i].histories = removedHistories
                                                        writeWebHistory(from: self.histories.flatMap { $0.histories })
                                                    }, label: {
                                                        Image(systemName: "bin.xmark.fill")
                                                    })
                                                }
                                                .swipeActions(edge: .leading) {
                                                    Button(action: {
                                                        if let showName = histories[i].title {
                                                            newBookmarkName = showName
                                                        } else {
                                                            newBookmarkName = ""
                                                        }
                                                        newBookmarkLink = histories[i].url.urlDecoded().urlEncoded()
                                                        isNewBookmarkPresented = true
                                                    }, label: {
                                                        Image(systemName: "bookmark")
                                                    })
                                                    Button(action: {
                                                        shareLink = histories[i].url.urlDecoded().urlEncoded()
                                                        isSharePresented = true
                                                    }, label: {
                                                        Image(systemName: "square.and.arrow.up.fill")
                                                    })
                                                }
                                            }
                                        }
                                    }
                                } header: {
                                    HStack {
                                        if unfoldedIndexs.contains(i) || !searchText.isEmpty {
                                            GeometryReader { proxy in
                                                Text(histories[i].dateString)
                                                    .offset(y: -min(proxy.frame(in: .named("HistoryList")).minY - 55, 0))
                                                    .onChange(of: proxy.frame(in: .named("HistoryList")).minY) { value in
                                                        if value < 55 {
                                                            pinnedTitle = histories[i].dateString
                                                            pinnedTitleOffsetY = 0
                                                        } else if i == 0 {
                                                            pinnedTitle = ""
                                                        } else if value < 120 {
                                                            if unfoldedIndexs.contains(i - 1) || !searchText.isEmpty {
                                                                pinnedTitle = histories[i - 1].dateString
                                                            } else {
                                                                pinnedTitle = ""
                                                            }
                                                            pinnedTitleOffsetY = value - 120
                                                        } else {
                                                            pinnedTitleOffsetY = 0
                                                        }
                                                    }
                                            }
                                        } else {
                                            Text(histories[i].dateString)
                                        }
                                        Spacer()
                                        if searchText.isEmpty {
                                            Button(action: {
                                                if unfoldedIndexs.contains(i) {
                                                    unfoldedIndexs.remove(i)
                                                } else {
                                                    unfoldedIndexs.update(with: i)
                                                }
                                            }, label: {
                                                Image(systemName: "chevron.forward")
                                                    .foregroundStyle(.accent)
                                                    .rotationEffect(unfoldedIndexs.contains(i) ? .degrees(90) : .zero)
                                                    .animation(.smooth, value: unfoldedIndexs)
                                            })
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Text("History.nothing")
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("History.not-recording")
                        .foregroundColor(.gray)
                }
            }
            .overlay {
                VStack {
                    HStack {
                        Text(pinnedTitle)
                            .font(.system(size: 13, weight: .medium))
                            .background {
                                if #available(watchOS 10, *) {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Material.ultraThin)
                                        .blur(radius: 5)
                                }
                            }
                            .offset(x: 13, y: 55 + pinnedTitleOffsetY)
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .coordinateSpace(name: "HistoryList")
            .animation(.smooth, value: unfoldedIndexs)
            .sheet(isPresented: $isSharePresented, content: { ShareView(linkToShare: $shareLink) })
            .sheet(isPresented: $isNewBookmarkPresented, content: { AddBookmarkView(initMarkName: $newBookmarkName, initMarkLink: $newBookmarkLink) })
            .sheet(isPresented: $isClearOptionsPresented) {
                NavigationStack {
                    List {
                        Section {
                            Button(action: {
                                selectedEmptyAction = 0
                            }, label: {
                                HStack {
                                    Text("上一小时")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if selectedEmptyAction == 0 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            })
                            Button(action: {
                                selectedEmptyAction = 1
                            }, label: {
                                HStack {
                                    Text("今天")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if selectedEmptyAction == 1 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            })
                            Button(action: {
                                selectedEmptyAction = 2
                            }, label: {
                                HStack {
                                    Text("昨天和今天")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if selectedEmptyAction == 2 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            })
                            Button(action: {
                                selectedEmptyAction = 3
                            }, label: {
                                HStack {
                                    Text("所有历史记录")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if selectedEmptyAction == 3 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            })
                        } header: {
                            Text("清除时间段")
                                .textCase(nil)
                        }
                        if labTabBrowsingEnabled && !(UserDefaults.standard.stringArray(forKey: "CurrentTabs") ?? [String]()).isEmpty {
                            Section {
                                Toggle("关闭所有标签页", isOn: $isAdditionalCloseAllTabs)
                            } header: {
                                Text("附加选项")
                                    .textCase(nil)
                            }
                        }
                        Section {
                            Button(role: .destructive, action: {
                                if isAdditionalCloseAllTabs {
                                    UserDefaults.standard.set([String](), forKey: "CurrentTabs")
                                }
                                if selectedEmptyAction == 3 {
                                    histories.removeAll()
                                    writeWebHistory(from: [])
                                    isClearOptionsPresented = false
                                    return
                                }
                                let currentTime = Date.now.timeIntervalSince1970
                                var maxTimeDiff = 0.0
                                switch selectedEmptyAction {
                                case 0:
                                    maxTimeDiff = 3600
                                case 1:
                                    maxTimeDiff = 86400
                                case 2:
                                    maxTimeDiff = 172800
                                default:
                                    break
                                }
                                var flatHistories = histories.flatMap { $0.histories }
                                for i in 0..<flatHistories.count {
                                    let time = flatHistories[i].time
                                    if currentTime - time <= maxTimeDiff {
                                        flatHistories[i].url = "[History Remove Token]"
                                    }
                                }
                                flatHistories.removeAll(where: { element in
                                    if element.url == "[History Remove Token]" {
                                        return true
                                    }
                                    return false
                                })
                                writeWebHistory(from: flatHistories)
                                if UserDefaults.standard.bool(forKey: "DCSaveHistory") && !ProcessInfo.processInfo.isLowPowerModeEnabled,
                                   let account = UserDefaults.standard.string(forKey: "DarockAccount"),
                                   !account.isEmpty {
                                    // Darock Cloud Upload
                                    let historiesToUpload = Array<SingleHistoryItem>(flatHistories.prefix(50))
                                    if let uploadData = jsonString(from: historiesToUpload) {
                                        _onFastPath()
                                        let encodedData = uploadData.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")
                                        DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/drkbs/cloud/update/\(account)/WebHistory.drkdataw/\(encodedData)".compatibleUrlEncoded()) { _, _ in }
                                    }
                                }
                                isClearOptionsPresented = false
                            }, label: {
                                Text("清除历史记录")
                                    .bold()
                            })
                        }
                    }
                    .navigationTitle("清除历史记录")
                }
            }
            .navigationTitle("历史记录")
            .toolbar {
                if #available(watchOS 10.5, *), !histories.isEmpty && isHistoryRecording && selectionHandler == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive, action: {
                            isClearOptionsPresented = true
                        }, label: {
                            Image(systemName: "arrow.up.trash.fill")
                                .foregroundColor(.red)
                        })
                    }
                }
            }
            .onAppear {
                histories = getWebHistory().dateGrouped()
                // Cloud
                if !darockAccount.isEmpty && isSaveHistoryToCloud && !ProcessInfo.processInfo.isLowPowerModeEnabled {
                    Task {
                        if let cloudHistories = await getWebHistoryFromCloud(with: darockAccount) {
                            let flatHistories = histories.flatMap { $0.histories }
                            let mergedHistories = mergeWebHistoriesBetween(primary: flatHistories, secondary: cloudHistories)
                            if mergedHistories != flatHistories {
                                histories = mergedHistories.dateGrouped()
                                writeWebHistory(from: histories.flatMap { $0.histories })
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: History Related Functions
func recordHistory(_ inp: String, webSearch: String, showName: String? = nil) {
    if (UserDefaults.standard.object(forKey: "IsHistoryTransferNeeded") as? Bool) ?? true {
        return
    }
    var fullHistory = getWebHistory()
    if let lstf = fullHistory.first {
        guard lstf.url != inp && lstf.url != getWebSearchedURL(inp, webSearch: webSearch, isSearchEngineShortcutEnabled: false) else {
            return
        }
    }
    if inp.isURL() || inp.hasPrefix("file://") {
        fullHistory.insert(.init(url: inp, title: showName, time: Date.now.timeIntervalSince1970), at: 0)
    } else {
        let rurl = getWebSearchedURL(inp, webSearch: webSearch, isSearchEngineShortcutEnabled: false)
        fullHistory.insert(.init(url: rurl, title: showName, time: Date.now.timeIntervalSince1970), at: 0)
    }
    writeWebHistory(from: fullHistory)
    if UserDefaults.standard.bool(forKey: "DCSaveHistory") && !ProcessInfo.processInfo.isLowPowerModeEnabled,
       let account = UserDefaults.standard.string(forKey: "DarockAccount"),
       !account.isEmpty {
        // Darock Cloud Upload
        let historiesToUpload = Array<SingleHistoryItem>(fullHistory.prefix(50))
        if let uploadData = jsonString(from: historiesToUpload) {
            _onFastPath()
            let encodedData = uploadData.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")
            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/drkbs/cloud/update/\(account)/WebHistory.drkdataw/\(encodedData)".compatibleUrlEncoded()) { _, _ in }
        }
    }
}
@_effects(readonly)
func getWebHistory() -> [SingleHistoryItem] {
    do {
        let jsonSource: String
        if _fastPath(FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/WebHistories.drkdataw")) {
            jsonSource = try String(contentsOfFile: NSHomeDirectory() + "/Documents/WebHistories.drkdataw", encoding: .utf8)
        } else {
            jsonSource = "[]"
        }
        return getJsonData([SingleHistoryItem].self, from: jsonSource) ?? [SingleHistoryItem]()
    } catch {
        globalErrorHandler(error)
    }
    return [SingleHistoryItem]()
}
func writeWebHistory(from histories: [SingleHistoryItem]) {
    do {
        if let json = jsonString(from: histories) {
            try json.write(toFile: NSHomeDirectory() + "/Documents/WebHistories.drkdataw", atomically: true, encoding: .utf8)
        }
    } catch {
        globalErrorHandler(error)
    }
}
@_effects(readonly)
func getWebHistoryFromCloud(with account: String) async -> [SingleHistoryItem]? {
    await withCheckedContinuation { continuation in
        DarockKit.Network.shared.requestJSON("https://fapi.darock.top:65535/drkbs/cloud/get/\(account)/WebHistory.drkdataw".compatibleUrlEncoded()) { respJson, isSuccess in
            if isSuccess {
                if let rawString = respJson.rawString(), let jsonData = getJsonData([SingleHistoryItem].self, from: rawString) {
                    _onFastPath()
                    continuation.resume(returning: jsonData)
                    return
                }
                continuation.resume(returning: nil)
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}
@_effects(readnone)
func mergeWebHistoriesBetween(primary: [SingleHistoryItem], secondary: [SingleHistoryItem]) -> [SingleHistoryItem] {
    var primCopy = primary
    for single in secondary where !primary.contains(where: { $0.time == single.time }) {
        var inserted = false
        for (index, item) in primCopy.enumerated() where single.time > item.time {
            primCopy.insert(single, at: index)
            inserted = true
            break
        }
        if _slowPath(!inserted) {
            primCopy.append(single)
        }
    }
    return primCopy
}

struct CloseHistoryTipView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ScrollView {
            Text("History.turn-off")
                .fontWeight(.bold)
                .font(.system(size: 20))
            Text("History.clear-history-at-the-same-time")
            Button(role: .destructive, action: {
                do {
                    try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/WebHistories.drkdataw")
                    if UserDefaults.standard.bool(forKey: "DCSaveHistory"),
                       let account = UserDefaults.standard.string(forKey: "DarockAccount"),
                       !account.isEmpty {
                        // Darock Cloud Upload
                        if let uploadData = jsonString(from: [SingleHistoryItem]()) {
                            _onFastPath()
                            let encodedData = uploadData.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")
                            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/drkbs/cloud/update/\(account)/WebHistory.drkdataw/\(encodedData)".compatibleUrlEncoded()) { _, _ in }
                        }
                    }
                } catch {
                    globalErrorHandler(error)
                }
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Label("History.clear", systemImage: "trash.fill")
            })
            Button(role: .cancel, action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Label("History.save", systemImage: "arrow.down.doc.fill")
            })
        }
    }
}

struct HistoryTransferView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("IsHistoryTransferNeeded") var isHistoryTransferNeeded = true
    var body: some View {
        List {
            Section {
                Button(action: {
                    let histories = UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()
                    let historyTitles = (UserDefaults.standard.dictionary(forKey: "WebHistoryNames") as? [String: String]) ?? [String: String]()
                    let recordTimePair = (UserDefaults.standard.dictionary(forKey: "WebHistoryRecordTimes") as? [String: Double]) ?? [String: Double]()
                    var newHistoriesTmp = [SingleHistoryItem]()
                    for history in histories {
                        newHistoriesTmp.append(.init(url: history, title: historyTitles[history], time: recordTimePair[history] ?? 1689895260))
                    }
                    if let targetStr = jsonString(from: newHistoriesTmp) {
                        do {
                            try targetStr.write(toFile: NSHomeDirectory() + "/Documents/WebHistories.drkdataw", atomically: true, encoding: .utf8)
                            UserDefaults.standard.removeObject(forKey: "WebHistory")
                            UserDefaults.standard.removeObject(forKey: "WebHistoryNames")
                            UserDefaults.standard.removeObject(forKey: "WebHistoryRecordTimes")
                            isHistoryTransferNeeded = false
                            presentationMode.wrappedValue.dismiss()
                            tipWithText("迁移已完成", symbol: "checkmark.circle.fill")
                        } catch {
                            globalErrorHandler(error)
                        }
                    } else {
                        tipWithText("迁移出错，请提交反馈", symbol: "xmark.circle.fill")
                    }
                }, label: {
                    Text("将所有历史记录转换为新架构")
                })
            } header: {
                Text("迁移方式 1")
            } footer: {
                Text("转换时暗礁浏览器可能无响应，请耐心等待转换完成。")
            }
            Section {
                Button(role: .destructive, action: {
                    UserDefaults.standard.removeObject(forKey: "WebHistory")
                    UserDefaults.standard.removeObject(forKey: "WebHistoryNames")
                    UserDefaults.standard.removeObject(forKey: "WebHistoryRecordTimes")
                    isHistoryTransferNeeded = false
                    presentationMode.wrappedValue.dismiss()
                    tipWithText("迁移已完成", symbol: "checkmark.circle.fill")
                }, label: {
                    Text("清空历史记录并在今后使用新架构")
                        .foregroundColor(.red)
                })
            } header: {
                Text("迁移方式 2")
            }
        }
        .navigationTitle("迁移历史记录")
    }
}

struct SingleHistoryItem: Codable, Equatable {
    var url: String
    var title: String?
    var time: TimeInterval
}
extension [SingleHistoryItem] {
    typealias GroupedHistory = (dateString: String, histories: Self)
    
    func dateGrouped() -> [GroupedHistory] {
        let dateFormatter = DateFormatter()
        let calendar = Calendar.current
        var result = [GroupedHistory]()
        let dateSortedHistories = self.sorted(by: { lhs, rhs in lhs.time > rhs.time })
        var previousDateString = ""
        if !dateSortedHistories.isEmpty {
            let yearDateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMMd", options: 0, locale: .autoupdatingCurrent)
            let withoutYearDateFormat = DateFormatter.dateFormat(fromTemplate: "MMMMdE", options: 0, locale: .autoupdatingCurrent)
            var shouldShowYear = calendar.dateComponents([.year], from: .init(timeIntervalSince1970: dateSortedHistories[0].time)).year!
            != calendar.dateComponents([.year], from: .now).year!
            var thisGroupHistories = Self()
            for history in dateSortedHistories {
                shouldShowYear = calendar.dateComponents([.year], from: .init(timeIntervalSince1970: history.time)).year!
                != calendar.dateComponents([.year], from: .now).year!
                dateFormatter.dateFormat = shouldShowYear ? yearDateFormat : withoutYearDateFormat
                let dateString = {
                    let date = Date(timeIntervalSince1970: history.time)
                    if _slowPath(calendar.isDateInToday(date)) {
                        return String(localized: "今天")
                    } else if calendar.isDateInYesterday(date) {
                        return String(localized: "昨天")
                    } else {
                        return dateFormatter.string(from: date)
                    }
                }()
                if dateString == previousDateString {
                    thisGroupHistories.append(history)
                } else if !thisGroupHistories.isEmpty {
                    result.append((previousDateString, thisGroupHistories))
                    thisGroupHistories.removeAll()
                }
                previousDateString = dateString
            }
        }
        return result
    }
}
