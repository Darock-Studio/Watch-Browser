//
//  BookListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 6/27/24.
//

import SwiftUI
import Dynamic
import EPUBKit
import Alamofire
import SDWebImageSwiftUI

struct BookListView: View {
    var body: some View {
        if !bookLinkLists.isEmpty {
            List {
                Section {
                    ForEach(0..<bookLinkLists.count, id: \.self) { i in
                        NavigationLink(destination: { BookViewerView(bookLink: bookLinkLists[i]) }, label: {
                            Text(bookLinkLists[i])
                        })
                    }
                }
                Section {
                    HStack {
                        Image(systemName: "lightbulb.max")
                            .foregroundColor(.orange)
                        Text("图书会在访问后保存在磁盘上，您可以稍后进行管理。")
                    }
                }
            }
            .navigationTitle("图书列表")
            .onDisappear {
                if dismissListsShouldRepresentWebView {
                    DispatchQueue.main.async {
                        Dynamic.UIApplication.sharedApplication.keyWindow.rootViewController.presentViewController(
                            AdvancedWebViewController.shared.vc,
                            animated: true,
                            completion: nil
                        )
                    }
                }
            }
        } else {
            Text("空图书列表")
        }
    }
}

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
            if let contents = document.tableOfContents.subTable {
                Section {
                    contentLinks(from: contents, with: document.contentDirectory)
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
                                                                 overrideOldWebView: true)
                    }, label: {
                        Text("开始阅读")
                    })
                }
            }
        }
    }
}

struct LocalBooksView: View {
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLocalBooks") var usePasscodeForLocalBooks = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var bookFolderNames = [String]()
    @State var nameChart = [String: String]()
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
                                        do {
                                            try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/\(bookFolderNames[i])")
                                            nameChart.removeValue(forKey: bookFolderNames[i])
                                            bookFolderNames.remove(at: i)
                                            UserDefaults.standard.set(bookFolderNames, forKey: "EPUBFlieFolders")
                                            UserDefaults.standard.set(nameChart, forKey: "EPUBFileNameChart")
                                        } catch {
                                            globalErrorHandler(error, at: "\(#file)-\(#function)-\(#line)")
                                        }
                                    }, label: {
                                        Image(systemName: "xmark.bin.fill")
                                    })
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
            .onAppear {
                bookFolderNames = UserDefaults.standard.stringArray(forKey: "EPUBFlieFolders") ?? [String]()
                nameChart = (UserDefaults.standard.dictionary(forKey: "EPUBFileNameChart") as? [String: String]) ?? [String: String]()
            }
        }
    }
}

struct BlurBackground: ViewModifier {
    var imageUrl: URL?
    @State private var backgroundPicOpacity: CGFloat = 0.0
    func body(content: Content) -> some View {
        if #available(watchOS 10, *) {
            content
                .containerBackground(for: .navigation) {
                    if let imageUrl {
                        ZStack {
                            WebImage(url: imageUrl)
                                .onSuccess { _, _, _ in
                                    backgroundPicOpacity = 1.0
                                }
                                .resizable()
                                .scaledToFill()
                                .blur(radius: 20)
                                .opacity(backgroundPicOpacity)
                                .animation(.easeOut(duration: 1.2), value: backgroundPicOpacity)
                            Color.black
                                .opacity(0.4)
                        }
                    }
                }
        } else {
            content
        }
    }
}
