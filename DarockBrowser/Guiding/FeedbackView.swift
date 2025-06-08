//
//  FeedbackView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/2/23.
//

import Cepheus
import DarockUI
import CorvusKit
import MarkdownUI
import DarockFoundation
import UserNotifications
@_spi(_internal) import RadarKit

struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var isNewVerAvailableAlertPresented = false
    var body: some View {
        if !COKChecker(caller: .darock).cachedCheckStatus {
            RKFeedbackView(projName: "Darock Browser")
                .radarAdditionalData(["NearestHistories": getWebHistory().map { $0.url.prefix(100) }.prefix(3).description])
                .radarTitleInputSample("示例：历史记录缺少最近的浏览数据")
                .radarConstantTags({
                    if isAppBetaBuild { [.init(_fromCombined: "Beta 版本&&&0.0,0.4784314036369324,1.0")!] } else { [] }
                }())
                .radarMessageHiddenKeys(["NearestHistories", "DeviceModelName", "LatestNSException", "LatestNSExceptionTime", "LatestSwiftError",
                                         "LatestSwiftErrorTime", "NotificationToken"])
                .radarFAQView(FAQView())
                .radarTipper { text, symbol in
                    tipWithText(text, symbol: symbol)
                }
                .radarOnNewFeedbackAppear {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { isGrand, _ in
                        DispatchQueue.main.async {
                            if isGrand {
                                WKExtension.shared().registerForRemoteNotifications()
                            }
                        }
                    }
                }
                .radarAppdiagnoseDataProcessor { plistObject in
                    plistObject.removeValue(forKey: "CurrentTabs")
                    plistObject.removeValue(forKey: "WebHistory")
                    plistObject.removeValue(forKey: "UserPasscodeEncrypted")
                    let removeKeyPrefixs = ["VideoProgressForLink", "WebHistory", "VideoMarkForLink", "BookmarkLink", "BookmarkName", "UserScript",
                                            "VideoHumanName", "AudioHumanName", "Bookmark"]
                    for key in plistObject.keys where removeKeyPrefixs.contains(where: { key.hasPrefix($0) }) {
                        plistObject.removeValue(forKey: key)
                    }
                }
                .radarIssuePlaces {
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
                    Text(verbatim: "Darock Cloud").tag("Darock Cloud&&&0.03921568766236305,0.5176469087600708,1.0")
                    Text("书签").tag("书签&&&0.03921568766236305,0.5176469087600708,1.0")
                    Text("历史记录").tag("历史记录&&&0.03921568766236305,0.5176469087600708,1.0")
                    Text("网页归档").tag("网页归档&&&0.03921568766236305,0.5176469087600708,1.0")
                    Text("播放列表").tag("播放列表&&&0.03921568766236305,0.5176469087600708,1.0")
                    Text("用户脚本").tag("用户脚本&&&0.03921568766236305,0.5176469087600708,1.0")
                    Text("本地媒体").tag("本地媒体&&&0.03921568766236305,0.5176469087600708,1.0")
                    Text("反馈助理").tag("反馈助理&&&0.5960784554481506,0.16470590233802795,0.7372550964355469")
                    Text("不在此列表中的其他方面").tag("其他&&&0.5215685963630676,0.5215685963630676,0.5215685963630676")
                }
                .radarAttachmentSelector { completion in
                    NavigationView {
                        List {
                            NavigationLink(destination: {
                                HistoryView { sel in
                                    completion("ExtHistories", sel)
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
                }
                .radarSuggsetResolver(SuggestedResolver.self)
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
                    requestAPI("/drkbs/newver") { respStr, isSuccess in
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
        } else {
            CorvusBannedView()
        }
    }
}

struct FAQView: View {
    var body: some View {
        List {
            NavigationLink(destination: {
                ScrollView {
                    CodedMarkdown(String(localized: """
                    **并非所有网页内的视频均能被解析**
                    
                    请**不要**提出网站视频无法播放之类的反馈
                    """))
                }
            }, label: {
                Text("关于视频…")
            })
            NavigationLink(destination: {
                ScrollView {
                    CodedMarkdown(String(localized: """
                    在少数情况下，播放视频时可能会出现**只有声音，没有画面或画面卡住**的情况。
                    
                    遇到此类情况，重启 Apple Watch 即可解决，请勿提交反馈。
                    """))
                }
            }, label: {
                Text("关于视频播放卡住…")
            })
            NavigationLink(destination: {
                ScrollView {
                    CodedMarkdown(String(localized: """
                    **并非所有网页都能在 Apple Watch 上正常工作**
                    
                    请**不要**提出网站*打不开*、*有问题*之类的反馈
                    """))
                }
            }, label: {
                Text("关于网页适配…")
            })
            NavigationLink(destination: {
                ScrollView {
                    CodedMarkdown(String(localized: """
                    单独为特定的网页优化根本**不可行**。
                    
                    想想今天让为网站A进行优化，明天另一个用户反馈想为网站B进行优化。不仅工作量大大提升，还会使代码极其难维护，这就是个无底洞。
                    
                    请**不要**提出为**特定网站**进行优化之类的反馈。
                    """))
                }
            }, label: {
                Text("关于特定网页优化…")
            })
        }
        .navigationTitle("常见问题")
    }
}

private struct CorvusBannedView: View {
    let declaration = String(localized: "法律之前人人平等，并有权享受法律的平等保护，不受任何歧视。人人有权享受平等保护，以免受违反本宣言的任何歧视行为以及煽动这种歧视的任何行为之害。")
    @Environment(\.presentationMode) var presentationMode
    @State var copyDeclarationInput = ""
    @State var descriptionInput = ""
    @State var descriptionSnapshotCount = 0
    @State var isSubmitting = false
    var body: some View {
        List {
            Section {
                Text("""
                你因为在“反馈助理”中发送不适宜的言论而被附加 Corvus 封禁。
                
                此封禁不会影响 App 功能，但会禁用你的“反馈助理”，以及在你的 App 内加上如你现在看到的水印。
                
                你可以通过下方的表单进行申诉。
                """)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            Section {
                Text(declaration)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                CepheusKeyboard(input: $copyDeclarationInput, prompt: "按原样抄写", CepheusIsEnabled: true, allowEmojis: false, aboutLinkIsHidden: true)
            } header: {
                Text("前置条件")
            } footer: {
                Text("请按原样抄写上方文本。")
            }
            Section {
                CepheusKeyboard(input: $descriptionInput, prompt: "描述文本", CepheusIsEnabled: true, aboutLinkIsHidden: true)
            } header: {
                Text("描述")
            } footer: {
                if !descriptionInput.isEmpty {
                    if descriptionInput.count < 200 {
                        Text("还差 \(200 - descriptionInput.count) 字")
                            .foregroundStyle(.red)
                    }
                } else {
                    Text("请对本次申诉情况进行详细描述。")
                }
            }
            .disabled(copyDeclarationInput != declaration)
            Section {
                Button(action: {
                    isSubmitting = true
                    Task {
                        do {
                            _ = try await RKCFeedbackManager(projectName: "Corvus申诉")
                                .newFeedback(.init(title: "暗礁浏览器", content: descriptionInput, sender: "User"))
                            tipWithText("已提交", symbol: "checkmark.circle.fill")
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            tipWithText("提交时出错", symbol: "xmark.circle.fill")
                        }
                        isSubmitting = false
                    }
                }, label: {
                    Text("提交")
                })
                .disabled(descriptionInput.count < 200 || isSubmitting)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Corvus 封禁")
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
