//
//  WebSummaryView.swift
//  WatchBrowser
//
//  Created by memz233 on 10/3/24.
//

import SwiftUI
import SwiftSoup
import DarockFoundation
import DarockIntelligenceKit

struct WebSummaryView: View {
    var webView: WKWebView
    @State var summaryString = ""
    @State var isFailedLoading = false
    @State var animateAngle: CGFloat = -45
    @State var animateTimer: Timer?
    var body: some View {
        NavigationStack {
            if !isFailedLoading {
                if !summaryString.isEmpty {
                    ScrollView {
                        Text(summaryString)
                    }
                    .navigationTitle("网页摘要")
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .navigationTitle("正在载入摘要…")
                }
            } else {
                VStack {
                    Text("总结摘要时出错")
                    Button(action: getAbstract, label: {
                        Text("重试")
                            .foregroundStyle(.blue)
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: WKInterfaceDevice.current().screenCornerRadius)
                .stroke(AngularGradient(
                    colors: [.init(hex: 0xf0aa3d), .init(hex: 0xef4b62), .init(hex: 0x9ec8e1), .init(hex: 0xce96f9)],
                    center: .center,
                    angle: .degrees(animateAngle)
                ), lineWidth: 6)
                .blur(radius: 3)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .onDisappear {
                    animateTimer?.invalidate()
                }
        }
        .onAppear {
            getAbstract()
            playHaptic(from: Bundle.main.url(forResource: "IntelligenceStart", withExtension: "ahap")!)
        }
    }
    
    func getAbstract() {
        isFailedLoading = false
        summaryString = ""
        animateTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            animateAngle += 1
        }
        webView.evaluateJavaScript("document.documentElement.outerHTML") { obj, _ in
            DispatchQueue(label: "com.darock.WatchBrowser.Intelligence.Abstract", qos: .userInitiated).async {
                if let sourceCode = obj as? String {
                    do {
                        let document = try SwiftSoup.parse(sourceCode)
                        var texts = [String]()
                        var appendTextCount = 0
                        for text in try document.select("*") {
                            let text = try text.text()
                            if text.trimmingCharacters(in: .whitespaces).isEmpty == false && !texts.contains(text) {
                                texts.append(text)
                                appendTextCount++
                                if appendTextCount > 2000 {
                                    break
                                }
                            }
                        }
                        let visibleText = texts.joined(separator: " ")
                        Task {
                            if !(await webSummary(from: String(visibleText.prefix(2000))) { str in
                                DispatchQueue.main.async {
                                    summaryString += str
                                }
                            }) {
                                DispatchQueue.main.async {
                                    isFailedLoading = true
                                }
                            }
                            DispatchQueue.main.async {
                                animateTimer?.invalidate()
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            isFailedLoading = true
                            animateTimer?.invalidate()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        isFailedLoading = true
                        animateTimer?.invalidate()
                    }
                }
            }
        }
    }
}

private func webSummary(from sourceText: String, addingTo addingHandler: @escaping (String) -> Void) async -> Bool {
    let langOption = UserDefaults.standard.string(forKey: "DIWebAbstractLangOption") ?? "Web"
    let modelOption = UserDefaults.standard.string(forKey: "DIWebAbstractModelOption") ?? "Faster"
    let messages: [IntelligenceChatMessage] = [
        .init(role: .system, content: """
        你是一个网页摘要总结助手，我将向你发送一部分网页中的文本，直接回复文本所对应网页内容的摘要，以\({
        if langOption == "Web" {
            return "网页内容"
        } else {
            return NSLocale.current.language.languageCode!.identifier
        }
        }())语言总结摘要，不要回复任何多余文本。
        """),
        .init(role: .user, content: sourceText)
    ]
    return await withCheckedContinuation { continuation in
        intelligenceChat(with: modelOption == "Accurater" ? .deepseekR1_7b : .deepseekR1_1p5b, about: messages, handling: .mainOnly) { result in
            switch result {
            case let .success(response):
                addingHandler(response.message.content)
                if response.isRequestFinished {
                    continuation.resume(returning: true)
                }
            case let .failure(error):
                debugPrint(error)
                continuation.resume(returning: false)
            }
        }
    }
}

extension WKInterfaceDevice {
    var screenCornerRadius: Double {
        switch self.screenBounds {
        case .init(x: 0, y: 0, width: 162, height: 197): 28   // 40mm
        case .init(x: 0, y: 0, width: 176, height: 215): 38.5 // 41mm
        case .init(x: 0, y: 0, width: 187, height: 223): 44   // 42mm
        case .init(x: 0, y: 0, width: 184, height: 224): 34   // 44mm
        case .init(x: 0, y: 0, width: 198, height: 242): 42.5 // 45mm
        case .init(x: 0, y: 0, width: 208, height: 248): 50   // 46mm
        case .init(x: 0, y: 0, width: 205, height: 251): 54   // 49mm
        default: 45
        }
    }
}
