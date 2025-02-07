//
//  Privacy.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI

extension SettingsView {
    struct PrivacySettingsView: View {
        @State var isAboutPrivacyPresented = false
        @AppStorage("PCReopenPreviousWebTab") var reopenPreviousWebTab = true
        var body: some View {
            List {
                Section {
                    Button(action: {
                        isAboutPrivacyPresented = true
                    }, label: {
                        Text("关于暗礁浏览器与隐私")
                    })
                }
                Section {
                    Toggle("启动时恢复上次浏览的页面", isOn: $reopenPreviousWebTab)
                    NavigationLink(destination: { CookieView() },
                                   label: { SettingItemLabel(title: "Cookie", image: "doc.fill", color: .gray) })
                    NavigationLink(destination: { WebsiteSecurityView() },
                                   label: { SettingItemLabel(title: "站点安全", image: "macwindow.on.rectangle", color: .gray) })
                }
                Section {
                    NavigationLink(destination: { DeveloperModeView() }, label: {
                        SettingItemLabel(title: "开发者模式", image: "hammer.fill", color: .gray, symbolFontSize: 10)
                    })
                } header: {
                    Text("安全性")
                }
            }
            .navigationTitle("隐私与安全性")
            .sheet(isPresented: $isAboutPrivacyPresented) {
                PrivacyAboutView(title: "关于暗礁浏览器与隐私", description: Text("\(Text("关于暗礁浏览器与隐私…").foregroundColor(.accentColor))"), detailText: """
                **关于暗礁浏览器与隐私**
                
                暗礁浏览器旨在保护你的信息并可让你选择共享的内容。
                
                ## 数据收集与使用
                本节中列出了暗礁浏览器 App 可能收集个人数据的功能及其对应的数据类别和用途。
                
                ### App
                暗礁浏览器 App 会收集少量的、与隐私信息无关的、不与你身份关联的交互数据（例如 App 启动）。这些数据将与其他人的数据汇总，仅用于 App 分析。
                
                ### Darock 账户
                在注册 Darock 账户时，Darock 会收集你的电子邮件地址。作为 Darock 账户凭据的一部分，电子邮件地址用于识别你的身份，以提供需要账户支持的 Darock 服务。
                
                ### 存储至 Darock Cloud
                #### 历史记录
                如果你选择将历史记录存储至 Darock Cloud，你最近的浏览历史记录将会自动上传至 Darock Cloud。这些信息将在受保护的区域存储，且不会用于向你提供历史记录同步功能以外的用途。
                
                ### 反馈助理
                在通过反馈助理提交反馈时，反馈助理会收集基于 IP 的大致位置。此信息被隔离存储，且不与你的身份关联，并会在合理的时间内被删除。这些信息仅用于保护 Darock 服务器和反馈助理，以及防止欺诈行为。
                
                反馈助理还会收集 App 诊断信息，你可以在每次提交前查看这些信息，并可选择删除。
                
                仅在你在反馈助理中选择“提交”后，这些信息才会被收集和发送。
                """)
            }
        }
        
        struct CookieView: View {
            @AppStorage("AllowCookies") var allowCookies = true
            var body: some View {
                List {
                    Section {
                        Toggle(isOn: $allowCookies) {
                            VStack(alignment: .leading) {
                                Text("Settings.cookies.allow")
                                Text("Settings.cookies.description")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                            }
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "minus.diamond")
                            Text("Settings.cookies.limitation")
                        }
                    }
                }
                .navigationTitle("Cookie")
            }
        }
        struct WebsiteSecurityView: View {
            @AppStorage("IsShowFraudulentWebsiteWarning") var isShowFraudulentWebsiteWarning = true
            @AppStorage("WKJavaScriptEnabled") var isJavaScriptEnabled = true
            var body: some View {
                List {
                    Section {
                        Toggle("显示欺诈性网站警告", isOn: $isShowFraudulentWebsiteWarning)
                        Toggle("JavaScript", isOn: $isJavaScriptEnabled)
                    }
                }
                .navigationTitle("站点安全")
            }
        }
        
        struct DeveloperModeView: View {
            @AppStorage("IsDeveloperModeEnabled") var isDeveloperModeEnabled = false
            var body: some View {
                List {
                    Section {
                        Toggle("开发者模式", isOn: $isDeveloperModeEnabled)
                    } footer: {
                        Text("如果你正在进行网页开发，开发者模式允许你使用开发所需的功能。")
                    }
                }
                .navigationTitle("开发者模式")
            }
        }
    }
}
