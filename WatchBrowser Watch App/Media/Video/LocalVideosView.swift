//
//  LocalVideosView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI

struct LocalVideosView: View {
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLocalVideos") var usePasscodeForLocalVideos = false
    @AppStorage("IsThisClusterInstalled") var isThisClusterInstalled = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var videoNames = [String]()
    @State var videoHumanNameChart = [String: String]()
    @State var isPlayerPresented = false
    @State var willPlayVideoLink = ""
    @State var isEditNamePresented = false
    @State var editNameVideoName = ""
    @State var editNameInput = ""
    @State var deleteItemIndex = 0
    @State var isDeleteItemAlertPresented = false
    var body: some View {
        if isLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLocalVideos {
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
                    if !videoNames.isEmpty {
                        ForEach(0..<videoNames.count, id: \.self) { i in
                            Button(action: {
                                if videoNames[i].hasPrefix("http://") || videoNames[i].hasPrefix("https://") {
                                    willPlayVideoLink = videoNames[i]
                                } else {
                                    willPlayVideoLink = URL(filePath: NSHomeDirectory() + "/Documents/DownloadedVideos/" + videoNames[i]).absoluteString
                                }
                                isPlayerPresented = true
                            }, label: {
                                HStack {
                                    if !videoNames[i].hasPrefix("http://") && !videoNames[i].hasPrefix("https://") {
                                        Image(systemName: "square.and.arrow.down.fill")
                                            .foregroundStyle(Color.gray)
                                    }
                                    Text(videoHumanNameChart[videoNames[i]] ?? videoNames[i])
                                }
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    deleteItemIndex = i
                                    isDeleteItemAlertPresented = true
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                                Button(action: {
                                    editNameVideoName = videoNames[i]
                                    isEditNamePresented = true
                                }, label: {
                                    Image(systemName: "pencil.line")
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
                                                atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/" + videoNames[i],
                                                toPath: containerFilePath
                                            )
                                            let saveFileName = videoNames[i].hasSuffix(".mp4") ? videoNames[i] : videoNames[i] + ".mp4"
                                            WKExtension.shared().openSystemURL(URL(string: "https://darock.top/cluster/add/\(saveFileName)")!)
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
            }
            .navigationTitle("视频")
            .alert("删除项目", isPresented: $isDeleteItemAlertPresented, actions: {
                Button(role: .cancel, action: {}, label: {
                    Text("取消")
                })
                Button(role: .destructive, action: {
                    do {
                        if videoNames[deleteItemIndex].hasPrefix("http://") || videoNames[deleteItemIndex].hasPrefix("https://") {
                            let linkFilePath = NSHomeDirectory() + "/Documents/SavedVideoLinks.drkdatas"
                            if !FileManager.default.fileExists(atPath: linkFilePath) {
                                try jsonString(from: [String]())!.write(toFile: linkFilePath, atomically: true, encoding: .utf8)
                            }
                            if let fileStr = try? String(contentsOfFile: linkFilePath, encoding: .utf8),
                               var links = getJsonData([String].self, from: fileStr) {
                                if let di = links.firstIndex(of: videoNames[deleteItemIndex]) {
                                    links.remove(at: di)
                                    try jsonString(from: links)!.write(toFile: linkFilePath, atomically: true, encoding: .utf8)
                                }
                            }
                        } else {
                            try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/" + videoNames[deleteItemIndex])
                        }
                        videoNames.remove(at: deleteItemIndex)
                    } catch {
                        globalErrorHandler(error)
                    }
                }, label: {
                    Text("删除")
                })
            }, message: {
                Text("确定要删除此项目吗\n此操作不可撤销")
            })
            .sheet(isPresented: $isPlayerPresented, content: { VideoPlayingView(link: $willPlayVideoLink) })
            .sheet(isPresented: $isEditNamePresented) {
                NavigationStack {
                    List {
                        Section {
                            TextField("名称", text: $editNameInput, style: "field-page")
                            Button(action: {
                                videoHumanNameChart.updateValue(editNameInput, forKey: editNameVideoName)
                                UserDefaults.standard.set(videoHumanNameChart, forKey: "VideoHumanNameChart")
                                isEditNamePresented = false
                            }, label: {
                                Label("保存", systemImage: "arrow.down.doc")
                            })
                        }
                    }
                    .navigationTitle("自定名称")
                    .navigationBarTitleDisplayMode(.large)
                }
                .onDisappear {
                    editNameInput = ""
                }
            }
            .onAppear {
                do {
                    videoNames = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos")
                    let linkFilePath = NSHomeDirectory() + "/Documents/SavedVideoLinks.drkdatas"
                    if FileManager.default.fileExists(atPath: linkFilePath) {
                        if let fileStr = try? String(contentsOfFile: linkFilePath, encoding: .utf8),
                           let links = getJsonData([String].self, from: fileStr) {
                            videoNames += links
                        }
                    }
                    videoNames.sort()
                    videoHumanNameChart = (UserDefaults.standard.dictionary(forKey: "VideoHumanNameChart") as? [String: String]) ?? [String: String]()
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
    }
}
