//
//  BetaJoinView.swift
//  WatchBrowser
//
//  Created by memz233 on 10/6/24.
//

import SwiftUI
import EFQRCode
import DarockKit

struct BetaJoinView: View {
    @State var isErrorLoading = false
    @State var title = ""
    @State var description = ""
    @State var link = ""
    var body: some View {
        Form {
            if !title.isEmpty {
                Section {
                    Text(title)
                }
                Section {
                    Text(description)
                } header: {
                    Text("测试内容")
                }
                Section {
                    VStack {
                        Image(decorative: EFQRCode.generate(for: link)!, scale: 1)
                            .resizable()
                            .frame(width: 120, height: 120)
                        Text("在 iPhone 上继续")
                    }
                    .centerAligned()
                } header: {
                    Text("加入测试")
                }
                .listRowBackground(Color.clear)
            } else if isErrorLoading {
                Text("载入时出错")
            } else {
                ProgressView()
                    .controlSize(.large)
                    .centerAligned()
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("参与 Beta 测试")
        .onAppear {
            DarockKit.Network.shared.requestString(
                "https://fapi.darock.top:65535/tf/get/DarockBrowser\(NSLocale.current.language.languageCode!.identifier == "zh" ? "" : "_en")"
            ) { respStr, isSuccess in
                if isSuccess {
                    let splited = respStr.apiFixed().components(separatedBy: "|")
                    if splited.count == 3 {
                        title = splited[0]
                        description = splited[1].replacingOccurrences(of: "\\\\n", with: "\n")
                        link = splited[2]
                    } else {
                        isErrorLoading = true
                    }
                } else {
                    isErrorLoading = true
                }
            }
        }
    }
}
