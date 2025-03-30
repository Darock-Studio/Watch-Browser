//
//  SoftwareUpdate.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI
import DarockFoundation
import AuthenticationServices

extension SettingsView.GeneralSettingsView {
    struct SoftwareUpdateView: View {
        @State var shouldUpdate = false
        @State var isLoading = true
        @State var isFailed = false
        @State var latestVer = ""
        var body: some View {
            ScrollView {
                VStack {
                    if !isLoading {
                        if shouldUpdate {
                            HStack {
                                Spacer()
                                    .frame(width: 10)
                                Image("AppIconImage")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(8)
                                Spacer()
                                    .frame(width: 10)
                                VStack {
                                    Text(verbatim: "v\(latestVer)")
                                        .font(.system(size: 14, weight: .medium))
                                    HStack {
                                        Text(verbatim: "Darock Studio")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                }
                            }
                            Divider()
                            Button(action: {
                                let session = ASWebAuthenticationSession(
                                    url: URL(string: "https://apps.apple.com/cn/app/darock-browser/id1670065481")!,
                                    callbackURLScheme: nil
                                ) { _, _ in
                                    return
                                }
                                session.prefersEphemeralWebBrowserSession = true
                                session.start()
                            }, label: {
                                Text("前往更新")
                            })
                        } else if isFailed {
                            Text("检查更新时出错")
                        } else {
                            Text("暗礁浏览器已是最新版本")
                        }
                    } else {
                        HStack {
                            Text("正在检查更新...")
                                .lineLimit(1)
                                .multilineTextAlignment(.leading)
                                .frame(width: 130)
                            Spacer()
                                .frame(maxWidth: .infinity)
                            ProgressView()
                        }
                    }
                }
            }
            .navigationTitle("软件更新")
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
                                            shouldUpdate = true
                                        } else if x == cx && y > cy {
                                            shouldUpdate = true
                                        } else if x == cx && y == cy && z > cz {
                                            shouldUpdate = true
                                        }
                                        latestVer = respStr.apiFixed()
                                        isLoading = false
                                    } else {
                                        isFailed = true
                                    }
                                } else {
                                    isFailed = true
                                }
                            } else {
                                isFailed = true
                            }
                        } else {
                            isFailed = true
                        }
                    } else {
                        isFailed = true
                    }
                }
            }
        }
    }
}
