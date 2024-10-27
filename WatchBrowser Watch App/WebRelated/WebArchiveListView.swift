//
//  WebArchiveListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//

import SwiftUI

struct WebArchiveListView: View {
    var selectionHandler: ((String?, String) -> Void)?
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForWebArchives") var usePasscodeForWebArchives = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var archiveLinks = [String]()
    @State var archiveCustomNameChart = [String: String]()
    @State var customingNameKey = ""
    @State var isArchiveCustomNamePresented = false
    @State var customNameInputCache = ""
    var body: some View {
        if isLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForWebArchives {
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
                if !archiveLinks.isEmpty {
                    Section {
                        ForEach(0..<archiveLinks.count, id: \.self) { i in
                            Button(action: {
                                if let selectionHandler {
                                    selectionHandler(
                                        archiveCustomNameChart[archiveLinks[i]],
                                        URL(
                                            fileURLWithPath: NSHomeDirectory()
                                            + "/Documents/WebArchives/\(archiveLinks[i].base64Encoded().replacingOccurrences(of: "/", with: "{slash}").prefix(Int(NAME_MAX - 9))).drkdataw"
                                        ).absoluteString
                                    )
                                } else {
                                    AdvancedWebViewController.shared.present(
                                        "",
                                        archiveUrl: URL(
                                            fileURLWithPath: NSHomeDirectory()
                                            + "/Documents/WebArchives/\(archiveLinks[i].base64Encoded().replacingOccurrences(of: "/", with: "{slash}").prefix(Int(NAME_MAX - 9))).drkdataw"
                                        )
                                    )
                                }
                            }, label: {
                                Text(archiveCustomNameChart[archiveLinks[i]] ?? archiveLinks[i])
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    do {
                                        try FileManager.default.removeItem(
                                            atPath: NSHomeDirectory()
                                            + "/Documents/WebArchives/\(archiveLinks[i].base64Encoded().replacingOccurrences(of: "/", with: "{slash}").prefix(Int(NAME_MAX - 9))).drkdataw"
                                        )
                                    } catch {
                                        globalErrorHandler(error)
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
                        .onMove { source, destination in
                            archiveLinks.move(fromOffsets: source, toOffset: destination)
                            UserDefaults.standard.set(archiveLinks, forKey: "WebArchiveList")
                        }
                    }
                } else {
                    Text("无网页归档")
                }
            }
            .navigationTitle("网页归档")
            .sheet(isPresented: $isArchiveCustomNamePresented) {
                NavigationStack {
                    List {
                        HStack {
                            Spacer()
                            Text("自定义名称")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        TextField("名称", text: $customNameInputCache, style: "field-page")
                        Button(action: {
                            archiveCustomNameChart.updateValue(customNameInputCache, forKey: customingNameKey)
                            isArchiveCustomNamePresented = false
                            UserDefaults.standard.set(archiveCustomNameChart, forKey: "WebArchiveCustomNameChart")
                        }, label: {
                            HStack {
                                Spacer()
                                Label("完成", systemImage: "checkmark")
                                Spacer()
                            }
                        })
                    }
                }
            }
            .onAppear {
                archiveLinks = UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()
                archiveCustomNameChart = (UserDefaults.standard.dictionary(forKey: "WebArchiveCustomNameChart") as? [String: String]) ?? [String: String]()
            }
        }
    }
}
