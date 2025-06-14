//
//  BookViewerView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import EPUBKit
import DarockUI
import Alamofire
import SDWebImageSwiftUI

struct BookViewerView: View {
    var bookLink: String
    @State var isFailedToLoad = false
    @State var bookDocument: EPUBDocument?
    @State var downloadProgress = ValuedProgress(completedUnitCount: 0, totalUnitCount: 0)
    var body: some View {
        List {
            if !isFailedToLoad {
                if let bookDocument {
                    BookDetailView(document: bookDocument)
                } else {
                    Section {
                        VStack {
                            Text("正在载入...")
                                .font(.system(size: 20, weight: .bold))
                            ProgressView(value: Double(downloadProgress.completedUnitCount), total: Double(downloadProgress.totalUnitCount))
                            Text("\(String(format: "%.2f", Double(downloadProgress.completedUnitCount) / Double(downloadProgress.totalUnitCount) * 100))%")
                            Text("\(String(format: "%.2f", Double(downloadProgress.completedUnitCount) / 1024 / 1024))MB / \(String(format: "%.2f", Double(downloadProgress.totalUnitCount) / 1024 / 1024))MB")
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                            if let eta = downloadProgress.estimatedTimeRemaining {
                                Text("预计时间：\(Int(eta))s")
                            }
                        }
                    }
                }
            } else {
                Text("载入书籍时出错")
            }
        }
        .modifier(BlurBackground(imageUrl: bookDocument?.cover))
        .navigationTitle(bookDocument?.title ?? "")
        .onAppear {
            let thisUUID = UUID().uuidString
            let destination: DownloadRequest.Destination = { _, _ in
                return (URL(fileURLWithPath: NSTemporaryDirectory() + "/EPUB\(thisUUID).epub"),
                        [.removePreviousFile, .createIntermediateDirectories])
            }
            AF.download(bookLink, to: destination)
                .downloadProgress { progress in
                    downloadProgress = ValuedProgress(completedUnitCount: progress.completedUnitCount,
                                                      totalUnitCount: progress.totalUnitCount,
                                                      estimatedTimeRemaining: progress.estimatedTimeRemaining)
                }
                .response { result in
                    guard let url = result.fileURL, let document = EPUBDocument(url: url) else {
                        debugPrint("Failed")
                        isFailedToLoad = true
                        try? FileManager.default.removeItem(atPath: NSTemporaryDirectory() + "/EPUB\(thisUUID).epub")
                        return
                    }
                    bookDocument = document
                    UserDefaults.standard.set(
                        [document.directory.lastPathComponent] + (UserDefaults.standard.stringArray(forKey: "EPUBFlieFolders") ?? [String]()),
                        forKey: "EPUBFlieFolders"
                    )
                    if let title = document.title {
                        var nChart = (UserDefaults.standard.dictionary(forKey: "EPUBFileNameChart") as? [String: String]) ?? [String: String]()
                        nChart.updateValue(title, forKey: document.directory.lastPathComponent)
                        UserDefaults.standard.set(nChart, forKey: "EPUBFileNameChart")
                    }
                    try? FileManager.default.removeItem(atPath: NSTemporaryDirectory() + "/EPUB\(thisUUID).epub")
                }
        }
    }
    
    struct BookDetailView: View {
        var document: EPUBDocument
        @AppStorage("RVReaderType") var readerType = "Scroll"
        @State var isCoverImageViewerPresented = false
        var body: some View {
            Section {
                if let cover = document.cover {
                    HStack {
                        Spacer()
                        WebImage(url: cover)
                            .resizable()
                            .scaledToFit()
                            .frame(height: WKInterfaceDevice.current().screenBounds.height - 100)
                            .cornerRadius(8)
                        Spacer()
                    }
                    .sheet(isPresented: $isCoverImageViewerPresented, content: { ImageViewerView(url: cover.absoluteString) })
                    .onTapGesture {
                        isCoverImageViewerPresented = true
                    }
                }
                if let author = document.author {
                    HStack {
                        Spacer()
                        Text(author)
                            .font(.system(size: 14))
                            .opacity(0.6)
                        Spacer()
                    }
                }
            }
            .listRowBackground(Color.clear)
            if readerType == "Scroll" {
                Section {
                    NavigationLink(destination: { BookReaderView(document: document) }, label: {
                        Text(UserDefaults.standard.integer(forKey: "\(document.directory.lastPathComponent)ReadOffset") == 0 ? "开始阅读" : "继续阅读")
                    })
                }
            } else {
                if let contents = document.tableOfContents.subTable {
                    Section {
                        contentLinks(from: contents, with: document.contentDirectory)
                    }
                }
            }
        }
        
        @ViewBuilder
        func contentLinks(from contents: [EPUBTableOfContents], with rootLink: URL) -> AnyView {
            AnyView(
                ForEach(0..<contents.count, id: \.self) { i in
                    NavigationLink(destination: {
                        if !(contents[i].subTable ?? [EPUBTableOfContents]()).isEmpty {
                            List {
                                if contents[i].item != nil {
                                    Section {
                                        NavigationLink(destination: { SingleContentPreviewView(content: contents[i], rootLink: rootLink) }, label: {
                                            Text(contents[i].label)
                                        })
                                    }
                                }
                                if let subTable = contents[i].subTable {
                                    Section {
                                        contentLinks(from: subTable, with: rootLink)
                                    }
                                }
                            }
                            .navigationTitle(contents[i].label)
                        } else {
                            SingleContentPreviewView(content: contents[i], rootLink: rootLink)
                        }
                    }, label: {
                        HStack {
                            Text(contents[i].label)
                            Spacer()
                            if !(contents[i].subTable ?? [EPUBTableOfContents]()).isEmpty {
                                Image(systemName: "chevron.forward")
                                    .opacity(0.6)
                            }
                        }
                    })
                }
            )
        }
        struct SingleContentPreviewView: View {
            var content: EPUBTableOfContents
            var rootLink: URL
            var body: some View {
                List {
                    Section {
                        HStack {
                            Spacer()
                            Text(content.label)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                    Section {
                        Button(action: {
                            pWebDelegateStartNavigationAutoViewport = true
                            AdvancedWebViewController.shared.present(archiveUrl: rootLink.appending(path: content.item!),
                                                                     loadMimeType: "text/html",
                                                                     overrideOldWebView: .alwaysAdvanced)
                        }, label: {
                            Text("开始阅读")
                        })
                    }
                }
            }
        }
    }
}
