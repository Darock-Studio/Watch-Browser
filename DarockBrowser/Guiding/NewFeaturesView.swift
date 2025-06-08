//
//  NewFeaturesView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//

import DarockUI

struct NewFeaturesView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Text("“暗礁浏览器”新功能")
                        .font(.system(size: 18, weight: .bold))
                    SingleFeatureRow(symbol: "network.badge.shield.half.filled", mainText: "专用代理", detailText: "现可使用专用代理以保护隐私")
                    Text("您可以随时在“提示→新功能”中重新打开此页")
                        .multilineTextAlignment(.center)
                        .opacity(0.7)
                    NavigationLink(destination: { PreviousUpdatesView() }, label: {
                        Text("以前的更新")
                    })
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                }
            }
        }
    }
    
    struct PreviousUpdatesView: View {
        var body: some View {
            ScrollView {
                VStack {
                    SingleFeatureRow(symbol: "button.programmable", mainText: "网页快捷按钮", detailText: "现可向网页顶部添加快捷操作按钮")
                    if #available(watchOS 10.0, *) {
                        SingleFeatureRow(symbol: "macwindow.on.rectangle", mainText: "标签页浏览", detailText: "现可进行基于标签页的网页浏览")
                    }
                    SingleFeatureRow(symbol: "_nightshift", mainText: "定时切换外观", detailText: "在设置→显示与亮度中更改外观切换定时设置")
                    SingleFeatureRow(symbol: "squareshape.split.2x2.dotted", mainText: "自定义布局", detailText: "在设置→浏览引擎中自定义网页视图和浏览菜单布局")
                    SingleFeatureRow(symbol: "list.bullet.rectangle.portrait", mainText: "更新的浏览菜单", detailText: "浏览菜单现在更美观并更易操作")
                    SingleFeatureRow(symbol: "globe.badge.chevron.backward", mainText: "旧版引擎设置", detailText: "现可设置是否为旧版浏览引擎自动启用阅读器模式")
                    SingleFeatureRow(symbol: "clock.badge.xmark", mainText: "在浏览中隐藏时间", detailText: "现可设置是否在网页中隐藏时间，减少干扰")
                    SingleFeatureRow(symbol: "bookmark", mainText: "网页内添加书签", detailText: "现可在浏览菜单中快速将当前页添加到书签")
                    SingleFeatureRow(symbol: "desktopcomputer", mainText: "请求桌面网站", detailText: "现可在浏览菜单中快速请求桌面网站")
                    SingleFeatureRow(symbol: "globe", mainText: "使用旧版引擎打开", detailText: "现可在浏览菜单中快速使用旧版引擎打开当前页")
                    if NSLocale.current.language.languageCode!.identifier != "zh" {
                        SingleFeatureRow(symbol: "bubble.left.and.bubble.right",
                                         mainText: "Discord Server",
                                         detailText: "Tap for Details about our Discord Server") { AnyView(
                                            JoinGroupView()
                                         )} // swiftlint:disable:this closure_end_indentation
                    }
                    SingleFeatureRow(symbol: "book.fill", mainText: "新版图书阅读器", detailText: "图书阅读器现在合并所有章节并自动保存阅读位置")
                    SingleFeatureRow(symbol: "book.and.wrench", mainText: "图书阅读器设置", detailText: "现可在设置→通用→阅读器中个性化设置图书阅读器")
                    SingleFeatureRow(symbol: "music.note.list", mainText: "音乐播放", detailText: "前往“提示”了解更多") { AnyView(
                        TipsView.MusicView()
                    )} // swiftlint:disable:this closure_end_indentation
                    SingleFeatureRow(symbol: "book", mainText: "图书解析", detailText: "直接在搜索框输入或在网页中轻触.epub链接以开始")
                    SingleFeatureRow(symbol: "applescript", mainText: "用户脚本", detailText: "可在脚本商店中获取各类网页脚本")
                    SingleFeatureRow(symbol: "photo", mainText: "查看图片", detailText: "现可单独放大查看网页中的图片", navigateTo: { AnyView(
                        List {
                            Section {
                                Label("打开包含图片的网页", systemImage: "1.circle.fill")
                                Label("打开\(Image(systemName: "ellipsis.circle"))浏览菜单", systemImage: "2.circle.fill")
                                Label("轻触“查看网页中图片”", systemImage: "3.circle.fill")
                            } header: {
                                Text("查看图片 - 步骤")
                            }
                        }
                            .navigationTitle("图片")
                    )})
                    SingleFeatureRow(symbol: "arrow.uturn.up", mainText: "视频直接跳转", detailText: "打开视频直链时，将直接跳转视频")
                    SingleFeatureRow(symbol: "globe", mainText: "增强的浏览引擎", detailText: "增强的浏览引擎包含更多高级功能", navigateTo: { AnyView(
                        List {
                            Section {
                                Label("打开包含视频的网页", systemImage: "1.circle.fill")
                                Label("打开\(Image(systemName: "ellipsis.circle"))浏览菜单", systemImage: "2.circle.fill")
                                Label("轻触“播放网页中视频”", systemImage: "3.circle.fill")
                            } header: {
                                Text("视频播放 - 步骤")
                            }
                            Section {
                                Text("历史记录现会记录每个导航页")
                            } header: {
                                Text("增强的历史记录")
                            }
                            Section {
                                Label("现在，更多的 Cookie 可被记录", systemImage: "checkmark.circle")
                                Label("Darock 始终重视您的隐私，所有 Cookie 仅在本地存储", systemImage: "hand.raised.square")
                            } header: {
                                Text("更好的 Cookie 支持")
                            }
                            Section {
                                Label("可在\(Image(systemName: "gear"))设置中打开“请求桌面网站”", systemImage: "desktopcomputer")
                            } header: {
                                Text("请求桌面网站")
                            }
                        }
                            .navigationTitle("高级功能")
                    )})
                    SingleFeatureRow(symbol: "square.and.arrow.up", mainText: "分享网页", detailText: "网页现可被分享至 iPhone 或其他 App")
                    SingleFeatureRow(symbol: "archivebox", mainText: "创建网页归档", detailText: "现可将网页归档以供离线查看")
                }
            }
            .navigationTitle("以前的更新")
        }
    }
}

struct SingleFeatureRow: View {
    var symbol: String
    var mainText: LocalizedStringKey
    var detailText: LocalizedStringKey
    var navigateTo: (() -> AnyView)?
    var body: some View {
        NavigationLink(destination: {
            if let navigateTo {
                navigateTo()
            } else {
                EmptyView()
            }
        }, label: {
            HStack {
                Spacer()
                Group {
                    if !symbol.hasPrefix("_") {
                        Image(systemName: symbol)
                    } else {
                        Image(_internalSystemName: String(symbol.dropFirst()))
                    }
                }
                .font(.system(size: 28))
                .foregroundColor(.blue)
                VStack {
                    HStack {
                        Text(mainText)
                            .font(.system(size: 18, weight: .bold))
                        Spacer()
                    }
                    HStack {
                        Text(detailText)
                            .font(.system(size: 14))
                            .opacity(0.6)
                        Spacer()
                    }
                }
                if navigateTo != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .opacity(0.7)
                }
            }
        })
        .buttonStyle(.plain)
        .padding(.vertical)
        .allowsHitTesting(navigateTo != nil)
    }
}
