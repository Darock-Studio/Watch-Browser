//
//  SuggestedResolvers.swift
//  WatchBrowser
//
//  Created by memz233 on 9/30/24.
//

import DarockUI
import RadarKit

enum SuggestedResolver: RKSuggestResolver {
    case reboot
    case networkCheck
    
    @ViewBuilder var viewBlock: some View {
        switch self {
        case .reboot:
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.accent)
                    VStack(alignment: .leading) {
                        Text("重新启动设备")
                            .font(.headline)
                        Text("重新启动设备通常可以解决许多软件问题。")
                            .font(.subheadline)
                        Button(action: {
                            AdvancedWebViewController.shared.present(
                                "https://support.apple.com/guide/watch/apd521a8a902/watchos",
                                overrideOldWebView: .alwaysLegacy
                            )
                        }, label: {
                            Text("进一步了解...")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        })
                        .buttonStyle(.plain)
                    }
                }
                Text("""
                上次重新启动时间：
                \({
                let uptime = ProcessInfo.processInfo.systemUptime
                let startupDate = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 - uptime)
                let df = DateFormatter()
                df.dateStyle = .medium
                df.timeStyle = .short
                return df.string(from: startupDate)
                }())
                """)
                .font(.footnote)
                .foregroundStyle(.gray)
            }
        case .networkCheck:
            NavigationLink(destination: { NetworkCheckView() }, label: {
                HStack {
                    HStack(alignment: .top) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading) {
                            Text("运行网络检查程序")
                                .font(.headline)
                            Text("运行一个快速诊断程序以检查网络连接。")
                                .font(.subheadline)
                        }
                    }
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                }
            })
        }
    }
    
    static func suggestView(for place: String) -> AnyView {
        AnyView(_suggestView(for: place))
    }
    @ViewBuilder
    private static func _suggestView(for place: String) -> some View {
        switch place {
        case "视频播放器":
            Section {
                SuggestedResolver.reboot.viewBlock
                SuggestedResolver.networkCheck.viewBlock
            } header: {
                Text("先试试这些方案")
            }
        case "网络连接":
            Section {
                SuggestedResolver.networkCheck.viewBlock
            } header: {
                Text("先试试这个方案")
            }
        case "密码":
            Section {
                NavigationLink(destination: { SettingsView.GeneralSettingsView.ResetView() }, label: {
                    HStack {
                        ZStack {
                            Color.gray
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                        }
                        Text("查看还原选项")
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                    }
                })
            } header: {
                Text("反馈问题无法帮助您找回密码")
            }
        default: EmptyView()
        }
    }
}
