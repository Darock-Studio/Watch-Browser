//
//  JoinGroupView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2023/10/21.
//

import SwiftUI
import EFQRCode

struct JoinGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("IsShowJoinGroup") var isShowJoinGroup = true
    var body: some View {
        List {
            if NSLocale.current.language.languageCode!.identifier != "zh" {
                Section {
                    NavigationLink(destination: {
                        VStack {
                            Image(decorative: EFQRCode.generate(for: "https://discord.gg/wumcXQ2aTJ")!, scale: 1)
                                .resizable()
                                .frame(width: 120, height: 120)
                            Text("在 iPhone 上继续")
                        }
                        .navigationTitle("加入群聊")
                        .navigationBarTitleDisplayMode(.inline)
                    }, label: {
                        VStack(alignment: .leading) {
                            Text("Darock Community")
                            Text("轻触以查看二维码")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.gray)
                        }
                    })
                } header: {
                    Text("Discord")
                }
            }
            Section {
                if NSLocale.current.language.languageCode!.identifier == "zh" {
                    NavigationLink(destination: {
                        VStack {
                            Image(decorative: EFQRCode.generate(for: "https://qm.qq.com/q/1q943WQLAo")!, scale: 1)
                                .resizable()
                                .frame(width: 120, height: 120)
                            Text("在 iPhone 上继续")
                        }
                        .navigationTitle("加入群聊")
                        .navigationBarTitleDisplayMode(.inline)
                    }, label: {
                        Text("欢迎加入 QQ 群 248036605")
                    })
                } else {
                    NavigationLink(destination: {
                        VStack {
                            Image(decorative: EFQRCode.generate(for: "https://t.me/drkcomu")!, scale: 1)
                                .resizable()
                                .frame(width: 120, height: 120)
                            Text("在 iPhone 上继续")
                        }
                        .navigationTitle("加入群聊")
                        .navigationBarTitleDisplayMode(.inline)
                    }, label: {
                        VStack(alignment: .leading) {
                            Text("@DRKCOMU")
                            Text("轻触以查看二维码")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.gray)
                        }
                    })
                }
            } header: {
                if NSLocale.current.language.languageCode!.identifier == "zh" {
                    Text("QQ")
                } else {
                    Text("Telegram")
                }
            }
            Section {
                Button(action: {
                    isShowJoinGroup = false
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("不再显示")
                })
            }
        }
        .navigationTitle("加入群聊")
    }
}
