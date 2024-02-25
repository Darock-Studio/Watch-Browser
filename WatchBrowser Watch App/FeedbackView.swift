//
//  FeedbackView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/2/23.
//

import SwiftUI
import DarockKit

fileprivate let globalStates: [LocalizedStringKey] = ["未标记", "按预期工作", "无法修复", "问题重复", "搁置", "正在修复", "已在未来版本修复", "已修复", "正在加载", "未能复现", "问题并不与App相关", "需要更多细节"]
fileprivate let globalStateColors = [Color.secondary, Color.red, Color.red, Color.red, Color.orange, Color.orange, Color.orange, Color.green, Color.secondary, Color.red, Color.secondary, Color.orange]
fileprivate let globalStateIcons = ["minus", "curlybraces", "xmark", "arrow.triangle.merge", "books.vertical", "hammer", "clock.badge.checkmark", "checkmark", "ellipsis", "questionmark", "bolt.horizontal", "arrowshape.turn.up.backward.badge.clock"]

struct FeedbackView: View {
    @State var feedbackIds = [String]()
    var body: some View {
        List {
            Section {
                NavigationLink(destination: { NewFeedbackView() }, label: {
                    Label("新建反馈", systemImage: "exclamationmark.bubble.fill")
                })
            }
            if feedbackIds.count != 0 {
                Section {
                    ForEach(0..<feedbackIds.count, id: \.self) { i in
                        NavigationLink(destination: { FeedbackDetailView(id: feedbackIds[i]) }, label: {
                            Text("ID: \(feedbackIds[i])")
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
        }
    }
    
    struct NewFeedbackView: View {
        @Environment(\.dismiss) var dismiss
        @State var titleInput = ""
        @State var contentInput = ""
        @State var feedbackType = 0
        @State var isSending = false
        var body: some View {
            List {
                Section {
                    TextField("标题", text: $titleInput)
                } footer: {
                    Text("简洁地描述问题")
                }
                Section {
                    TextField("详情", text: $contentInput)
                }
                Section {
                    Picker("反馈类型", selection: $feedbackType) {
                        Text("错误/异常行为").tag(0)
                        Text("建议").tag(1)
                    }
                }
                Section {
                    Button(action: {
                        if titleInput == "" {
#if os(watchOS) || os(visionOS)
                            tipWithText("标题不能为空", symbol: "xmark.circle.fill")
#else
                            AlertKitAPI.present(title: "标题不能为空", icon: .error, style: .iOS17AppleMusic, haptic: .error)
#endif
                            return
                        }
                        isSending = true
                        let msgToSend = """
                        \(titleInput)
                        State：0
                        Type：\(feedbackType)
                        Content：\(contentInput)
                        Version：v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)
                        Time：\(Date.now.timeIntervalSince1970)
                        Sender: User
                        """
                        DarockKit.Network.shared.requestString("https://api.darock.top/feedback/submit/anony/Darock Browser/\(msgToSend.base64Encoded().replacingOccurrences(of: "/", with: "{slash}"))") { respStr, isSuccess in
                            if isSuccess {
                                if Int(respStr) != nil {
                                    var arr = UserDefaults.standard.stringArray(forKey: "RadarFBIDs") ?? [String]()
                                    arr.insert(respStr, at: 0)
                                    UserDefaults.standard.set(arr, forKey: "RadarFBIDs")
#if os(watchOS) || os(visionOS)
                                    tipWithText("已发送", symbol: "paperplane.fill")
#else
                                    AlertKitAPI.present(title: "已发送", icon: .done, style: .iOS17AppleMusic, haptic: .success)
#endif
                                    dismiss()
                                } else {
#if os(watchOS) || os(visionOS)
                                    tipWithText("服务器错误", symbol: "xmark.circle.fill")
#else
                                    AlertKitAPI.present(title: "服务器错误", icon: .error, style: .iOS17AppleMusic, haptic: .error)
#endif
                                }
                            }
                        }
                    }, label: {
                        if !isSending {
                            Text("发送")
                        } else {
                            ProgressView()
                        }
                    })
                    .disabled(isSending)
                } footer: {
                    Text("Darock 会收集必要的诊断信息以便进行改进，信息不会关联到您个人。如果您不愿意被收集信息，请勿发送。")
                }
            }
        }
    }
    struct FeedbackDetailView: View {
        var id: String
        @State var title = ""
        @State var typeText = ""
        @State var content = ""
        @State var status = 8
        @State var replies = [(status: Int, content: String, sender: String)]()
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
                        Section {
                            HStack {
                                Image(systemName: globalStateIcons[replies[i].status])
                                    .foregroundStyle(globalStateColors[replies[i].status])
                                Text(globalStates[replies[i].status])
                            }
                        } header: {
                            Text("状态")
                        }
                        Section {
                            Text(replies[i].content)
                        } header: {
                            Text("回复内容")
                        }
                    }
                }
            }
            .navigationTitle(id)
            .onAppear {
                DarockKit.Network.shared.requestString("https://api.darock.top/radar/details/Darock Browser/\(id)") { respStr, isSuccess in
                    if isSuccess {
                        let lineSpd = respStr.apiFixed().components(separatedBy: "\\n").map { String($0) }
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
                                    if lineSpd[i].split(separator: "：").count < 2 { continue }
                                    let mspd = lineSpd[j].split(separator: "：").map { String($0) }
                                    if mspd[0] == "State" {
                                        st = Int(mspd[1]) ?? 8
                                    } else if mspd[0] == "Content" {
                                        co = mspd[1]
                                    } else if mspd[0] == "Sender" {
                                        se = mspd[1]
                                    }
                                }
                                replies.append((status: st, content: co, sender: se))
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    FeedbackView()
}