//
//  HistoryView.swift
//  WatchBrowser Watch App
//
//  Created by WindowsMEMZ on 2023/5/2.
//

import SwiftUI
import AuthenticationServices

struct HistoryView: View {
    var selectionHandler: ((String) -> Void)?
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @AppStorage("AllowCookies") var AllowCookies = false
    @State var isSettingPresented = false
    @State var isStopRecordingPagePresenting = false
    @State var histories = [String]()
    @State var isSharePresented = false
    @State var shareLink = ""
    @State var searchText = ""
    var body: some View {
        List {
            if selectionHandler == nil {
                Section {
                    Toggle("History.record", isOn: $isHistoryRecording)
                        .onChange(of: isHistoryRecording, perform: { e in
                            if !e {
                                isStopRecordingPagePresenting = true
                            }
                        })
                        .sheet(isPresented: $isStopRecordingPagePresenting, onDismiss: {
                            histories = UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()
                        }, content: {CloseHistoryTipView()})
                }
            }
            Section {
                if isHistoryRecording {
                    if histories.count != 0 {
                        TextField("\(Image(systemName: "magnifyingglass")) 搜索", text: $searchText)
                        ForEach(0...histories.count - 1, id: \.self) { i in
                            if searchText.isEmpty || histories[i].contains(searchText) {
                                Button(action: {
                                    if let selectionHandler {
                                        selectionHandler(histories[i])
                                    } else {
                                        if !histories[i].hasPrefix("file://") {
                                            AdvancedWebViewController.shared.present(histories[i].urlDecoded().urlEncoded())
                                        } else {
                                            AdvancedWebViewController.shared.present("", archiveUrl: URL(string: histories[i])!)
                                        }
                                    }
                                }, label: {
                                    if histories[i].hasPrefix("https://www.bing.com/search?q=") {
                                        Label(String(histories[i].urlDecoded().dropFirst(30)), systemImage: "magnifyingglass")
                                    } else if histories[i].hasPrefix("https://www.baidu.com/s?wd=") {
                                        Label(String(histories[i].urlDecoded().dropFirst(27)), systemImage: "magnifyingglass")
                                    } else if histories[i].hasPrefix("https://www.google.com/search?q=") {
                                        Label(String(histories[i].urlDecoded().dropFirst(32)), systemImage: "magnifyingglass")
                                    } else if histories[i].hasPrefix("https://www.sogou.com/web?query=") {
                                        Label(String(histories[i].urlDecoded().dropFirst(32)), systemImage: "magnifyingglass")
                                    } else if histories[i].hasPrefix("file://") {
                                        Label(String(histories[i].split(separator: "/").last!.split(separator: ".")[0]).replacingOccurrences(of: "{slash}", with: "/").base64Decoded() ?? "[解析失败]", systemImage: "archivebox")
                                    } else {
                                        Label(histories[i], systemImage: "globe")
                                    }
                                })
                                .privacySensitive()
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive, action: {
                                        histories.remove(at: i)
                                        UserDefaults.standard.set(histories, forKey: "WebHistory")
                                    }, label: {
                                        Image(systemName: "bin.xmark.fill")
                                    })
                                }
                                .swipeActions(edge: .leading) {
                                    Button(action: {
                                        shareLink = histories[i].urlDecoded().urlEncoded()
                                        isSharePresented = true
                                    }, label: {
                                        Image(systemName: "square.and.arrow.up.fill")
                                    })
                                }
                            }
                        }
                    } else {
                        Text("History.nothing")
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("History.not-recording")
                        .foregroundColor(.gray)
                }
            }
        }
        .sheet(isPresented: $isSharePresented, content: {ShareView(linkToShare: $shareLink)})
        .onAppear {
            histories = UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()
        }
    }
}

func RecordHistory(_ inp: String, webSearch: String) {
    var fullHistory = UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()
    if let lstf = fullHistory.first {
        guard lstf != inp && lstf != GetWebSearchedURL(inp, webSearch: webSearch, isSearchEngineShortcutEnabled: false) else {
            return
        }
    }
    if inp.isURL() || inp.hasPrefix("file://") {
        fullHistory = [inp] + fullHistory
    } else {
        fullHistory = [GetWebSearchedURL(inp, webSearch: webSearch, isSearchEngineShortcutEnabled: false)] + fullHistory
    }
    UserDefaults.standard.set(fullHistory, forKey: "WebHistory")
}

struct historiesettingView: View {
    @AppStorage("isHistoryRecording") var isHistoryRecording = true
    @State var isClosePagePresented = false
    var body: some View {
        List {
            Text("History.settings")
                .fontWeight(.bold)
                .font(.system(size: 20))
            Section {
                Toggle("History.record", isOn: $isHistoryRecording)
                    .onChange(of: isHistoryRecording, perform: { e in
                        if !e {
                            isClosePagePresented = true
                        }
                    })
                    .sheet(isPresented: $isClosePagePresented, content: {CloseHistoryTipView()})
            }
            Section {
                Button(role: .destructive, action: {
                    UserDefaults.standard.set([String](), forKey: "WebHistory")
                }, label: {
                    Text("History.clear")
                })
            }
        }
    }
}

struct CloseHistoryTipView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var body: some View {
        ScrollView {
            Text("History.turn-off")
                .fontWeight(.bold)
                .font(.system(size: 20))
            Text("History.clear-history-at-the-same-time")
            Button(role: .destructive, action: {
                UserDefaults.standard.set([String](), forKey: "WebHistory")
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Label("History.clear", systemImage: "trash.fill")
            })
            Button(role: .cancel, action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Label("History.save", systemImage: "arrow.down.doc.fill")
            })
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
