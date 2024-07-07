//
//  DAssistAdView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/6/9.
//

import SwiftUI
import EFQRCode
import AuthenticationServices

@available(watchOS 10.0, *)
struct DAssistAdView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("IsShowDAssistantAd") var isShowDAssistantAd = true
    var body: some View {
        List {
            Section {
                Text("由 Darock 开发的暗礁助手让您能够在 iPhone 和 Apple Watch 上与 AI 对话并获取帮助")
                Button(action: {
                    let session = ASWebAuthenticationSession(
                        url: URL(string: "https://apps.apple.com/cn/app/%E6%9A%97%E7%A4%81%E5%8A%A9%E6%89%8B/id6496372036")!,
                        callbackURLScheme: nil
                    ) { _, _ in
                        return
                    }
                    session.prefersEphemeralWebBrowserSession = true
                    session.start()
                }, label: {
                    Text("前往 App Store 下载")
                        .foregroundStyle(Color.blue)
                })
                NavigationLink(destination: {
                    VStack {
                        VStack {
                            Image(decorative: EFQRCode.generate(for: "https://apps.apple.com/cn/app/%E6%9A%97%E7%A4%81%E5%8A%A9%E6%89%8B/id6496372036")!,
                                  scale: 1)
                                .resizable()
                                .frame(width: 100, height: 100)
                            Text("在 iPhone 上继续")
                        }
                    }
                }, label: {
                    Text("或在 iPhone 上的 App Store 继续")
                        .foregroundStyle(Color.blue)
                })
            }
            Section {
                Text("Darock 为暗礁浏览器用户准备了暗礁助手的订阅免费试用")
                NavigationLink(destination: {
                    VStack {
                        VStack {
                            Image(decorative: EFQRCode.generate(for: "https://apps.apple.com/redeem?ctx=offercodes&id=6496372036&code=DRKBROWSERASSISTANT35")!,
                                  scale: 1)
                                .resizable()
                                .frame(width: 100, height: 100)
                            Text("在 iPhone 上继续")
                        }
                    }
                }, label: {
                    Text("3.5 订阅免费试用兑换")
                        .foregroundStyle(Color.blue)
                })
                NavigationLink(destination: {
                    VStack {
                        VStack {
                            Image(decorative: EFQRCode.generate(for: "https://apps.apple.com/redeem?ctx=offercodes&id=6496372036&code=DRKBROWSERASSISTANT40")!,
                                  scale: 1)
                                .resizable()
                                .frame(width: 100, height: 100)
                            Text("在 iPhone 上继续")
                        }
                    }
                }, label: {
                    Text("4.0 订阅免费试用兑换")
                        .foregroundStyle(Color.blue)
                })
            }
            Section {
                Button(action: {
                    isShowDAssistantAd = false
                    dismiss()
                }, label: {
                    Text("退出并不再显示")
                        .foregroundStyle(Color.blue)
                })
            }
        }
        .navigationTitle("推荐 - 暗礁助手")
        .scrollIndicators(.visible, axes: .vertical)
    }
}
