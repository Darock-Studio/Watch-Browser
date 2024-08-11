//
//  BookListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 6/27/24.
//

import OSLog
import SwiftUI
import Dynamic
import EPUBKit
import Alamofire
import MarkdownUI
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
            Section {
                NavigationLink(destination: { BookReaderView(document: document) }, label: {
                    Text(UserDefaults.standard.integer(forKey: "\(document.directory.lastPathComponent)ReadOffset") == 0 ? "开始阅读" : "继续阅读")
                })
            }
        }
    }
}

struct LocalBooksView: View {
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLocalBooks") var usePasscodeForLocalBooks = false
    @AppStorage("IsThisClusterInstalled") var isThisClusterInstalled = false
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
                                            globalErrorHandler(error)
                                        }
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
            .onAppear {
                bookFolderNames = UserDefaults.standard.stringArray(forKey: "EPUBFlieFolders") ?? [String]()
                nameChart = (UserDefaults.standard.dictionary(forKey: "EPUBFileNameChart") as? [String: String]) ?? [String: String]()
            }
        }
    }
}

struct BookReaderView: View {
    var document: EPUBDocument
    @AppStorage("RVFontSize") var fontSize = 14
    @AppStorage("RVIsBoldText") var isBoldText = false
    @AppStorage("RVCharacterSpacing") var characterSpacing = 1.0
    @State var contents = CodableAttributedStringArray()
    @State var loadProgress = 0.0
    @State var toolbarVisibility = Visibility.visible
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                if !contents.isEmpty {
                    LazyVStack(alignment: .leading) {
                        ForEach(0..<contents.count, id: \.self) { i in
                            Text(AttributedString(contents[i]))
                                .onAppear {
                                    UserDefaults.standard.set(i, forKey: "\(document.directory.lastPathComponent)ReadOffset")
                                }
                        }
                    }
                    .onTapGesture {
                        toolbarVisibility = .visible
                        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                            toolbarVisibility = .hidden
                        }
                    }
                    .onAppear {
                        withAnimation {
                            scrollProxy.scrollTo(UserDefaults.standard.integer(forKey: "\(document.directory.lastPathComponent)ReadOffset"), anchor: .center)
                        }
                    }
                } else {
                    Text("正在载入...")
                    ProgressView(value: loadProgress)
                    Text("首次载入可能需要一些时间，完成后将缓存数据以加快后续载入。")
                        .padding(.vertical)
                }
            }
        }
        .toolbar(toolbarVisibility, for: .navigationBar)
        .animation(.easeOut, value: toolbarVisibility)
        .onAppear {
            extendScreenIdleTime(1200)
            DispatchQueue(label: "com.darock.WatchBrowser.load-book-content", qos: .userInitiated).async {
                do {
                    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/tmp/Book\(document.directory.lastPathComponent)Cache.drkdatae") {
                        let data = try Data(contentsOf: URL(filePath: NSHomeDirectory() + "/tmp/Book\(document.directory.lastPathComponent)Cache.drkdatae"))
                        let decoder = PropertyListDecoder()
                        contents = try decoder.decode(CodableAttributedStringArray.self, from: data)
                        contents = CodableAttributedStringArray(contents.map { element in
                            let mutable = NSMutableAttributedString(attributedString: element)
                            let fullRange = NSMakeRange(0, element.length)
                            mutable.setAttributes([.foregroundColor: UIColor.white,
                                                   .font: UIFont.systemFont(ofSize: CGFloat(fontSize), weight: isBoldText ? .bold : .regular),
                                                   .kern: CGFloat(characterSpacing)],
                                                  range: fullRange
                            )
                            return NSAttributedString(attributedString: mutable)
                        })
                    }
                    let spines = document.spine.items
                    var tmpContents = [NSAttributedString]()
                    for i in 0..<spines.count {
                        let id = spines[i].idref
                        let idChart = document.manifest.items
                        if let path = idChart[id]?.path {
                            let rawStr = try String(contentsOf: document.contentDirectory.appending(path: path), encoding: .utf8)
                            let splitedStrs = rawStr.components(separatedBy: .newlines)
                            for j in 0..<splitedStrs.count {
                                let attrStr = try NSMutableAttributedString(
                                    data: splitedStrs[j].data(using: .utf8)!,
                                    options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                                    documentAttributes: nil
                                )
                                let fullRange = NSMakeRange(0, attrStr.length)
                                attrStr.setAttributes([.foregroundColor: UIColor.white,
                                                       .font: UIFont.systemFont(ofSize: CGFloat(fontSize), weight: isBoldText ? .bold : .regular),
                                                       .kern: CGFloat(characterSpacing)],
                                                      range: fullRange
                                )
                                tmpContents.append(attrStr)
                                loadProgress += 1.0 / Double(splitedStrs.count) * 1.0 / Double(spines.count)
                            }
                        }
                    }
                    contents = .init(tmpContents)
                    DispatchQueue.main.async {
                        recoverNormalIdleTime()
                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                            toolbarVisibility = .hidden
                        }
                    }
                    let encoder = PropertyListEncoder()
                    encoder.outputFormat = .binary
                    try encoder.encode(contents).write(to: URL(filePath: NSHomeDirectory() + "/tmp/Book\(document.directory.lastPathComponent)Cache.drkdatae"))
                } catch {
                    globalErrorHandler(error)
                }
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
                                .frame(width: WKInterfaceDevice.current().screenBounds.width, height: WKInterfaceDevice.current().screenBounds.height)
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

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


private struct CodableAttributedString: Codable {
    var attributedString: NSAttributedString = NSAttributedString()
    
    enum CodingKeys: String, CodingKey {
        case string
    }
    
    init() {}
    init(_ attributedString: NSAttributedString) {
        self.attributedString = attributedString
    }
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let attrStr = try container.decode(String.self, forKey: .string)
        attributedString = .init(string: attrStr)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(attributedString.string, forKey: .string)
    }
}
struct CodableAttributedStringArray: Codable {
    private var array: [CodableAttributedString] = []
    
    enum CodingKeys: String, CodingKey {
        case array
    }
    
    init() {}
    init(_ array: [NSAttributedString]) {
        self.array = array.map { CodableAttributedString($0) }
    }
}
extension CodableAttributedStringArray {
    subscript (index: Int) -> NSAttributedString {
        get {
            return array[index].attributedString
        }
        set {
            array[index].attributedString = newValue
        }
    }
    
    @inlinable
    func map<T, E>(_ transform: (NSAttributedString) throws(E) -> T) throws(E) -> [T] where E: Error {
        let initialCapacity = array.underestimatedCount
        var result = ContiguousArray<T>()
        result.reserveCapacity(initialCapacity)
        
        var iterator = array.makeIterator()
        
        // Add elements up to the initial capacity without checking for regrowth.
        for _ in 0..<initialCapacity {
            result.append(try transform(iterator.next()!.attributedString))
        }
        // Add remaining elements, if any.
        while let element = iterator.next() {
            result.append(try transform(element.attributedString))
        }
        
        return Array(result)
    }
    
    var isEmpty: Bool {
        array.isEmpty
    }
    
    var count: Int {
        array.count
    }
}
