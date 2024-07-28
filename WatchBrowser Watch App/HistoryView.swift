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
    @State var histories = [SingleHistoryItem]()
    @State var isSharePresented = false
    @State var isNewBookmarkPresented = false
    @State var isClearOptionsPresented = false
    @State var shareLink = ""
    @State var searchText = ""
    @State var newBookmarkName = ""
    @State var newBookmarkLink = ""
    @State var selectedEmptyAction = 0
    @State var isAdditionalCloseAllTabs = false
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
            .navigationBarBackButtonHidden()
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
                            .accessibilityIdentifier("RecordHistoryToggle")
                            .onChange(of: isHistoryRecording, perform: { e in
                                if !e {
                                    isStopRecordingPagePresenting = true
                                }
                            })
                            .sheet(isPresented: $isStopRecordingPagePresenting, onDismiss: {
                                histories = getWebHistory()
                            }, content: { CloseHistoryTipView() })
                    }
                }
                Section {
                    if isHistoryRecording {
                        if histories.count != 0 {
                            TextField("搜索", text: $searchText)
                            ForEach(0..<histories.count, id: \.self) { i in
                                if searchText.isEmpty || histories[i].url.contains(searchText) || (histories[i].title?.contains(searchText) ?? false) {
                                    Button(action: {
                                        if let selectionHandler {
                                            selectionHandler(histories[i].url)
                                        } else {
                                            if histories[i].url.hasPrefix("file://") {
                                                AdvancedWebViewController.shared.present("", archiveUrl: URL(string: histories[i].url)!)
                                            } else if histories[i].url.hasSuffix(".mp4") {
                                                videoLinkLists = [histories[i].url]
                                                pShouldPresentVideoList = true
                                                dismissListsShouldRepresentWebView = false
                                            } else if histories[i].url.hasSuffix(".mp3") {
                                                audioLinkLists = [histories[i].url]
                                                pShouldPresentAudioList = true
                                                dismissListsShouldRepresentWebView = false
                                            } else if histories[i].url.hasSuffix(".png")
                                                        || histories[i].url.hasSuffix(".jpg")
                                                        || histories[i].url.hasSuffix(".webp") {
                                                imageLinkLists = [histories[i].url]
                                                pShouldPresentImageList = true
                                                dismissListsShouldRepresentWebView = false
                                            } else if histories[i].url.hasSuffix(".epub") {
                                                bookLinkLists = [histories[i].url]
                                                pShouldPresentBookList = true
                                                dismissListsShouldRepresentWebView = false
                                            } else {
                                                AdvancedWebViewController.shared.present(histories[i].url.urlDecoded().urlEncoded())
                                            }
                                        }
                                    }, label: {
                                        if let showName = histories[i].title, !showName.isEmpty {
                                            VStack(alignment: .leading) {
                                                if histories[i].url.hasPrefix("https://www.bing.com/search?q=")
                                                    || histories[i].url.hasPrefix("https://www.baidu.com/s?wd=")
                                                    || histories[i].url.hasPrefix("https://www.google.com/search?q=")
                                                    || histories[i].url.hasPrefix("https://www.sogou.com/web?query=") {
                                                    Label(showName, systemImage: "magnifyingglass")
                                                } else if histories[i].url.hasPrefix("file://") {
                                                    Label(showName, systemImage: "archivebox")
                                                } else {
                                                    Label(showName, systemImage: "globe")
                                                }
                                                Text(histories[i].url)
                                                    .font(.system(size: 14))
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                                    .foregroundStyle(Color.gray)
                                            }
                                        } else {
                                            if histories[i].url.hasPrefix("https://www.bing.com/search?q=") {
                                                Label(String(histories[i].url.urlDecoded().dropFirst(30)), systemImage: "magnifyingglass")
                                            } else if histories[i].url.hasPrefix("https://www.baidu.com/s?wd=") {
                                                Label(String(histories[i].url.urlDecoded().dropFirst(27)), systemImage: "magnifyingglass")
                                            } else if histories[i].url.hasPrefix("https://www.google.com/search?q=") {
                                                Label(String(histories[i].url.urlDecoded().dropFirst(32)), systemImage: "magnifyingglass")
                                            } else if histories[i].url.hasPrefix("https://www.sogou.com/web?query=") {
                                                Label(String(histories[i].url.urlDecoded().dropFirst(32)), systemImage: "magnifyingglass")
                                            } else if histories[i].url.hasPrefix("file://") {
                                                Label(
                                                    String(histories[i].url.split(separator: "/").last!.split(separator: ".")[0])
                                                        .replacingOccurrences(of: "{slash}", with: "/")
                                                        .base64Decoded() ?? "[解析失败]",
                                                    systemImage: "archivebox"
                                                )
                                            } else if histories[i].url.hasSuffix(".mp4") {
                                                Label(histories[i].url, systemImage: "film")
                                            } else if histories[i].url.hasSuffix(".mp3") {
                                                Label(histories[i].url, systemImage: "music.note")
                                            } else if histories[i].url.hasSuffix(".png")
                                                        || histories[i].url.hasSuffix(".jpg")
                                                        || histories[i].url.hasSuffix(".webp") {
                                                Label(histories[i].url, systemImage: "photo")
                                            } else if histories[i].url.hasSuffix(".epub") {
                                                Label(histories[i].url, systemImage: "book")
                                            } else {
                                                Label(histories[i].url, systemImage: "globe")
                                            }
                                        }
                                    })
                                    .privacySensitive()
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive, action: {
                                            histories.remove(at: i)
                                            writeWebHistory(from: histories)
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
                        } else {
                            Text("History.nothing")
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("History.not-recording")
                            .foregroundColor(.gray)
                    }
                }
            }
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
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    if selectedEmptyAction == 0 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.blue)
                                    }
                                }
                            })
                            Button(action: {
                                selectedEmptyAction = 1
                            }, label: {
                                HStack {
                                    Text("今天")
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    if selectedEmptyAction == 1 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.blue)
                                    }
                                }
                            })
                            Button(action: {
                                selectedEmptyAction = 2
                            }, label: {
                                HStack {
                                    Text("昨天和今天")
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    if selectedEmptyAction == 2 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.blue)
                                    }
                                }
                            })
                            Button(action: {
                                selectedEmptyAction = 3
                            }, label: {
                                HStack {
                                    Text("所有历史记录")
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    if selectedEmptyAction == 3 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.blue)
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
                                    writeWebHistory(from: histories)
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
                                for i in 0..<histories.count {
                                    let time = histories[i].time
                                    if currentTime - time <= maxTimeDiff {
                                        histories[i].url = "[History Remove Token]"
                                    }
                                }
                                histories.removeAll(where: { element in
                                    if element.url == "[History Remove Token]" {
                                        return true
                                    }
                                    return false
                                })
                                writeWebHistory(from: histories)
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
                histories = getWebHistory()
                // Cloud
                if !darockAccount.isEmpty && isSaveHistoryToCloud {
                    Task {
                        if let cloudHistories = await getWebHistoryFromCloud(with: darockAccount) {
                            let mergedHistories = mergeWebHistoriesBetween(primary: histories, secondary: cloudHistories)
                            if mergedHistories != histories {
                                histories = mergedHistories
                                writeWebHistory(from: histories)
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
    if UserDefaults.standard.bool(forKey: "DCSaveHistory"),
       let account = UserDefaults.standard.string(forKey: "DarockAccount"),
       !account.isEmpty {
        // Darock Cloud Upload
        let historiesToUpload = Array<SingleHistoryItem>(fullHistory.prefix(50))
        if let uploadData = jsonString(from: historiesToUpload) {
            _onFastPath()
            let encodedData = uploadData.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")
            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/drkbs/cloud/update/\(account)/WebHistory.drkdataw/\(encodedData)") { _, _ in }
        }
    }
}
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
func getWebHistoryFromCloud(with account: String) async -> [SingleHistoryItem]? {
    await withCheckedContinuation { continuation in
        DarockKit.Network.shared.requestJSON("https://fapi.darock.top:65535/drkbs/cloud/get/\(account)/WebHistory.drkdataw") { respJson, isSuccess in
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
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ScrollView {
            Text("History.turn-off")
                .fontWeight(.bold)
                .font(.system(size: 20))
            Text("History.clear-history-at-the-same-time")
            Button(role: .destructive, action: {
                do {
                    try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/WebHistories.drkdataw")
                } catch {
                    globalErrorHandler(error)
                }
                dismiss()
            }, label: {
                Label("History.clear", systemImage: "trash.fill")
            })
            Button(role: .cancel, action: {
                dismiss()
            }, label: {
                Label("History.save", systemImage: "arrow.down.doc.fill")
            })
        }
    }
}

struct HistoryTransferView: View {
    @Environment(\.dismiss) var dismiss
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
                            dismiss()
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
                    dismiss()
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

func jsonString<T>(from value: T) -> String? where T: Encodable {
    do {
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(value)
        return String(decoding: jsonData, as: UTF8.self)
    } catch {
        print("Error encoding data to JSON: \(error)")
    }
    return nil
}
func getJsonData<T>(_ type: T.Type, from json: String) -> T? where T: Decodable {
    do {
        let jsonData = json.data(using: .utf8)!
        let jsonDecoder = JSONDecoder()
        return try jsonDecoder.decode(type, from: jsonData)
    } catch {
        print("Error decoding JSON to data: \(error)")
    }
    return nil
}
