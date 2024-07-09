//
//  NewFeaturesView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//

import SwiftUI

struct NewFeaturesView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("“暗礁浏览器”新功能")
                        .font(.system(size: 18, weight: .bold))
                        .accessibilityIdentifier("NewFeaturesTitle")
                    SingleFeatureRow(symbol: "music.note.list", mainText: "音乐播放", detailText: "前往“提示”了解更多") { AnyView(
                        TipsView.MusicView()
                    )} // swiftlint:disable:this closure_end_indentation
                    Text("您可以随时在“提示->新功能”中重新打开此页")
                        .multilineTextAlignment(.center)
                        .opacity(0.7)
                }
            }
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
                Image(systemName: symbol)
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

// MARK: ArchivedNewFeatures
private struct _NewFeaturesViewArchived240709: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("“暗礁浏览器”新功能")
                        .font(.system(size: 18, weight: .bold))
                        .accessibilityIdentifier("NewFeaturesTitle")
                    SingleFeatureRow(symbol: "book", mainText: "图书解析", detailText: "直接在搜索框输入或在网页中轻触.epub链接以开始")
                    Text("您可以随时在“提示->新功能”中重新打开此页")
                        .multilineTextAlignment(.center)
                        .opacity(0.7)
                }
            }
        }
    }
}
private struct _NewFeaturesViewArchived240628: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("“暗礁浏览器”新功能")
                        .font(.system(size: 18, weight: .bold))
                        .accessibilityIdentifier("NewFeaturesTitle")
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
                    Text("您可以随时在“设置”中重新打开此页")
                        .multilineTextAlignment(.center)
                        .opacity(0.7)
                }
            }
        }
    }
}
private struct _NewFeaturesArchived240502: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("“暗礁浏览器”新功能")
                        .font(.system(size: 18, weight: .bold))
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
                    Text("您可以随时在“设置”中重新打开此页")
                        .multilineTextAlignment(.center)
                        .opacity(0.7)
                }
            }
        }
    }
}
