//
//  MLTestsView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2023/10/21.
//

import SwiftUI
import EFQRCode

struct MLTestsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("IsShowBetaTest1") var isShowBetaTest = true
    var body: some View {
        List {
            Section {
                Text("Darock 邀请您参与 Beta 测试")
                Text("App: 喵哩喵哩")
                Text("描述: Apple Watch 上的 Bilibili 客户端")
            }
            Section {
                NavigationLink(destination: {
                    VStack {
                        Image(decorative: EFQRCode.generate(for: "https://cd.darock.top:32767/meowbili/")!, scale: 1)
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text("在 iPhone 上继续")
                    }
                }, label: {
                    Text("了解详情")
                })
                NavigationLink(destination: {
                    VStack {
                        Image(decorative: EFQRCode.generate(for: "https://testflight.apple.com/join/TbuBT6ig")!, scale: 1)
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text("在 iPhone 上继续")
                    }
                }, label: {
                    Text("下载")
                })
            }
            Section {
                Button(action: {
                    isShowBetaTest = false
                    dismiss()
                }, label: {
                    Text("退出, 不再显示本次测试")
                })
            }
        }
        .navigationTitle("邀请测试")
    }
}

#Preview {
    MLTestsView()
}
