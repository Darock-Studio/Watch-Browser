//
//  SettingsView.swift
//  WatchBrowser Watch App
//
//  Created by WindowsMEMZ on 2023/6/6.
//

import SwiftUI
import DarockAccountUI
import DarockFoundation

struct SettingsView: View {
    @AppStorage("DarockAccount") var darockAccount = ""
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("IsDeveloperModeEnabled") var isDeveloperModeEnabled = false
    @AppStorage("DarockAccountCachedUsername") var accountUsername = ""
    @State var isNewFeaturesPresented = false
    @State var isPasscodeViewPresented = false
    @State var isEnterPasscodeViewInputPresented = false
    @State var passcodeInputTmp = ""
    @State var isDarockAccountLoginPresented = false
    @State var darockAccountPasscodeInputTmp = ""
    var body: some View {
        List {
            Section {
                if darockAccount.isEmpty {
                    Button(action: {
                        isDarockAccountLoginPresented = true
                    }, label: {
                        HStack {
                            ZStack {
                                Image(systemName: "circle.dotted")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.init(hex: 0x144683))
                                Image(systemName: "circle.dotted")
                                    .font(.system(size: 30, weight: .light))
                                    .rotationEffect(.degrees(8))
                                    .foregroundColor(.init(hex: 0x144683))
                                Text(verbatim: "D")
                                    .font(.custom("HYWenHei-85W", size: 14))
                                    .foregroundColor(.init(hex: 0x0c79ff))
                                    .scaleEffect(1.2)
                            }
                            VStack(alignment: .leading) {
                                Text("Darock 账户")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("登录以为今后账户相关功能做好准备。")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    })
                    .sheet(isPresented: $isDarockAccountLoginPresented, onDismiss: {
                        if !darockAccount.isEmpty {
                            requestString("https://api.darock.top/user/name/get/\(darockAccount)".compatibleUrlEncoded()) { respStr, isSuccess in
                                if isSuccess {
                                    accountUsername = respStr.apiFixed()
                                }
                            }
                        }
                    }, content: { DAUILoginView() })
                } else {
                    NavigationLink(destination: {
                        DAUIAccountManagementView(username: accountUsername)
                            .darockAccountPasswordProcessorForSensitiveOperations { completion in
                                PasswordInputView(text: $darockAccountPasscodeInputTmp, placeholder: "输入锁定密码") { pwd in
                                    if pwd.md5 == userPasscodeEncrypted {
                                        completion()
                                    } else {
                                        tipWithText("密码错误", symbol: "xmark.circle.fill")
                                    }
                                    darockAccountPasscodeInputTmp = ""
                                }
                                .toolbar(.hidden, for: .navigationBar)
                            }
                            .darockAccountCloudView {
                                DarockCloudView()
                            }
                    }, label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Group {
                                    if !accountUsername.isEmpty {
                                        Text(accountUsername)
                                            .lineLimit(1)
                                            .minimumScaleFactor(accountUsername.count <= 20 ? 0.1 : 0.5)
                                    } else {
                                        Text(verbatim: "loading")
                                            .redacted(reason: .placeholder)
                                    }
                                }
                                .font(.system(size: 16, weight: .semibold))
                                Text("Darock 账户以及更多")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    })
                }
            }
            Section {
                NavigationLink(destination: { ProPurchaseView() }, label: { SettingItemLabel(title: "暗礁浏览器 Pro", image: "sparkles", color: .blue) })
                NavigationLink(destination: { DarockIntelligenceView() }, label: {
                    HStack {
                        Image("DarockIntelligenceIcon")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                        Text("Darock 智能")
                    }
                })
                if #available(watchOS 10.0, *) {
                    NavigationLink(destination: { WidgetSettingsView() },
                                   label: { SettingItemLabel(title: "小组件", image: "watchface.applewatch.case", color: .blue) })
                }
            }
            Section {
                NavigationLink(destination: { PrivateRelaySettingsView() }, label: { SettingItemLabel(title: "专用代理", image: "network.badge.shield.half.filled", color: .blue) })
                NavigationLink(destination: { StaredSettingsView() }, label: { SettingItemLabel(title: "常用设置", image: "star", color: .orange) })
                NavigationLink(destination: { NetworkSettingsView() }, label: { SettingItemLabel(title: "网络", image: "network", color: .blue) })
            }
            Section {
                NavigationLink(destination: { GeneralSettingsView() },
                               label: { SettingItemLabel(title: "通用", image: "gear", color: .gray) })
                NavigationLink(destination: { DisplaySettingsView() },
                               label: { SettingItemLabel(title: "显示与亮度", image: "sun.max.fill", color: .blue) })
                NavigationLink(destination: { BrowsingEngineSettingsView() },
                               label: { SettingItemLabel(title: "浏览引擎", image: "globe", color: .blue) })
                if #available(watchOS 10.0, *) {
                    NavigationLink(destination: { BrowsingPreferenceSettingsView() },
                                   label: { SettingItemLabel(title: "浏览偏好", image: "viewfinder", color: .gray) })
                }
                NavigationLink(destination: { SearchSettingsView() },
                               label: { SettingItemLabel(title: "搜索", image: "magnifyingglass", color: .gray) })
                #if compiler(>=6)
                NavigationLink(destination: { GesturesSettingsView() },
                               label: { SettingItemLabel(title: "手势", privateImage: "hand.side.pinch.fill", color: .blue) })
                #endif
            }
            Section {
                Button(action: {
                    if userPasscodeEncrypted.isEmpty {
                        isPasscodeViewPresented = true
                    } else {
                        isEnterPasscodeViewInputPresented = true
                    }
                }, label: {
                    SettingItemLabel(title: "密码", image: "lock.fill", color: .red)
                })
                NavigationLink(destination: { PrivacySettingsView() },
                               label: { SettingItemLabel(title: "隐私与安全性", image: "hand.raised.fill", color: .blue) })
            }
            Section {
                if isDeveloperModeEnabled {
                    NavigationLink(destination: { DeveloperSettingsView() }, label: {
                        SettingItemLabel(title: "开发者", image: "hammer.fill", color: .blue, symbolFontSize: 10)
                    })
                }
                NavigationLink(destination: { LaboratoryView() }, label: {
                    SettingItemLabel(title: "实验室", image: {
                        if #available(watchOS 10, *) {
                            "flask.fill"
                        } else {
                            "hammer.fill"
                        }
                    }(), color: .blue)
                })
                if UserDefaults(suiteName: "group.darockst")!.bool(forKey: "IsDarockInternalTap-to-RadarAvailable") {
                    NavigationLink(destination: { InternalDebuggingView() }, label: {
                        SettingItemLabel(title: "Debugging", image: "ant.fill", color: .purple)
                    })
                }
            }
        }
        .navigationTitle("设置")
        .wrapIf({
            if #available(watchOS 10, *) { true } else { false }
        }()) { content in
            content
                .navigationDestination(isPresented: $isPasscodeViewPresented, destination: { PasswordSettingsView() })
        } else: { content in
            content
                ._navigationDestination(isPresented: $isPasscodeViewPresented, content: { PasswordSettingsView() })
        }
        .sheet(isPresented: $isEnterPasscodeViewInputPresented) {
            PasswordInputView(text: $passcodeInputTmp, placeholder: "输入你的密码") { pwd in
                if pwd.md5 == userPasscodeEncrypted {
                    isPasscodeViewPresented = true
                } else {
                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                }
                passcodeInputTmp = ""
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            if !darockAccount.isEmpty {
                requestString("https://api.darock.top/user/name/get/\(darockAccount)".compatibleUrlEncoded()) { respStr, isSuccess in
                    if isSuccess {
                        accountUsername = respStr.apiFixed()
                    }
                }
            }
        }
        .onReceive(appBecomeInactiveSubject) { _ in
            isPasscodeViewPresented = false
        }
    }
    
    struct SettingItemLabel: View {
        var title: LocalizedStringKey
        var image: String
        var isPrivateImage: Bool
        var color: Color
        var symbolFontSize: CGFloat
        
        init(title: LocalizedStringKey, image: String, color: Color, symbolFontSize: CGFloat = 12) {
            self.title = title
            self.image = image
            self.isPrivateImage = false
            self.color = color
            self.symbolFontSize = symbolFontSize
        }
        init(title: LocalizedStringKey, privateImage: String, color: Color, symbolFontSize: CGFloat = 12) {
            self.title = title
            self.image = privateImage
            self.isPrivateImage = true
            self.color = color
            self.symbolFontSize = symbolFontSize
        }
        
        var body: some View {
            HStack {
                ZStack {
                    color
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                    Group {
                        if !isPrivateImage {
                            Image(systemName: image)
                        } else {
                            Image(_internalSystemName: image)
                        }
                    }
                    .font(.system(size: symbolFontSize))
                }
                Text(title)
            }
        }
    }
}
