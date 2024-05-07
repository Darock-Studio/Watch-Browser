//
//  FeedbackView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/2/23.
//

import SwiftUI
import DarockKit
import SwiftDate
import MarkdownUI

fileprivate let globalStates: [LocalizedStringKey] = ["未标记", "按预期工作", "无法修复", "问题重复", "搁置", "正在修复", "已在未来版本修复", "已修复", "正在加载", "未能复现", "问题并不与App相关", "需要更多细节", "被删除"]
fileprivate let globalStateColors = [Color.secondary, Color.red, Color.red, Color.red, Color.orange, Color.orange, Color.orange, Color.green, Color.secondary, Color.red, Color.secondary, Color.orange, Color.red]
fileprivate let globalStateIcons = ["minus", "curlybraces", "xmark", "arrow.triangle.merge", "books.vertical", "hammer", "clock.badge.checkmark", "checkmark", "ellipsis", "questionmark", "bolt.horizontal", "arrowshape.turn.up.backward.badge.clock", "xmark.square.fill"]

struct FeedbackView: View {
    @State var feedbackIds = [String]()
    @State var badgeOnIds = [String]()
    var body: some View {
        List {
            Section {
                NavigationLink(destination: { NewFeedbackView() }, label: {
                    Label("新建反馈", systemImage: "exclamationmark.bubble.fill")
                })
                NavigationLink(destination: { FAQView() }, label: {
                    Label("常见问题", systemImage: "sparkles")
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
        .onAppear {
            feedbackIds = UserDefaults.standard.stringArray(forKey: "RadarFBIDs") ?? [String]()
            badgeOnIds.removeAll()
            for id in feedbackIds {
                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/details/Darock Browser/\(id)") { respStr, isSuccess in
                    if isSuccess {
                        let repCount = respStr.apiFixed().components(separatedBy: "---").count - 1
                        let lastViewCount = UserDefaults.standard.integer(forKey: "RadarFB\(id)ReplyCount")
                        if repCount > lastViewCount {
                            badgeOnIds.append(id)
                        }
                    }
                }
            }
        }
    }
    
    struct NewFeedbackView: View {
        @Environment(\.dismiss) var dismiss
        @State var titleInput = ""
        @State var contentInputs = [""]
        @State var feedbackType = 0
        @State var isSending = false
        @State var isDetailSelectorPresented = false
        @State var extHistories = [String]()
        @State var dontSendDiagnose = false
        @State var isRemoveDiagAlertPresented = false
        var body: some View {
            Form {
                List {
                    Section {
                        TextField("标题", text: $titleInput)
                    } header: {
                        Text("请为你的反馈提供描述性的标题：")
                    } footer: {
                        Text("示例：历史记录缺少最近的浏览数据")
                    }
                    Section {
                        ForEach(0..<contentInputs.count, id: \.self) { i in
                            TextField("描述行\(i + 1)", text: $contentInputs[i])
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
                        Picker("反馈类型", selection: $feedbackType) {
                            Text("错误/异常行为").tag(0)
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
                                                            .font(.system(size: 13))
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
                                                            .font(.system(size: 13))
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
                                                        Text({ () -> String in
                                                            let histories = UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()
                                                            let sendHistories: [String]
                                                            if histories.count >= 3 {
                                                                sendHistories = [histories[0], histories[1], histories[2]]
                                                            } else if !histories.isEmpty {
                                                                sendHistories = histories
                                                            } else {
                                                                sendHistories = [String]()
                                                            }
                                                            return String(sendHistories.description.prefix(300))
                                                        }())
                                                        .font(.system(size: 13))
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
                                        }
                                        .navigationTitle("appdiagnose_\(Date.now.toString(.custom("yyyy.MM.dd_HH-mm-ssZZZZ")))")
                                    }, label: {
                                        HStack {
                                            Image(systemName: "folder")
                                                .foregroundColor(.purple)
                                            Text("appdiagnose_\(Date.now.toString(.custom("yyyy.MM.dd_HH-mm-ssZZZZ")))")
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
                                    NavigationLink(destination: {HistoryView(selectionHandler: { sel in
                                        extHistories.append(sel)
                                        isDetailSelectorPresented = false
                                    }).navigationTitle("选取历史记录")}, label: {
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
                            if titleInput == "" {
                                tipWithText("标题不能为空", symbol: "xmark.circle.fill")
                                return
                            }
                            isSending = true
                            let histories = UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()
                            let sendHistories: [String]
                            if histories.count >= 3 {
                                sendHistories = [histories[0], histories[1], histories[2]]
                            } else if !histories.isEmpty {
                                sendHistories = histories
                            } else {
                                sendHistories = [String]()
                            }
                            let extDiags = { () -> String in
                                if !dontSendDiagnose {
                                    return """
                                    
                                    Version：v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)
                                    NearestHistories：\(sendHistories.description.prefix(300))
                                    OS：\(WKInterfaceDevice.current().systemVersion)
                                    """
                                } else {
                                    return ""
                                }
                            }()
                            let msgToSend = """
                            \(titleInput)
                            State：0
                            Type：\(feedbackType)
                            Content：\(contentInputs.joined(separator: "\\n"))
                            Time：\(Date.now.timeIntervalSince1970)\(extDiags)\(!extHistories.isEmpty ? "\nExtHistories：" + extHistories.description : "")
                            Sender: User
                            """
                            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/feedback/submit/anony/Darock Browser/\(msgToSend.base64Encoded().replacingOccurrences(of: "/", with: "{slash}"))") { respStr, isSuccess in
                                if isSuccess {
                                    if Int(respStr) != nil {
                                        var arr = UserDefaults.standard.stringArray(forKey: "RadarFBIDs") ?? [String]()
                                        arr.insert(respStr, at: 0)
                                        UserDefaults.standard.set(arr, forKey: "RadarFBIDs")
                                        tipWithText("已发送", symbol: "paperplane.fill")
                                        dismiss()
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
        }
    }
    struct FeedbackDetailView: View {
        var id: String
        @State var title = ""
        @State var typeText = ""
        @State var content = ""
        @State var status = 8
        @State var replies = [(status: Int, content: String, sender: String)]()
        @State var isSendReplyPresented = false
        @State var replyInput = ""
        @State var isReplySubmitted = false
        var body: some View {
            List {
                Section {
                    Text(title)
                } header: {
                    Text("标题")
                }
                Section {
                    Text(typeText)
                } header: {
                    Text("类型")
                }
                Section {
                    Text(content)
                } header: {
                    Text("内容")
                }
                Section {
                    HStack {
                        Image(systemName: globalStateIcons[status])
                            .foregroundStyle(globalStateColors[status])
                        Text(globalStates[status])
                    }
                } header: {
                    Text("状态")
                }
                if replies.count != 0 {
                    ForEach(0..<replies.count, id: \.self) { i in
                        Section {
                            Divider()
                        } footer: {
                            Text("回复 \(i + 1)")
                        }
                        .listRowBackground(Color.clear)
                        Section {
                            Text(replies[i].sender)
                        } header: {
                            Text("来自")
                        }
                        if replies[i].sender != "User" && replies[i].status != 8 {
                            Section {
                                HStack {
                                    Image(systemName: globalStateIcons[replies[i].status])
                                        .foregroundStyle(globalStateColors[replies[i].status])
                                    Text(globalStates[replies[i].status])
                                }
                            } header: {
                                Text("状态")
                            }
                        }
                        if replies[i].content != "" {
                            Section {
                                Text(replies[i].content)
                            } header: {
                                Text("回复内容")
                            }
                        }
                    }
                }
                Section {
                    Button(action: {
                        isSendReplyPresented = true
                    }, label: {
                        Label("回复", systemImage: "arrowshape.turn.up.left.fill")
                    })
                    .disabled((replies.last?.status ?? 0) == 1 || (replies.last?.status ?? 0) == 2 || (replies.last?.status ?? 0) == 3 || (replies.last?.status ?? 0) == 7  || (replies.last?.status ?? 0) == 10 || status == 12)
                } footer: {
                    if (replies.last?.status ?? 0) == 1 || (replies.last?.status ?? 0) == 2 || (replies.last?.status ?? 0) == 3 || (replies.last?.status ?? 0) == 7 || (replies.last?.status ?? 0) == 10 {
                        Text("此反馈已关闭，若要重新进行反馈，请创建一个新的反馈")
                    }
                }
            }
            .navigationTitle(id)
            .onAppear {
                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/details/Darock Browser/\(id)") { respStr, isSuccess in
                    if isSuccess {
                        let lineSpd = respStr.apiFixed().components(separatedBy: "\\n").map { String($0) }
                        if lineSpd[0] == "nternal Server Erro" {
                            title = "本反馈已被删除"
                            status = 12
                            return
                        }
                        title = lineSpd[0]
                        for i in 1..<lineSpd.count {
                            if lineSpd[i] == "---" { break }
                            if lineSpd[i].split(separator: "：").count < 2 { continue }
                            let mspd = lineSpd[i].split(separator: "：").map { String($0) }
                            if mspd[0] == "State" {
                                status = Int(mspd[1]) ?? 8
                            } else if mspd[0] == "Content" {
                                content = mspd[1]
                            } else if mspd[0] == "Type" {
                                switch mspd[1] {
                                case "0":
                                    typeText = "错误/异常行为"
                                default:
                                    typeText = "建议"
                                }
                            }
                        }
                        let repSpd = respStr.apiFixed().components(separatedBy: "---").map { String($0) }
                        if repSpd.count > 1 {
                            for i in 1..<repSpd.count {
                                let lineSpd = repSpd[i].components(separatedBy: "\\n").map { String($0) }
                                var st = 8
                                var co = ""
                                var se = ""
                                for j in 0..<lineSpd.count {
                                    if lineSpd[j].split(separator: "：").count < 2 { continue }
                                    let mspd = lineSpd[j].split(separator: "：").map { String($0) }
                                    if mspd[0] == "State" {
                                        st = Int(mspd[1]) ?? 8
                                    } else if mspd[0] == "Content" {
                                        co = mspd[1]
                                    } else if mspd[0] == "Sender" {
                                        se = mspd[1]
                                    }
                                }
                                if se == "System" && st == 8 && co.isEmpty { // Radar Internal
                                    continue
                                }
                                replies.append((status: st, content: co, sender: se))
                            }
                        }
                        UserDefaults.standard.set(replies.count, forKey: "RadarFB\(id)ReplyCount")
                    }
                }
            }
            .onDisappear {
                UserDefaults.standard.set(replies.count, forKey: "RadarFB\(id)ReplyCount")
            }
            .sheet(isPresented: $isSendReplyPresented) {
                TextField("回复信息", text: $replyInput)
                    .onSubmit {
                        if isReplySubmitted {
                            return
                        }
                        isReplySubmitted = true
                        if replyInput != "" {
                            let enced = """
                            Content：\(replyInput)
                            Sender：User
                            """.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")
                            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/reply/Darock Browser/\(id)/\(enced)") { respStr, isSuccess in
                                if isSuccess {
                                    if respStr.apiFixed() == "Success" {
                                        replies.append((status: 8, content: replyInput, sender: "User"))
                                        replyInput = ""
                                        isSendReplyPresented = false
                                    } else {
                                        tipWithText("未知错误", symbol: "xmark.circle.fill")
                                    }
                                }
                            }
                        }
                    }
            }
        }
    }
}

struct FAQView: View {
    var body: some View {
        List {
            NavigationLink(destination: {
                ScrollView {
                    Markdown(String(localized: """
                    **并非所有网页内的视频均能被解析**
                    
                    请**不要**提出〇〇网站视频无法播放之类的反馈
                    """))
                }
            }, label: {
                Text("关于视频...")
            })
            NavigationLink(destination: {
                ScrollView {
                    Markdown(String(localized: """
                    **并非所有网页都能在 Apple Watch 上正常工作**
                    
                    请**不要**提出〇〇网站*打不开*、*有问题*之类的反馈
                    """))
                }
            }, label: {
                Text("关于网页适配...")
            })
        }
        .navigationTitle("常见问题")
    }
}
