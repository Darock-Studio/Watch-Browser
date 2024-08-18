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
struct ClusterAdView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("IsShowClusterAd") var isShowClusterAd = true
    var body: some View {
        List {
            Section {
                Text("由 Darock 开发的暗礁暗礁文件让您能够在 Apple Watch 上轻松存储、管理和查看文件。")
                Button(action: {
                    let session = ASWebAuthenticationSession(
                        url: URL(string: "https://apps.apple.com/app/cluster-files/id6581473546")!,
                        callbackURLScheme: nil
                    ) { _, _ in }
                    session.prefersEphemeralWebBrowserSession = true
                    session.start()
                }, label: {
                    Text("前往 App Store 下载")
                        .foregroundStyle(Color.blue)
                })
                NavigationLink(destination: {
                    VStack {
                        VStack {
                            Image(decorative: EFQRCode.generate(for: "https://apps.apple.com/app/cluster-files/id6581473546")!,
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
                Text("暗礁文件可与暗礁浏览器配合使用，在安装暗礁文件后，您可以将暗礁浏览器中的本地媒体存储至暗礁文件。")
            }
            Section {
                Button(action: {
                    isShowClusterAd = false
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("退出并不再显示")
                        .foregroundStyle(Color.blue)
                })
            }
        }
        .navigationTitle("推荐 - 暗礁文件")
        .scrollIndicators(.visible, axes: .vertical)
    }
}
