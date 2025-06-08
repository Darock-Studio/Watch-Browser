//
//  JoinGroupView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2023/10/21.
//

import DarockUI
import EFQRCode

struct JoinGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("IsShowJoinGroup2") var isShowJoinGroup = true
    var body: some View {
        List {
            if NSLocale.current.language.languageCode!.identifier == "zh" {
                Section {
                    NavigationLink(destination: {
                        VStack {
                            Image(decorative: EFQRCode.generate(for: "https://qm.qq.com/q/M9Bd05kp6U")!, scale: 1)
                                .resizable()
                                .frame(width: 120, height: 120)
                            Text("在 iPhone 上继续")
                        }
                        .navigationTitle("加入群聊")
                        .navigationBarTitleDisplayMode(.inline)
                    }, label: {
                        Text(verbatim: "欢迎加入 QQ 群 1019196619")
                    })
                } header: {
                    Text(verbatim: "QQ")
                }
            } else {
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
                            Text(verbatim: "Darock Community")
                            Text("轻触以查看二维码")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                        }
                    })
                } header: {
                    Text(verbatim: "Discord")
                }
                Section {
                    NavigationLink(destination: {
                        VStack {
                            Image(decorative: EFQRCode.generate(for: "https://t.me/darockcommunity")!, scale: 1)
                                .resizable()
                                .frame(width: 120, height: 120)
                            Text("在 iPhone 上继续")
                        }
                        .navigationTitle("加入群聊")
                        .navigationBarTitleDisplayMode(.inline)
                    }, label: {
                        VStack(alignment: .leading) {
                            Text(verbatim: "@DAROCKCOMMUNITY")
                            Text("轻触以查看二维码")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                        }
                    })
                } header: {
                    Text(verbatim: "Telegram")
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
