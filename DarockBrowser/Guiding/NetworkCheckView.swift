//
//  NetworkCheckView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 6/24/24.
//

import DarockUI
import DarockFoundation

struct NetworkCheckView: View {
    @State var progressTimer: Timer?
    @State var networkState = 0
    @State var darockAPIState = 0
    @State var isTroubleshooting = false
    @State var isNewVerAvailable = false
    var lightColors: [Color] = [.secondary, .orange, .red, .green, .red]
    var body: some View {
        List {
            Section {
                if !isTroubleshooting {
                    if networkState == 3 && darockAPIState == 3 {
                        HStack {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                            Text("一切良好")
                                .bold()
                        }
                        NavigationLink(destination: { FeedbackView() }, label: {
                            VStack(alignment: .leading) {
                                Text("仍有问题？")
                                Text(isNewVerAvailable ? "“反馈助理”不可用，因为暗礁浏览器有更新可用" : "反馈问题")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        })
                        .disabled(isNewVerAvailable)
                    } else {
                        Text("可能的问题：")
                            .bold()
                        if networkState == 2 {
                            NavigationLink(destination: { NetworkProblemDetailsView() }, label: {
                                Text("无法连接互联网")
                            })
                        }
                        if darockAPIState == 2 || darockAPIState == 4 {
                            NavigationLink(destination: { DarockAPIProblemDetailsView() }, label: {
                                Text(darockAPIState == 2 ? "Darock API：不可用" : "Darock API：无效返回")
                            })
                        }
                    }
                } else {
                    Text("正在检查…")
                        .bold()
                }
            } footer: {
                if !(networkState == 3 && darockAPIState == 3) {
                    Text("轻点以查看详情")
                }
            }
            Section("连接状态") {
                HStack {
                    Circle()
                        .frame(width: 10)
                        .foregroundStyle(lightColors[networkState])
                        .padding(.trailing, 7)
                    if networkState == 0 {
                        Text("互联网")
                    } else if networkState == 1 {
                        Text("互联网：正在检查")
                    } else if networkState == 2 {
                        Text("互联网：离线")
                    } else if networkState == 3 {
                        Text("互联网：在线")
                    }
                    Spacer()
                }
                .padding()
                HStack {
                    Circle()
                        .frame(width: 10)
                        .foregroundStyle(lightColors[darockAPIState])
                        .padding(.trailing, 7)
                    if darockAPIState == 0 {
                        Text("Darock API")
                            .foregroundStyle(networkState != 3 ? Color.secondary : .primary)
                    } else if darockAPIState == 1 {
                        Text("Darock API：正在检查")
                    } else if darockAPIState == 2 {
                        Text("Darock API：不可用")
                    } else if darockAPIState == 3 {
                        Text("Darock API：可用")
                    } else if darockAPIState == 4 {
                        Text("Darock API：无效返回")
                    }
                    Spacer()
                }
                .disabled(networkState != 3)
                .padding()
                Button(action: {
                    isTroubleshooting = true
                    networkState = 0
                    darockAPIState = 0
                    checkInternet()
                }, label: {
                    Text(isTroubleshooting ? "正在检查…" : "重新检查")
                })
                .disabled(isTroubleshooting)
            }
        }
        .navigationTitle("网络检查")
        .onAppear {
            isTroubleshooting = true
            networkState = 0
            darockAPIState = 0
            checkInternet()
            requestAPI("/drkbs/newver") { respStr, isSuccess in
                if isSuccess {
                    let spdVer = respStr.apiFixed().split(separator: ".")
                    if spdVer.count == 3 {
                        if let x = Int(spdVer[0]), let y = Int(spdVer[1]), let z = Int(spdVer[2]) {
                            let currVerSpd = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).split(separator: ".")
                            if currVerSpd.count == 3 {
                                if let cx = Int(currVerSpd[0]), let cy = Int(currVerSpd[1]), let cz = Int(currVerSpd[2]) {
                                    if x > cx {
                                        isNewVerAvailable = true
                                    } else if x == cx && y > cy {
                                        isNewVerAvailable = true
                                    } else if x == cx && y == cy && z > cz {
                                        isNewVerAvailable = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            progressTimer?.invalidate()
        }
    }
    
    func checkInternet() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
            timer.invalidate()
            networkState = 1
            requestString("https://apple.com.cn") { _, isSuccess in
                if isSuccess {
                    checkDarock()
                    networkState = 3
                } else {
                    networkState = 2
                    isTroubleshooting = false
                }
            }
        }
        
        func checkDarock() {
            darockAPIState = 1
            requestAPI("/") { respStr, isSuccess in
                if isSuccess {
                    if respStr.apiFixed() == "OK" {
                        darockAPIState = 3
                    } else {
                        darockAPIState = 4
                    }
                } else {
                    darockAPIState = 1
                }
                isTroubleshooting = false
            }
        }
    }
    
    struct NetworkProblemDetailsView: View {
        var body: some View {
            List {
                Section {
                    Text("网络问题")
                        .bold()
                }
                Section("这代表什么？") {
                    Text("Apple Watch 目前无法连接到互联网")
                }
                Section("我应当怎么做？") {
                    Text("确认 Apple Watch 已连接到互联网")
                    Text("断开 Apple Watch 与 iPhone 的连接")
                }
                Section("还是不行？") {
                    Text("尝试在 iPhone 设置中关闭无线局域网与蓝牙")
                }
            }
        }
    }
    struct DarockAPIProblemDetailsView: View {
        var body: some View {
            NavigationStack {
                List {
                    Section {
                        Text("Darock API 问题")
                            .bold()
                    }
                    Section("这代表什么？") {
                        Text("Darock API 服务器目前出现了问题，这不是你的错")
                    }
                    Section("我应当怎么做？") {
                        Text("等待 Darock 修复")
                    }
                }
            }
        }
    }
}
