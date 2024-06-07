//
//  WebArchiveListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//

import SwiftUI

struct WebArchiveListView: View {
    @State var archiveLinks = [String]()
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
                        Text(archiveLinks[i])
                    })
                    .swipeActions {
                        Button(role: .destructive, action: {
                            do {
                                try FileManager.default.removeItem(
                                    atPath: NSHomeDirectory()
                                    + "/Documents/WebArchives/\(archiveLinks[i].base64Encoded().replacingOccurrences(of: "/", with: "{slash}")).drkdataw"
                                )
                            } catch {
                                print(error)
                            }
                            archiveLinks.remove(at: i)
                            UserDefaults.standard.set(archiveLinks, forKey: "WebArchiveList")
                        }, label: {
                            Image(systemName: "xmark.bin.fill")
                        })
                    }
                }
            } else {
                Text("无网页归档")
            }
        }
        .navigationTitle("网页归档")
        .onAppear {
            archiveLinks = UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()
        }
    }
}

#Preview {
    WebArchiveListView()
}
