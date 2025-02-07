//
//  GeneralSettingsView.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI
import StorageUI

extension SettingsView {
    struct GeneralSettingsView: View {
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { AboutView() },
                                   label: { SettingItemLabel(title: "关于", image: "applewatch", color: .gray) })
                    NavigationLink(destination: { SoftwareUpdateView() },
                                   label: { SettingItemLabel(title: "软件更新", image: "gear.badge", color: .gray) })
                    NavigationLink(destination: {
                        SUIStorageManagementView {
                            SUIStorageListFile(
                                name: "视频",
                                tintColor: .purple,
                                path: NSHomeDirectory() + "/Documents/DownloadedVideos",
                                allowDelete: true,
                                customNameConverter: UserDefaults.standard.dictionary(forKey: "VideoHumanNameChart") as? [String: String]
                            ) { name in
                                if var dic = UserDefaults.standard.dictionary(forKey: "VideoHumanNameChart") as? [String: String] {
                                    dic.removeValue(forKey: name)
                                    UserDefaults.standard.set(dic, forKey: "VideoHumanNameChart")
                                }
                            }
                            SUIStorageListFile(
                                name: "音乐",
                                tintColor: .red,
                                path: NSHomeDirectory() + "/Documents/DownloadedAudios",
                                allowDelete: true,
                                customNameConverter: UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]
                            ) { name in
                                if var dic = UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String] {
                                    dic.removeValue(forKey: name)
                                    UserDefaults.standard.set(dic, forKey: "AudioHumanNameChart")
                                }
                            }
                            SUIStorageListFile(
                                name: "图片",
                                tintColor: .orange,
                                path: NSHomeDirectory() + "/Documents/LocalImages",
                                showFilesInList: false
                            )
                        }
                    },
                                   label: { SettingItemLabel(title: "储存空间", image: "externaldrive.fill", color: .gray) })
                }
                Section {
                    NavigationLink(destination: { ContinuityView() },
                                   label: { SettingItemLabel(title: "连续互通", image: "point.3.filled.connected.trianglepath.dotted", color: .blue) })
                }
                Section {
                    NavigationLink(destination: { KeyboardView() },
                                   label: { SettingItemLabel(title: "键盘", image: "keyboard.fill", color: .gray) })
                    NavigationLink(destination: { MusicPlayerView() },
                                   label: { SettingItemLabel(title: "音乐播放器", image: "music.note.list", color: .red) })
                    NavigationLink(destination: { ImageViewerView() },
                                   label: { SettingItemLabel(title: "图像查看器", image: "photo.fill.on.rectangle.fill", color: .blue) })
                    NavigationLink(destination: { ReaderView() },
                                   label: { SettingItemLabel(title: "阅读器", image: "book.fill", color: .orange) })
                }
                Section {
                    NavigationLink(destination: { LegalView() },
                                   label: { SettingItemLabel(title: "法律与监管", image: {
                        if #available(watchOS 11.0, *) {
                            "checkmark.seal.text.page.fill"
                        } else {
                            "text.justify.left"
                        }
                    }(), color: .gray) })
                }
                Section {
                    NavigationLink(destination: { ResetView() },
                                   label: { SettingItemLabel(title: "还原", image: "arrow.counterclockwise", color: .gray) })
                }
            }
            .navigationTitle("通用")
        }
    }
}
