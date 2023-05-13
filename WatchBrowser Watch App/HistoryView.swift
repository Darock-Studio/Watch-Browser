//
//  HistoryView.swift
//  WatchBrowser Watch App
//
//  Created by WindowsMEMZ on 2023/5/2.
//

import SwiftUI
import AuthenticationServices

struct HistoryView: View {
    @AppStorage("IsRecordHistory") var isRecordHistory = true
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @State var isSettingPresented = false
    var body: some View {
        List {
            VStack {
                HStack {
                    Spacer()
                    Text("历史记录")
                        .fontWeight(.bold)
                        .font(.system(size: 20))
                    Spacer()
                }
                HStack {
                    Spacer()
                    Text("单击查看选项")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                    Spacer()
                }
            }
            .onTapGesture {
                isSettingPresented = true
            }
            .sheet(isPresented: $isSettingPresented, content: {HistorySettingView()})
            Section {
                if isRecordHistory {
                    let historys = UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()
                    if historys.count != 0 {
                        ForEach(0...historys.count - 1, id: \.self) { i in
                            Button(action: {
                                let session = ASWebAuthenticationSession(
                                    url: URL(string: historys[i].urlEncoded())!,
                                    callbackURLScheme: nil
                                ) { _, _ in
                                    
                                }
                                session.prefersEphemeralWebBrowserSession = !isAllowCookie
                                session.start()
                            }, label: {
                                if historys[i].hasPrefix("https://www.bing.com/search?q=") {
                                    Label(String(historys[i].dropFirst(30)), systemImage: "magnifyingglass")
                                } else if historys[i].hasPrefix("https://www.baidu.com/s?wd=") {
                                    Label(String(historys[i].dropFirst(27)), systemImage: "magnifyingglass")
                                } else if historys[i].hasPrefix("https://www.google.com/search?q=") {
                                    Label(String(historys[i].dropFirst(32)), systemImage: "magnifyingglass")
                                } else if historys[i].hasPrefix("https://www.sogou.com/web?query=") {
                                    Label(String(historys[i].dropFirst(32)), systemImage: "magnifyingglass")
                                } else {
                                    Label(historys[i], systemImage: "globe")
                                }
                            })
                        }
                    } else {
                        Text("无历史记录")
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("未开启记录")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct HistorySettingView: View {
    @AppStorage("IsRecordHistory") var isRecordHistory = true
    @State var isClosePagePresented = false
    var body: some View {
        List {
            Text("历史记录选项")
                .fontWeight(.bold)
                .font(.system(size: 20))
            Section {
                Toggle("记录历史记录", isOn: $isRecordHistory)
                    .onChange(of: isRecordHistory, perform: { e in
                        if !e {
                            isClosePagePresented = true
                        }
                    })
                    .sheet(isPresented: $isClosePagePresented, content: {CloseHistoryTipView()})
            }
            Section {
                Button(role: .destructive, action: {
                    UserDefaults.standard.set([String](), forKey: "WebHistory")
                }, label: {
                    Text("清空历史记录")
                })
            }
        }
    }
}

struct CloseHistoryTipView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var body: some View {
        ScrollView {
            Text("关闭历史记录")
                .fontWeight(.bold)
                .font(.system(size: 20))
            Text("要在关闭历史记录的同时清空列表吗？")
            Button(role: .destructive, action: {
                UserDefaults.standard.set([String](), forKey: "WebHistory")
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Label("清空", systemImage: "trash.fill")
            })
            Button(role: .cancel, action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Label("保留", systemImage: "arrow.down.doc.fill")
            })
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
