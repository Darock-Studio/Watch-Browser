//
//  BrowsingEngine.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import DarockUI
import DarockFoundation

extension SettingsView {
    struct BrowsingEngineSettingsView: View {
        @AppStorage("isUseOldWebView") var isUseOldWebView = false
        @AppStorage("WebViewLayout") var webViewLayout = "MaximumViewport"
        @AppStorage("BrowsingMenuLayout") var browsingMenuLayout = "Detailed"
        @AppStorage("RequestDesktopWeb") var requestDesktopWeb = false
        @AppStorage("UseBackforwardGesture") var useBackforwardGesture = true
        @AppStorage("KeepDigitalTime") var keepDigitalTime = false
        @AppStorage("HideDigitalTime") var hideDigitalTime = false
        @AppStorage("AlwaysReloadWebPageAfterCrash") var alwaysReloadWebPageAfterCrash = false
        @AppStorage("ForceApplyDarkMode") var forceApplyDarkMode = false
        @AppStorage("LBIsAutoEnterReader") var isAutoEnterReader = true
        @AppStorage("IsProPurchased") var isProPurchased = false
        var body: some View {
            List {
                Section {
                    Toggle("使用旧版浏览引擎", isOn: $isUseOldWebView)
                }
                if !isUseOldWebView {
                    Section {
                        Picker("网页视图", selection: $webViewLayout) {
                            Label("最大可视区域", systemImage: "applewatch.case.inset.filled").tag("MaximumViewport")
                            Label("模糊顶部", systemImage: "platter.filled.top.applewatch.case").tag("BlurTopBar")
                            Label("快速返回", systemImage: "chevron.backward.circle").tag("FastPrevious")
                        }
                        .disabled(!isProPurchased)
                        Picker("浏览菜单", selection: $browsingMenuLayout) {
                            Label("详细", systemImage: "list.bullet").tag("Detailed")
                            Label("紧凑", systemImage: "circle.grid.3x3.fill").tag("Compact")
                        }
                        .disabled(!isProPurchased)
                        NavigationLink(destination: { FastButtonsView() }, label: {
                            VStack(alignment: .leading) {
                                Label("快捷按钮", systemImage: "button.programmable")
                                if webViewLayout == "FastPrevious" {
                                    Text("网页视图布局为“快速返回”时，快捷按钮不可用")
                                        .font(.footnote)
                                        .foregroundStyle(.gray)
                                }
                            }
                        })
                        .disabled(!isProPurchased || webViewLayout == "FastPrevious")
                    } header: {
                        Text("布局")
                    } footer: {
                        if !isProPurchased {
                            NavigationLink(destination: { ProPurchaseView() }, label: {
                                Text("\(Text("激活暗礁浏览器 Pro ").bold().foregroundColor(.blue))以更改布局设置。")
                            })
                            .buttonStyle(.plain)
                        }
                    }
                    Section {
                        Toggle(isOn: $requestDesktopWeb) {
                            HStack {
                                Image(systemName: "desktopcomputer")
                                    .foregroundStyle(.blue.gradient)
                                Text("请求桌面网站")
                            }
                        }
                        Toggle(isOn: $useBackforwardGesture) {
                            HStack {
                                Image(systemName: "hand.draw")
                                    .foregroundStyle(.purple.gradient)
                                Text("使用手势返回上一页")
                            }
                        }
                        Toggle(isOn: $hideDigitalTime) {
                            HStack {
                                Image(systemName: "clock.badge.xmark")
                                    .foregroundStyle(.blue.gradient)
                                Text("隐藏时间")
                            }
                        }
                        .onChange(of: hideDigitalTime) { _ in
                            if hideDigitalTime {
                                keepDigitalTime = false
                            }
                        }
                        Toggle(isOn: $keepDigitalTime) {
                            HStack {
                                Image(systemName: "clock")
                                Text("保持时间可见")
                            }
                        }
                        .disabled(webViewLayout == "FastPrevious")
                        .onChange(of: keepDigitalTime) { _ in
                            if keepDigitalTime {
                                hideDigitalTime = false
                            }
                        }
                        Toggle(isOn: $alwaysReloadWebPageAfterCrash) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundStyle(.blue.gradient)
                                Text("网页崩溃后总是自动重新载入")
                            }
                        }
                        Toggle(isOn: $forceApplyDarkMode) {
                            HStack {
                                Image(systemName: "rectangle.inset.filled")
                                    .foregroundStyle(.gray.gradient)
                                Text("强制深色模式")
                            }
                        }
                    }
                } else {
                    Section {
                        Toggle(isOn: $isAutoEnterReader) {
                            HStack {
                                Image(systemName: "doc.plaintext")
                                    .foregroundStyle(.blue.gradient)
                                Text("可用时自动进入阅读器")
                            }
                        }
                    }
                }
            }
            .navigationTitle("浏览引擎")
        }
        
        struct FastButtonsView: View {
            @AppStorage("HideDigitalTime") var hideDigitalTime = false
            @State var buttons = [WebViewFastButton].getCurrentFastButtons()
            var body: some View {
                List {
                    Section {
                        HStack {
                            Image(systemName: "ellipsis.circle")
                            ForEach(0..<buttons.count, id: \.self) { i in
                                Spacer()
                                Image(systemName: {
                                    switch buttons[i] {
                                    case .nextPage: "chevron.forward"
                                    case .previousPage: "chevron.backward"
                                    case .refresh: "arrow.clockwise"
                                    case .decodeVideo: "film.stack"
                                    case .decodeImage: "photo.stack"
                                    case .decodeMusic: "music.quarternote.3"
                                    case .exit: "escape"
                                    case .empty: "ellipsis.circle"
                                    }
                                }())
                                .opacity(buttons[i] == .empty || (i == 3 && !hideDigitalTime) ? 0 : 1)
                                .foregroundStyle(buttons[i] == .exit ? .red : .blue)
                            }
                        }
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                    } header: {
                        Text("预览")
                    }
                    .listRowBackground(Color.clear)
                    Section {
                        ForEach(0..<buttons.count, id: \.self) { i in
                            Picker("按钮 \(i + 1)", selection: $buttons[i]) {
                                Label("无", systemImage: "circle.dashed").tag(WebViewFastButton.empty)
                                Label("上一页", systemImage: "chevron.backward").tag(WebViewFastButton.previousPage)
                                Label("下一页", systemImage: "chevron.forward").tag(WebViewFastButton.nextPage)
                                Label("重新载入", systemImage: "arrow.clockwise").tag(WebViewFastButton.refresh)
                                Label("退出网页", systemImage: "escape").tag(WebViewFastButton.exit)
                                Label("播放网页视频", systemImage: "film.stack").tag(WebViewFastButton.decodeVideo)
                                Label("查看网页图片", systemImage: "photo.stack").tag(WebViewFastButton.decodeImage)
                                Label("播放网页音频", systemImage: "music.quarternote.3").tag(WebViewFastButton.decodeMusic)
                            }
                            .disabled(i == 3 && !hideDigitalTime)
                        }
                    } footer: {
                        if !hideDigitalTime {
                            Text("启用“隐藏时间”以添加按钮 4")
                        }
                    }
                }
                .navigationTitle("快捷按钮")
                .onChange(of: buttons) { _ in
                    buttons.updateFastButtons()
                }
            }
        }
    }
}

enum WebViewFastButton: Codable {
    case previousPage
    case nextPage
    case refresh
    case decodeVideo
    case decodeImage
    case decodeMusic
    case exit
    case empty
}
extension [WebViewFastButton] {
    static func getCurrentFastButtons() -> Self {
        if let jsonStr = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/WebViewFastButtons.drkdataw", encoding: .utf8),
           let data = getJsonData(Self.self, from: jsonStr) {
            if data.count == 4 {
                return data
            }
        }
        return [.empty, .empty, .empty, .empty]
    }
    
    func updateFastButtons() {
        if let jsonStr = jsonString(from: self) {
            do {
                try jsonStr.write(toFile: NSHomeDirectory() + "/Documents/WebViewFastButtons.drkdataw", atomically: true, encoding: .utf8)
            } catch {
                globalErrorHandler(error)
            }
        }
    }
}
