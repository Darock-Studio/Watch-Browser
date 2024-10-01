//
//  LocalAudiosView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI
import DarockKit
import AVFoundation

struct LocalAudiosView: View {
    var selectHandler: ((String) -> Void)?
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLocalAudios") var usePasscodeForLocalAudios = false
    @AppStorage("IsThisClusterInstalled") var isThisClusterInstalled = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var audioNames = [String]()
    @State var audioHumanNameChart = [String: String]()
    @State var isEditNamePresented = false
    @State var editNameAudioName = ""
    @State var editNameInput = ""
    @State var deleteItemIndex = 0
    @State var isDeleteItemAlertPresented = false
    var body: some View {
        if isLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLocalAudios {
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
                    if !audioNames.isEmpty {
                        ForEach(0..<audioNames.count, id: \.self) { i in
                            Button(action: {
                                if let selectHandler {
                                    selectHandler("%DownloadedContent@=\(audioNames[i])")
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    setForAudioPlaying()
                                    globalAudioCurrentPlaylist = "LocalDownloadedAudio"
                                    let audioPathPrefix = URL(filePath: NSHomeDirectory() + "/Documents/DownloadedAudios")
                                    globalAudioPlayer.replaceCurrentItem(with: AVPlayerItem(url: audioPathPrefix.appending(path: audioNames[i])))
                                    if let noSuffix = audioNames[i].split(separator: ".").first, let mid = Int(noSuffix) {
                                        nowPlayingAudioId = String(mid)
                                    } else {
                                        nowPlayingAudioId = ""
                                    }
                                    pShouldPresentAudioController = true
                                    globalAudioPlayer.play()
                                }
                            }, label: {
                                Text(audioHumanNameChart[audioNames[i]] ?? audioNames[i])
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    deleteItemIndex = i
                                    isDeleteItemAlertPresented = true
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                                Button(action: {
                                    editNameAudioName = audioNames[i]
                                    editNameInput = audioHumanNameChart[audioNames[i]] ?? audioNames[i]
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
                                                atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/" + audioNames[i],
                                                toPath: containerFilePath
                                            )
                                            WKExtension.shared().openSystemURL(URL(string: "https://darock.top/cluster/add/\(audioNames[i])")!)
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
            .navigationTitle("本地音频")
            .alert("删除项目", isPresented: $isDeleteItemAlertPresented, actions: {
                Button(role: .cancel, action: {}, label: {
                    Text("取消")
                })
                Button(role: .destructive, action: {
                    do {
                        // Delete this in all playlists
                        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/Playlists") {
                            let playlistFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/Playlists")
                            for file in playlistFiles {
                                let content = try String(contentsOfFile: NSHomeDirectory() + "/Documents/Playlists/\(file)")
                                if var data = getJsonData([String].self, from: content) {
                                    data.removeAll(where: { element in
                                        element == "%DownloadedContent@=\(audioNames[deleteItemIndex])"
                                    })
                                    if let newStr = jsonString(from: data) {
                                        try newStr.write(
                                            toFile: NSHomeDirectory() + "/Documents/Playlists/\(file)",
                                            atomically: true,
                                            encoding: .utf8
                                        )
                                    }
                                }
                            }
                        }
                        try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/" + audioNames[deleteItemIndex])
                        audioNames.remove(at: deleteItemIndex)
                    } catch {
                        globalErrorHandler(error)
                    }
                }, label: {
                    Text("删除")
                })
            }, message: {
                Text("确定要删除此项目吗\n此操作不可撤销")
            })
            .sheet(isPresented: $isEditNamePresented) {
                NavigationStack {
                    List {
                        Section {
                            TextField("名称", text: $editNameInput, style: "field-page")
                            Button(action: {
                                audioHumanNameChart.updateValue(editNameInput, forKey: editNameAudioName)
                                UserDefaults.standard.set(audioHumanNameChart, forKey: "AudioHumanNameChart")
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
                    audioNames = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios")
                    audioHumanNameChart = (UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]) ?? [String: String]()
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
    }
}
