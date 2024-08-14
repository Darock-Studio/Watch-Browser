//
//  BrowsingTabsView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/6/6.
//

import SwiftUI
import Dynamic

var tabCurrentReferences = [String: TabWebKitReference]()

@available(watchOS 10.0, *)
struct BrowsingTabsView: View {
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForBrowsingTab") var usePasscodeForBrowsingTab = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var tabs = [String]()
    @State var convertTitles = [String: String]()
    @State var isClearWarningPresented = false
    var body: some View {
        if isLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForBrowsingTab {
            PasswordInputView(text: $passcodeInputCache, placeholder: "输入密码", dismissAfterComplete: false) { pwd in
                if pwd.md5 == userPasscodeEncrypted {
                    isLocked = false
                } else {
                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                }
                passcodeInputCache = ""
            }
            .navigationBarBackButtonHidden()
        } else {
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
            .alert("关闭所有标签页", isPresented: $isClearWarningPresented, actions: {
                Button(role: .destructive, action: {
                    tabs.removeAll()
                    convertTitles.removeAll()
                    UserDefaults.standard.set(tabs, forKey: "CurrentTabs")
                    UserDefaults.standard.set(convertTitles, forKey: "WebHistoryNames")
                }, label: {
                    Text("确定")
                })
                Button(role: .cancel, action: {
                    
                }, label: {
                    Text("取消")
                })
            }, message: {
                Text("确定吗？")
            })
            .toolbar {
                if !tabs.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive, action: {
                            isClearWarningPresented = true
                        }, label: {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                        })
                    }
                }
            }
            .onAppear {
                tabs = UserDefaults.standard.stringArray(forKey: "CurrentTabs") ?? [String]()
                convertTitles = (UserDefaults.standard.dictionary(forKey: "WebHistoryNames") as? [String: String]) ?? [String: String]()
            }
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
    var webViewObject: WKWebView
    var webViewParentController: AnyObject
}
