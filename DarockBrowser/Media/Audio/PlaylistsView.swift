//
//  PlaylistsView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI
import DarockFoundation

struct PlaylistsView: View {
    var selectHandler: ((String) -> Void)?
    @Environment(\.presentationMode) var presentationMode
    @State var listFileNames = [String]()
    @State var isCreateListPresented = false
    @State var createListNameInput = ""
    @State var deletingIndex = 0
    @State var isConfirmDeletePresented = false
    @State var renameSourceName = ""
    @State var isRenamePresented = false
    @State var renameInput = ""
    var body: some View {
        List {
            if #unavailable(watchOS 10.5) {
                Section {
                    Button(action: {
                        isCreateListPresented = true
                    }, label: {
                        HStack {
                            Spacer()
                            Label("新建播放列表", systemImage: "plus")
                            Spacer()
                        }
                    })
                }
            }
            if !listFileNames.isEmpty {
                Section {
                    ForEach(0..<listFileNames.count, id: \.self) { i in
                        Group {
                            if let selectHandler {
                                Button(action: {
                                    selectHandler(listFileNames[i])
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Text(listFileNames[i].dropLast(9))
                                })
                            } else {
                                NavigationLink(destination: { ListDetailView(fileName: listFileNames[i]) }, label: {
                                    Text(listFileNames[i].dropLast(9))
                                })
                            }
                        }
                        .swipeActions {
                            Button(action: {
                                deletingIndex = i
                                isConfirmDeletePresented = true
                            }, label: {
                                Image(systemName: "xmark.bin.fill")
                            })
                            .tint(.red)
                            Button(action: {
                                renameSourceName = String(listFileNames[i].dropLast(9))
                                isRenamePresented = true
                            }, label: {
                                Image(systemName: "pencil.line")
                            })
                        }
                    }
                }
            } else {
                Text("无播放列表")
            }
        }
        .navigationTitle("\(selectHandler != nil ? "添加到" : "")播放列表")
        .sheet(isPresented: $isCreateListPresented) {
            NavigationStack {
                List {
                    Section {
                        TextField("名称", text: $createListNameInput, style: "field-page")
                        Button(action: {
                            let listStr = jsonString(from: [String]())!
                            do {
                                try listStr.write(toFile: NSHomeDirectory() + "/Documents/Playlists/\(createListNameInput).drkdatap",
                                                  atomically: true,
                                                  encoding: .utf8)
                            } catch {
                                globalErrorHandler(error)
                            }
                            createListNameInput = ""
                            getPlaylistFiles()
                            isCreateListPresented = false
                        }, label: {
                            Label("创建", systemImage: "plus")
                        })
                    }
                }
                .navigationTitle("创建播放列表")
            }
        }
        .sheet(isPresented: $isRenamePresented) {
            NavigationStack {
                List {
                    HStack {
                        Spacer()
                        Text("修改名称")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    TextField("名称", text: $renameInput, style: "field-page")
                    Button(action: {
                        do {
                            try FileManager.default.moveItem(
                                atPath: NSHomeDirectory() + "/Documents/Playlists/\(renameSourceName).drkdatap",
                                toPath: NSHomeDirectory() + "/Documents/Playlists/\(renameInput).drkdatap"
                            )
                            getPlaylistFiles()
                            isRenamePresented = false
                        } catch {
                            globalErrorHandler(error)
                        }
                    }, label: {
                        HStack {
                            Spacer()
                            Label("完成", systemImage: "checkmark")
                            Spacer()
                        }
                    })
                    .disabled(renameInput.isEmpty)
                }
            }
            .onDisappear {
                renameInput = ""
            }
        }
        .alert("删除播放列表", isPresented: $isConfirmDeletePresented, actions: {
            Button(role: .cancel, action: {
                
            }, label: {
                Text("取消")
            })
            Button(role: .destructive, action: {
                do {
                    try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/Playlists/\(listFileNames[deletingIndex])")
                    listFileNames.remove(at: deletingIndex)
                } catch {
                    globalErrorHandler(error)
                }
            }, label: {
                Text("确认")
            })
        }, message: {
            Text("这将删除播放列表中的所有内容\n确定吗？")
        })
        .toolbar {
            if #available(watchOS 10.5, *) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isCreateListPresented = true
                    }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
        }
        .onAppear {
            getPlaylistFiles()
        }
    }
    
    func getPlaylistFiles() {
        do {
            if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/Playlists") {
                listFileNames = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/Playlists")
            } else {
                try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/Playlists", withIntermediateDirectories: true)
            }
        } catch {
            globalErrorHandler(error)
        }
    }
    
    struct ListDetailView: View {
        var fileName: String
        @State var listContent = [String]()
        @State var isAddMusicPresented = false
        @State var renameContentIndex = 0
        @State var isRenamePresented = false
        @State var renameInput = ""
        @State var audioHumanNameChart = [String: String]()
        var body: some View {
            List {
                if #unavailable(watchOS 10.5) {
                    Button(action: {
                        isAddMusicPresented = true
                    }, label: {
                        HStack {
                            Spacer()
                            Label("添加歌曲", systemImage: "plus")
                            Spacer()
                        }
                    })
                }
                if !listContent.isEmpty {
                    Section {
                        ForEach(0..<listContent.count, id: \.self) { i in
                            Button(action: {
                                setForAudioPlaying()
                                globalAudioCurrentPlaylist = fileName
                                playAudio(url: listContent[i])
                            }, label: {
                                Text(audioHumanNameChart[String(listContent[i].split(separator: "/").last!.split(separator: "=").last!)] ?? listContent[i])
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    listContent.remove(at: i)
                                    saveCurrentContent()
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                                Button(action: {
                                    renameContentIndex = i
                                    isRenamePresented = true
                                }, label: {
                                    Image(systemName: "pencil.line")
                                })
                            }
                        }
                        .onMove { source, destination in
                            listContent.move(fromOffsets: source, toOffset: destination)
                            saveCurrentContent()
                        }
                    }
                } else {
                    Text("空播放列表")
                }
            }
            .navigationTitle(fileName.dropLast(9))
            .sheet(isPresented: $isAddMusicPresented, onDismiss: { saveCurrentContent() }, content: { AddMusicToListView(listContent: $listContent) })
            .sheet(isPresented: $isRenamePresented) {
                NavigationStack {
                    List {
                        Section {
                            TextField("新名称", text: $renameInput, style: "field-page")
                            Button(action: {
                                audioHumanNameChart.updateValue(
                                    renameInput,
                                    forKey: String(listContent[renameContentIndex].split(separator: "/").last!.split(separator: "=").last!)
                                )
                                UserDefaults.standard.set(audioHumanNameChart, forKey: "AudioHumanNameChart")
                                saveCurrentContent()
                                isRenamePresented = false
                            }, label: {
                                Label("完成", systemImage: "checkmark")
                            })
                        }
                    }
                    .navigationTitle("重命名")
                }
                .onDisappear {
                    renameInput = ""
                }
            }
            .toolbar {
                if #available(watchOS 10.5, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isAddMusicPresented = true
                        }, label: {
                            Image(systemName: "plus")
                        })
                    }
                }
            }
            .onAppear {
                do {
                    let fileContent = try String(contentsOfFile: NSHomeDirectory() + "/Documents/Playlists/\(fileName)", encoding: .utf8)
                    listContent = getJsonData([String].self, from: fileContent) ?? [String]()
                } catch {
                    globalErrorHandler(error)
                }
                audioHumanNameChart = (UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]) ?? [String: String]()
            }
        }
        
        func saveCurrentContent() {
            if let content = jsonString(from: listContent) {
                do {
                    try content.write(toFile: NSHomeDirectory() + "/Documents/Playlists/\(fileName)", atomically: true, encoding: .utf8)
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
        
        struct AddMusicToListView: View {
            @Binding var listContent: [String]
            @Environment(\.presentationMode) var presentationMode
            @State var linkInput = ""
            @State var isAddLinkInvalid = false
            var body: some View {
                NavigationStack {
                    List {
                        Section {
                            NavigationLink(destination: {
                                LocalAudiosView { url in
                                    listContent.append(url)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }, label: {
                                Text("从离线歌曲选择")
                            })
                            TextField("输入歌曲链接", text: $linkInput, style: "field-page")
                                .onSubmit {
                                    if !linkInput.hasSuffix(".mp3") {
                                        isAddLinkInvalid = true
                                        return
                                    }
                                    if !linkInput.hasPrefix("http://") && !linkInput.hasPrefix("https://") {
                                        linkInput = "http://" + linkInput
                                    }
                                    listContent.append(linkInput)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            if isAddLinkInvalid {
                                HStack {
                                    Image(systemName: "xmark.octagon.fill")
                                        .foregroundStyle(.red)
                                    Text("歌曲链接无效")
                                }
                            }
                        }
                        Section {
                            Label("可在解析的音频列表页左滑项目以添加到列表", systemImage: "lightbulb.max")
                        }
                    }
                    .navigationTitle("添加歌曲")
                }
            }
        }
    }
}
