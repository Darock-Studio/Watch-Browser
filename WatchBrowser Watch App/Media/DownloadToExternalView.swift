//
//  DownloadToExternalView.swift
//  WatchBrowser
//
//  Created by memz233 on 11/10/24.
//

import SwiftUI
import DarockKit
import AuthenticationServices

struct DownloadToExternalView: View {
    var url: String
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("IsThisClusterInstalled") var isThisClusterInstalled = false
    var body: some View {
        NavigationStack {
            List {
                if isThisClusterInstalled {
                    Section {
                        VStack(alignment: .leading) {
                            Text("下载文件")
                                .font(.headline)
                            Text(url)
                                .font(.subheadline)
                                .lineLimit(1)
                                .opacity(0.6)
                        }
                    }
                    .listRowBackground(Color.clear)
                    Section {
                        Button(action: {
                            let metadata = ExternalDownloadMetadata(
                                url: URL(string: url)!,
                                saveFileName: String(url.split(separator: "?", maxSplits: 1).first?.split(separator: "/").last ?? "File")
                            )
                            let encodedData = jsonString(from: metadata)?.base64Encoded() ?? ""
                            WKExtension.shared().openSystemURL(URL(string: "https://darock.top/cluster/download/\(encodedData)")!)
                        }, label: {
                            Text("在暗礁文件中下载")
                        })
                    }
                } else {
                    Section {
                        Text("尚未安装暗礁文件")
                        Button(action: {
                            let session = ASWebAuthenticationSession(
                                url: URL(string: "https://apps.apple.com/app/cluster-files/id6581473546")!,
                                callbackURLScheme: nil
                            ) { _, _ in }
                            session.prefersEphemeralWebBrowserSession = true
                            session.start()
                        }, label: {
                            Text("前往 App Store 下载")
                                .foregroundStyle(.blue)
                        })
                    }
                }
            }
            .navigationTitle("通过暗礁文件下载")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
            }
        }
    }
}

private struct ExternalDownloadMetadata: Codable {
    var url: URL
    var httpHeaders: [String: String]?
    var saveFileName: String
}
