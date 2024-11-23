//
//  FeedbackView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/2/23.
//

import SwiftUI
import RadarKit
import DarockKit
import MarkdownUI
import UserNotifications

struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var isNewVerAvailableAlertPresented = false
    var body: some View {
        RKFeedbackView(projName: "Darock Browser")
            .radarAdditionalData(["NearestHistories": getWebHistory().map { $0.url.prefix(100) }.prefix(3).description])
            .radarTitleInputSample("示例：历史记录缺少最近的浏览数据")
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
            .radarMessageMarkdownRender { str in
                Markdown(str)
                    .markdownTheme(.gitHub)
                    .environment(\.openURL, OpenURLAction { url in
                        AdvancedWebViewController.shared.present(url.absoluteString)
                        return .handled
                    })
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
