//
//  Widget.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import Pictor
import SwiftUI
import WidgetKit
import DarockFoundation

extension SettingsView {
    @available(watchOS 10.0, *)
    struct WidgetSettingsView: View {
        @AppStorage("IsProPurchased") var isProPurchased = false
        var body: some View {
            if isProPurchased {
                List {
                    Section {
                        NavigationLink(destination: { BookmarkWidgetsView() }, label: {
                            Label("书签", systemImage: "bookmark")
                        })
                    }
                }
                .navigationTitle("小组件")
            } else {
                ProUnavailableView()
            }
        }
        
        struct BookmarkWidgetsView: View {
            @State var bookmarks = [SingleWidgetBookmark]()
            @State var isAddBookmarkPresented = false
            var body: some View {
                List {
                    if !bookmarks.isEmpty {
                        Section {
                            ForEach(0..<bookmarks.count, id: \.self) { i in
                                NavigationLink(destination: { ModifyBookmarkView(index: i) }, label: {
                                    VStack(alignment: .leading) {
                                        Text(bookmarks[i].displayName)
                                        Text(bookmarks[i].link)
                                            .font(.system(size: 14))
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                            .foregroundStyle(.gray)
                                    }
                                })
                                .swipeActions {
                                    Button(role: .destructive, action: {
                                        bookmarks.remove(at: i)
                                        let containerPath = FileManager.default.containerURL(
                                            forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets"
                                        )!.path
                                        do {
                                            try jsonString(from: bookmarks)?.write(
                                                toFile: containerPath + "/WidgetBookmarks.drkdataw",
                                                atomically: true,
                                                encoding: .utf8
                                            )
                                        } catch {
                                            globalErrorHandler(error)
                                        }
                                        WidgetCenter.shared.reloadTimelines(ofKind: "BookmarkWidgets")
                                        WidgetCenter.shared.invalidateConfigurationRecommendations()
                                    }, label: {
                                        Image(systemName: "xmark.circle.fill")
                                    })
                                }
                            }
                        }
                    } else {
                        VStack {
                            Image(systemName: "circle.slash")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            VStack {
                                Text("无书签小组件")
                                    .font(.headline)
                                Text("轻触 \(Image(systemName: "plus")) 按钮以添加")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical)
                        }
                        .centerAligned()
                        .listRowBackground(Color.clear)
                    }
                }
                .navigationTitle("书签小组件")
                .sheet(isPresented: $isAddBookmarkPresented, onDismiss: refreshBookmarks, content: { AddBookmarkView() })
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isAddBookmarkPresented = true
                        }, label: {
                            Image(systemName: "plus")
                        })
                    }
                }
                .onAppear {
                    refreshBookmarks()
                }
            }
            
            func refreshBookmarks() {
                let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets")!.path
                if let _bookmarksStr = try? String(contentsOfFile: containerPath + "/WidgetBookmarks.drkdataw", encoding: .utf8),
                   let fileBookmarks = getJsonData([SingleWidgetBookmark].self, from: _bookmarksStr) {
                    bookmarks = fileBookmarks
                }
            }
            
            struct AddBookmarkView: View {
                @Environment(\.presentationMode) var presentationMode
                @State var nameInput = ""
                @State var linkInput = ""
                @State var symbolSelection = "bookmark.fill"
                @State var isHistorySelectorPresented = false
                @State var isBookmarkSelectorPresented = false
                var body: some View {
                    NavigationStack {
                        List {
                            Section {
                                TextField("名称", text: $nameInput)
                                TextField("链接", text: $linkInput) {
                                    if !linkInput.hasPrefix("http://") && !linkInput.hasPrefix("https://") {
                                        linkInput = "http://" + linkInput
                                    }
                                }
                                .noAutoInput()
                                PictorSymbolPicker(symbol: $symbolSelection, presentAsSheet: true, selectionColor: .white, aboutLinkIsHidden: true, label: {
                                    VStack(alignment: .leading) {
                                        Text("符号")
                                        HStack(spacing: 2) {
                                            Image(systemName: symbolSelection)
                                            Text(symbolSelection)
                                                .lineLimit(1)
                                        }
                                        .font(.system(size: 14))
                                        .foregroundStyle(.gray)
                                    }
                                })
                            }
                            Section {
                                Button(action: {
                                    isHistorySelectorPresented = true
                                }, label: {
                                    Label("从历史记录选择", systemImage: "clock")
                                })
                                Button(action: {
                                    isBookmarkSelectorPresented = true
                                }, label: {
                                    Label("从网页书签选择", systemImage: "bookmark")
                                })
                            }
                        }
                        .navigationTitle("添加书签小组件")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    let containerPath = FileManager.default.containerURL(
                                        forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets"
                                    )!.path
                                    var bookmarks = [SingleWidgetBookmark]()
                                    if let _bookmarksStr = try? String(contentsOfFile: containerPath + "/WidgetBookmarks.drkdataw", encoding: .utf8),
                                       let fileBookmarks = getJsonData([SingleWidgetBookmark].self, from: _bookmarksStr) {
                                        bookmarks = fileBookmarks
                                    }
                                    bookmarks.append(.init(displayName: nameInput, displaySymbol: symbolSelection, link: linkInput))
                                    do {
                                        try jsonString(from: bookmarks)?.write(
                                            toFile: containerPath + "/WidgetBookmarks.drkdataw",
                                            atomically: true,
                                            encoding: .utf8
                                        )
                                    } catch {
                                        globalErrorHandler(error)
                                    }
                                    WidgetCenter.shared.reloadTimelines(ofKind: "BookmarkWidgets")
                                    WidgetCenter.shared.invalidateConfigurationRecommendations()
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Image(systemName: "plus")
                                })
                                .disabled(nameInput.isEmpty || linkInput.isEmpty)
                            }
                        }
                    }
                    .sheet(isPresented: $isHistorySelectorPresented) {
                        NavigationStack {
                            HistoryView { sel in
                                linkInput = sel
                                isHistorySelectorPresented = false
                            }
                            .navigationTitle("选取历史记录")
                        }
                    }
                    .sheet(isPresented: $isBookmarkSelectorPresented) {
                        NavigationStack {
                            BookmarkView { name, link in
                                nameInput = name
                                linkInput = link
                                isBookmarkSelectorPresented = false
                            }
                            .navigationTitle("选取书签")
                        }
                    }
                }
            }
            struct ModifyBookmarkView: View {
                var index: Int
                @Environment(\.presentationMode) var presentationMode
                @State var nameInput = ""
                @State var linkInput = ""
                @State var symbolSelection = "bookmark.fill"
                @State var isHistorySelectorPresented = false
                @State var isBookmarkSelectorPresented = false
                var body: some View {
                    List {
                        Section {
                            TextField("名称", text: $nameInput)
                            TextField("链接", text: $linkInput) {
                                if !linkInput.hasPrefix("http://") && !linkInput.hasPrefix("https://") {
                                    linkInput = "http://" + linkInput
                                }
                            }
                            .noAutoInput()
                            PictorSymbolPicker(symbol: $symbolSelection, presentAsSheet: true, selectionColor: .white, aboutLinkIsHidden: true, label: {
                                VStack(alignment: .leading) {
                                    Text("符号")
                                    HStack(spacing: 2) {
                                        Image(systemName: symbolSelection)
                                        Text(symbolSelection)
                                            .lineLimit(1)
                                    }
                                    .font(.system(size: 14))
                                    .foregroundStyle(.gray)
                                }
                            })
                        }
                        Section {
                            Button(action: {
                                isHistorySelectorPresented = true
                            }, label: {
                                Label("从历史记录选择", systemImage: "clock")
                            })
                            Button(action: {
                                isBookmarkSelectorPresented = true
                            }, label: {
                                Label("从网页书签选择", systemImage: "bookmark")
                            })
                        }
                    }
                    .navigationTitle("修改书签")
                    .sheet(isPresented: $isHistorySelectorPresented) {
                        NavigationStack {
                            HistoryView { sel in
                                linkInput = sel
                                isHistorySelectorPresented = false
                            }
                            .navigationTitle("选取历史记录")
                        }
                    }
                    .sheet(isPresented: $isBookmarkSelectorPresented) {
                        NavigationStack {
                            BookmarkView { name, link in
                                nameInput = name
                                linkInput = link
                                isBookmarkSelectorPresented = false
                            }
                            .navigationTitle("选取书签")
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                let containerPath = FileManager.default.containerURL(
                                    forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets"
                                )!.path
                                var bookmarks = [SingleWidgetBookmark]()
                                if let _bookmarksStr = try? String(contentsOfFile: containerPath + "/WidgetBookmarks.drkdataw", encoding: .utf8),
                                   let fileBookmarks = getJsonData([SingleWidgetBookmark].self, from: _bookmarksStr) {
                                    bookmarks = fileBookmarks
                                }
                                bookmarks[index] = .init(displayName: nameInput, displaySymbol: symbolSelection, link: linkInput)
                                do {
                                    try jsonString(from: bookmarks)?.write(
                                        toFile: containerPath + "/WidgetBookmarks.drkdataw",
                                        atomically: true,
                                        encoding: .utf8
                                    )
                                } catch {
                                    globalErrorHandler(error)
                                }
                                WidgetCenter.shared.reloadTimelines(ofKind: "BookmarkWidgets")
                                WidgetCenter.shared.invalidateConfigurationRecommendations()
                                presentationMode.wrappedValue.dismiss()
                            }, label: {
                                Image(systemName: "checkmark")
                            })
                            .disabled(nameInput.isEmpty || linkInput.isEmpty)
                        }
                    }
                    .onAppear {
                        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets")!.path
                        if let _bookmarksStr = try? String(contentsOfFile: containerPath + "/WidgetBookmarks.drkdataw", encoding: .utf8),
                           let fileBookmarks = getJsonData([SingleWidgetBookmark].self, from: _bookmarksStr) {
                            if let bookmark = fileBookmarks[from: index] {
                                nameInput = bookmark.displayName
                                linkInput = bookmark.link
                                symbolSelection = bookmark.displaySymbol
                            } else {
                                presentationMode.wrappedValue.dismiss()
                                tipWithText("载入出错，请提交反馈", symbol: "xmark.circle.fill")
                            }
                        }
                    }
                }
            }
        }
    }
}
