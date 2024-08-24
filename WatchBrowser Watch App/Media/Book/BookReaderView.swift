//
//  BookReaderView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI
import EPUBKit
import DarockKit

struct BookReaderView: View {
    var document: EPUBDocument
    @AppStorage("RVFontSize") var fontSize = 14
    @AppStorage("RVIsBoldText") var isBoldText = false
    @AppStorage("RVCharacterSpacing") var characterSpacing = 1.0
    @State private var contents = CodableAttributedStringArray()
    @State var loadProgress = 0.0
    @State var toolbarVisibility = Visibility.visible
    @State var toolbarVisibilityResetTimer: Timer?
    @State var progressJumpSliderValue = 0.0
    @State var isFullLoaded = false
    @State var isProgressDraging = false
    @State var progressDragingNewPosition = 0.0
    @State var largeJumpCheckTimer: Timer?
    @State var previousPosition = 0
    @State var isRevertAvailable = false
    @State var revertPosition = 0
    @State var revertUnavailableCount = 0
    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                ScrollView {
                    if !contents.isEmpty {
                        LazyVStack(alignment: .leading) {
                            ForEach(0..<contents.count, id: \.self) { i in
                                Text(AttributedString(contents[i]))
                                    .onAppear {
                                        progressJumpSliderValue = Double(i)
                                        if _fastPath(isFullLoaded) {
                                            UserDefaults.standard.set(i, forKey: "\(document.directory.lastPathComponent)ReadOffset")
                                        }
                                    }
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
                .scrollIndicators(.never)
                if toolbarVisibility != .hidden && !contents.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView(value: isProgressDraging ? progressDragingNewPosition : progressJumpSliderValue, total: Double(contents.count - 1))
                            .progressViewStyle(.linear)
                            .padding()
                            .padding(.bottom)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        toolbarVisibilityResetTimer?.invalidate()
                                        toolbarVisibilityResetTimer = nil
                                        isProgressDraging = true
                                        let newPosition = progressJumpSliderValue
                                        + value.translation.width / (WKInterfaceDevice.current().screenBounds.width - 20) * Double(contents.count - 1)
                                        if newPosition >= 0 && newPosition <= Double(contents.count - 1) {
                                            progressDragingNewPosition = newPosition
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation {
                                            scrollProxy.scrollTo(Int(progressDragingNewPosition), anchor: .center)
                                        }
                                        progressJumpSliderValue = progressDragingNewPosition
                                        isProgressDraging = false
                                        if toolbarVisibilityResetTimer == nil {
                                            toolbarVisibilityResetTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                                toolbarVisibility = .hidden
                                            }
                                        }
                                    }
                            )
                    }
                    .ignoresSafeArea()
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isRevertAvailable {
                        Button(action: {
                            withAnimation {
                                scrollProxy.scrollTo(revertPosition, anchor: .center)
                                isRevertAvailable = false
                            }
                        }, label: {
                            Image(systemName: "arrow.uturn.backward")
                        })
                    }
                }
            }
        }
        .toolbar(toolbarVisibility, for: .navigationBar)
        ._statusBarHidden(toolbarVisibility == .hidden)
        .animation(.easeOut, value: toolbarVisibility)
        .onTapGesture {
            toolbarVisibility = .visible
            if isFullLoaded {
                if toolbarVisibilityResetTimer != nil {
                    toolbarVisibilityResetTimer?.invalidate()
                }
                toolbarVisibilityResetTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                    toolbarVisibility = .hidden
                }
            }
        }
        .onAppear {
            extendScreenIdleTime(1200)
            DispatchQueue(label: "com.darock.WatchBrowser.load-book-content", qos: .userInitiated).async {
                do {
                    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/tmp/Book\(document.directory.lastPathComponent)Cache.drkdatae") {
                        let data = try Data(contentsOf: URL(filePath: NSHomeDirectory() + "/tmp/Book\(document.directory.lastPathComponent)Cache.drkdatae"))
                        let decoder = PropertyListDecoder()
                        let decodeContents = try decoder.decode(CodableAttributedStringArray.self, from: data)
                        DispatchQueue.main.async {
                            contents = CodableAttributedStringArray(decodeContents.map { element in
                                let mutable = NSMutableAttributedString(attributedString: element)
                                let fullRange = NSMakeRange(0, element.length)
                                mutable.setAttributes([.foregroundColor: UIColor.white,
                                                       .font: UIFont.systemFont(ofSize: CGFloat(fontSize), weight: isBoldText ? .bold : .regular),
                                                       .kern: CGFloat(characterSpacing)],
                                                      range: fullRange
                                )
                                return NSAttributedString(attributedString: mutable)
                            })
                            recoverNormalIdleTime()
                            toolbarVisibilityResetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                toolbarVisibility = .hidden
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isFullLoaded = true
                            }
                        }
                        return
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
                    DispatchQueue.main.async {
                        contents = .init(tmpContents)
                        recoverNormalIdleTime()
                        toolbarVisibilityResetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                            toolbarVisibility = .hidden
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isFullLoaded = true
                        }
                    }
                    let encoder = PropertyListEncoder()
                    encoder.outputFormat = .binary
                    try encoder.encode(contents).write(to: URL(filePath: NSHomeDirectory() + "/tmp/Book\(document.directory.lastPathComponent)Cache.drkdatae"))
                } catch {
                    globalErrorHandler(error)
                }
            }
            largeJumpCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                if _slowPath(previousPosition != 0 && isFullLoaded && !isRevertAvailable && abs(Int(progressJumpSliderValue) - previousPosition) > 100) {
                    revertPosition = previousPosition
                    isRevertAvailable = true
                    revertUnavailableCount = 10
                } else if _slowPath(isRevertAvailable && revertUnavailableCount > 0) {
                    revertUnavailableCount--
                    if _slowPath(revertUnavailableCount == 0) {
                        isRevertAvailable = false
                    }
                }
                previousPosition = Int(progressJumpSliderValue)
            }
        }
        .onDisappear {
            largeJumpCheckTimer?.invalidate()
            largeJumpCheckTimer = nil
        }
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
private struct CodableAttributedStringArray: Codable {
    private var array: [CodableAttributedString] = []
    
    enum CodingKeys: String, CodingKey {
        case array
    }
    
    init() {}
    init(_ array: [NSAttributedString]) {
        self.array = array.map { CodableAttributedString($0) }
    }
}
private extension CodableAttributedStringArray {
    subscript (index: Int) -> NSAttributedString {
        get {
            return array[index].attributedString
        }
        set {
            array[index].attributedString = newValue
        }
    }
    
    func map<T>(_ transform: (NSAttributedString) throws -> T) rethrows -> [T] {
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
