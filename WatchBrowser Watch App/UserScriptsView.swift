//
//  UserScriptsView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/5/2.
//

import SwiftUI
import DarockKit
import SwiftSoup

struct UserScriptsView: View {
    @State var scriptNames = [String]()
    var body: some View {
        List {
            Section {
                NavigationLink(destination: { UserScriptsAddView() }, label: {
                    Label("添加脚本", systemImage: "plus")
                })
            }
            Section {
                if !scriptNames.isEmpty {
                    ForEach(0..<scriptNames.count, id: \.self) { i in
                        Text(scriptNames[i])
                            .lineLimit(3)
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    scriptNames.remove(at: i)
                                    UserDefaults.standard.set(scriptNames, forKey: "UserScriptNames")
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                            }
                    }
                }
            } header: {
                Text("已启用的脚本")
            }
        }
        .navigationTitle("用户脚本")
        .onAppear {
            scriptNames = UserDefaults.standard.stringArray(forKey: "UserScriptNames") ?? [String]()
            if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/UserScripts/") {
                try? FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/UserScripts/", withIntermediateDirectories: false)
            }
        }
    }
}

struct UserScriptsAddView: View {
    @State var searchResults = [(title: String, url: String)]()
    @State var searchInput = ""
    @State var isSearching = false
    var body: some View {
        List {
            Section {
                TextField("搜索...", text: $searchInput)
                    .submitLabel(.search)
                    .onSubmit {
                        if !searchInput.isEmpty {
                            isSearching = true
                            DarockKit.Network.shared
                                .requestString("https://greasyfork.org/\(NSLocale.current.languageCode == "zh" ? "zh-CN" : "en-US")/scripts?q=\(searchInput)")
                            { respStr, isSuccess in
                                if isSuccess {
                                    do {
                                        let doc = try SwiftSoup.parse(respStr)
                                        let scripts = try doc.body()?.select("a")
                                        if let scripts {
                                            for script in scripts {
                                                if try script.outerHtml().contains("class=\"script-link\""),
                                                   let target = try? script.attr("href"),
                                                   let title = try? script.text() {
                                                    searchResults.append((title, target))
                                                }
                                            }
                                        }
                                        isSearching = false
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }
                    }
            } footer: {
                Text("脚本均来自greasyfork.org，Darock 无法进行审核，请自行辨别内容")
            }
            Section {
                if !isSearching {
                    if !searchResults.isEmpty {
                        ForEach(0..<searchResults.count, id: \.self) { i in
                            NavigationLink(destination: { ScriptDetailView(title: searchResults[i].title, url: searchResults[i].url) }, label: {
                                Text(searchResults[i].title)
                                    .lineLimit(3)
                            })
                        }
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle("添加脚本")
    }
    
    struct ScriptDetailView: View {
        var title: String
        var url: String
        @State var applyTo = ""
        @State var description = ""
        @State var jsLink = ""
        @State var isInstalling = false
        @State var isInstalled = false
        var body: some View {
            List {
                Section {
                    Text(title)
                } header: {
                    Text("标题")
                }
                Section {
                    Text(applyTo)
                } header: {
                    Text("应用到")
                }
                Section {
                    if !jsLink.isEmpty {
                        if !isInstalling {
                            if !isInstalled {
                                Button(action: {
                                    isInstalling = true
                                    DarockKit.Network.shared.requestString(jsLink) { respStr, isSuccess in
                                        if isSuccess {
                                            do {
                                                try respStr.write(
                                                    toFile: NSHomeDirectory()
                                                    + "/Documents/UserScripts/\(title.replacingOccurrences(of: "/", with: "{slash}")).js",
                                                    atomically: true,
                                                    encoding: .utf8
                                                )
                                                UserDefaults.standard.set(
                                                    (UserDefaults.standard.stringArray(forKey: "UserScriptNames") ?? [String]()) + [title],
                                                    forKey: "UserScriptNames"
                                                )
                                                isInstalled = true
                                                isInstalling = false
                                            } catch {
                                                print(error)
                                            }
                                        }
                                    }
                                }, label: {
                                    Label("安装此脚本", systemImage: "plus")
                                        .foregroundColor(.green)
                                })
                            } else {
                                Text("此脚本已安装")
                            }
                        } else {
                            ProgressView()
                        }
                    }
                } header: {
                    Text("操作")
                }
                Section {
                    Text(description)
                } header: {
                    Text("描述")
                }
            }
            .navigationTitle("脚本详情")
            .onAppear {
                if (UserDefaults.standard.stringArray(forKey: "UserScriptNames") ?? [String]()).contains(title) {
                    isInstalled = true
                }
                DarockKit.Network.shared.requestString("https://greasyfork.org\(url)") { respStr, isSuccess in
                    if isSuccess {
                        do {
                            let doc = try SwiftSoup.parse(respStr)
                            if let metadataBlock = try doc.body()?.getElementsByClass("script-meta-block").first() {
                                applyTo = try metadataBlock.getElementsByClass("block-list expandable").select("code").text()
                            }
                            if let addInfo = try doc.body()?.getElementById("additional-info") {
                                description = try addInfo.select("p").map { try $0.text() }.joined(separator: "\n\n")
                            }
                            if let installArea = try doc.body()?.getElementById("install-area") {
                                jsLink = try installArea.select("a").first()!.attr("href")
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
    }
}
