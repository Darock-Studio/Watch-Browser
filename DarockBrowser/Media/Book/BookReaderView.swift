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
    @State private var contents = [String]()
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
                                Text(contents[i])
                                    .font(.system(size: CGFloat(fontSize), weight: isBoldText ? .bold : .regular))
                                    .kerning(characterSpacing)
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
            DispatchQueue(label: "com.darock.WatchBrowser.load-book-content", qos: .userInitiated).async {
                do {
                    let spines = document.spine.items
                    var tmpContents = [String]()
                    for i in 0..<spines.count {
                        let id = spines[i].idref
                        let idChart = document.manifest.items
                        if let path = idChart[id]?.path {
                            let rawStr = try String(contentsOf: document.contentDirectory.appending(path: path), encoding: .utf8)
                            let attrStr = try NSMutableAttributedString(
                                data: rawStr.data(using: .utf8)!,
                                options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                                documentAttributes: nil
                            )
                            let progressAddPiece = 1.0 / Double(spines.count)
                            tmpContents.append(contentsOf: attrStr.string.components(separatedBy: .newlines))
                            loadProgress += progressAddPiece
                        }
                    }
                    DispatchQueue.main.async {
                        contents = .init(tmpContents)
                        toolbarVisibilityResetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                            toolbarVisibility = .hidden
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isFullLoaded = true
                        }
                    }
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
