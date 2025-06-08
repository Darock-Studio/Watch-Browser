//
//  ShareView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/3/23.
//

import DarockUI
import EFQRCode
import DarockFoundation

struct ShareView: View {
    @Binding var linkToShare: String
    var body: some View {
        NavigationView {
            List {
                if #available(watchOS 9, *) {
                    if let surl = URL(string: linkToShare) {
                        ShareLink("共享表单", item: surl)
                    }
                }
                NavigationLink(destination: {
                    VStack {
                        Image(decorative: EFQRCode.generate(for: linkToShare)!, scale: 1)
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text("分享到 iPhone")
                    }
                }, label: {
                    Label("二维码", systemImage: "qrcode")
                })
                NavigationLink(destination: { ShortURLView(url: linkToShare) }, label: {
                    Label(title: {
                        VStack(alignment: .leading) {
                            Text("生成短链接")
                            Text("通过 Darock 短链接服务")
                                .font(.footnote)
                                .opacity(0.6)
                        }
                    }, icon: {
                        Image(systemName: "link.badge.plus")
                    })
                })
            }
            .navigationTitle("分享方式")
        }
    }
}

private struct ShortURLView: View {
    var url: String
    @State var shortURL: String?
    var body: some View {
        Group {
            if let url = shortURL {
                Group {
                    if !url.isEmpty {
                        Text(url)
                    } else {
                        Text("生成短链接时出错")
                    }
                }
                .padding()
            } else {
                ProgressView()
                    .controlSize(.large)
                    .onAppear {
                        requestJSON("https://drcc.cc/api/link/gen/\(url.base64Encoded().replacingOccurrences(of: "/", with: "{slash}"))") { respJson, isSuccess in
                            if isSuccess, let url = respJson["url"].string {
                                shortURL = url
                            } else {
                                shortURL = ""
                            }
                        }
                    }
            }
        }
        .navigationTitle("Darock 短链接")
        .navigationBarTitleDisplayMode(.inline)
    }
}
