//
//  WebArchiveListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//

import SwiftUI

struct WebArchiveListView: View {
    @State var archiveLinks = [String]()
    @State var archiveCustomNameChart = [String: String]()
    @State var customingNameKey = ""
    @State var isArchiveCustomNamePresented = false
    @State var customNameInputCache = ""
    var body: some View {
        List {
            if !archiveLinks.isEmpty {
                ForEach(0..<archiveLinks.count, id: \.self) { i in
                    Button(action: {
                        AdvancedWebViewController.shared.present(
                            "",
                            archiveUrl: URL(
                                fileURLWithPath: NSHomeDirectory()
                                + "/Documents/WebArchives/\(archiveLinks[i].base64Encoded().replacingOccurrences(of: "/", with: "{slash}")).drkdataw"
                            )
                        )
                    }, label: {
                        Text(archiveCustomNameChart[archiveLinks[i]] ?? archiveLinks[i])
                    })
                    .swipeActions {
                        Button(role: .destructive, action: {
                            do {
                                try FileManager.default.removeItem(
                                    atPath: NSHomeDirectory()
                                    + "/Documents/WebArchives/\(archiveLinks[i].base64Encoded().replacingOccurrences(of: "/", with: "{slash}")).drkdataw"
                                )
                            } catch {
                                globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
                            }
                            archiveLinks.remove(at: i)
                            UserDefaults.standard.set(archiveLinks, forKey: "WebArchiveList")
                        }, label: {
                            Image(systemName: "xmark.bin.fill")
                        })
                        Button(action: {
                            customingNameKey = archiveLinks[i]
                            customNameInputCache = archiveCustomNameChart[archiveLinks[i]] ?? ""
                            isArchiveCustomNamePresented = true
                        }, label: {
                            Image(systemName: "pencil.line")
                        })
                    }
                }
            } else {
                Text("无网页归档")
            }
        }
        .navigationTitle("网页归档")
        .sheet(isPresented: $isArchiveCustomNamePresented) {
            VStack {
                Text("自定义名称")
                    .font(.system(size: 20, weight: .bold))
                TextField("名称", text: $customNameInputCache)
                Button(action: {
                    archiveCustomNameChart.updateValue(customNameInputCache, forKey: customingNameKey)
                    isArchiveCustomNamePresented = false
                    UserDefaults.standard.set(archiveCustomNameChart, forKey: "WebArchiveCustomNameChart")
                }, label: {
                    Label("完成", systemImage: "checkmark")
                })
            }
        }
        .onAppear {
            archiveLinks = UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()
            archiveCustomNameChart = (UserDefaults.standard.dictionary(forKey: "WebArchiveCustomNameChart") as? [String: String]) ?? [String: String]()
        }
    }
}
