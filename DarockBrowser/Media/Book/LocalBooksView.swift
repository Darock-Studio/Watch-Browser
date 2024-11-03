//
//  LocalBooksView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI
import EPUBKit

struct LocalBooksView: View {
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLocalBooks") var usePasscodeForLocalBooks = false
    @AppStorage("IsThisClusterInstalled") var isThisClusterInstalled = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var bookFolderNames = [String]()
    @State var nameChart = [String: String]()
    @State var deleteItemIndex = 0
    @State var isDeleteItemAlertPresented = false
    var body: some View {
        if isLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLocalBooks {
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
                if !bookFolderNames.isEmpty {
                    Section {
                        ForEach(0..<bookFolderNames.count, id: \.self) { i in
                            if let epubDoc = EPUBDocument(url: URL(filePath: NSHomeDirectory() + "/Documents/\(bookFolderNames[i])")) {
                                NavigationLink(destination: {
                                    List {
                                        BookViewerView.BookDetailView(document: epubDoc)
                                    }
                                    .modifier(BlurBackground(imageUrl: epubDoc.cover))
                                    .navigationTitle(EPUBDocument(url: URL(filePath: NSHomeDirectory() + "/Documents/\(bookFolderNames[i])"))!.title ?? "")
                                }, label: {
                                    Text(nameChart[bookFolderNames[i]] ?? bookFolderNames[i])
                                })
                                .swipeActions {
                                    Button(role: .destructive, action: {
                                        deleteItemIndex = i
                                        isDeleteItemAlertPresented = true
                                    }, label: {
                                        Image(systemName: "xmark.bin.fill")
                                    })
                                }
                                .swipeActions(edge: .leading) {
                                    if isThisClusterInstalled {
                                        Button(action: {
                                            do {
                                                let containerFilePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.darockst")!.path + "/TransferFile.drkdatat"
                                                if FileManager.default.fileExists(atPath: containerFilePath) {
                                                    try FileManager.default.removeItem(atPath: containerFilePath)
                                                }
                                                try FileManager.default.copyItem(
                                                    atPath: NSHomeDirectory() + "/Documents/" + bookFolderNames[i],
                                                    toPath: containerFilePath
                                                )
                                                WKExtension.shared().openSystemURL(URL(string: "https://darock.top/cluster/add/\(bookFolderNames[i])")!)
                                            } catch {
                                                globalErrorHandler(error)
                                            }
                                        }, label: {
                                            Image(systemName: "square.grid.3x1.folder.badge.plus")
                                        })
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("无本地图书")
                }
            }
            .navigationTitle("本地图书")
            .navigationBarTitleDisplayMode(.inline)
            .alert("删除项目", isPresented: $isDeleteItemAlertPresented, actions: {
                Button(role: .cancel, action: {}, label: {
                    Text("取消")
                })
                Button(role: .destructive, action: {
                    do {
                        try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/\(bookFolderNames[deleteItemIndex])")
                        nameChart.removeValue(forKey: bookFolderNames[deleteItemIndex])
                        bookFolderNames.remove(at: deleteItemIndex)
                        UserDefaults.standard.set(bookFolderNames, forKey: "EPUBFlieFolders")
                        UserDefaults.standard.set(nameChart, forKey: "EPUBFileNameChart")
                    } catch {
                        globalErrorHandler(error)
                    }
                }, label: {
                    Text("删除")
                })
            }, message: {
                Text("确定要删除此项目吗\n此操作不可撤销")
            })
            .onAppear {
                bookFolderNames = UserDefaults.standard.stringArray(forKey: "EPUBFlieFolders") ?? [String]()
                nameChart = (UserDefaults.standard.dictionary(forKey: "EPUBFileNameChart") as? [String: String]) ?? [String: String]()
            }
        }
    }
}
