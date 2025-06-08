//
//  Reader.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import DarockUI
import DarockFoundation

extension SettingsView.GeneralSettingsView {
    struct ReaderView: View {
        @AppStorage("RVReaderType") var readerType = "Scroll"
        @AppStorage("RVFontSize") var fontSize = 14
        @AppStorage("RVIsBoldText") var isBoldText = false
        @AppStorage("RVCharacterSpacing") var characterSpacing = 1.0
        @State var attributedExample = NSMutableAttributedString()
        @State var shouldShowFontDot = false
        var body: some View {
            VStack {
                if readerType == "Scroll" {
                    Text(AttributedString(attributedExample))
                        .frame(height: 80)
                        .mask {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black, Color.black, Color.black.opacity(0)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .animation(.default, value: attributedExample)
                }
                Form {
                    List {
                        Section {
                            Picker("阅读模式", selection: $readerType) {
                                Text("滚动").tag("Scroll")
                                Text("按章节划分").tag("Paging")
                            }
                        }
                        Section {
                            HStack {
                                Button(action: {
                                    if fontSize > 12 {
                                        fontSize--
                                        refreshAttributedExample()
                                    }
                                    shouldShowFontDot = true
                                }, label: {
                                    Text(verbatim: "A")
                                        .font(.system(size: 18, design: .rounded))
                                        .centerAligned()
                                })
                                .buttonStyle(.plain)
                                Divider()
                                Button(action: {
                                    if fontSize < 26 {
                                        fontSize++
                                        refreshAttributedExample()
                                    }
                                    shouldShowFontDot = true
                                }, label: {
                                    Text(verbatim: "A")
                                        .font(.system(size: 26, design: .rounded))
                                        .centerAligned()
                                })
                                .buttonStyle(.plain)
                            }
                        } footer: {
                            if shouldShowFontDot {
                                HStack(spacing: 2) {
                                    ForEach(12...26, id: \.self) { i in
                                        Circle()
                                            .fill(fontSize >= i ? Color.white : .gray.opacity(0.5))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .animation(.easeIn, value: fontSize)
                            }
                        }
                        .animation(.easeOut(duration: 0.2), value: shouldShowFontDot)
                        .disabled(readerType != "Scroll")
                        Section {
                            Toggle("粗体文本", isOn: $isBoldText)
                                .onChange(of: isBoldText) { _ in
                                    refreshAttributedExample()
                                }
                        }
                        .disabled(readerType != "Scroll")
                        Section {
                            VStack(alignment: .leading) {
                                Text("字间距")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.gray)
                                Slider(value: $characterSpacing, in: 0.8...2.5, step: 0.05)
                                    .onChange(of: characterSpacing) { _ in
                                        refreshAttributedExample()
                                    }
                                Text(characterSpacing ~ 2)
                                    .centerAligned()
                            }
                        }
                        .disabled(readerType != "Scroll")
                        Section {}
                    }
                }
            }
            .navigationTitle("阅读器")
            .onAppear {
                refreshAttributedExample()
            }
        }
        
        func refreshAttributedExample() {
            attributedExample = .init(
                string: String(
                    localized: "晚饭过后，我沿着海滩散步，想找一个绝佳的位置读完手里的书，再开启一本新书。我发现了一个地方，目之所及，空无一人。这里还有一张吊床，可以阅读和小憩。我躺下来，几经调整，找到一个最舒适的姿势，就此遁入书中，沉浸在最后一个章节。一时间，"
                ),
                attributes: [
                    .font: UIFont.systemFont(ofSize: CGFloat(fontSize), weight: isBoldText ? .bold : .regular),
                    .kern: CGFloat(characterSpacing)
                ]
            )
        }
    }
}
