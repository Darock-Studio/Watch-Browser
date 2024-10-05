//
//  FeedbackView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/2/23.
//

import SwiftUI
import DarockKit
import MarkdownUI
import UserNotifications

fileprivate let globalStates: [LocalizedStringKey] = [
    "未标记",
    "按预期工作",
    "无法修复",
    "问题重复",
    "搁置",
    "正在修复",
    "已在未来版本修复",
    "已修复",
    "正在加载",
    "未能复现",
    "问题并不与App相关",
    "需要更多细节",
    "被删除"
]
fileprivate let globalStateColors = [
    Color.secondary,
    Color.red,
    Color.red,
    Color.red,
    Color.orange,
    Color.orange,
    Color.orange,
    Color.green,
    Color.secondary,
    Color.red,
    Color.secondary,
    Color.orange,
    Color.red
]
fileprivate let globalStateIcons = [
    "minus",
    "curlybraces",
    "xmark",
    "arrow.triangle.pull",
    "books.vertical",
    "hammer",
    "clock.badge.checkmark",
    "checkmark",
    "ellipsis",
    "questionmark",
    "bolt.horizontal",
    "arrowshape.turn.up.backward.badge.clock",
    "xmark.square.fill"
]

struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var feedbackIds = [String]()
    @State var badgeOnIds = [String]()
    @State var isNewNewsAvailable = false
    @State var isNewVerAvailableAlertPresented = false
    var body: some View {
        List {
            Section {
                NavigationLink(destination: { NewFeedbackView() }, label: {
                    Label("新建反馈", systemImage: "exclamationmark.bubble")
                })
                NavigationLink(destination: { NewsView() }, label: {
                    HStack {
                        Label("新闻", systemImage: "newspaper")
                        Spacer()
                        if isNewNewsAvailable {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 10, height: 10)
                        }
                    }
                })
                NavigationLink(destination: { FAQView() }, label: {
                    Label("常见问题", systemImage: "sparkles")
                })
                NavigationLink(destination: { StateMeaningsView() }, label: {
                    Label("了解反馈状态", systemImage: "bolt.badge.clock")
                })
            } footer: {
                Text("提交反馈前，请先检查常见问题")
            }
            if feedbackIds.count != 0 {
                Section {
                    ForEach(0..<feedbackIds.count, id: \.self) { i in
                        NavigationLink(destination: { FeedbackDetailView(id: feedbackIds[i]) }, label: {
                            HStack {
                                if badgeOnIds.contains(feedbackIds[i]) {
                                    Image(systemName: "1.circle.fill")
                                        .foregroundColor(.red)
                                }
                                Text("ID: \(feedbackIds[i])")
                            }
                        })
                        .swipeActions {
                            Button(role: .destructive, action: {
                                feedbackIds.remove(at: i)
                                UserDefaults.standard.set(feedbackIds, forKey: "RadarFBIDs")
                            }, label: {
                                Image(systemName: "xmark.bin.fill")
                            })
                        }
                    }
                } header: {
                    Text("发送的反馈")
                }
            }
        }
        .navigationTitle("反馈助理")
        .alert("“反馈助理”不可用", isPresented: $isNewVerAvailableAlertPresented, actions: {
            Button(role: .cancel, action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("确定")
            })
        }, message: {
            Text("暗礁浏览器有更新可用。")
        })
        .onAppear {
            feedbackIds = UserDefaults.standard.stringArray(forKey: "RadarFBIDs") ?? [String]()
            badgeOnIds.removeAll()
            for id in feedbackIds {
                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/details/Darock Browser/\(id)".compatibleUrlEncoded()) { respStr, isSuccess in
                    if isSuccess {
                        let repCount = respStr.apiFixed().components(separatedBy: "---").count - 1
                        let lastViewCount = UserDefaults.standard.integer(forKey: "RadarFB\(id)ReplyCount")
                        if repCount > lastViewCount {
                            badgeOnIds.append(id)
                        }
                    }
                }
            }
            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/news/get/Darock Browser".compatibleUrlEncoded()) { respStr, isSuccess in
                if isSuccess {
                    let fixed = respStr.apiFixed()
                    if fixed != "None" {
                        let spd = fixed.split(separator: "|").map { String($0) }
                        var fcp = [String]()
                        for text in spd {
                            let partSpd = text.split(separator: "^^").map { String($0) }
                            if let id = partSpd[from: 0] {
                                fcp.append(id)
                            }
                        }
                        let readNewsIDs = UserDefaults.standard.stringArray(forKey: "ReadNewsIDs") ?? []
                        newsCheck: do {
                            for id in fcp where !readNewsIDs.contains(id) {
                                isNewNewsAvailable = true
                                break newsCheck
                            }
                            isNewNewsAvailable = false
                        }
                    } else {
                        isNewNewsAvailable = false
                    }
                }
            }
            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/drkbs/newver".compatibleUrlEncoded()) { respStr, isSuccess in
                if isSuccess {
                    let spdVer = respStr.apiFixed().split(separator: ".")
                    if spdVer.count == 3 {
                        if let x = Int(spdVer[0]), let y = Int(spdVer[1]), let z = Int(spdVer[2]) {
                            let currVerSpd = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).split(separator: ".")
                            if currVerSpd.count == 3 {
                                if let cx = Int(currVerSpd[0]), let cy = Int(currVerSpd[1]), let cz = Int(currVerSpd[2]) {
                                    if x > cx {
                                        isNewVerAvailableAlertPresented = true
                                    } else if x == cx && y > cy {
                                        isNewVerAvailableAlertPresented = true
                                    } else if x == cx && y == cy && z > cz {
                                        isNewVerAvailableAlertPresented = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    struct NewFeedbackView: View {
        @Environment(\.presentationMode) var presentationMode
        @Namespace var issuePlaceSelectorId
        @State var titleInput = ""
        @State var contentInputs = [""]
        @State var issuePlace = ""
        @State var feedbackType = 0
        @State var isSending = false
        @State var isDetailSelectorPresented = false
        @State var extHistories = [String]()
        @State var dontSendDiagnose = false
        @State var isRemoveDiagAlertPresented = false
        @State var isDraftAlertPresented = false
        @State var isDraftLoaded = false
        var body: some View {
            ScrollViewReader { scrollProxy in
                Form {
                    Section {
                        TextField("标题", text: $titleInput)
                    } header: {
                        Text("请为你的反馈提供描述性的标题：")
                    } footer: {
                        Text("示例：历史记录缺少最近的浏览数据")
                    }
                    Section {
                        ForEach(0..<contentInputs.count, id: \.self) { i in
                            TextField("描述行\(i &+ 1)", text: $contentInputs[i])
                                .swipeActions {
                                    if contentInputs.count > 1 {
                                        Button(role: .destructive, action: {
                                            contentInputs.remove(at: i)
                                        }, label: {
                                            Image(systemName: "xmark.circle.fill")
                                        })
                                    }
                                }
                        }
                        Button(action: {
                            contentInputs.append("")
                        }, label: {
                            Label("换行", systemImage: "text.append")
                        })
                    } header: {
                        Text("请描述该问题以及重现问题的步骤：")
                    } footer: {
                        Text("""
                        请包括：
                        - 问题的清晰描述
                        - 逐步说明重现问题的详细步骤（如果可能）
                        - 期望的结果
                        - 当前所示结果
                        """)
                    }
                    Section {
                        Picker("问题区域", selection: $issuePlace) {
                            Text("选择一项").tag("")
                            Text("界面").tag("UI&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("网络连接").tag("网络连接&&&0.19615289568901062,0.7796291708946228,0.34923407435417175")
                            Text("浏览引擎").tag("浏览引擎&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("旧版浏览引擎").tag("旧版浏览引擎&&&0.39999979734420776,0.6156863570213318,0.2039215862751007")
                            Text("设置").tag("设置&&&0.20000001788139343,0.20000001788139343,0.20000001788139343")
                            Text("辅助功能").tag("辅助功能&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("个性化主屏幕").tag("个性化主屏幕&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("搜索").tag("搜索&&&0.20000001788139343,0.20000001788139343,0.20000001788139343")
                            Text("密码").tag("密码&&&0.886274516582489,0.14117646217346191,0.0")
                            Text("隐私与安全性").tag("隐私与安全性&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("开发者设置").tag("开发者设置&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("实验室项目").tag("实验室项目&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("连续互通").tag("连续互通&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("第三方全键盘").tag("第三方全键盘&&&0.20000001788139343,0.20000001788139343,0.20000001788139343")
                            Text("音乐播放器").tag("音乐播放器&&&0.886274516582489,0.14117646217346191,0.0")
                            Text("图像查看器").tag("图像查看器&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("阅读器").tag("阅读器&&&0.7686275243759155,0.7372550964355469,0.0")
                            Text("视频播放器").tag("视频播放器&&&0.36078429222106934,0.36078429222106934,0.36078429222106934")
                            Text("Darock 账户").tag("Darock 账户&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("Darock Cloud").tag("Darock Cloud&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("书签").tag("书签&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("历史记录").tag("历史记录&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("网页归档").tag("网页归档&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("播放列表").tag("播放列表&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("用户脚本").tag("用户脚本&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("本地媒体").tag("本地媒体&&&0.03921568766236305,0.5176469087600708,1.0")
                            Text("反馈助理").tag("反馈助理&&&0.5960784554481506,0.16470590233802795,0.7372550964355469")
                            Text("不在此列表中的其他方面").tag("其他&&&0.5215685963630676,0.5215685963630676,0.5215685963630676")
                        }
                        .id(issuePlaceSelectorId)
                    }
                    switch issuePlace {
                    case let s where s.hasPrefix("视频播放器"):
                        Section {
                            SuggestedResolver.reboot.viewBlock
                            SuggestedResolver.networkCheck.viewBlock
                        } header: {
                            Text("先试试这些方案")
                        }
                    case let s where s.hasPrefix("网络连接"):
                        Section {
                            SuggestedResolver.networkCheck.viewBlock
                        } header: {
                            Text("先试试这个方案")
                        }
                    case let s where s.hasPrefix("密码"):
                        Section {
                            NavigationLink(destination: { SettingsView.GeneralSettingsView.ResetView() }, label: {
                                HStack {
                                    ZStack {
                                        Color.gray
                                            .frame(width: 20, height: 20)
                                            .clipShape(Circle())
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 12))
                                    }
                                    Text("查看还原选项")
                                    Spacer()
                                    Image(systemName: "chevron.forward")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.gray)
                                }
                            })
                        } header: {
                            Text("反馈问题无法帮助您找回密码")
                        }
                    default: EmptyView()
                    }
                    Section {
                        Picker("反馈类型", selection: $feedbackType) {
                            Text("错误/异常行为").tag(0)
                            Text("应用程序崩溃").tag(2)
                            Text("速度缓慢/没有响应").tag(3)
                            Text("建议").tag(1)
                        }
                    }
                    Section {
                        if !dontSendDiagnose {
                            NavigationLink(destination: {
                                List {
                                    NavigationLink(destination: {
                                        List {
                                            NavigationLink(destination: {
                                                ScrollView {
                                                    HStack {
                                                        Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)")
                                                            .font(.system(size: 13, design: .monospaced))
                                                            .multilineTextAlignment(.leading)
                                                        Spacer()
                                                    }
                                                }
                                            }, label: {
                                                HStack {
                                                    Image(systemName: "doc")
                                                        .foregroundColor(.purple)
                                                    Text("Version.drkdatav")
                                                        .font(.system(size: 12))
                                                        .lineLimit(1)
                                                }
                                            })
                                            NavigationLink(destination: {
                                                ScrollView {
                                                    HStack {
                                                        Text("\(WKInterfaceDevice.current().systemVersion)")
                                                            .font(.system(size: 13, design: .monospaced))
                                                            .multilineTextAlignment(.leading)
                                                        Spacer()
                                                    }
                                                }
                                            }, label: {
                                                HStack {
                                                    Image(systemName: "doc")
                                                        .foregroundColor(.purple)
                                                    Text("OS.drkdatao")
                                                        .font(.system(size: 12))
                                                        .lineLimit(1)
                                                }
                                            })
                                            NavigationLink(destination: {
                                                ScrollView {
                                                    HStack {
                                                        Text("\(getWebHistory().map { $0.url.prefix(100) }.prefix(3))")
                                                            .font(.system(size: 13, design: .monospaced))
                                                            .multilineTextAlignment(.leading)
                                                        Spacer()
                                                    }
                                                }
                                            }, label: {
                                                HStack {
                                                    Image(systemName: "doc")
                                                        .foregroundColor(.purple)
                                                    Text("NearestHistories.drkdatan")
                                                        .font(.system(size: 12))
                                                        .lineLimit(1)
                                                }
                                            })
                                            if let settings = getAllSettingsForAppdiagnose() {
                                                NavigationLink(destination: {
                                                    ScrollView {
                                                        HStack {
                                                            Text(settings)
                                                                .font(.system(size: 13, design: .monospaced))
                                                                .multilineTextAlignment(.leading)
                                                            Spacer()
                                                        }
                                                    }
                                                }, label: {
                                                    HStack {
                                                        Image(systemName: "doc")
                                                            .foregroundColor(.purple)
                                                        Text("Settings.drkdatas")
                                                            .font(.system(size: 12))
                                                            .lineLimit(1)
                                                    }
                                                })
                                            }
                                        }
                                    }, label: {
                                        HStack {
                                            Image(systemName: "folder")
                                                .foregroundColor(.purple)
                                            Text("appdiagnose")
                                                .font(.system(size: 12))
                                                .lineLimit(1)
                                        }
                                    })
                                }
                                .navigationTitle("appdiagnose Logs")
                            }, label: {
                                HStack {
                                    Text("DarockBrowser Appdiagnose")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    isRemoveDiagAlertPresented = true
                                }, label: {
                                    Image(systemName: "xmark.circle.fill")
                                })
                            }
                        }
                        if !extHistories.isEmpty {
                            ForEach(0..<extHistories.count, id: \.self) { i in
                                Label(extHistories[i], systemImage: "clock")
                                    .font(.system(size: 13))
                                    .lineLimit(2)
                                    .swipeActions {
                                        Button(role: .destructive, action: {
                                            extHistories.remove(at: i)
                                        }, label: {
                                            Image(systemName: "xmark.circle.fill")
                                        })
                                    }
                            }
                        }
                        Button(action: {
                            isDetailSelectorPresented = true
                        }, label: {
                            Label("添加附件", systemImage: "paperclip")
                                .foregroundColor(.purple)
                        })
                        .sheet(isPresented: $isDetailSelectorPresented, content: {
                            NavigationView {
                                List {
                                    NavigationLink(destination: {
                                        HistoryView { sel in
                                            extHistories.append(sel)
                                            isDetailSelectorPresented = false
                                        }
                                        .navigationTitle("选取历史记录")
                                    }, label: {
                                        HStack {
                                            Text("历史记录")
                                            Spacer()
                                            Image(systemName: "clock")
                                        }
                                    })
                                }
                                .navigationTitle("添加附件")
                            }
                        })
                    } header: {
                        Text("附件")
                    } footer: {
                        Text("由“反馈助理”收集的诊断数据可能包含个人信息。你可以在提交前轻点查看附加数据，或向左轻扫删除。")
                    }
                    Section {
                        Button(action: {
                            if titleInput.isEmpty {
                                tipWithText("标题不能为空", symbol: "xmark.circle.fill")
                                return
                            }
                            if issuePlace.isEmpty {
                                tipWithText("需选择问题区域", symbol: "xmark.circle.fill")
                                withAnimation {
                                    scrollProxy.scrollTo(issuePlaceSelectorId)
                                }
                                return
                            }
                            isSending = true
                            let extDiags = { () -> String in
                                if _fastPath(!dontSendDiagnose) {
                                    var extData = """
                                    
                                    Version：v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)
                                    NearestHistories：\(getWebHistory().map { $0.url.prefix(100) }.prefix(3))
                                    OS：\(WKInterfaceDevice.current().systemVersion)
                                    DeviceModelName：\(WKInterfaceDevice.modelName) (\(WKInterfaceDevice.modelIdentifier))
                                    """
                                    if let settings = getAllSettingsForAppdiagnose() {
                                        _onFastPath()
                                        extData += "\nSettings：\(settings)"
                                    }
                                    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/NSExceptionLogs") {
                                        do {
                                            var content = ""
                                            var latestTime = 0.0
                                            for file in try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/NSExceptionLogs") {
                                                if let time = Double(file.dropLast(4)), time > latestTime {
                                                    content = try String(
                                                        contentsOfFile: NSHomeDirectory() + "/Documents/NSExceptionLogs/" + file,
                                                        encoding: .utf8
                                                    )
                                                    latestTime = time
                                                }
                                            }
                                            if !content.isEmpty {
                                                extData += "\nLatestNSException：\(content.replacingOccurrences(of: "\n", with: "\\n"))\nLatestNSExceptionTime：\(latestTime)"
                                            }
                                        } catch {
                                            globalErrorHandler(error)
                                        }
                                    }
                                    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/SwiftErrorLogs") {
                                        do {
                                            var content = ""
                                            var latestTime = 0.0
                                            for file in try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/SwiftErrorLogs") {
                                                if let time = Double(file.dropLast(4)), time > latestTime {
                                                    content = try String(
                                                        contentsOfFile: NSHomeDirectory() + "/Documents/SwiftErrorLogs/" + file,
                                                        encoding: .utf8
                                                    )
                                                    latestTime = time
                                                }
                                            }
                                            if !content.isEmpty {
                                                extData += "\nLatestSwiftError：\(content.replacingOccurrences(of: "\n", with: "\\n"))\nLatestSwiftErrorTime：\(latestTime)"
                                            }
                                        } catch {
                                            globalErrorHandler(error)
                                        }
                                    }
                                    return extData
                                } else {
                                    return ""
                                }
                            }()
                            var tagsString = ""
                            switch feedbackType {
                            case 0:
                                tagsString += "bug&&&0.7098039388656616,0.10196077078580856,0.0"
                            case 1:
                                tagsString += "优化&&&0.03921568766236305,0.5176469087600708,1.0"
                            case 2:
                                tagsString += "bug&&&0.7098039388656616,0.10196077078580856,0.0<****>崩溃&&&0.7098039388656616,0.10196077078580856,0.0"
                            case 3:
                                tagsString += "App 无响应&&&0.7686275243759155,0.7372550368309021,0.0"
                            default: break
                            }
                            if !tagsString.isEmpty {
                                tagsString += "<****>"
                            }
                            tagsString += issuePlace
                            let msgToSend = """
                            \(titleInput)
                            State：0
                            Type：\(feedbackType)
                            Content：\(contentInputs.joined(separator: "\\n"))
                            Time：\(Date.now.timeIntervalSince1970)\(extDiags)\(!extHistories.isEmpty ? "\nExtHistories：" + extHistories.description : "")
                            NotificationToken：\(UserDefaults.standard.string(forKey: "UserNotificationToken") ?? "None")
                            Sender: User
                            UpdateTags：\(tagsString)
                            """
                            DarockKit.Network.shared
                                .requestString("https://fapi.darock.top:65535/feedback/submit/anony/Darock Browser/\(msgToSend.base64Encoded().replacingOccurrences(of: "/", with: "{slash}"))".compatibleUrlEncoded()) { respStr, isSuccess in
                                    if isSuccess {
                                        if Int(respStr) != nil {
                                            var arr = UserDefaults.standard.stringArray(forKey: "RadarFBIDs") ?? [String]()
                                            arr.insert(respStr, at: 0)
                                            UserDefaults.standard.set(arr, forKey: "RadarFBIDs")
                                            tipWithText("已发送", symbol: "paperplane.fill")
                                            presentationMode.wrappedValue.dismiss()
                                        } else {
                                            tipWithText("服务器错误", symbol: "xmark.circle.fill")
                                        }
                                    }
                                }
                        }, label: {
                            if !isSending {
                                Text("提交")
                            } else {
                                ProgressView()
                            }
                        })
                        .disabled(isSending)
                    }
                }
            }
            .navigationTitle("提交反馈")
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        if !isSending && !titleInput.isEmpty || contentInputs != [""] {
                            isDraftAlertPresented = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }, label: {
                        Image(systemName: "chevron.backward")
                    })
                }
            }
            .onAppear {
                if !isDraftLoaded {
                    titleInput = UserDefaults.standard.string(forKey: "FeedbackNewDraftTitle") ?? ""
                    contentInputs = UserDefaults.standard.stringArray(forKey: "FeedbackNewDraftContent") ?? [""]
                    isDraftLoaded = true
                }
                
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { isGrand, _ in
                    DispatchQueue.main.async {
                        if isGrand {
                            WKExtension.shared().registerForRemoteNotifications()
                        }
                    }
                }
            }
            .alert("移除诊断信息", isPresented: $isRemoveDiagAlertPresented, actions: {
                Button(role: .destructive, action: {
                    dontSendDiagnose = true
                }, label: {
                    Text("移除诊断信息")
                })
                Button(role: .cancel, action: {
                    
                }, label: {
                    Text("取消")
                        .bold()
                })
            }, message: {
                Text("移除诊断信息会限制 Darock 理解并解决问题的能力。")
            })
            .alert("未完成的编辑", isPresented: $isDraftAlertPresented, actions: {
                Button(role: .destructive, action: {
                    UserDefaults.standard.removeObject(forKey: "FeedbackNewDraftTitle")
                    UserDefaults.standard.removeObject(forKey: "FeedbackNewDraftContent")
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("删除草稿")
                })
                Button(role: .cancel, action: {
                    UserDefaults.standard.set(titleInput, forKey: "FeedbackNewDraftTitle")
                    UserDefaults.standard.set(contentInputs, forKey: "FeedbackNewDraftContent")
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("存储草稿")
                })
            }, message: {
                Text("你要存储当前的草稿吗？")
            })
        }
    }
    struct FeedbackDetailView: View {
        var id: String
        private let projName = "Darock Browser"
        @Environment(\.presentationMode) var presentationMode
        @State var feedbackText = ""
        @State var formattedTexts = [String]()
        @State var replies = [[String]]()
        @State var isNoReply = true
        @State var isReplyPresented = false
        @State var replyInput = ""
        @State var isReplySubmitted = false
        @State var isReplyDisabled = false
        var body: some View {
            Form {
                if formattedTexts.count != 0 {
                    getView(from: formattedTexts)
                }
                if !isNoReply {
                    ForEach(0..<replies.count, id: \.self) { i in
                        if !replies[i].contains(where: { $0.hasPrefix("Sender：_") }) {
                            getView(from: replies[i], isReply: true)
                        }
                    }
                }
                Section {
                    Button(action: {
                        isReplyPresented = true
                    }, label: {
                        Label("回复", systemImage: "arrowshape.turn.up.left.2")
                    })
                    .disabled(isReplyDisabled)
                } footer: {
                    if isReplyDisabled {
                        Text("此反馈已关闭，若要重新进行反馈，请创建一个新的反馈")
                    }
                }
            }
            .sheet(isPresented: $isReplyPresented, onDismiss: {
                refresh()
            }, content: {
                TextField("回复信息", text: $replyInput) {
                    if isReplySubmitted {
                        return
                    }
                    isReplySubmitted = true
                    if replyInput != "" {
                        let enced = """
                        Content：\(replyInput)
                        Sender：User
                        Time：\(Date.now.timeIntervalSince1970)
                        """.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")
                        DarockKit.Network.shared
                            .requestString("https://fapi.darock.top:65535/radar/reply/Darock Browser/\(id)/\(enced)".compatibleUrlEncoded()) { respStr, isSuccess in
                                if isSuccess {
                                    if respStr.apiFixed() == "Success" {
                                        refresh()
                                        replyInput = ""
                                        isReplyPresented = false
                                    } else {
                                        tipWithText("未知错误", symbol: "xmark.circle.fill")
                                    }
                                    isReplySubmitted = false
                                }
                            }
                    }
                }
            })
            .navigationTitle(id)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refresh()
            }
        }
        
        @inline(__always)
        func refresh() {
            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/details/\(projName)/\(id)".compatibleUrlEncoded()) { respStr, isSuccess in
                if isSuccess {
                    formattedTexts.removeAll()
                    replies.removeAll()
                    feedbackText = respStr.apiFixed()
                        .replacingOccurrences(of: "\\\\n", with: "____LINEBREAK_REPLACE_TOKEN____")
                        .replacingOccurrences(of: "\\n", with: "\n")
                        .replacingOccurrences(of: "____LINEBREAK_REPLACE_TOKEN____", with: "\\n")
                        .replacingOccurrences(of: "\\\"", with: "\"")
                    let spd = feedbackText.split(separator: "\n")
                    for text in spd {
                        if text == "---" { break }
                        formattedTexts.append(String(text))
                    }
                    if feedbackText.split(separator: "---").count > 1 {
                        let repliesText = Array(feedbackText.split(separator: "---").dropFirst()).map { String($0) }
                        for text in repliesText {
                            let spd = text.split(separator: "\n").map { String($0) }
                            var tar = [String]()
                            for lt in spd {
                                tar.append(lt)
                                if _slowPath(lt.hasPrefix("State：")) {
                                    if let st = Int(String(lt.dropFirst(6))) {
                                        isReplyDisabled = st == 1 || st == 2 || st == 3 || st == 7 || st == 10
                                    }
                                }
                            }
                            replies.append(tar)
                        }
                        
                        isNoReply = false
                    }
                    UserDefaults.standard.set(feedbackText.split(separator: "---").count, forKey: "RadarFB\(id)ReplyCount")
                }
            }
        }
        
        @ViewBuilder
        func getView(from: [String], isReply: Bool = false) -> some View {
            VStack {
                ForEach(0..<from.count, id: \.self) { j in
                    if from[j].hasPrefix("Sender") {
                        HStack {
                            Text(from[j].dropFirst(7))
                                .font(.system(size: 18))
                                .bold()
                            Spacer()
                        }
                    }
                }
                ForEach(0..<from.count, id: \.self) { j in
                    if from[j].hasPrefix("Time") {
                        if let intt = Double(String(from[j].dropFirst(5))) {
                            HStack {
                                Text({ () -> String in
                                    let df = DateFormatter()
                                    df.dateFormat = "yyyy-MM-dd hh:mm:ss"
                                    return df.string(from: Date(timeIntervalSince1970: intt))
                                }())
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                                Spacer()
                            }
                        }
                    }
                }
                Divider()
                if !isReply {
                    HStack {
                        Text(from[0])
                            .font(.system(size: 18))
                            .bold()
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    Divider()
                }
                ForEach(0...from.count - 1, id: \.self) { i in
                    if !(!from[i].contains("：") && !from[i].contains(":") && i == 0)
                        // ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        //                       Not Title
                        && (!from[i].hasPrefix("Sender")) && (!from[i].hasPrefix("Time")) && !from[i].hasPrefix("_") {
                        // ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~      ^~~~~~~~~~~~~~~~~~~~~~~~~~~    ^~~~~~~~~~~~~~~~~~~~~~~
                        //          Not Sender                         Not Time                 Not Internal Field
                        if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") != "" {
                            HStack {
                                Text(from[i].contains("：") && from[i] != "：" ? String(from[i].split(separator: "：")[0]).titleReadable() : "")
                                    .font(.system(size: 17))
                                    .bold()
                                Spacer()
                            }
                        }
                        HStack {
                            if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "State" {
                                if let index = Int(from[i].split(separator: "：").count > 1 ? String(from[i].split(separator: "：")[1]) : from[i]) {
                                    HStack {
                                        Group {
                                            Image(systemName: globalStateIcons[index])
                                            Text(globalStates[index])
                                        }
                                        .foregroundStyle(globalStateColors[index])
                                        .font(.system(size: 14))
                                    }
                                } else {
                                    Text(from[i].split(separator: "：").count > 1 ? String(from[i].split(separator: "：")[1]) : from[i])
                                        .font(.system(size: 14))
                                }
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "NotificationToken" {
                                Text("[Hex Data]")
                                    .font(.system(size: 14))
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "Settings" {
                                Text("[Privacy Hidden]")
                                    .font(.system(size: 14))
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "LatestNSException" {
                                Text("[Large Data]")
                                    .font(.system(size: 14))
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "LatestSwiftError" {
                                Text("[Large Data]")
                                    .font(.system(size: 14))
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "UpdateTitle" {
                                if let source = from[i].split(separator: "：")[from: 1]?.split(separator: "__->__")[from: 0],
                                   let to = from[i].split(separator: "：")[from: 1]?.split(separator: "__->__")[from: 1] {
                                    Markdown("~\(source)~ → **\(to)**")
                                        .markdownTheme(.gitHub)
                                }
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "UpdateTags" {
                                if let combined = from[i].split(separator: "：")[from: 1] {
                                    let tags = Array<FeedbackTag>(fromCombined: String(combined))
                                    if !tags.isEmpty {
                                        VStack {
                                            ScrollView(.horizontal) {
                                                HStack {
                                                    ForEach(0..<tags.count, id: \.self) { i in
                                                        Text(tags[i].name)
                                                            .font(.system(size: 15, weight: .semibold))
                                                            .foregroundStyle(.white)
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 3)
                                                            .background {
                                                                if #available(watchOS 10.0, *) {
                                                                    Capsule()
                                                                        .fill(tags[i].color)
                                                                        .stroke(Material.ultraThin.opacity(0.2), lineWidth: 2)
                                                                } else {
                                                                    tags[i].color
                                                                        .clipShape(Capsule())
                                                                }
                                                            }
                                                    }
                                                }
                                            }
                                            .scrollIndicators(.never)
                                            if NSLocale.current.language.languageCode!.identifier != "zh" {
                                                Text("标签不会被本地化，因为它们是动态添加的。")
                                            }
                                        }
                                    }
                                }
                            } else if (from[i].contains("：") && from[i] != "："
                                       ? from[i].split(separator: "：")[0]
                                       : "") == "AddDuplicateDelete"
                                        || (from[i].contains("：") && from[i] != "："
                                            ? from[i].split(separator: "：")[0]
                                            : "") == "DuplicateTo",
                                      let goId = Int(from[i].split(separator: "：")[1]) {
                                Text("FB\(projName.projNameLinked())\(String(goId))")
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "MarkdownContent" {
                                Markdown(
                                    (from[i].split(separator: "：").count > 1
                                     ? String(from[i].split(separator: "：", maxSplits: 1)[1])
                                     : from[i]).replacingOccurrences(of: "\\n", with: "\n")
                                )
                                .markdownTheme(.gitHub)
                                .font(.system(size: 14))
                                .environment(\.openURL, OpenURLAction { url in
                                    AdvancedWebViewController.shared.present(url.absoluteString)
                                    return .handled
                                })
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") != "NearestHistories" {
                                Text(
                                    (from[i].split(separator: "：").count > 1
                                    ? String(from[i].split(separator: "：", maxSplits: 1)[1])
                                     : from[i]).replacingOccurrences(of: "\\n", with: "\n")
                                )
                                .font(.system(size: 14))
                            }
                            Spacer()
                        }
                        if i != from.count - 1 {
                            Spacer()
                                .frame(height: 10)
                        }
                    }
                }
            }
        }
    }
}

private struct NewsView: View {
    let projName = "Darock Browser"
    @State var news: [SingleNewsFile]?
    var body: some View {
        List {
            if let news {
                if !news.isEmpty {
                    ForEach(0..<news.count, id: \.self) { i in
                        VStack(alignment: .leading) {
                            NavigationLink(destination: { NewsDetailView(projName: projName, id: news[i].id) }, label: {
                                HStack {
                                    if news[i].isUnread {
                                        Circle()
                                            .fill(Color.purple)
                                            .frame(width: 8, height: 8)
                                    }
                                    Text(news[i].title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    Spacer()
                                    Text({
                                        let df = DateFormatter()
                                        df.dateFormat = "yy/MM/dd"
                                        return df.string(from: Date(timeIntervalSince1970: news[i].time))
                                    }())
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                }
                            })
                            Text(news[i].type)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "newspaper.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            Text("无新闻")
                                .font(.headline)
                                .padding(.vertical)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            } else {
                ProgressView()
                    .centerAligned()
            }
        }
        .refreshable(action: refreshNews)
        .navigationTitle("新闻列表")
        .onAppear {
            Task {
                await refreshNews()
            }
        }
    }
    
    @Sendable
    func refreshNews() async {
        let result = await DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/news/get/\(projName)".compatibleUrlEncoded())
        if case .success(let respStr) = result {
            let fixed = respStr.apiFixed()
            if fixed != "None" {
                let spd = fixed.split(separator: "|").map { String($0) }
                var fcp = [SingleNewsFile]()
                let readNewsIDs = UserDefaults.standard.stringArray(forKey: "ReadNewsIDs") ?? []
                for text in spd {
                    let partSpd = text.split(separator: "^^").map { String($0) }
                    if let id = partSpd[from: 0],
                       let title = partSpd[from: 1],
                       let type = partSpd[from: 2],
                       let time = partSpd[from: 3],
                       let doubleTime = Double(time) {
                        fcp.append(.init(id: id, title: title, type: type, time: doubleTime, isUnread: !readNewsIDs.contains(id)))
                    }
                }
                news = fcp.sorted { lhs, rhs in
                    return lhs.time > rhs.time
                }
            } else {
                news = []
            }
        }
    }
    
    struct NewsDetailView: View {
        var projName: String
        var id: String
        @Environment(\.presentationMode) var presentationMode
        @State var isLoading = true
        @State var isUnavailableAlertPresented = false
        @State var sourceText = ""
        @State var title = ""
        @State var type = ""
        @State var content = ""
        var body: some View {
            ScrollView {
                if !isLoading {
                    Markdown(content)
                        .markdownTheme(.github)
                } else {
                    ProgressView()
                }
            }
            .refreshable(action: refresh)
            .navigationTitle(title.isEmpty ? id : title)
            .navigationBarTitleDisplayMode(.inline)
            .alert("无法载入新闻", isPresented: $isUnavailableAlertPresented, actions: {
                Button(role: .cancel, action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("确认")
                })
            }, message: {
                Text("该新闻不存在")
            })
            .onAppear {
                Task {
                    await refresh()
                }
                let readList = UserDefaults.standard.stringArray(forKey: "ReadNewsIDs") ?? []
                if !readList.contains(id) {
                    UserDefaults.standard.set(readList + [id], forKey: "ReadNewsIDs")
                }
            }
        }
        
        @Sendable
        func refresh() async {
            isLoading = true
            let result = await DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/news/detail/\(projName)/\(id)".compatibleUrlEncoded())
            if case let .success(respStr) = result {
                guard respStr.apiFixed() != "Not Exist" else {
                    isUnavailableAlertPresented = true
                    return
                }
                sourceText = respStr.apiFixed()
                    .replacingOccurrences(of: "\\\\n", with: "____LINEBREAK_REPLACE_TOKEN____")
                    .replacingOccurrences(of: "\\n", with: "\n")
                    .replacingOccurrences(of: "____LINEBREAK_REPLACE_TOKEN____", with: "\\n")
                    .replacingOccurrences(of: "\\\"", with: "\"")
                let sourceSpd = sourceText.split(separator: "\n").map { String($0) }
                title = sourceSpd[from: 0] ?? ""
                type = sourceSpd[from: 1] ?? ""
                content = sourceSpd.dropFirst(3).joined(separator: "\n")
            }
            isLoading = false
        }
    }
}
private struct SingleNewsFile: Identifiable {
    var id: String
    var title: String
    var type: String
    var time: TimeInterval
    var isUnread: Bool
}

struct FAQView: View {
    var body: some View {
        List {
            NavigationLink(destination: {
                ScrollView {
                    Markdown(String(localized: """
                    **并非所有网页内的视频均能被解析**
                    
                    请**不要**提出网站视频无法播放之类的反馈
                    """))
                }
            }, label: {
                Text("关于视频...")
            })
            NavigationLink(destination: {
                ScrollView {
                    Markdown(String(localized: """
                    在少数情况下，播放视频时可能会出现**只有声音，没有画面或画面卡住**的情况。
                    
                    遇到此类情况，重启 Apple Watch 即可解决，请勿提交反馈。
                    """))
                }
            }, label: {
                Text("关于视频播放卡住...")
            })
            NavigationLink(destination: {
                ScrollView {
                    Markdown(String(localized: """
                    **并非所有网页都能在 Apple Watch 上正常工作**
                    
                    请**不要**提出网站*打不开*、*有问题*之类的反馈
                    """))
                }
            }, label: {
                Text("关于网页适配...")
            })
            NavigationLink(destination: {
                ScrollView {
                    Markdown(String(localized: """
                    单独为特定的网页优化根本**不可行**。
                    
                    想想今天让为网站A进行优化，明天另一个用户反馈想为网站B进行优化。不仅工作量大大提升，还会使代码极其难维护，这就是个无底洞。
                    
                    请**不要**提出为**特定网站**进行优化之类的反馈。
                    """))
                }
            }, label: {
                Text("关于特定网页优化...")
            })
        }
        .navigationTitle("常见问题")
    }
}
private struct StateMeaningsView: View {
    var body: some View {
        ScrollView {
            Text("""
            \(Text("\(Image(systemName: globalStateIcons[0]))未标记").foregroundColor(globalStateColors[0]))：反馈暂未被阅读，或是正在验证问题。
            
            \(Text("\(Image(systemName: globalStateIcons[1]))按预期工作").foregroundColor(globalStateColors[1]))：报告中描述的是预期中的表现。
            
            \(Text("\(Image(systemName: globalStateIcons[2]))无法修复").foregroundColor(globalStateColors[2]))：报告中的问题无法被修复，或是不具有可行性。
            
            \(Text("\(Image(systemName: globalStateIcons[3]))问题重复").foregroundColor(globalStateColors[3]))：在你提交此报告前，已有另一人提出了相同的问题，你仍会在第一个报告得到修复后收到“已修复”的状态更新。
                    你的报告可能会与那些初看似乎具有相同根源的类似报告分到一组。但是，类似的报告也可能包含多种原因。如果你发现该修复方案解决了类似报告中的问题，但无法完全解决你报告的问题，请提交新报告。
            
            \(Text("\(Image(systemName: globalStateIcons[4]))搁置").foregroundColor(globalStateColors[4]))：短时间内可能无法解决此问题。
            
            \(Text("\(Image(systemName: globalStateIcons[5]))正在修复").foregroundColor(globalStateColors[5]))：Darock 正在为此问题提供修复方案。
            
            \(Text("\(Image(systemName: globalStateIcons[6]))已在未来版本修复").foregroundColor(globalStateColors[6]))：修复工作已完成，但还未提交更新或是更新正在等待发布。
            
            \(Text("\(Image(systemName: globalStateIcons[7]))已修复").foregroundColor(globalStateColors[7]))：修复工作已完成，可更新至最新版本验证修复。
            
            \(Text("\(Image(systemName: globalStateIcons[9]))未能复现").foregroundColor(globalStateColors[9]))：未能通过报告中的问题复现问题，需要提供更多信息。
            
            \(Text("\(Image(systemName: globalStateIcons[10]))问题并不与 App 相关").foregroundColor(globalStateColors[10]))：报告与 App 本身无关，或是问题并非由 App 本身引起。
            
            \(Text("\(Image(systemName: globalStateIcons[11]))需要更多细节").foregroundColor(globalStateColors[11]))：提供的信息不足以让我们确定问题，你需要补充更多信息。
            """)
        }
        .navigationTitle("反馈状态")
    }
}

extension String {
    @_effects(readnone)
    func dropFirst(_ k: Character) -> String {
        if self.hasPrefix(String(k)) {
            return String(self.dropFirst())
        } else {
            return self
        }
    }
    @_effects(readnone)
    func dropLast(_ k: Character) -> String {
        if self.hasSuffix(String(k)) {
            return String(self.dropLast())
        } else {
            return self
        }
    }
    @_effects(readnone)
    func projNameLinked() -> Self {
        let shortMd5d = String(self.md5.prefix(8)).lowercased()
        let a2nchart: [Character: Int] = ["a": 0, "b": 1, "c": 2, "d": 3, "e": 4, "f": 5, "g": 6, "h": 7, "i": 8, "j": 9, "k": 0, "l": 1, "m": 2, "n": 3, "o": 4, "p": 5, "q": 6, "r": 7, "s": 8, "t": 9, "u": 0, "v": 1, "w": 2, "x": 3, "y": 4, "z": 5] // swiftlint:disable:this line_length
        var ced = ""
        for c in shortMd5d {
            if Int(String(c)) == nil {
                ced += String(a2nchart[c]!)
            } else {
                ced += String(c)
            }
        }
        return ced
    }
    @_effects(readnone)
    func titleReadable() -> LocalizedStringKey {
        switch self {
        case "State":
            return "状态"
        case "Type":
            return "类型"
        case "Content", "MarkdownContent":
            return "描述"
        case "Version":
            return "App 版本"
        case "OS":
            return "系统版本"
        case "ExtHistories":
            return "额外历史记录"
        case "DuplicateTo":
            return "与此反馈重复"
        case "AddDuplicateDelete":
            return "关联反馈"
        case "NotificationToken":
            return "通知令牌"
        case "UpdateTags":
            return "更新标签"
        case "Settings":
            return "设置"
        default:
            return LocalizedStringKey(self)
        }
    }
}
extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

@_effects(readonly)
func getAllSettingsForAppdiagnose() -> String? {
    let prefPath = NSHomeDirectory() + "/Library/Preferences/com.darock.WatchBrowser.watchkitapp.plist"
    if let plistData = FileManager.default.contents(atPath: prefPath) {
        do {
            if var plistObject = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                plistObject.removeValue(forKey: "CurrentTabs")
                plistObject.removeValue(forKey: "WebHistory")
                plistObject.removeValue(forKey: "UserPasscodeEncrypted")
                let removeKeyPrefixs = ["VideoProgressForLink", "WebHistory", "VideoMarkForLink", "BookmarkLink", "BookmarkName"]
                for key in plistObject.keys where removeKeyPrefixs.contains(where: { key.hasPrefix($0) }) {
                    plistObject.removeValue(forKey: key)
                }
                let jsonData = try JSONSerialization.data(withJSONObject: plistObject)
                return String(decoding: jsonData, as: UTF8.self)
            }
        } catch {
            globalErrorHandler(error)
        }
    }
    return nil
}

struct FeedbackTag: Equatable {
    var name: String
    var color: Color
    
    init(name: String, color: Color) {
        self.name = name
        self.color = color
    }
    init?(fromCombined string: String) {
        let spd = string.components(separatedBy: "&&&")
        if let name = spd[from: 0], let colors = spd[from: 1] {
            let colorSplited = colors.components(separatedBy: ",")
            if let red = colorSplited[from: 0], let green = colorSplited[from: 1], let blue = colorSplited[from: 2],
               let red = Double(red), let green = Double(green), let blue = Double(blue) {
                self.name = name
                self.color = Color(red: red, green: green, blue: blue)
                return
            }
        }
        
        return nil
    }
    
    func toString() -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        return "\(name)&&&\(red),\(green),\(blue)"
    }
    
    static func == (lhs: FeedbackTag, rhs: FeedbackTag) -> Bool {
        return lhs.name == rhs.name
    }
}
extension Array<FeedbackTag> {
    init(fromCombined string: String) {
        var result = [FeedbackTag]()
        let spd = string.components(separatedBy: "<****>")
        for tag in spd {
            if let tag = FeedbackTag(fromCombined: tag) {
                result.append(tag)
            }
        }
        
        self = result
    }
    
    func toString() -> String {
        if isEmpty {
            return "[None]"
        }
        return map { $0.toString() }.joined(separator: "<****>")
    }
}
