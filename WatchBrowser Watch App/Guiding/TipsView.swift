//
//  TipsView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 6/20/24.
//

import SwiftUI

struct TipsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: { NewFeaturesView() }, label: {
                    Label(title: {
                        Text("新功能")
                    }, icon: {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                    })
                })
            }
            Section {
                NavigationLink(destination: { SetupChecklistView() }, label: {
                    Label(title: {
                        Text("设置清单")
                    }, icon: {
                        Image(systemName: {
                            if #available(watchOS 10, *) {
                                "checkmark.rectangle.stack"
                            } else {
                                "rectangle.badge.checkmark"
                            }
                        }())
                        .foregroundColor(.yellow)
                    })
                })
                NavigationLink(destination: { PracticeKeyGesturesView() }, label: {
                    Label(title: {
                        Text("练习主要手势")
                    }, icon: {
                        Image(systemName: "hand.draw")
                            .foregroundColor(.purple)
                    })
                })
            } header: {
                Text("开始")
            }
            Section {
                NavigationLink(destination: { BeyondTheBasicsView() }, label: {
                    Label(title: {
                        Text("进阶技巧")
                    }, icon: {
                        Image(systemName: "star")
                            .foregroundColor(.orange)
                    })
                })
            } header: {
                Text("发现更多")
            }
            Section {
                NavigationLink(destination: { MusicView() }, label: {
                    Label(title: {
                        Text("音乐")
                    }, icon: {
                        Image(systemName: "music.note")
                            .foregroundColor(.red)
                    })
                })
                NavigationLink(destination: { PhotosView() }, label: {
                    Label(title: {
                        Text("图片")
                    }, icon: {
                        Image(systemName: "photo")
                            .foregroundColor(.orange)
                    })
                })
                NavigationLink(destination: { BooksView() }, label: {
                    Label(title: {
                        Text("图书")
                    }, icon: {
                        Image(systemName: "book")
                            .foregroundColor(.green)
                    })
                })
                NavigationLink(destination: { VideosView() }, label: {
                    Label(title: {
                        Text("视频")
                    }, icon: {
                        Image(systemName: "film.stack")
                            .foregroundColor(.mint)
                    })
                })
            } header: {
                Text("媒体")
            }
        }
        .navigationTitle("提示")
        .navigationBarTitleDisplayMode(.large)
    }
    
    struct SetupChecklistView: View {
        @AppStorage("DarockAccount") var darockAccount = ""
        @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
        var body: some View {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            if #available(watchOS 10, *) {
                                Image(systemName: "checkmark.rectangle.stack.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "sparkles.rectangle.stack.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                            }
                            Text("设置清单")
                                .font(.system(size: 20, weight: .bold))
                            Text("从此处开始设置你的暗礁浏览器。")
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                Section {
                    NavigationLink(destination: {
                        userPasscodeEncrypted.isEmpty ? SettingsView(isPasscodeViewPresented: true) : SettingsView(isEnterPasscodeViewInputPresented: true)
                    }, label: {
                        HStack {
                            Image(systemName: userPasscodeEncrypted.isEmpty ? "lock.open.fill" : "lock.fill")
                                .font(.system(size: 30))
                                .foregroundColor(userPasscodeEncrypted.isEmpty ? .red : .green)
                            VStack(alignment: .leading) {
                                Text("密码")
                                HStack {
                                    if !userPasscodeEncrypted.isEmpty {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.green)
                                    }
                                    Text(userPasscodeEncrypted.isEmpty ? "前往密码设置" : "密码已设置")
                                }
                            }
                        }
                    })
                    NavigationLink(destination: { SettingsView() }, label: {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            VStack(alignment: .leading) {
                                Text("Darock 账户")
                                HStack {
                                    if !darockAccount.isEmpty {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.green)
                                    }
                                    Text(darockAccount.isEmpty ? "前往登录 Darock 账户" : "你已登录")
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    struct PracticeKeyGesturesView: View {
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { SwipeBackView() }, label: {
                        HStack {
                            Image(systemName: "hand.point.left")
                                .foregroundColor(.purple)
                            Text("导航手势")
                        }
                    })
                    NavigationLink(destination: { PinchZoomView() }, label: {
                        HStack {
                            Image(systemName: "hand.pinch")
                                .foregroundColor(.purple)
                            Text("缩放手势")
                        }
                    })
                } header: {
                    Text("网页浏览中可用的手势")
                }
            }
            .navigationTitle("练习主要手势")
        }
        
        struct SwipeBackView: View {
            var body: some View {
                VStack {
                    Text("滑动以返回")
                        .font(.system(size: 20, weight: .bold))
                    HStack {
                        Image(systemName: "arrow.backward")
                            .font(.system(size: 30, weight: .bold))
                        Spacer()
                        Text("从边缘\n向右滑动")
                    }
                }
                .onDisappear {
                    tipWithText("完成！", symbol: "checkmark.circle.fill")
                }
            }
        }
        struct PinchZoomView: View {
            var body: some View {
                VStack {
                    Image(systemName: "hand.pinch.fill")
                        .font(.system(size: 30, weight: .bold))
                    Text("双指捏合以缩放")
                        .padding()
                }
                .touchZoomable()
            }
        }
    }
    
    struct BeyondTheBasicsView: View {
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { FastClearView() }, label: {
                        Label(title: {
                            Text("快速清除")
                        }, icon: {
                            Image(systemName: "xmark.bin.fill")
                                .foregroundColor(.red)
                        })
                    })
                    NavigationLink(destination: { FastBookmarkView() }, label: {
                        Label(title: {
                            Text("快速书签")
                        }, icon: {
                            Image(systemName: "bookmark.fill")
                        })
                    })
                    NavigationLink(destination: { DownloadMediaView() }, label: {
                        Label(title: {
                            Text("下载媒体")
                        }, icon: {
                            Image(systemName: "arrow.down.doc.fill")
                                .foregroundColor(.green)
                        })
                    })
                }
            }
            .navigationTitle("进阶技巧")
        }
        
        struct FastClearView: View {
            @State var tmpInput = String(localized: "这里有一些内容，尝试快速清除它们。")
            var body: some View {
                List {
                    Section {
                        Text("“快速清除”可让你快速清除搜索框中的内容")
                    }
                    .listRowBackground(Color.clear)
                    Section {
                        TextField("Home.search-or-URL", text: $tmpInput)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .swipeActions {
                                Button(action: {
                                    tmpInput = ""
                                    tipWithText("完成！", symbol: "checkmark.circle.fill")
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                                .tint(.red)
                            }
                        HStack {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.blue)
                            Text("向左滑动输入框")
                        }
                    } header: {
                        Text("尝试一下？")
                    }
                }
                .navigationTitle("快速清除")
            }
        }
        struct FastBookmarkView: View {
            @State var tmpInput = String(localized: "你想将此段内容的搜索结果添加到书签")
            var body: some View {
                List {
                    Section {
                        Text("“快速书签”可让你快速将搜索框中的内容添加到书签")
                    }
                    .listRowBackground(Color.clear)
                    Section {
                        TextField("Home.search-or-URL", text: $tmpInput)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(action: {
                                    tipWithText("完成！", symbol: "checkmark.circle.fill")
                                }, label: {
                                    Image(systemName: "bookmark.fill")
                                })
                            }
                        HStack {
                            Text("向右滑动输入框")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    } header: {
                        Text("尝试一下？")
                    } footer: {
                        Text("仅作示例，此处的操作不会真的添加书签。")
                    }
                }
                .navigationTitle("快速书签")
            }
        }
        struct DownloadMediaView: View {
            var body: some View {
                List {
                    Section {
                        Text("在视频或音频列表页向左滑动项目即可下载")
                    }
                    Section {
                        Text(verbatim: "https://darock.top/Shiroko.mp4")
                            .swipeActions {
                                Button(action: {
                                    tipWithText("完成！", symbol: "checkmark.circle.fill")
                                }, label: {
                                    Image(systemName: "square.and.arrow.down")
                                })
                            }
                        HStack {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.blue)
                            Text("向左滑动媒体链接")
                        }
                    } header: {
                        Text("尝试一下？")
                    } footer: {
                        Text("仅作示例，此处的操作不会真的下载视频。")
                    }
                }
            }
        }
    }
    
    struct MusicView: View {
        var body: some View {
            List {
                Section {
                    Text("轻触浏览菜单“播放网页音频”、在网页中寻找或直接在搜索框中输入音频链接")
                }
                Section {
                    Button(action: {
                        audioLinkLists = ["http://music.\(0b10100011).com/song/media/outer/url?id=411500345.mp3"]
                        pShouldPresentAudioList = true
                        dismissListsShouldRepresentWebView = false
                    }, label: {
                        Text("查看示例音频")
                    })
                } header: {
                    Text("示例音频")
                } footer: {
                    Text("仅作示例。")
                }
            }
            .navigationTitle("音乐")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    struct PhotosView: View {
        @State var randomIndex = 0
        var body: some View {
            List {
                Section {
                    Text("轻触浏览菜单“查看网页图片”、在网页中寻找或直接在搜索框中输入图片链接")
                }
                Section {
                    Button(action: {
                        imageLinkLists = [
                            Bundle.main.privateFrameworksURL!
                                .appending(path: "TripleQuestionmarkCore.framework/\(tqcImageNameList[randomIndex])")
                                .absoluteString
                        ]
                        pShouldPresentImageList = true
                        dismissListsShouldRepresentWebView = false
                    }, label: {
                        Text("查看示例图片")
                    })
                } header: {
                    Text("示例图片")
                } footer: {
                    Text("仅作示例。\n\(tqcCopyrightList[randomIndex])")
                }
            }
            .navigationTitle("图片")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                randomIndex = Int.random(in: 0..<tqcImageNameList.count)
                debugPrint(randomIndex)
            }
        }
        
        let tqcImageNameList = [
            "___MesugakiAmane.drkdatau",
            "___YoutouMurasameChan.drkdatau",
            "___0721NeneChan.drkdatau",
            "___KawaiiChieriChan.drkdatau"
        ]
        let tqcCopyrightList = [
            "© 2024 YUZUSOFT/JUNOS Inc. All Rights Reserved.",
            "© 2024 YUZUSOFT/JUNOS Inc. All Rights Reserved.",
            "© 2024 YUZUSOFT/JUNOS Inc. All Rights Reserved.",
            "© 2024 きゃべつそふと All Rights Reserved."
        ]
    }
    struct BooksView: View {
        var body: some View {
            List {
                Section {
                    Text("在网页中寻找或直接在搜索框中输入.epub链接")
                }
                Section {
                    Button(action: {
                        bookLinkLists = ["https://darock.storage.linecom.net.cn/darockbrowser/example/ThreeBody.epub"]
                        pShouldPresentBookList = true
                        dismissListsShouldRepresentWebView = false
                    }, label: {
                        Text("查看示例图书 [《三体》(1.83 MB)]")
                    })
                } header: {
                    Text("示例图书")
                } footer: {
                    Text("仅作示例，请支持正版图书。")
                }
            }
            .navigationTitle("图书")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    struct VideosView: View {
        var body: some View {
            List {
                Section {
                    Text("轻触浏览菜单“播放网页视频”、在网页中寻找或直接在搜索框中输入视频链接")
                }
                Section {
                    Button(action: {
                        videoLinkLists = ["https://darock.storage.linecom.net.cn/darockbrowser/example/Shiroko.mp4"]
                        pShouldPresentVideoList = true
                        dismissListsShouldRepresentWebView = false
                    }, label: {
                        Text("查看示例视频 (41.4 MB)")
                    })
                } header: {
                    Text("示例视频")
                } footer: {
                    Text("仅作示例\n©2020 NAT GAMES Co., Ltd. All Rights Reserved.\n©2020 Yostar, Inc. All Rights Reserved.")
                }
            }
            .navigationTitle("视频")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
