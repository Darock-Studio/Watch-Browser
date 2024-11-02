//
//  WebAbstractView.swift
//  WatchBrowser
//
//  Created by memz233 on 10/3/24.
//

import SwiftUI
import DarockKit
import SwiftSoup

struct WebAbstractView: View {
    var webView: WKWebView
    @State var abstractString = ""
    @State var isFailedLoading = false
    @State var animateAngle: CGFloat = -45
    @State var animateTimer: Timer?
    var body: some View {
        NavigationStack {
            if !isFailedLoading {
                if !abstractString.isEmpty {
                    ScrollView {
                        Text(abstractString)
                    }
                    .navigationTitle("网页摘要")
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .navigationTitle("正在载入摘要...")
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
        abstractString = ""
        animateTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            animateAngle += 1
        }
        webView.evaluateJavaScript("document.documentElement.outerHTML") { obj, _ in
            DispatchQueue(label: "com.darock.WatchBrowser.Intelligence.Abstract", qos: .userInitiated).async {
                if let sourceCode = obj as? String {
                    do {
                        let document = try SwiftSoup.parse(sourceCode)
                        let textElements = try document.select("*").filter { try $0.text().trimmingCharacters(in: .whitespaces).isEmpty == false }
                        var texts = [String]()
                        for text in try textElements.map({ try $0.text() }) where !texts.contains(text) {
                            texts.append(text)
                        }
                        let visibleText = texts.joined(separator: " ")
                        Task {
                            if let abstract = await webAbstract(from: String(visibleText.prefix(7000))) {
                                DispatchQueue.main.async {
                                    abstractString = abstract
                                }
                            } else {
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

private func webAbstract(from sourceText: String) async -> String? {
    let langOption = UserDefaults.standard.string(forKey: "DIWebAbstractLangOption") ?? "Web"
    let messages: [SingleIntelligenceMessage] = [
        SingleIntelligenceMessage(role: .system, content: """
        你是一个网页摘要总结助手，我将向你发送一部分网页中的文本，直接回复文本所对应网页内容的摘要，以\({
        if langOption == "Web" {
            return "网页内容"
        } else {
            return NSLocale.current.language.languageCode!.identifier
        }
        }())语言总结摘要，不要回复任何多余文本。
        """),
        SingleIntelligenceMessage(role: .user, content: sourceText)
    ]
    return await getRawIntelligenceCompletionData(from: messages)
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
