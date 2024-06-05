//
//  BrowsingTabsView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/6/6.
//

import SwiftUI
import Dynamic

var tabCurrentReferences = [String: TabWebKitReference]()

struct BrowsingTabsView: View {
    @State var tabs = [String]()
    @State var convertTitles = [String: String]()
    var body: some View {
        List {
            Section {
                if !tabs.isEmpty {
                    ForEach(0..<tabs.count, id: \.self) { i in
                        Button(action: {
                            AdvancedWebViewController.shared.currentTabIndex = i
                            if let ref = tabCurrentReferences[tabs[i]] {
                                AdvancedWebViewController.shared.recover(from: ref)
                            } else {
                                AdvancedWebViewController.shared.present(tabs[i])
                            }
                        }, label: {
                            Text(convertTitles[tabs[i]] ?? tabs[i])
                        })
                        .swipeActions {
                            Button(role: .destructive, action: {
                                tabCurrentReferences.removeValue(forKey: tabs[i])
                                tabs.remove(at: i)
                                UserDefaults.standard.set(tabs, forKey: "CurrentTabs")
                            }, label: {
                                Image(systemName: "xmark.circle.fill")
                            })
                        }
                    }
                } else {
                    Text("无打开的标签页")
                }
            }
        }
        .navigationTitle("标签页")
        .onAppear {
            tabs = UserDefaults.standard.stringArray(forKey: "CurrentTabs") ?? [String]()
            convertTitles = (UserDefaults.standard.dictionary(forKey: "WebHistoryNames") as? [String: String]) ?? [String: String]()
        }
    }
}

struct TabWebKitReference: Identifiable {
    let id = UUID()
    
    var webViewHolder: Dynamic // UIView
    var menuController: Dynamic // UIViewController
    var menuView: Dynamic // UIScrollView
    var vc: Dynamic // UIViewController
    var loadProgressView: Dynamic // UIProgressView
    var webViewObject: AnyObject
    var webViewParentController: AnyObject
}
