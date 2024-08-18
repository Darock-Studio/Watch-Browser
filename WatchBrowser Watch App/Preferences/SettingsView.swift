//
//  SettingsView.swift
//  WatchBrowser Watch App
//
//  Created by WindowsMEMZ on 2023/6/6.
//

import Charts
import SwiftUI
import Cepheus
import EFQRCode
import DarockKit
import SwiftDate
import CoreLocation
import NetworkExtension
import UserNotifications
import TripleQuestionmarkCore
import AuthenticationServices

struct SettingsView: View {
    @AppStorage("DarockAccount") var darockAccount = ""
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("IsDeveloperModeEnabled") var isDeveloperModeEnabled = false
    @State var isNewFeaturesPresented = false
    @State var isPasscodeViewPresented = false
    @State var isEnterPasscodeViewInputPresented = false
    @State var passcodeInputTmp = ""
    @State var isDarockAccountLoginPresented = false
    @State var accountUsername = ""
    var body: some View {
        ZStack {
            if #unavailable(watchOS 10.0) {
                NavigationLink("", isActive: $isPasscodeViewPresented, destination: { PasswordSettingsView() })
                    .frame(width: 0, height: 0)
                    .hidden()
            }
            List {
                Section {
                    if darockAccount.isEmpty {
                        Button(action: {
                            isDarockAccountLoginPresented = true
                        }, label: {
                            HStack {
                                ZStack {
                                    Image(systemName: "circle.dotted")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.init(hex: 0x144683))
                                    Image(systemName: "circle.dotted")
                                        .font(.system(size: 30, weight: .light))
                                        .rotationEffect(.degrees(8))
                                        .foregroundColor(.init(hex: 0x144683))
                                    Text("D")
                                        .font(.custom("HYWenHei-85W", size: 14))
                                        .foregroundColor(.init(hex: 0x0c79ff))
                                        .scaleEffect(1.2)
                                }
                                VStack(alignment: .leading) {
                                    Text("Darock 账户")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("登录以为今后账户相关功能做好准备。")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        })
                        .sheet(isPresented: $isDarockAccountLoginPresented, onDismiss: {
                            if !darockAccount.isEmpty {
                                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/user/name/get/\(darockAccount)".compatibleUrlEncoded()) { respStr, isSuccess in
                                    if isSuccess {
                                        accountUsername = respStr.apiFixed()
                                    }
                                }
                            }
                        }, content: { DarockAccountLogin() })
                    } else {
                        NavigationLink(destination: { DarockAccountManagementMain(username: accountUsername) }, label: {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Group {
                                        if !accountUsername.isEmpty {
                                            Text(accountUsername)
                                                .lineLimit(1)
                                                .minimumScaleFactor(accountUsername.count <= 20 ? 0.1 : 0.5)
                                        } else {
                                            Text(verbatim: "loading")
                                                .redacted(reason: .placeholder)
                                        }
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    Text("Darock 账户以及更多")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        })
                    }
                }
                Section {
                    NavigationLink(destination: { StaredSettingsView() }, label: { SettingItemLabel(title: "常用设置", image: "star", color: .orange) })
                    NavigationLink(destination: { NetworkSettingsView() }, label: { SettingItemLabel(title: "网络", image: "network", color: .blue) })
                }
                Section {
                    NavigationLink(destination: { GeneralSettingsView() },
                                   label: { SettingItemLabel(title: "通用", image: "gear", color: .gray) })
                    NavigationLink(destination: { DisplaySettingsView() },
                                   label: { SettingItemLabel(title: "显示与亮度", image: "sun.max.fill", color: .blue) })
                    NavigationLink(destination: { BrowsingEngineSettingsView() },
                                   label: { SettingItemLabel(title: "浏览引擎", image: "globe", color: .blue) })
                    NavigationLink(destination: { HomeScreenSettingsView() },
                                   label: { SettingItemLabel(title: "主屏幕", image: "list.bullet.rectangle.portrait", color: .blue) })
                    NavigationLink(destination: { SearchSettingsView() },
                                   label: { SettingItemLabel(title: "搜索", image: "magnifyingglass", color: .gray) })
                }
                Section {
                    Button(action: {
                        if userPasscodeEncrypted.isEmpty {
                            isPasscodeViewPresented = true
                        } else {
                            isEnterPasscodeViewInputPresented = true
                        }
                    }, label: {
                        SettingItemLabel(title: "密码", image: "lock.fill", color: .red)
                    })
                    NavigationLink(destination: { PrivacySettingsView() },
                                   label: { SettingItemLabel(title: "隐私与安全性", image: "hand.raised.fill", color: .blue) })
                }
                Section {
                    if isDeveloperModeEnabled {
                        NavigationLink(destination: { DeveloperSettingsView() }, label: {
                            SettingItemLabel(title: "开发者", image: "hammer.fill", color: .blue, symbolFontSize: 10)
                        })
                    }
                    NavigationLink(destination: { LaboratoryView() }, label: {
                        SettingItemLabel(title: "实验室", image: {
                            if #available(watchOS 10, *) {
                                "flask.fill"
                            } else {
                                "hammer.fill"
                            }
                        }(), color: .blue)
                    })
                    if UserDefaults(suiteName: "group.darockst")!.bool(forKey: "IsDarockInternalTap-to-RadarAvailable") {
                        NavigationLink(destination: { InternalDebuggingView() }, label: {
                            SettingItemLabel(title: "Debugging", image: "ant.fill", color: .purple)
                        })
                    }
                }
            }
            .navigationTitle("设置")
            .navigationDestination(isPresented: $isPasscodeViewPresented, destination: { PasswordSettingsView() })
            .sheet(isPresented: $isEnterPasscodeViewInputPresented) {
                PasswordInputView(text: $passcodeInputTmp, placeholder: "输入你的密码") { pwd in
                    if pwd.md5 == userPasscodeEncrypted {
                        isPasscodeViewPresented = true
                    } else {
                        tipWithText("密码错误", symbol: "xmark.circle.fill")
                    }
                    passcodeInputTmp = ""
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            .onAppear {
                if !darockAccount.isEmpty {
                    DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/user/name/get/\(darockAccount)".compatibleUrlEncoded()) { respStr, isSuccess in
                        if isSuccess {
                            accountUsername = respStr.apiFixed()
                        }
                    }
                }
            }
        }
    }
    
    struct SettingItemLabel: View {
        var title: LocalizedStringKey
        var image: String
        var color: Color
        var symbolFontSize: CGFloat = 12
        var body: some View {
            HStack {
                ZStack {
                    color
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                    Image(systemName: image)
                        .font(.system(size: symbolFontSize))
                }
                Text(title)
            }
        }
    }
    struct SettingsSectionInfoView: View {
        var title: LocalizedStringKey
        var description: LocalizedStringKey
        var image: String
        var color: Color
        var body: some View {
            VStack {
                Spacer()
                    .frame(height: 6)
                ZStack {
                    color
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                    Image(systemName: image)
                        .font(.system(size: 25))
                }
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                Text(description)
                    .font(.system(size: 15))
                    .padding(.vertical, 3)
                Spacer()
                    .frame(height: 6)
            }
        }
    }
    
    struct StaredSettingsView: View {
        @AppStorage("RequestDesktopWeb") var requestDesktopWeb = false
        @AppStorage("ForceApplyDarkMode") var forceApplyDarkMode = false
        var body: some View {
            List {
                Section {
                    Toggle(isOn: $forceApplyDarkMode) {
                        HStack {
                            Image(systemName: "rectangle.inset.filled")
                                .foregroundStyle(Color.gray.gradient)
                            Text("强制深色模式")
                        }
                    }
                    Toggle(isOn: $requestDesktopWeb) {
                        HStack {
                            Image(systemName: "desktopcomputer")
                                .foregroundStyle(Color.blue.gradient)
                            Text("请求桌面网站")
                        }
                    }
                }
            }
            .navigationTitle("常用设置")
        }
    }
    struct NetworkSettingsView: View {
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { NetworkCheckView() }, label: { SettingItemLabel(title: "网络检查", image: "checkmark", color: .green) })
                }
            }
            .navigationTitle("网络")
        }
    }
    
    struct GeneralSettingsView: View {
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { AboutView() },
                                   label: { SettingItemLabel(title: "关于", image: "applewatch", color: .gray) })
                    NavigationLink(destination: { SoftwareUpdateView() },
                                   label: { SettingItemLabel(title: "软件更新", image: "gear.badge", color: .gray) })
                    NavigationLink(destination: { StorageView() },
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
                                   label: { SettingItemLabel(title: "法律与监管", image: "text.justify.left", color: .gray) })
                }
                Section {
                    NavigationLink(destination: { ResetView() },
                                   label: { SettingItemLabel(title: "还原", image: "arrow.counterclockwise", color: .gray) })
                }
            }
            .navigationTitle("通用")
        }
        
        struct AboutView: View {
            @State var songCount = 0
            @State var videoCount = 0
            @State var photoCount = 0
            @State var bookCount = 0
            var body: some View {
                List {
                    Section {
                        HStack {
                            Text("App 版本")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("构建版本")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)
                                .foregroundColor(.gray)
                        }
                    }
                    Section {
                        HStack {
                            Text("音乐")
                            Spacer()
                            Text(String(songCount))
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("视频")
                            Spacer()
                            Text(String(videoCount))
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("图片")
                            Spacer()
                            Text(String(photoCount))
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("图书")
                            Spacer()
                            Text(String(bookCount))
                                .foregroundColor(.gray)
                        }
                        if #available(watchOS 10, *) {
                            TQCAccentColorHiddenButton {
                                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/analyze/add/DBTQCAccentColor/\(Date.now.timeIntervalSince1970)".compatibleUrlEncoded()) { _, _ in }
                            }
                        }
                    }
                }
                .navigationTitle("关于")
                .onAppear {
                    do {
                        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/") {
                            songCount = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/").count
                        }
                        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/") {
                            videoCount = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/").count
                        }
                        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/LocalImages/") {
                            photoCount = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/LocalImages/").count
                        }
                        let allDocumentFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents")
                        bookCount = 0
                        for file in allDocumentFiles where file.hasPrefix("EPUB") {
                            bookCount++
                        }
                    } catch {
                        globalErrorHandler(error)
                    }
                }
            }
        }
        struct SoftwareUpdateView: View {
            @State var shouldUpdate = false
            @State var isLoading = true
            @State var isFailed = false
            @State var latestVer = ""
            var body: some View {
                ScrollView {
                    VStack {
                        if !isLoading {
                            if shouldUpdate {
                                HStack {
                                    Spacer()
                                        .frame(width: 10)
                                    Image("AppIconImage")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(8)
                                    Spacer()
                                        .frame(width: 10)
                                    VStack {
                                        Text("v\(latestVer)")
                                            .font(.system(size: 14, weight: .medium))
                                        HStack {
                                            Text("Darock Studio")
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                            Spacer()
                                        }
                                    }
                                }
                                Divider()
                                Button(action: {
                                    let session = ASWebAuthenticationSession(
                                        url: URL(string: "https://apps.apple.com/cn/app/darock-browser/id1670065481")!,
                                        callbackURLScheme: nil
                                    ) { _, _ in
                                        return
                                    }
                                    session.prefersEphemeralWebBrowserSession = true
                                    session.start()
                                }, label: {
                                    Text("前往更新")
                                })
                            } else if isFailed {
                                Text("检查更新时出错")
                            } else {
                                Text("暗礁浏览器已是最新版本")
                            }
                        } else {
                            HStack {
                                Text("正在检查更新...")
                                    .lineLimit(1)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: 130)
                                Spacer()
                                    .frame(maxWidth: .infinity)
                                ProgressView()
                            }
                        }
                    }
                }
                .navigationTitle("软件更新")
                .onAppear {
                    DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/drkbs/newver".compatibleUrlEncoded()) { respStr, isSuccess in
                        if isSuccess {
                            let spdVer = respStr.apiFixed().split(separator: ".")
                            if spdVer.count == 3 {
                                if let x = Int(spdVer[0]), let y = Int(spdVer[1]), let z = Int(spdVer[2]) {
                                    let currVerSpd = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String).split(separator: ".")
                                    if currVerSpd.count == 3 {
                                        if let cx = Int(currVerSpd[0]), let cy = Int(currVerSpd[1]), let cz = Int(currVerSpd[2]) {
                                            if x > cx {
                                                shouldUpdate = true
                                            } else if x == cx && y > cy {
                                                shouldUpdate = true
                                            } else if x == cx && y == cy && z > cz {
                                                shouldUpdate = true
                                            }
                                            latestVer = respStr.apiFixed()
                                            isLoading = false
                                        } else {
                                            isFailed = true
                                        }
                                    } else {
                                        isFailed = true
                                    }
                                } else {
                                    isFailed = true
                                }
                            } else {
                                isFailed = true
                            }
                        } else {
                            isFailed = true
                        }
                    }
                }
            }
        }
        struct StorageView: View {
            @State var isLoading = true
            @State var mediaSize: UInt64 = 0
            @State var webArchiveSize: UInt64 = 0
            @State var bookSize: UInt64 = 0
            @State var tmpSize: UInt64 = 0
            @State var bundleSize: UInt64 = 0
            @State var isClearingCache = false
            @State var videoMetadatas = [[String: String]]()
            @State var bookMetadatas = [[String: String]]()
            @State var audioMetadatas = [[String: String]]()
            var body: some View {
                Form {
                    List {
                        if !isLoading {
                            Section {
                                VStack {
                                    HStack {
                                        Text("已使用 \(bytesToMegabytes(bytes: mediaSize + webArchiveSize + bookSize + tmpSize + bundleSize) ~ 2) MB")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    Chart {
                                        BarMark(x: .value("", bundleSize))
                                            .foregroundStyle(by: .value("", "Gray"))
                                        BarMark(x: .value("", mediaSize))
                                            .foregroundStyle(by: .value("", "Purple"))
                                        BarMark(x: .value("", webArchiveSize))
                                            .foregroundStyle(by: .value("", "Orange"))
                                        BarMark(x: .value("", bookSize))
                                            .foregroundStyle(by: .value("", "Green"))
                                        BarMark(x: .value("", tmpSize))
                                            .foregroundStyle(by: .value("", "Primary"))
                                    }
                                    .chartForegroundStyleScale(
                                        ["Gray": .gray,
                                         "Purple": .purple,
                                         "Orange": .orange,
                                         "Green": .green,
                                         "Primary": .primary,
                                         "Secondary": Color(hex: 0x333333)]
                                    )
                                    .chartXAxis(.hidden)
                                    .chartLegend(.hidden)
                                    .cornerRadius(2)
                                    .frame(height: 15)
                                    .padding(.vertical, 2)
                                    Group {
                                        HStack {
                                            Circle()
                                                .fill(Color.gray)
                                                .frame(width: 10, height: 10)
                                            Text("暗礁浏览器")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                            Spacer()
                                        }
                                        if mediaSize > 0 {
                                            HStack {
                                                Circle()
                                                    .fill(Color.purple)
                                                    .frame(width: 10, height: 10)
                                                Text("媒体")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                            }
                                        }
                                        if bookSize > 0 {
                                            HStack {
                                                Circle()
                                                    .fill(Color.green)
                                                    .frame(width: 10, height: 10)
                                                Text("图书")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                            }
                                        }
                                        if webArchiveSize > 0 {
                                            HStack {
                                                Circle()
                                                    .fill(Color.orange)
                                                    .frame(width: 10, height: 10)
                                                Text("网页归档")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                            }
                                        }
                                        if tmpSize > 0 {
                                            HStack {
                                                Circle()
                                                    .fill(Color.primary)
                                                    .frame(width: 10, height: 10)
                                                Text("缓存数据")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding(.vertical, -1)
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            if !videoMetadatas.isEmpty {
                                Section {
                                    ForEach(0..<videoMetadatas.count, id: \.self) { i in
                                        VStack {
                                            HStack {
                                                Text(videoMetadatas[i]["Title"]!)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .lineLimit(2)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("\(bytesToMegabytes(bytes: UInt64(videoMetadatas[i]["Size"] ?? "0") ?? 0) ~ 2) MB")
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                            }
                                        }
                                        .swipeActions {
                                            Button(role: .destructive, action: {
                                                do {
                                                    try FileManager.default.removeItem(
                                                        atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/" + videoMetadatas[i]["FileName"]!
                                                    )
                                                    videoMetadatas.remove(at: i)
                                                } catch {
                                                    globalErrorHandler(error)
                                                }
                                            }, label: {
                                                Image(systemName: "xmark.bin.fill")
                                            })
                                        }
                                    }
                                } header: {
                                    Text("视频")
                                }
                            }
                            if !audioMetadatas.isEmpty {
                                Section {
                                    ForEach(0..<audioMetadatas.count, id: \.self) { i in
                                        VStack {
                                            HStack {
                                                Text(audioMetadatas[i]["Title"]!)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .lineLimit(2)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("\(bytesToMegabytes(bytes: UInt64(audioMetadatas[i]["Size"] ?? "0") ?? 0) ~ 2) MB")
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                            }
                                        }
                                        .swipeActions {
                                            Button(role: .destructive, action: {
                                                do {
                                                    try FileManager.default.removeItem(
                                                        atPath: NSHomeDirectory() + "/Documents/DownloadedAudios/" + audioMetadatas[i]["FileName"]!
                                                    )
                                                    audioMetadatas.remove(at: i)
                                                } catch {
                                                    globalErrorHandler(error)
                                                }
                                            }, label: {
                                                Image(systemName: "xmark.bin.fill")
                                            })
                                        }
                                    }
                                } header: {
                                    Text("音乐")
                                }
                            }
                            if !bookMetadatas.isEmpty {
                                Section {
                                    ForEach(0..<bookMetadatas.count, id: \.self) { i in
                                        if let name = bookMetadatas[i]["Name"], let sizeStr = bookMetadatas[i]["Size"], let size = UInt64(sizeStr) {
                                            VStack {
                                                HStack {
                                                    Text(name)
                                                        .font(.system(size: 13, weight: .bold))
                                                        .lineLimit(2)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text("\(bytesToMegabytes(bytes: size) ~ 2) MB")
                                                        .font(.system(size: 15))
                                                        .foregroundColor(.gray)
                                                    Spacer()
                                                }
                                            }
                                            .swipeActions {
                                                Button(role: .destructive, action: {
                                                    do {
                                                        var names = UserDefaults.standard.stringArray(forKey: "EPUBFlieFolders") ?? [String]()
                                                        names.removeAll(where: { element in
                                                            return if element == bookMetadatas[i]["Folder"]! { true } else { false }
                                                        })
                                                        try FileManager.default.removeItem(
                                                            atPath: NSHomeDirectory() + "/Documents/" + bookMetadatas[i]["Folder"]!
                                                        )
                                                        bookMetadatas.remove(at: i)
                                                    } catch {
                                                        globalErrorHandler(error)
                                                    }
                                                }, label: {
                                                    Image(systemName: "xmark.bin.fill")
                                                })
                                            }
                                        }
                                    }
                                } header: {
                                    Text("图书")
                                }
                            }
                            Section {
                                NavigationLink(destination: {
                                    List {
                                        Section {
                                            HStack {
                                                Image("AppIconImage")
                                                    .resizable()
                                                    .frame(width: 26, height: 26)
                                                    .clipShape(Circle())
                                                Spacer()
                                                    .frame(width: 5)
                                                VStack {
                                                    HStack {
                                                        Text("暗礁浏览器")
                                                            .font(.system(size: 18))
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("Darock Studio")
                                                            .font(.system(size: 14))
                                                            .foregroundColor(.gray)
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("版本：\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
                                                            .font(.system(size: 14))
                                                            .foregroundColor(.gray)
                                                        Spacer()
                                                    }
                                                }
                                            }
                                            HStack {
                                                Text("总空间")
                                                Spacer()
                                                Text("\(bytesToMegabytes(bytes: bundleSize) ~ 2) MB")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .navigationTitle("暗礁浏览器")
                                }, label: {
                                    HStack {
                                        Image("AppIconImage")
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .clipShape(Circle())
                                        Spacer()
                                            .frame(width: 5)
                                        VStack {
                                            HStack {
                                                Text("暗礁浏览器 (\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String))")
                                                Spacer()
                                            }
                                            HStack {
                                                Text("\(bytesToMegabytes(bytes: bundleSize) ~ 2) MB")
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                            }
                                        }
                                    }
                                })
                                if bytesToMegabytes(bytes: tmpSize) > 0.2 {
                                    NavigationLink(destination: {
                                        List {
                                            Section {
                                                HStack {
                                                    ZStack {
                                                        Color.gray
                                                            .frame(width: 20, height: 20)
                                                            .clipShape(Circle())
                                                        Image(systemName: "ellipsis.circle")
                                                            .font(.system(size: 12))
                                                    }
                                                    Spacer()
                                                        .frame(width: 5)
                                                    VStack {
                                                        HStack {
                                                            Text("缓存数据")
                                                            Spacer()
                                                        }
                                                        HStack {
                                                            Text("\(bytesToMegabytes(bytes: tmpSize) ~ 2) MB")
                                                                .font(.system(size: 15))
                                                                .foregroundColor(.gray)
                                                            Spacer()
                                                        }
                                                    }
                                                }
                                            }
                                            Section {
                                                if !isClearingCache {
                                                    Button(action: {
                                                        DispatchQueue(label: "com.darock.WatchBrowser.storage-clear-cache", qos: .userInitiated).async {
                                                            do {
                                                                isClearingCache = true
                                                                let filePaths = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
                                                                for filePath in filePaths {
                                                                    let fullPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(filePath)
                                                                    try FileManager.default.removeItem(atPath: fullPath)
                                                                }
                                                                isClearingCache = false
                                                            } catch {
                                                                globalErrorHandler(error)
                                                            }
                                                        }
                                                    }, label: {
                                                        Text("清除缓存")
                                                    })
                                                } else {
                                                    ProgressView()
                                                }
                                            }
                                        }
                                        .navigationTitle("缓存数据")
                                    }, label: {
                                        HStack {
                                            ZStack {
                                                Color.gray
                                                    .frame(width: 20, height: 20)
                                                    .clipShape(Circle())
                                                Image(systemName: "ellipsis")
                                                    .font(.system(size: 12))
                                            }
                                            Spacer()
                                                .frame(width: 5)
                                            VStack {
                                                HStack {
                                                    Text("缓存数据")
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text("\(bytesToMegabytes(bytes: tmpSize) ~ 2) MB")
                                                        .font(.system(size: 15))
                                                        .foregroundColor(.gray)
                                                    Spacer()
                                                }
                                            }
                                        }
                                    })
                                }
                            }
                        } else {
                            HStack {
                                Text("正在载入")
                                Spacer()
                                ProgressView()
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .navigationTitle("储存空间")
                .onAppear {
                    if isLoading {
                        DispatchQueue(label: "com.darock.DarockBili.storage-load", qos: .userInitiated).async {
                            do {
                                // Size counting
                                mediaSize = (folderSize(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos") ?? 0)
                                + (folderSize(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios") ?? 0)
                                webArchiveSize = folderSize(atPath: NSHomeDirectory() + "/Documents/WebArchives") ?? 0
                                tmpSize = folderSize(atPath: NSTemporaryDirectory()) ?? 0
                                bundleSize = folderSize(atPath: Bundle.main.bundlePath) ?? 0
                                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos") {
                                    // Video Sizes
                                    let files = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos")
                                    let videoHumanNameChart = (
                                        UserDefaults.standard.dictionary(forKey: "VideoHumanNameChart") as? [String: String]
                                    ) ?? [String: String]()
                                    for file in files {
                                        var dicV = [String: String]()
                                        dicV.updateValue(NSHomeDirectory() + "/Documents/DownloadedVideos/\(file)", forKey: "Path")
                                        do {
                                            let attributes = try FileManager.default.attributesOfItem(atPath: dicV["Path"]!)
                                            if (attributes[.type] as! FileAttributeType) != .typeDirectory {
                                                if let fileSize = attributes[.size] as? UInt64 {
                                                    dicV.updateValue(String(fileSize), forKey: "Size")
                                                }
                                            } else {
                                                if let fileSize = folderSize(atPath: NSHomeDirectory() + "/Documents/DownloadedVideos/\(file)") {
                                                    dicV.updateValue(String(fileSize), forKey: "Size")
                                                }
                                            }
                                        } catch {
                                            globalErrorHandler(error)
                                        }
                                        if let vn = videoHumanNameChart[file] {
                                            dicV.updateValue(vn, forKey: "Title")
                                        } else {
                                            dicV.updateValue(file, forKey: "Title")
                                        }
                                        dicV.updateValue(file, forKey: "FileName")
                                        videoMetadatas.append(dicV)
                                    }
                                    videoMetadatas.sort { UInt64($0["Size"] ?? "0")! > UInt64($1["Size"] ?? "0")! }
                                }
                                if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios") {
                                    // Audio Sizes
                                    let files = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/DownloadedAudios")
                                    let audioHumanNameChart = (
                                        UserDefaults.standard.dictionary(forKey: "AudioHumanNameChart") as? [String: String]
                                    ) ?? [String: String]()
                                    for file in files {
                                        var dicV = [String: String]()
                                        dicV.updateValue(NSHomeDirectory() + "/Documents/DownloadedAudios/\(file)", forKey: "Path")
                                        do {
                                            let attributes = try FileManager.default.attributesOfItem(atPath: dicV["Path"]!)
                                            if let fileSize = attributes[.size] as? UInt64 {
                                                dicV.updateValue(String(fileSize), forKey: "Size")
                                            }
                                        } catch {
                                            globalErrorHandler(error)
                                        }
                                        if let vn = audioHumanNameChart[file] {
                                            dicV.updateValue(vn, forKey: "Title")
                                        } else {
                                            dicV.updateValue(file, forKey: "Title")
                                        }
                                        dicV.updateValue(file, forKey: "FileName")
                                        audioMetadatas.append(dicV)
                                    }
                                    audioMetadatas.sort { UInt64($0["Size"] ?? "0")! > UInt64($1["Size"] ?? "0")! }
                                }
                                let allDocumentFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents")
                                let bookNameChart = (UserDefaults.standard.dictionary(forKey: "EPUBFileNameChart") as? [String: String]) ?? [String: String]()
                                for file in allDocumentFiles where file.hasPrefix("EPUB") {
                                    // Books
                                    var metadata = [String: String]()
                                    metadata.updateValue(file, forKey: "Folder")
                                    if let fileSize = folderSize(atPath: NSHomeDirectory() + "/Documents/\(file)") {
                                        bookSize &+= fileSize
                                        metadata.updateValue(String(fileSize), forKey: "Size")
                                    }
                                    if let name = bookNameChart[file] {
                                        metadata.updateValue(name, forKey: "Name")
                                    }
                                    bookMetadatas.append(metadata)
                                }
                                bookMetadatas.sort { UInt64($0["Size"] ?? "0")! > UInt64($1["Size"] ?? "0")! }
                                isLoading = false
                            } catch {
                                globalErrorHandler(error)
                            }
                        }
                    }
                }
            }
            
            func folderSize(atPath path: String) -> UInt64? {
                let fileManager = FileManager.default
                guard let files = fileManager.enumerator(atPath: path) else {
                    return nil
                }
                
                var totalSize: UInt64 = 0
                
                for case let file as String in files {
                    let filePath = "\(path)/\(file)"
                    do {
                        let attributes = try fileManager.attributesOfItem(atPath: filePath)
                        if let fileSize = attributes[.size] as? UInt64 {
                            totalSize &+= fileSize
                        }
                    } catch {
                        globalErrorHandler(error)
                    }
                }
                
                return totalSize
            }
            func bytesToMegabytes(bytes: UInt64) -> Double {
                let megabytes = Double(bytes) / (1024 * 1024)
                return megabytes
            }
        }
        
        struct ContinuityView: View {
            @AppStorage("CCIsHandoffEnabled") var isHandoffEnabled = true
            @AppStorage("CCIsContinuityMediaEnabled") var isContinuityMediaEnabled = true
            var body: some View {
                List {
                    Section {
                        Toggle("接力", isOn: $isHandoffEnabled)
                    } footer: {
                        Text("接力让你能够快速在另一设备上继续浏览暗礁浏览器中的网页。在暗礁浏览器浏览网页时，带有 Apple Watch 角标的 Safari 图标会出现在 iPhone 的 App 切换器或 iPad 和 Mac 的 Dock 栏中。")
                    }
                    Section {
                        Toggle("连续互通媒体", isOn: $isContinuityMediaEnabled)
                    } footer: {
                        Text("在使用暗礁浏览器查看媒体时，可在其他设备上继续查看媒体。")
                    }
                }
                .navigationTitle("连续互通")
            }
        }
        
        struct KeyboardView: View {
            @AppStorage("ModifyKeyboard") var modifyKeyboard = false
            @State var isKeyboardPresented = false
            var body: some View {
                List {
                    Section {
                        Toggle(isOn: $modifyKeyboard) {
                            Text("Settings.keyboard.third-party")
                        }
                        if #available(watchOS 10, *) {
                            CepheusKeyboard(input: .constant(""), prompt: "Settings.keyboard.preview", CepheusIsEnabled: true)
                        } else {
                            Button(action: {
                                isKeyboardPresented = true
                            }, label: {
                                Label("Settings.keyboard.preview", systemImage: "keyboard.badge.eye")
                            })
                            .sheet(isPresented: $isKeyboardPresented, content: {
                                ExtKeyboardView(startText: "") { _ in }
                            })
                        }
                    } footer: {
                        VStack(alignment: .leading) {
                            Text("Settings.keyboard.discription")
                            if #available(watchOS 10, *) {
                                Text("Powered by Cepheus Keyboard")
                            }
                        }
                    }
                    if #available(watchOS 10, *), modifyKeyboard {
                        NavigationLink(destination: { CepheusSettingsView() }, label: {
                            Text("键盘设置...")
                        })
                    }
                }
                .navigationTitle("Settings.keyboard")
            }
        }
        struct DownloaderView: View {
            @AppStorage("DLIsFeedbackWhenFinish") var isFeedbackWhenFinish = false
            var body: some View {
                List {
                    Section {
                        Toggle("完成后提醒", isOn: $isFeedbackWhenFinish)
                    }
                }
                .navigationTitle("下载器")
            }
        }
        struct MusicPlayerView: View {
            @AppStorage("MPIsShowTranslatedLyrics") var isShowTranslatedLyrics = true
            @AppStorage("MPBackgroundPlay") var isAllowBackgroundPlay = false
            var body: some View {
                List {
                    Section {
                        Toggle("显示翻译歌词", isOn: $isShowTranslatedLyrics)
                    }
                    Section {
                        Toggle("允许后台播放", isOn: $isAllowBackgroundPlay)
                    } footer: {
                        Text("若要在后台播放，你需要在播放前连接蓝牙音频设备。")
                    }
                }
                .navigationTitle("音乐播放器")
            }
        }
        struct ImageViewerView: View {
            @AppStorage("IVUseDigitalCrownFor") var useDigitalCrownFor = "zoom"
            @AppStorage("MaxmiumScale") var maxmiumScale = 6.0
            var body: some View {
                List {
                    Section {
                        Picker("将数码表冠用作", selection: $useDigitalCrownFor) {
                            Text("缩放")
                                .tag("zoom")
                            Text("切换")
                                .tag("switch")
                        }
                        if useDigitalCrownFor == "zoom" {
                            VStack {
                                Text("最大缩放倍数")
                                Slider(value: $maxmiumScale, in: 6.0...50.0, step: 0.5) {
                                    EmptyView()
                                }
                                Text("\(String(format: "%.1f", maxmiumScale))x")
                            }
                        }
                    }
                }
                .navigationTitle("图像查看器")
            }
        }
        struct ReaderView: View {
            @State var attributedExample = NSMutableAttributedString()
            @AppStorage("RVFontSize") var fontSize = 14
            @AppStorage("RVIsBoldText") var isBoldText = false
            @AppStorage("RVCharacterSpacing") var characterSpacing = 1.0
            @State var shouldShowFontDot = false
            var body: some View {
                VStack {
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
                    Form {
                        List {
                            Section {
                                HStack {
                                    Button(action: {
                                        if fontSize > 12 {
                                            fontSize--
                                            refreshAttributedExample()
                                        }
                                        shouldShowFontDot = true
                                    }, label: {
                                        Text("A")
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
                                        Text("A")
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
                            Section {
                                Toggle("粗体文本", isOn: $isBoldText)
                                    .onChange(of: isBoldText) { _ in
                                        refreshAttributedExample()
                                    }
                            }
                            Section {
                                VStack(alignment: .leading) {
                                    Text("字间距")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.gray)
                                    Slider(value: $characterSpacing, in: 0.8...2.5, step: 0.05)
                                        .onChange(of: characterSpacing) { _ in
                                            refreshAttributedExample()
                                        }
                                    Text(characterSpacing ~ 2)
                                        .centerAligned()
                                }
                            }
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
        
        struct LegalView: View {
            var body: some View {
                List {
                    Section {
                        NavigationLink(destination: {
                            ScrollView {
                                Text(verbatim: """
                                                    GNU AFFERO GENERAL PUBLIC LICENSE
                                Version 3, 19 November 2007
                                
                                Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
                                Everyone is permitted to copy and distribute verbatim copies
                                of this license document, but changing it is not allowed.
                                
                                Preamble
                                
                                The GNU Affero General Public License is a free, copyleft license for
                                software and other kinds of works, specifically designed to ensure
                                cooperation with the community in the case of network server software.
                                
                                The licenses for most software and other practical works are designed
                                to take away your freedom to share and change the works.  By contrast,
                                our General Public Licenses are intended to guarantee your freedom to
                                share and change all versions of a program--to make sure it remains free
                                software for all its users.
                                
                                When we speak of free software, we are referring to freedom, not
                                price.  Our General Public Licenses are designed to make sure that you
                                have the freedom to distribute copies of free software (and charge for
                                them if you wish), that you receive source code or can get it if you
                                want it, that you can change the software or use pieces of it in new
                                free programs, and that you know you can do these things.
                                
                                Developers that use our General Public Licenses protect your rights
                                with two steps: (1) assert copyright on the software, and (2) offer
                                you this License which gives you legal permission to copy, distribute
                                and/or modify the software.
                                
                                A secondary benefit of defending all users' freedom is that
                                improvements made in alternate versions of the program, if they
                                receive widespread use, become available for other developers to
                                incorporate.  Many developers of free software are heartened and
                                encouraged by the resulting cooperation.  However, in the case of
                                software used on network servers, this result may fail to come about.
                                The GNU General Public License permits making a modified version and
                                letting the public access it on a server without ever releasing its
                                source code to the public.
                                
                                The GNU Affero General Public License is designed specifically to
                                ensure that, in such cases, the modified source code becomes available
                                to the community.  It requires the operator of a network server to
                                provide the source code of the modified version running there to the
                                users of that server.  Therefore, public use of a modified version, on
                                a publicly accessible server, gives the public access to the source
                                code of the modified version.
                                
                                An older license, called the Affero General Public License and
                                published by Affero, was designed to accomplish similar goals.  This is
                                a different license, not a version of the Affero GPL, but Affero has
                                released a new version of the Affero GPL which permits relicensing under
                                this license.
                                
                                The precise terms and conditions for copying, distribution and
                                modification follow.
                                
                                TERMS AND CONDITIONS
                                
                                0. Definitions.
                                
                                "This License" refers to version 3 of the GNU Affero General Public License.
                                
                                "Copyright" also means copyright-like laws that apply to other kinds of
                                works, such as semiconductor masks.
                                
                                "The Program" refers to any copyrightable work licensed under this
                                License.  Each licensee is addressed as "you".  "Licensees" and
                                "recipients" may be individuals or organizations.
                                
                                To "modify" a work means to copy from or adapt all or part of the work
                                in a fashion requiring copyright permission, other than the making of an
                                exact copy.  The resulting work is called a "modified version" of the
                                earlier work or a work "based on" the earlier work.
                                
                                A "covered work" means either the unmodified Program or a work based
                                on the Program.
                                
                                To "propagate" a work means to do anything with it that, without
                                permission, would make you directly or secondarily liable for
                                infringement under applicable copyright law, except executing it on a
                                computer or modifying a private copy.  Propagation includes copying,
                                distribution (with or without modification), making available to the
                                public, and in some countries other activities as well.
                                
                                To "convey" a work means any kind of propagation that enables other
                                parties to make or receive copies.  Mere interaction with a user through
                                a computer network, with no transfer of a copy, is not conveying.
                                
                                An interactive user interface displays "Appropriate Legal Notices"
                                to the extent that it includes a convenient and prominently visible
                                feature that (1) displays an appropriate copyright notice, and (2)
                                tells the user that there is no warranty for the work (except to the
                                extent that warranties are provided), that licensees may convey the
                                work under this License, and how to view a copy of this License.  If
                                the interface presents a list of user commands or options, such as a
                                menu, a prominent item in the list meets this criterion.
                                
                                1. Source Code.
                                
                                The "source code" for a work means the preferred form of the work
                                for making modifications to it.  "Object code" means any non-source
                                form of a work.
                                
                                A "Standard Interface" means an interface that either is an official
                                standard defined by a recognized standards body, or, in the case of
                                interfaces specified for a particular programming language, one that
                                is widely used among developers working in that language.
                                
                                The "System Libraries" of an executable work include anything, other
                                than the work as a whole, that (a) is included in the normal form of
                                packaging a Major Component, but which is not part of that Major
                                Component, and (b) serves only to enable use of the work with that
                                Major Component, or to implement a Standard Interface for which an
                                implementation is available to the public in source code form.  A
                                "Major Component", in this context, means a major essential component
                                (kernel, window system, and so on) of the specific operating system
                                (if any) on which the executable work runs, or a compiler used to
                                produce the work, or an object code interpreter used to run it.
                                
                                The "Corresponding Source" for a work in object code form means all
                                the source code needed to generate, install, and (for an executable
                                work) run the object code and to modify the work, including scripts to
                                control those activities.  However, it does not include the work's
                                System Libraries, or general-purpose tools or generally available free
                                programs which are used unmodified in performing those activities but
                                which are not part of the work.  For example, Corresponding Source
                                includes interface definition files associated with source files for
                                the work, and the source code for shared libraries and dynamically
                                linked subprograms that the work is specifically designed to require,
                                such as by intimate data communication or control flow between those
                                subprograms and other parts of the work.
                                
                                The Corresponding Source need not include anything that users
                                can regenerate automatically from other parts of the Corresponding
                                Source.
                                
                                The Corresponding Source for a work in source code form is that
                                same work.
                                
                                2. Basic Permissions.
                                
                                All rights granted under this License are granted for the term of
                                copyright on the Program, and are irrevocable provided the stated
                                conditions are met.  This License explicitly affirms your unlimited
                                permission to run the unmodified Program.  The output from running a
                                covered work is covered by this License only if the output, given its
                                content, constitutes a covered work.  This License acknowledges your
                                rights of fair use or other equivalent, as provided by copyright law.
                                
                                You may make, run and propagate covered works that you do not
                                convey, without conditions so long as your license otherwise remains
                                in force.  You may convey covered works to others for the sole purpose
                                of having them make modifications exclusively for you, or provide you
                                with facilities for running those works, provided that you comply with
                                the terms of this License in conveying all material for which you do
                                not control copyright.  Those thus making or running the covered works
                                for you must do so exclusively on your behalf, under your direction
                                and control, on terms that prohibit them from making any copies of
                                your copyrighted material outside their relationship with you.
                                
                                Conveying under any other circumstances is permitted solely under
                                the conditions stated below.  Sublicensing is not allowed; section 10
                                makes it unnecessary.
                                
                                3. Protecting Users' Legal Rights From Anti-Circumvention Law.
                                
                                No covered work shall be deemed part of an effective technological
                                measure under any applicable law fulfilling obligations under article
                                11 of the WIPO copyright treaty adopted on 20 December 1996, or
                                similar laws prohibiting or restricting circumvention of such
                                measures.
                                
                                When you convey a covered work, you waive any legal power to forbid
                                circumvention of technological measures to the extent such circumvention
                                is effected by exercising rights under this License with respect to
                                the covered work, and you disclaim any intention to limit operation or
                                modification of the work as a means of enforcing, against the work's
                                users, your or third parties' legal rights to forbid circumvention of
                                technological measures.
                                
                                4. Conveying Verbatim Copies.
                                
                                You may convey verbatim copies of the Program's source code as you
                                receive it, in any medium, provided that you conspicuously and
                                appropriately publish on each copy an appropriate copyright notice;
                                keep intact all notices stating that this License and any
                                non-permissive terms added in accord with section 7 apply to the code;
                                keep intact all notices of the absence of any warranty; and give all
                                recipients a copy of this License along with the Program.
                                
                                You may charge any price or no price for each copy that you convey,
                                and you may offer support or warranty protection for a fee.
                                
                                5. Conveying Modified Source Versions.
                                
                                You may convey a work based on the Program, or the modifications to
                                produce it from the Program, in the form of source code under the
                                terms of section 4, provided that you also meet all of these conditions:
                                
                                a) The work must carry prominent notices stating that you modified
                                it, and giving a relevant date.
                                
                                b) The work must carry prominent notices stating that it is
                                released under this License and any conditions added under section
                                7.  This requirement modifies the requirement in section 4 to
                                "keep intact all notices".
                                
                                c) You must license the entire work, as a whole, under this
                                License to anyone who comes into possession of a copy.  This
                                License will therefore apply, along with any applicable section 7
                                additional terms, to the whole of the work, and all its parts,
                                regardless of how they are packaged.  This License gives no
                                permission to license the work in any other way, but it does not
                                invalidate such permission if you have separately received it.
                                
                                d) If the work has interactive user interfaces, each must display
                                Appropriate Legal Notices; however, if the Program has interactive
                                interfaces that do not display Appropriate Legal Notices, your
                                work need not make them do so.
                                
                                A compilation of a covered work with other separate and independent
                                works, which are not by their nature extensions of the covered work,
                                and which are not combined with it such as to form a larger program,
                                in or on a volume of a storage or distribution medium, is called an
                                "aggregate" if the compilation and its resulting copyright are not
                                used to limit the access or legal rights of the compilation's users
                                beyond what the individual works permit.  Inclusion of a covered work
                                in an aggregate does not cause this License to apply to the other
                                parts of the aggregate.
                                
                                6. Conveying Non-Source Forms.
                                
                                You may convey a covered work in object code form under the terms
                                of sections 4 and 5, provided that you also convey the
                                machine-readable Corresponding Source under the terms of this License,
                                in one of these ways:
                                
                                a) Convey the object code in, or embodied in, a physical product
                                (including a physical distribution medium), accompanied by the
                                Corresponding Source fixed on a durable physical medium
                                customarily used for software interchange.
                                
                                b) Convey the object code in, or embodied in, a physical product
                                (including a physical distribution medium), accompanied by a
                                written offer, valid for at least three years and valid for as
                                long as you offer spare parts or customer support for that product
                                model, to give anyone who possesses the object code either (1) a
                                copy of the Corresponding Source for all the software in the
                                product that is covered by this License, on a durable physical
                                medium customarily used for software interchange, for a price no
                                more than your reasonable cost of physically performing this
                                conveying of source, or (2) access to copy the
                                Corresponding Source from a network server at no charge.
                                
                                c) Convey individual copies of the object code with a copy of the
                                written offer to provide the Corresponding Source.  This
                                alternative is allowed only occasionally and noncommercially, and
                                only if you received the object code with such an offer, in accord
                                with subsection 6b.
                                
                                d) Convey the object code by offering access from a designated
                                place (gratis or for a charge), and offer equivalent access to the
                                Corresponding Source in the same way through the same place at no
                                further charge.  You need not require recipients to copy the
                                Corresponding Source along with the object code.  If the place to
                                copy the object code is a network server, the Corresponding Source
                                may be on a different server (operated by you or a third party)
                                that supports equivalent copying facilities, provided you maintain
                                clear directions next to the object code saying where to find the
                                Corresponding Source.  Regardless of what server hosts the
                                Corresponding Source, you remain obligated to ensure that it is
                                available for as long as needed to satisfy these requirements.
                                
                                e) Convey the object code using peer-to-peer transmission, provided
                                you inform other peers where the object code and Corresponding
                                Source of the work are being offered to the general public at no
                                charge under subsection 6d.
                                
                                A separable portion of the object code, whose source code is excluded
                                from the Corresponding Source as a System Library, need not be
                                included in conveying the object code work.
                                
                                A "User Product" is either (1) a "consumer product", which means any
                                tangible personal property which is normally used for personal, family,
                                or household purposes, or (2) anything designed or sold for incorporation
                                into a dwelling.  In determining whether a product is a consumer product,
                                doubtful cases shall be resolved in favor of coverage.  For a particular
                                product received by a particular user, "normally used" refers to a
                                typical or common use of that class of product, regardless of the status
                                of the particular user or of the way in which the particular user
                                actually uses, or expects or is expected to use, the product.  A product
                                is a consumer product regardless of whether the product has substantial
                                commercial, industrial or non-consumer uses, unless such uses represent
                                the only significant mode of use of the product.
                                
                                "Installation Information" for a User Product means any methods,
                                procedures, authorization keys, or other information required to install
                                and execute modified versions of a covered work in that User Product from
                                a modified version of its Corresponding Source.  The information must
                                suffice to ensure that the continued functioning of the modified object
                                code is in no case prevented or interfered with solely because
                                modification has been made.
                                
                                If you convey an object code work under this section in, or with, or
                                specifically for use in, a User Product, and the conveying occurs as
                                part of a transaction in which the right of possession and use of the
                                User Product is transferred to the recipient in perpetuity or for a
                                fixed term (regardless of how the transaction is characterized), the
                                Corresponding Source conveyed under this section must be accompanied
                                by the Installation Information.  But this requirement does not apply
                                if neither you nor any third party retains the ability to install
                                modified object code on the User Product (for example, the work has
                                been installed in ROM).
                                
                                The requirement to provide Installation Information does not include a
                                requirement to continue to provide support service, warranty, or updates
                                for a work that has been modified or installed by the recipient, or for
                                the User Product in which it has been modified or installed.  Access to a
                                network may be denied when the modification itself materially and
                                adversely affects the operation of the network or violates the rules and
                                protocols for communication across the network.
                                
                                Corresponding Source conveyed, and Installation Information provided,
                                in accord with this section must be in a format that is publicly
                                documented (and with an implementation available to the public in
                                source code form), and must require no special password or key for
                                unpacking, reading or copying.
                                
                                7. Additional Terms.
                                
                                "Additional permissions" are terms that supplement the terms of this
                                License by making exceptions from one or more of its conditions.
                                Additional permissions that are applicable to the entire Program shall
                                be treated as though they were included in this License, to the extent
                                that they are valid under applicable law.  If additional permissions
                                apply only to part of the Program, that part may be used separately
                                under those permissions, but the entire Program remains governed by
                                this License without regard to the additional permissions.
                                
                                When you convey a copy of a covered work, you may at your option
                                remove any additional permissions from that copy, or from any part of
                                it.  (Additional permissions may be written to require their own
                                removal in certain cases when you modify the work.)  You may place
                                additional permissions on material, added by you to a covered work,
                                for which you have or can give appropriate copyright permission.
                                
                                Notwithstanding any other provision of this License, for material you
                                add to a covered work, you may (if authorized by the copyright holders of
                                that material) supplement the terms of this License with terms:
                                
                                a) Disclaiming warranty or limiting liability differently from the
                                terms of sections 15 and 16 of this License; or
                                
                                b) Requiring preservation of specified reasonable legal notices or
                                author attributions in that material or in the Appropriate Legal
                                Notices displayed by works containing it; or
                                
                                c) Prohibiting misrepresentation of the origin of that material, or
                                requiring that modified versions of such material be marked in
                                reasonable ways as different from the original version; or
                                
                                d) Limiting the use for publicity purposes of names of licensors or
                                authors of the material; or
                                
                                e) Declining to grant rights under trademark law for use of some
                                trade names, trademarks, or service marks; or
                                
                                f) Requiring indemnification of licensors and authors of that
                                material by anyone who conveys the material (or modified versions of
                                it) with contractual assumptions of liability to the recipient, for
                                any liability that these contractual assumptions directly impose on
                                those licensors and authors.
                                
                                All other non-permissive additional terms are considered "further
                                restrictions" within the meaning of section 10.  If the Program as you
                                received it, or any part of it, contains a notice stating that it is
                                governed by this License along with a term that is a further
                                restriction, you may remove that term.  If a license document contains
                                a further restriction but permits relicensing or conveying under this
                                License, you may add to a covered work material governed by the terms
                                of that license document, provided that the further restriction does
                                not survive such relicensing or conveying.
                                
                                If you add terms to a covered work in accord with this section, you
                                must place, in the relevant source files, a statement of the
                                additional terms that apply to those files, or a notice indicating
                                where to find the applicable terms.
                                
                                Additional terms, permissive or non-permissive, may be stated in the
                                form of a separately written license, or stated as exceptions;
                                the above requirements apply either way.
                                
                                8. Termination.
                                
                                You may not propagate or modify a covered work except as expressly
                                provided under this License.  Any attempt otherwise to propagate or
                                modify it is void, and will automatically terminate your rights under
                                this License (including any patent licenses granted under the third
                                paragraph of section 11).
                                
                                However, if you cease all violation of this License, then your
                                license from a particular copyright holder is reinstated (a)
                                provisionally, unless and until the copyright holder explicitly and
                                finally terminates your license, and (b) permanently, if the copyright
                                holder fails to notify you of the violation by some reasonable means
                                prior to 60 days after the cessation.
                                
                                Moreover, your license from a particular copyright holder is
                                reinstated permanently if the copyright holder notifies you of the
                                violation by some reasonable means, this is the first time you have
                                received notice of violation of this License (for any work) from that
                                copyright holder, and you cure the violation prior to 30 days after
                                your receipt of the notice.
                                
                                Termination of your rights under this section does not terminate the
                                licenses of parties who have received copies or rights from you under
                                this License.  If your rights have been terminated and not permanently
                                reinstated, you do not qualify to receive new licenses for the same
                                material under section 10.
                                
                                9. Acceptance Not Required for Having Copies.
                                
                                You are not required to accept this License in order to receive or
                                run a copy of the Program.  Ancillary propagation of a covered work
                                occurring solely as a consequence of using peer-to-peer transmission
                                to receive a copy likewise does not require acceptance.  However,
                                nothing other than this License grants you permission to propagate or
                                modify any covered work.  These actions infringe copyright if you do
                                not accept this License.  Therefore, by modifying or propagating a
                                covered work, you indicate your acceptance of this License to do so.
                                
                                10. Automatic Licensing of Downstream Recipients.
                                
                                Each time you convey a covered work, the recipient automatically
                                receives a license from the original licensors, to run, modify and
                                propagate that work, subject to this License.  You are not responsible
                                for enforcing compliance by third parties with this License.
                                
                                An "entity transaction" is a transaction transferring control of an
                                organization, or substantially all assets of one, or subdividing an
                                organization, or merging organizations.  If propagation of a covered
                                work results from an entity transaction, each party to that
                                transaction who receives a copy of the work also receives whatever
                                licenses to the work the party's predecessor in interest had or could
                                give under the previous paragraph, plus a right to possession of the
                                Corresponding Source of the work from the predecessor in interest, if
                                the predecessor has it or can get it with reasonable efforts.
                                
                                You may not impose any further restrictions on the exercise of the
                                rights granted or affirmed under this License.  For example, you may
                                not impose a license fee, royalty, or other charge for exercise of
                                rights granted under this License, and you may not initiate litigation
                                (including a cross-claim or counterclaim in a lawsuit) alleging that
                                any patent claim is infringed by making, using, selling, offering for
                                sale, or importing the Program or any portion of it.
                                
                                11. Patents.
                                
                                A "contributor" is a copyright holder who authorizes use under this
                                License of the Program or a work on which the Program is based.  The
                                work thus licensed is called the contributor's "contributor version".
                                
                                A contributor's "essential patent claims" are all patent claims
                                owned or controlled by the contributor, whether already acquired or
                                hereafter acquired, that would be infringed by some manner, permitted
                                by this License, of making, using, or selling its contributor version,
                                but do not include claims that would be infringed only as a
                                consequence of further modification of the contributor version.  For
                                purposes of this definition, "control" includes the right to grant
                                patent sublicenses in a manner consistent with the requirements of
                                this License.
                                
                                Each contributor grants you a non-exclusive, worldwide, royalty-free
                                patent license under the contributor's essential patent claims, to
                                make, use, sell, offer for sale, import and otherwise run, modify and
                                propagate the contents of its contributor version.
                                
                                In the following three paragraphs, a "patent license" is any express
                                agreement or commitment, however denominated, not to enforce a patent
                                (such as an express permission to practice a patent or covenant not to
                                sue for patent infringement).  To "grant" such a patent license to a
                                party means to make such an agreement or commitment not to enforce a
                                patent against the party.
                                
                                If you convey a covered work, knowingly relying on a patent license,
                                and the Corresponding Source of the work is not available for anyone
                                to copy, free of charge and under the terms of this License, through a
                                publicly available network server or other readily accessible means,
                                then you must either (1) cause the Corresponding Source to be so
                                available, or (2) arrange to deprive yourself of the benefit of the
                                patent license for this particular work, or (3) arrange, in a manner
                                consistent with the requirements of this License, to extend the patent
                                license to downstream recipients.  "Knowingly relying" means you have
                                actual knowledge that, but for the patent license, your conveying the
                                covered work in a country, or your recipient's use of the covered work
                                in a country, would infringe one or more identifiable patents in that
                                country that you have reason to believe are valid.
                                
                                If, pursuant to or in connection with a single transaction or
                                arrangement, you convey, or propagate by procuring conveyance of, a
                                covered work, and grant a patent license to some of the parties
                                receiving the covered work authorizing them to use, propagate, modify
                                or convey a specific copy of the covered work, then the patent license
                                you grant is automatically extended to all recipients of the covered
                                work and works based on it.
                                
                                A patent license is "discriminatory" if it does not include within
                                the scope of its coverage, prohibits the exercise of, or is
                                conditioned on the non-exercise of one or more of the rights that are
                                specifically granted under this License.  You may not convey a covered
                                work if you are a party to an arrangement with a third party that is
                                in the business of distributing software, under which you make payment
                                to the third party based on the extent of your activity of conveying
                                the work, and under which the third party grants, to any of the
                                parties who would receive the covered work from you, a discriminatory
                                patent license (a) in connection with copies of the covered work
                                conveyed by you (or copies made from those copies), or (b) primarily
                                for and in connection with specific products or compilations that
                                contain the covered work, unless you entered into that arrangement,
                                or that patent license was granted, prior to 28 March 2007.
                                
                                Nothing in this License shall be construed as excluding or limiting
                                any implied license or other defenses to infringement that may
                                otherwise be available to you under applicable patent law.
                                
                                12. No Surrender of Others' Freedom.
                                
                                If conditions are imposed on you (whether by court order, agreement or
                                otherwise) that contradict the conditions of this License, they do not
                                excuse you from the conditions of this License.  If you cannot convey a
                                covered work so as to satisfy simultaneously your obligations under this
                                License and any other pertinent obligations, then as a consequence you may
                                not convey it at all.  For example, if you agree to terms that obligate you
                                to collect a royalty for further conveying from those to whom you convey
                                the Program, the only way you could satisfy both those terms and this
                                License would be to refrain entirely from conveying the Program.
                                
                                13. Remote Network Interaction; Use with the GNU General Public License.
                                
                                Notwithstanding any other provision of this License, if you modify the
                                Program, your modified version must prominently offer all users
                                interacting with it remotely through a computer network (if your version
                                supports such interaction) an opportunity to receive the Corresponding
                                Source of your version by providing access to the Corresponding Source
                                from a network server at no charge, through some standard or customary
                                means of facilitating copying of software.  This Corresponding Source
                                shall include the Corresponding Source for any work covered by version 3
                                of the GNU General Public License that is incorporated pursuant to the
                                following paragraph.
                                
                                Notwithstanding any other provision of this License, you have
                                permission to link or combine any covered work with a work licensed
                                under version 3 of the GNU General Public License into a single
                                combined work, and to convey the resulting work.  The terms of this
                                License will continue to apply to the part which is the covered work,
                                but the work with which it is combined will remain governed by version
                                3 of the GNU General Public License.
                                
                                14. Revised Versions of this License.
                                
                                The Free Software Foundation may publish revised and/or new versions of
                                the GNU Affero General Public License from time to time.  Such new versions
                                will be similar in spirit to the present version, but may differ in detail to
                                address new problems or concerns.
                                
                                Each version is given a distinguishing version number.  If the
                                Program specifies that a certain numbered version of the GNU Affero General
                                Public License "or any later version" applies to it, you have the
                                option of following the terms and conditions either of that numbered
                                version or of any later version published by the Free Software
                                Foundation.  If the Program does not specify a version number of the
                                GNU Affero General Public License, you may choose any version ever published
                                by the Free Software Foundation.
                                
                                If the Program specifies that a proxy can decide which future
                                versions of the GNU Affero General Public License can be used, that proxy's
                                public statement of acceptance of a version permanently authorizes you
                                to choose that version for the Program.
                                
                                Later license versions may give you additional or different
                                permissions.  However, no additional obligations are imposed on any
                                author or copyright holder as a result of your choosing to follow a
                                later version.
                                
                                15. Disclaimer of Warranty.
                                
                                THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
                                APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
                                HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
                                OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
                                THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
                                PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
                                IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
                                ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
                                
                                16. Limitation of Liability.
                                
                                IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
                                WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
                                THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
                                GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
                                USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
                                DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
                                PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
                                EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
                                SUCH DAMAGES.
                                
                                17. Interpretation of Sections 15 and 16.
                                
                                If the disclaimer of warranty and limitation of liability provided
                                above cannot be given local legal effect according to their terms,
                                reviewing courts shall apply local law that most closely approximates
                                an absolute waiver of all civil liability in connection with the
                                Program, unless a warranty or assumption of liability accompanies a
                                copy of the Program in return for a fee.
                                
                                END OF TERMS AND CONDITIONS
                                
                                How to Apply These Terms to Your New Programs
                                
                                If you develop a new program, and you want it to be of the greatest
                                possible use to the public, the best way to achieve this is to make it
                                free software which everyone can redistribute and change under these terms.
                                
                                To do so, attach the following notices to the program.  It is safest
                                to attach them to the start of each source file to most effectively
                                state the exclusion of warranty; and each file should have at least
                                the "copyright" line and a pointer to where the full notice is found.
                                
                                <one line to give the program's name and a brief idea of what it does.>
                                Copyright (C) <year>  <name of author>
                                
                                This program is free software: you can redistribute it and/or modify
                                it under the terms of the GNU Affero General Public License as published
                                by the Free Software Foundation, either version 3 of the License, or
                                (at your option) any later version.
                                
                                This program is distributed in the hope that it will be useful,
                                but WITHOUT ANY WARRANTY; without even the implied warranty of
                                MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
                                GNU Affero General Public License for more details.
                                
                                You should have received a copy of the GNU Affero General Public License
                                along with this program.  If not, see <https://www.gnu.org/licenses/>.
                                
                                Also add information on how to contact you by electronic and paper mail.
                                
                                If your software can interact with users remotely through a computer
                                network, you should also make sure that it provides a way for users to
                                get its source.  For example, if your program is a web application, its
                                interface could display a "Source" link that leads users to an archive
                                of the code.  There are many ways you could offer source, and different
                                solutions will be better for different programs; see section 13 for the
                                specific requirements.
                                
                                You should also get your employer (if you work as a programmer) or school,
                                if any, to sign a "copyright disclaimer" for the program, if necessary.
                                For more information on this, and how to apply and follow the GNU AGPL, see
                                <https://www.gnu.org/licenses/>.
                                """)
                            }
                            .navigationTitle("许可证")
                        }, label: {
                            Text("许可证")
                        })
                        NavigationLink(destination: { OpenSourceView() }, label: {
                            Text("开源协议许可")
                        })
                    } header: {
                        Text("暗礁浏览器")
                    }
                    if NSLocale.current.language.languageCode!.identifier == "zh" {
                        Section {
                            Button(action: {
                                let session = ASWebAuthenticationSession(
                                    url: URL(string: "https://beian.miit.gov.cn")!,
                                    callbackURLScheme: nil
                                ) { _, _ in
                                    
                                }
                                session.prefersEphemeralWebBrowserSession = true
                                session.start()
                            }, label: {
                                Text("浙ICP备2024071295号-2A")
                            })
                        } header: {
                            Text("中国大陆ICP备案号")
                        }
                    }
                }
                .navigationTitle("法律与监管")
            }
            
            struct OpenSourceView: View {
                @State var isTQCView1Presented = false
                var body: some View {
                    List {
                        SinglePackageBlock(name: "AEXML", license: "MIT license")
                        SinglePackageBlock(name: "Alamofire", license: "MIT license")
                        SinglePackageBlock(name: "Cepheus", license: "Apache License 2.0")
                        SinglePackageBlock(name: "Dynamic", license: "Apache License 2.0")
                        SinglePackageBlock(name: "EFQRCode", license: "MIT license")
                        SinglePackageBlock(name: "EPUBKit", license: "MIT license")
                        SinglePackageBlock(name: "libwebp", license: "BSD-3-Clause license")
                        SinglePackageBlock(name: "NetworkImage", license: "MIT license")
                        SinglePackageBlock(name: "Punycode", license: "MIT license")
                        SinglePackageBlock(name: "SDWebImage", license: "MIT license")
                        SinglePackageBlock(name: "SDWebImagePDFCoder", license: "MIT license")
                        SinglePackageBlock(name: "SDWebImageSVGCoder", license: "MIT license")
                        SinglePackageBlock(name: "SDWebImageSwiftUI", license: "MIT license")
                        SinglePackageBlock(name: "SDWebImageWebPCoder", license: "MIT license")
                        SinglePackageBlock(name: "swift_qrcodejs", license: "MIT license")
                        SinglePackageBlock(name: "swift-markdown-ui", license: "MIT license")
                        SinglePackageBlock(name: "SwiftDate", license: "MIT license")
                        SinglePackageBlock(name: "SwiftSoup", license: "MIT license")
                        SinglePackageBlock(name: "SwiftyJSON", license: "MIT license")
                        SinglePackageBlock(name: "Vela", license: "Apache License 2.0")
                        SinglePackageBlock(name: "Zip", license: "MIT license")
                        SinglePackageBlock(name: "???Core", license: "???")
                            .onTapGesture {
                                isTQCView1Presented = true
                            }
                    }
                    .navigationTitle("开源协议许可")
                    .sheet(isPresented: $isTQCView1Presented, content: {
                        TQCOnaniiView()
                            .onAppear {
                                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/analyze/add/DBTQCOnanii/\(Date.now.timeIntervalSince1970)".compatibleUrlEncoded()) { _, _ in }
                            }
                    })
                }
                
                struct SinglePackageBlock: View {
                    var name: String
                    var license: String
                    var body: some View {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(Color(hex: 0xa06f2f))
                            VStack {
                                HStack {
                                    Text(name)
                                    Spacer()
                                }
                                HStack {
                                    Text(license)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        struct ResetView: View {
            @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
            @State var isResetSettingsWarningPresented = false
            @State var isResetAllWarningPresented = false
            @State var isResetSettingsPasscodePresented = false
            @State var isResetSettingsDelayPresented = false
            @State var passcodeInputTmp = ""
            var body: some View {
                List {
                    Section {
                        Button(action: {
                            if userPasscodeEncrypted.isEmpty {
                                isResetSettingsWarningPresented = true
                            } else {
                                if checkSecurityDelay() {
                                    isResetSettingsPasscodePresented = true
                                } else {
                                    isResetSettingsDelayPresented = true
                                }
                            }
                        }, label: {
                            Text("还原所有设置")
                        })
                        Button(action: {
                            isResetAllWarningPresented = true
                        }, label: {
                            Text("抹掉所有内容和设置")
                        })
                    }
                }
                .navigationTitle("还原")
                .alert("还原所有设置", isPresented: $isResetSettingsWarningPresented, actions: {
                    Button(role: .cancel, action: { }, label: {
                        Text("取消")
                    })
                    Button(role: .destructive, action: {
                        do {
                            try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Library/Preferences/com.darock.WatchBrowser.watchkitapp.plist")
                            tipWithText("已还原", symbol: "checkmark.circle.fill")
                        } catch {
                            tipWithText("还原时出错", symbol: "xmark.circle.fill")
                            globalErrorHandler(error)
                        }
                    }, label: {
                        Text("还原")
                    })
                }, message: {
                    Text("此操作不可逆\n确定吗？")
                })
                .alert("抹掉所有内容和设置", isPresented: $isResetAllWarningPresented, actions: {
                    Button(role: .cancel, action: { }, label: {
                        Text("取消")
                    })
                    Button(role: .destructive, action: {
                        do {
                            let filePaths = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents")
                            for filePath in filePaths {
                                let fullPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(filePath)
                                try FileManager.default.removeItem(atPath: fullPath)
                            }
                            try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Library/Preferences/com.darock.WatchBrowser.watchkitapp.plist")
                            tipWithText("已抹掉", symbol: "checkmark.circle.fill")
                        } catch {
                            tipWithText("抹掉时出错", symbol: "xmark.circle.fill")
                            globalErrorHandler(error)
                        }
                    }, label: {
                        Text("抹掉")
                    })
                }, message: {
                    Text("此操作不可逆\n确定吗？")
                })
                .sheet(isPresented: $isResetSettingsDelayPresented, content: { SecurityDelayRequiredView(reasonTitle: "需要安全延时以抹掉所有设置") })
                .sheet(isPresented: $isResetSettingsPasscodePresented) {
                    PasswordInputView(text: $passcodeInputTmp, placeholder: "输入密码以继续") { pwd in
                        if pwd.md5 == userPasscodeEncrypted {
                            isResetSettingsWarningPresented = true
                        } else {
                            tipWithText("密码错误", symbol: "xmark.circle.fill")
                        }
                        passcodeInputTmp = ""
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
    }
    struct DisplaySettingsView: View {
        @AppStorage("IsWebMinFontSizeStricted") var isWebMinFontSizeStricted = false
        @AppStorage("WebMinFontSize") var webMinFontSize = 10.0
        @AppStorage("ABIsReduceBrightness") var isReduceBrightness = false
        @AppStorage("ABReduceBrightnessLevel") var reduceBrightnessLevel = 0.2
        var body: some View {
            List {
                Section {
                    Toggle("限制最小字体大小", isOn: $isWebMinFontSizeStricted)
                    VStack {
                        Slider(value: $webMinFontSize, in: 10...50, step: 1) {
                            Text("字体大小")
                        }
                        Text(String(format: "%.0f", webMinFontSize))
                    }
                    .disabled(!isWebMinFontSizeStricted)
                }
                Section {
                    Toggle("降低亮度", isOn: $isReduceBrightness)
                    VStack {
                        Slider(value: $reduceBrightnessLevel, in: 0.0...0.8, step: 0.05) {
                            Text("降低亮度")
                        }
                        Text(String(format: "%.2f", reduceBrightnessLevel))
                    }
                    .disabled(!isReduceBrightness)
                } footer: {
                    Text("屏幕右上方的时间不会被降低亮度")
                }
            }
            .navigationTitle("显示与亮度")
        }
    }
    struct BrowsingEngineSettingsView: View {
        @AppStorage("isUseOldWebView") var isUseOldWebView = false
        @AppStorage("RequestDesktopWeb") var requestDesktopWeb = false
        @AppStorage("UseBackforwardGesture") var useBackforwardGesture = true
        @AppStorage("KeepDigitalTime") var keepDigitalTime = false
        @AppStorage("HideDigitalTime") var hideDigitalTime = false
        @AppStorage("ShowFastExitButton") var showFastExitButton = false
        @AppStorage("AlwaysReloadWebPageAfterCrash") var alwaysReloadWebPageAfterCrash = false
        @AppStorage("PreloadSearchContent") var preloadSearchContent = true
        @AppStorage("ForceApplyDarkMode") var forceApplyDarkMode = false
        @AppStorage("LBIsAutoEnterReader") var isAutoEnterReader = true
        var body: some View {
            List {
                Section {
                    Toggle("使用旧版浏览引擎", isOn: $isUseOldWebView)
                }
                if !isUseOldWebView {
                    Section {
                        Toggle(isOn: $requestDesktopWeb) {
                            HStack {
                                Image(systemName: "desktopcomputer")
                                    .foregroundStyle(Color.blue.gradient)
                                Text("请求桌面网站")
                            }
                        }
                        Toggle(isOn: $useBackforwardGesture) {
                            HStack {
                                Image(systemName: "hand.draw")
                                    .foregroundStyle(Color.purple.gradient)
                                Text("使用手势返回上一页")
                            }
                        }
                        Toggle(isOn: $hideDigitalTime) {
                            HStack {
                                Image(systemName: "clock.badge.xmark")
                                    .foregroundStyle(Color.blue.gradient)
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
                        .onChange(of: keepDigitalTime) { _ in
                            if keepDigitalTime {
                                hideDigitalTime = false
                            }
                        }
                        Toggle(isOn: $showFastExitButton) {
                            HStack {
                                Image(systemName: "escape")
                                    .foregroundStyle(Color.red.gradient)
                                Text("显示“快速退出”按钮")
                            }
                        }
                        Toggle(isOn: $alwaysReloadWebPageAfterCrash) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundStyle(Color.blue.gradient)
                                Text("网页崩溃后总是自动重新载入")
                            }
                        }
                        if #available(watchOS 10, *) {
                            Toggle(isOn: $preloadSearchContent) {
                                HStack {
                                    Image(systemName: "sparkle.magnifyingglass")
                                        .foregroundStyle(Color.orange.gradient)
                                    Text("预载入搜索内容")
                                }
                            }
                        }
                        Toggle(isOn: $forceApplyDarkMode) {
                            HStack {
                                Image(systemName: "rectangle.inset.filled")
                                    .foregroundStyle(Color.gray.gradient)
                                Text("强制深色模式")
                            }
                        }
                    }
                } else {
                    Section {
                        Toggle(isOn: $isAutoEnterReader) {
                            HStack {
                                Image(systemName: "doc.plaintext")
                                    .foregroundStyle(Color.blue.gradient)
                                Text("可用时自动进入阅读器")
                            }
                        }
                    }
                }
            }
            .navigationTitle("浏览引擎")
        }
    }
    struct HomeScreenSettingsView: View {
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { ControlSettingsView() }, label: {
                        Label("组件", systemImage: "rectangle.grid.1x2")
                    })
                    if #available(watchOS 10, *) {
                        NavigationLink(destination: { ToolbarSettingsView() }, label: {
                            Label("工具栏", systemImage: "circle.dashed")
                        })
                    }
                }
            }
            .navigationTitle("主屏幕")
        }
        
        struct ControlSettingsView: View {
            @State var homeScreenSorts = [HomeScreenControlType]()
            @State var isAddControlPresented = false
            var body: some View {
                List {
                    Section {
                        if !homeScreenSorts.isEmpty {
                            ForEach(0..<homeScreenSorts.count, id: \.self) { i in
                                switch homeScreenSorts[i] {
                                case .searchField:
                                    Label("搜索输入框", systemImage: "character.cursor.ibeam")
                                case .searchButton:
                                    Label("搜索按钮", systemImage: "magnifyingglass")
                                case .spacer:
                                    Label("间隔", systemImage: "square.dashed")
                                        .swipeActions {
                                            Button(role: .destructive, action: {
                                                homeScreenSorts.remove(at: i)
                                                savePreferences()
                                            }, label: {
                                                Image(systemName: "xmark.bin.fill")
                                            })
                                        }
                                case .pinnedBookmarks:
                                    Label("固定的书签", systemImage: "pin.fill")
                                case .text(let text):
                                    TextFieldLink(label: {
                                        VStack(alignment: .leading) {
                                            Text("自定义文本")
                                                .font(.system(size: 13))
                                                .foregroundStyle(Color.gray)
                                            Text(text)
                                            Text("轻触以编辑")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.gray)
                                        }
                                    }, onSubmit: { str in
                                        homeScreenSorts[i] = .text(str)
                                        savePreferences()
                                    })
                                    .swipeActions {
                                        Button(role: .destructive, action: {
                                            homeScreenSorts.remove(at: i)
                                            savePreferences()
                                        }, label: {
                                            Image(systemName: "xmark.bin.fill")
                                        })
                                    }
                                case .navigationLink(let navigation):
                                    VStack(alignment: .leading) {
                                        Text("导航到")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.gray)
                                        switch navigation {
                                        case .bookmark:
                                            Label("Home.bookmarks", systemImage: "bookmark")
                                        case .history:
                                            Label("Home.history", systemImage: "clock")
                                        case .webarchive:
                                            Label("网页归档", systemImage: "archivebox")
                                        case .musicPlaylist:
                                            Label("播放列表", systemImage: "music.note.list")
                                        case .localMedia:
                                            Label("本地媒体", systemImage: "play.square.stack")
                                        case .userscript:
                                            Label("用户脚本", systemImage: "applescript")
                                        case .chores:
                                            Label("杂项", systemImage: "square.on.square")
                                        case .feedbackAssistant:
                                            Label("反馈助理", systemImage: "exclamationmark.bubble")
                                        case .tips:
                                            Label("提示", systemImage: "lightbulb")
                                        case .settings:
                                            Label("Home.settings", systemImage: "gear")
                                        }
                                    }
                                }
                            }
                            .onMove { source, destination in
                                homeScreenSorts.move(fromOffsets: source, toOffset: destination)
                                savePreferences()
                            }
                        }
                    } header: {
                        Text("拖动以重新排序")
                    } footer: {
                        Text("功能不可用时，项目可能仍然不会在主屏幕的对应位置显示。")
                    }
                }
                .navigationTitle("组件")
                .sheet(isPresented: $isAddControlPresented) {
                    AddControlView { newControl in
                        homeScreenSorts.append(newControl)
                        savePreferences()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            isAddControlPresented = true
                        }, label: {
                            Image(systemName: "plus")
                        })
                    }
                }
                .onAppear {
                    if let currentPref = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/HomeScreen.drkdatah", encoding: .utf8),
                       let data = getJsonData([HomeScreenControlType].self, from: currentPref) {
                        homeScreenSorts = data
                    } else {
                        homeScreenSorts = HomeScreenControlType.defaultScreen
                    }
                }
            }
            
            func savePreferences() {
                if let newPref = jsonString(from: homeScreenSorts) {
                    do {
                        try newPref.write(toFile: NSHomeDirectory() + "/Documents/HomeScreen.drkdatah", atomically: true, encoding: .utf8)
                    } catch {
                        globalErrorHandler(error)
                    }
                }
            }
            
            struct AddControlView: View {
                var completion: (HomeScreenControlType) -> Void
                @Environment(\.presentationMode) var presentationMode
                var body: some View {
                    NavigationStack {
                        List {
                            Section {
                                Button(action: {
                                    completion(.spacer)
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Label("间隔", systemImage: "square.dashed")
                                })
                                Button(action: {
                                    completion(.text(""))
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Label("自定义文本", systemImage: "textformat")
                                })
                            }
                        }
                        .navigationTitle("添加控件")
                    }
                }
            }
        }
        @available(watchOS 10.0, *)
        struct ToolbarSettingsView: View {
            @Environment(\.presentationMode) var presentationMode
            @State var currentToolbar: HomeScreenToolbar?
            @State var toolChanging = HomeScreenControlType.spacer
            @State var toolChangingPosition = HomeScreenToolbarPosition.topLeading
            @State var isChangeToolPresented = false
            var body: some View {
                List {
                    Section {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Label("返回", systemImage: "chevron.backward")
                        })
                    }
                }
                .navigationTitle("工具栏")
                .navigationBarBackButtonHidden()
                .sheet(isPresented: $isChangeToolPresented) {
                    ChangeToolView(item: toolChanging) { newControl in
                        switch toolChangingPosition {
                        case .topLeading:
                            currentToolbar?.topLeading = newControl
                        case .topTrailing:
                            currentToolbar?.topTrailing = newControl
                        case .bottomLeading:
                            currentToolbar?.bottomLeading = newControl
                        case .bottomCenter:
                            currentToolbar?.bottomCenter = newControl
                        case .bottomTrailing:
                            currentToolbar?.bottomTrailing = newControl
                        }
                        savePreferences()
                    }
                }
                .toolbar {
                    if let currentToolbar {
                        getFullToolbar(by: currentToolbar, with: .preference) { type, position, _ in
                            toolChanging = type
                            toolChangingPosition = position
                            isChangeToolPresented = true
                        }
                    }
                }
                .onAppear {
                    if let currentPref = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/MainToolbar.drkdatam", encoding: .utf8),
                       let data = getJsonData(HomeScreenToolbar.self, from: currentPref) {
                        currentToolbar = data
                    } else {
                        currentToolbar = HomeScreenToolbar.default
                    }
                }
            }
            
            func savePreferences() {
                if let currentToolbar, let newPref = jsonString(from: currentToolbar) {
                    do {
                        try newPref.write(toFile: NSHomeDirectory() + "/Documents/MainToolbar.drkdatam", atomically: true, encoding: .utf8)
                    } catch {
                        globalErrorHandler(error)
                    }
                }
            }
            
            struct ChangeToolView: View {
                var item: HomeScreenControlType
                var completion: (HomeScreenControlType) -> Void
                @Environment(\.presentationMode) var presentationMode
                var body: some View {
                    NavigationStack {
                        List {
                            Section {
                                Button(action: {
                                    completion(.spacer)
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Label("无", systemImage: "circle.dashed")
                                })
                                Button(action: {
                                    completion(.searchButton)
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Label("搜索", systemImage: "magnifyingglass")
                                })
                                Button(action: {
                                    completion(.navigationLink(.bookmark))
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text("导航到")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.gray)
                                        Label("Home.bookmarks", systemImage: "bookmark")
                                    }
                                })
                                Button(action: {
                                    completion(.navigationLink(.history))
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text("导航到")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.gray)
                                        Label("Home.history", systemImage: "clock")
                                    }
                                })
                                Button(action: {
                                    completion(.navigationLink(.webarchive))
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text("导航到")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.gray)
                                        Label("网页归档", systemImage: "archivebox")
                                    }
                                })
                                Button(action: {
                                    completion(.navigationLink(.localMedia))
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text("导航到")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.gray)
                                        Label("本地媒体", systemImage: "play.square.stack")
                                    }
                                })
                                Button(action: {
                                    completion(.navigationLink(.userscript))
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text("导航到")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.gray)
                                        Label("用户脚本", systemImage: "applescript")
                                    }
                                })
                                Button(action: {
                                    completion(.navigationLink(.feedbackAssistant))
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text("导航到")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.gray)
                                        Label("反馈助理", systemImage: "exclamationmark.bubble")
                                    }
                                })
                                Button(action: {
                                    completion(.navigationLink(.tips))
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text("导航到")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.gray)
                                        Label("提示", systemImage: "lightbulb")
                                    }
                                })
                                Button(action: {
                                    completion(.navigationLink(.settings))
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    VStack(alignment: .leading) {
                                        Text("导航到")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.gray)
                                        Label("Home.settings", systemImage: "gear")
                                    }
                                })
                            }
                        }
                        .navigationTitle("更改工具")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
        }
    }
    struct SearchSettingsView: View {
        @AppStorage("WebSearch") var webSearch = "必应"
        @AppStorage("IsLongPressAlternativeSearch") var isLongPressAlternativeSearch = false
        @AppStorage("AlternativeSearch") var alternativeSearch = "必应"
        @AppStorage("AllowCookies") var allowCookies = true
        @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
        @State var customSearchEngineList = [String]()
        let engineTitle = [
            "必应": String(localized: "Search.bing"),
            "百度": String(localized: "Search.baidu"),
            "谷歌": String(localized: "Search.google"),
            "搜狗": String(localized: "Search.sougou")
        ]
        var body: some View {
            List {
                Section {
                    Picker(selection: $webSearch, label: Text(isSearchEngineShortcutEnabled ? "默认搜索引擎" : "Settings.search.engine")) {
                        ForEach(EngineNames.allCases, id: \.self) { engineNames in
                            Text(engineTitle[engineNames.rawValue]!).tag(engineNames.rawValue)
                        }
                        if customSearchEngineList.count != 0 {
                            ForEach(0..<customSearchEngineList.count, id: \.self) { i in
                                Text(
                                    customSearchEngineList[i]
                                        .replacingOccurrences(of: "%lld", with: String(localized: "Settings.search.customize.search-content"))
                                )
                                .tag(customSearchEngineList[i])
                            }
                        }
                    }
                    Toggle("长按搜索按钮使用次要搜索引擎", isOn: $isLongPressAlternativeSearch)
                    if isLongPressAlternativeSearch {
                        Picker(selection: $alternativeSearch, label: Text("次要搜索引擎")) {
                            ForEach(EngineNames.allCases, id: \.self) { engineNames in
                                Text(engineTitle[engineNames.rawValue]!).tag(engineNames.rawValue)
                            }
                            if customSearchEngineList.count != 0 {
                                ForEach(0..<customSearchEngineList.count, id: \.self) { i in
                                    Text(
                                        customSearchEngineList[i]
                                            .replacingOccurrences(of: "%lld", with: String(localized: "Settings.search.customize.search-content"))
                                    )
                                    .tag(customSearchEngineList[i])
                                }
                            }
                        }
                    }
                    if webSearch == "谷歌" && !allowCookies {
                        NavigationLink(destination: { PrivacySettingsView() }, label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("可能需要允许 Cookies 以使“谷歌”搜索引擎正常工作")
                                        .font(.system(size: 14))
                                    Text("前往“隐私与安全性”设置")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.forward")
                                    .foregroundColor(.gray)
                            }
                        })
                    }
                }
                Section {
                    NavigationLink(destination: { CustomSearchEngineSettingsView() }, label: {
                        Text("管理自定搜索引擎...")
                    })
                    NavigationLink(destination: { SearchEngineShortcutSettingsView() }, label: {
                        Text("搜索引擎快捷方式...")
                    })
                }
            }
            .navigationTitle("搜索")
            .onAppear {
                customSearchEngineList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
            }
        }
        
        struct CustomSearchEngineSettingsView: View {
            @State var isAddCustomSEPresented = false
            @State var customSearchEngineList = [String]()
            var body: some View {
                Group {
                    if #available(watchOS 10, *) {
                        MainView(isAddCustomSEPresented: $isAddCustomSEPresented, customSearchEngineList: $customSearchEngineList)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button(action: {
                                        isAddCustomSEPresented = true
                                    }, label: {
                                        Image(systemName: "plus")
                                    })
                                }
                            }
                    } else {
                        MainView(isAddCustomSEPresented: $isAddCustomSEPresented, customSearchEngineList: $customSearchEngineList)
                    }
                }
                .sheet(isPresented: $isAddCustomSEPresented, onDismiss: {
                    customSearchEngineList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
                }, content: { AddCustomSearchEngineView(isAddCustomSEPresented: $isAddCustomSEPresented) })
            }
            
            struct MainView: View {
                @Binding var isAddCustomSEPresented: Bool
                @Binding var customSearchEngineList: [String]
                var body: some View {
                    List {
                        if #unavailable(watchOS 10) {
                            Section {
                                Button(action: {
                                    isAddCustomSEPresented = true
                                }, label: {
                                    Label("Settings.search.customize.add", systemImage: "plus")
                                })
                            }
                        }
                        if customSearchEngineList.count != 0 {
                            ForEach(0..<customSearchEngineList.count, id: \.self) { i in
                                Text(
                                    customSearchEngineList[i]
                                        .replacingOccurrences(of: "%lld", with: String(localized: "Settings.search.customize.search-content"))
                                )
                                    .swipeActions {
                                        Button(role: .destructive, action: {
                                            customSearchEngineList.remove(at: i)
                                            UserDefaults.standard.set(customSearchEngineList, forKey: "CustomSearchEngineList")
                                        }, label: {
                                            Image(systemName: "xmark.bin.fill")
                                        })
                                    }
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Settings.search.customize.nothing")
                                Spacer()
                            }
                        }
                    }
                    .onAppear {
                        customSearchEngineList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
                    }
                }
            }
            
            struct AddCustomSearchEngineView: View {
                @Binding var isAddCustomSEPresented: Bool
                @State var customUrlInput = ""
                var body: some View {
                    NavigationView {
                        List {
                            Section {
                                TextField("Settings.search.customize.link", text: $customUrlInput)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } footer: {
                                Text("Settings.search.customize.link.discription")
                            }
                            Section {
                                NavigationLink(destination: { Step2(customUrlInput: customUrlInput, isAddCustomSEPresented: $isAddCustomSEPresented) }, label: {
                                    Text("Settings.search.customize.next")
                                })
                                .disabled(customUrlInput.isEmpty)
                            }
                        }
                        .navigationTitle("Settings.search.customize.link.title")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }
                
                struct Step2: View {
                    var customUrlInput: String
                    @Binding var isAddCustomSEPresented: Bool
                    @State var charas = [Character]()
                    @State var cursorPosition = 0.0
                    var body: some View {
                        VStack {
                            ScrollViewReader { p in
                                ScrollView(.horizontal) {
                                    HStack(spacing: 0) {
                                        if charas.count != 0 {
                                            ForEach(0..<charas.count, id: \.self) { i in
                                                Text(String(charas[i]))
                                                if i == Int(cursorPosition) {
                                                    Color.accentColor
                                                        .frame(width: 3, height: 26)
                                                        .cornerRadius(3)
                                                        .id("cur")
                                                        .onAppear {
                                                            p.scrollTo("cur")
                                                        }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .focusable()
                            .digitalCrownRotation(
                                $cursorPosition,
                                from: 0,
                                through: Double(charas.count - 1),
                                by: 1,
                                sensitivity: .medium,
                                isHapticFeedbackEnabled: true
                            )
                            Spacer()
                                .frame(height: 15)
                            Text("Settings.search.customize.cursor")
                                .font(.footnote)
                                .opacity(0.65)
                            Button(action: {
                                var combinedText = ""
                                for i in 0..<charas.count {
                                    combinedText += String(charas[i])
                                    if i == Int(cursorPosition) {
                                        combinedText += "%lld"
                                    }
                                }
                                if !combinedText.hasPrefix("http://") && !combinedText.hasPrefix("https://") {
                                    combinedText = "http://" + combinedText
                                }
                                var newLists = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
                                newLists.append(combinedText)
                                UserDefaults.standard.set(newLists, forKey: "CustomSearchEngineList")
                                isAddCustomSEPresented = false
                            }, label: {
                                Label("Settings.search.customize.done", systemImage: "checkmark")
                            })
                        }
                        .navigationTitle("Settings.search.customize.cursor.title")
                        .navigationBarTitleDisplayMode(.inline)
                        .onAppear {
                            for c in customUrlInput {
                                charas.append(c)
                            }
                            cursorPosition = Double(charas.count - 1)
                        }
                    }
                }
            }
        }
        struct SearchEngineShortcutSettingsView: View {
            @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
            var body: some View {
                List {
                    Section {
                        Toggle(isOn: $isSearchEngineShortcutEnabled, label: {
                            Text("Settings.search.shortcut.enable")
                        })
                    } footer: {
                        Text("Settings.search.shortcut.discription")
                    }
                    if isSearchEngineShortcutEnabled {
                        Section {
                            HStack {
                                Text("Search.bing")
                                Spacer()
                                Text("bing")
                                    .font(.system(size: 15).monospaced())
                            }
                            HStack {
                                Text("Search.baidu")
                                Spacer()
                                Text("baidu")
                                    .font(.system(size: 15).monospaced())
                            }
                            HStack {
                                Text("Search.google")
                                Spacer()
                                Text("google")
                                    .font(.system(size: 15).monospaced())
                            }
                            HStack {
                                Text("Search.sougou")
                                Spacer()
                                Text("sogou")
                                    .font(.system(size: 15).monospaced())
                            }
                        }
                    }
                }
                .navigationTitle("Settings.search.shorcut")
            }
        }
    }
    
    struct PasswordSettingsView: View {
        @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
        @AppStorage("UsePasscodeForLockDarockBrowser") var usePasscodeForLockDarockBrowser = false
        @AppStorage("UsePasscodeForLockBookmarks") var usePasscodeForLockBookmarks = false
        @AppStorage("UsePasscodeForLockHistories") var usePasscodeForLockHistories = false
        @AppStorage("UsePasscodeForLocalAudios") var usePasscodeForLocalAudios = false
        @AppStorage("UsePasscodeForLocalImages") var usePasscodeForLocalImages = false
        @AppStorage("UsePasscodeForLocalVideos") var usePasscodeForLocalVideos = false
        @AppStorage("UsePasscodeForWebArchives") var usePasscodeForWebArchives = false
        @AppStorage("UsePasscodeForLocalBooks") var usePasscodeForLocalBooks = false
        @AppStorage("IsSecurityDelayEnabled") var isSecurityDelayEnabled = false
        @AppStorage("LabTabBrowsingEnabled") var labTabBrowsingEnabled = false
        @AppStorage("UsePasscodeForBrowsingTab") var usePasscodeForBrowsingTab = false
        @State var isSetPasswordInputPresented = false
        @State var isSetPasswordConfirmInputPresented = false
        @State var isClosePasswordPresented = false
        @State var isChangePasswordPresented = false
        @State var passcodeInputTmp = ""
        @State var passcodeInputTmp2 = ""
        @State var isClosePasscodeDelayPresented = false
        @State var isChangePasscodeDelayPresented = false
        var body: some View {
            List {
                if !userPasscodeEncrypted.isEmpty {
                    Section {
                        Toggle("锁定暗礁浏览器", isOn: $usePasscodeForLockDarockBrowser)
                        Toggle("锁定书签", isOn: $usePasscodeForLockBookmarks)
                        Toggle("锁定历史记录", isOn: $usePasscodeForLockHistories)
                        Toggle("锁定本地音频", isOn: $usePasscodeForLocalAudios)
                        Toggle("锁定本地图片", isOn: $usePasscodeForLocalImages)
                        Toggle("锁定本地视频", isOn: $usePasscodeForLocalVideos)
                        Toggle("锁定网页归档", isOn: $usePasscodeForWebArchives)
                        Toggle("锁定本地图书", isOn: $usePasscodeForLocalBooks)
                        if labTabBrowsingEnabled {
                            Toggle("锁定标签页", isOn: $usePasscodeForBrowsingTab)
                        }
                    } header: {
                        Text("将密码用于：")
                    }
                }
                Section {
                    if !userPasscodeEncrypted.isEmpty {
                        Button(action: {
                            if checkSecurityDelay() {
                                isClosePasswordPresented = true
                            } else {
                                isClosePasscodeDelayPresented = true
                            }
                        }, label: {
                            Text("关闭密码")
                        })
                        .sheet(isPresented: $isClosePasswordPresented) {
                            PasswordInputView(text: $passcodeInputTmp, placeholder: "输入当前密码") { pwd in
                                if pwd.md5 == userPasscodeEncrypted {
                                    userPasscodeEncrypted = ""
                                    tipWithText("密码已关闭", symbol: "checkmark.circle.fill")
                                } else {
                                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                                }
                                passcodeInputTmp = ""
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                        Button(action: {
                            if checkSecurityDelay() {
                                isChangePasswordPresented = true
                            } else {
                                isChangePasscodeDelayPresented = true
                            }
                        }, label: {
                            Text("更改密码")
                        })
                        .sheet(isPresented: $isChangePasswordPresented) {
                            PasswordInputView(text: $passcodeInputTmp, placeholder: "输入当前密码") { pwd in
                                if pwd.md5 == userPasscodeEncrypted {
                                    isSetPasswordInputPresented = true
                                } else {
                                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                                }
                                passcodeInputTmp = ""
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                        .sheet(isPresented: $isSetPasswordInputPresented) {
                            PasswordInputView(text: $passcodeInputTmp, placeholder: "输入新密码") { pwd in
                                passcodeInputTmp = pwd
                                isSetPasswordConfirmInputPresented = true
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                        .sheet(isPresented: $isSetPasswordConfirmInputPresented) {
                            PasswordInputView(text: $passcodeInputTmp2, placeholder: "确认密码") { pwd in
                                if passcodeInputTmp == pwd {
                                    userPasscodeEncrypted = pwd.md5
                                    passcodeInputTmp = ""
                                    tipWithText("密码已设置", symbol: "checkmark.circle.fill")
                                } else {
                                    isSetPasswordConfirmInputPresented = true
                                }
                                passcodeInputTmp2 = ""
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                    } else {
                        Button(action: {
                            isSetPasswordInputPresented = true
                        }, label: {
                            Text("开启密码")
                        })
                        .sheet(isPresented: $isSetPasswordInputPresented) {
                            PasswordInputView(text: $passcodeInputTmp, placeholder: "输入新密码") { pwd in
                                passcodeInputTmp = pwd
                                isSetPasswordConfirmInputPresented = true
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                        .sheet(isPresented: $isSetPasswordConfirmInputPresented) {
                            PasswordInputView(text: $passcodeInputTmp2, placeholder: "确认密码") { pwd in
                                if passcodeInputTmp == pwd {
                                    userPasscodeEncrypted = pwd.md5
                                    passcodeInputTmp = ""
                                    tipWithText("密码已设置", symbol: "checkmark.circle.fill")
                                } else {
                                    isSetPasswordConfirmInputPresented = true
                                }
                                passcodeInputTmp2 = ""
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                    }
                }
                if !userPasscodeEncrypted.isEmpty {
                    Section {
                        NavigationLink(destination: { SecurityDelayView() }, label: {
                            HStack {
                                Text("安全延时")
                                Spacer()
                                Text(isSecurityDelayEnabled ? "已启用" : "未启用")
                                    .foregroundColor(.gray)
                            }
                        })
                    }
                }
            }
            .navigationTitle("密码")
            .sheet(isPresented: $isClosePasscodeDelayPresented, content: { SecurityDelayRequiredView(reasonTitle: "需要安全延时以关闭密码") })
            .sheet(isPresented: $isChangePasscodeDelayPresented, content: { SecurityDelayRequiredView(reasonTitle: "需要安全延时以更改密码") })
        }
        
        struct SecurityDelayView: View {
            @AppStorage("IsSecurityDelayEnabled") var isSecurityDelayEnabled = false
            @AppStorage("SecurityDelayRequirement") var securityDelayRequirement = "always"
            @AppStorage("IsFirstShowSecurityDelay") var isFirstShowSecurityDelay = true
            @State var isDebugDelayPresented = false
            @State var isTurnOffDelayPresented = false
            @State var isChangeToByLocationPresented = false
            @State var isAddLocationDelayPresented = false
            @State var isLocationPermissionPresented = false
            @State var addLocationCheckTimer: Timer?
            @State var trustedLocations = [[Double]]()
            var body: some View {
                List {
                    Section {
                        Toggle("启用安全延时", isOn: $isSecurityDelayEnabled)
                            .onChange(of: isSecurityDelayEnabled) { value in
                                if !value {
                                    isSecurityDelayEnabled = true
                                    if !checkSecurityDelay() {
                                        isTurnOffDelayPresented = true
                                    } else {
                                        isSecurityDelayEnabled = false
                                    }
                                }
                                isFirstShowSecurityDelay = false
                            }
                        if isFirstShowSecurityDelay {
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.yellow)
                                Text("一旦开启安全延时，您将需要等待一小时才能够关闭。")
                                    .font(.system(size: 15))
                            }
                        }
                    } footer: {
                        Text("安全延时在您进行更改密码等敏感操作时要求额外的等待时间，以保护您的隐私安全。")
                    }
                    if isSecurityDelayEnabled {
                        Section {
                            Button(action: {
                                if securityDelayRequirement != "byLocation" {
                                    if CLLocationManager.locationServicesEnabled() {
                                        if !checkSecurityDelay() {
                                            isChangeToByLocationPresented = true
                                        } else {
                                            securityDelayRequirement = "byLocation"
                                        }
                                    } else {
                                        isLocationPermissionPresented = true
                                    }
                                }
                            }, label: {
                                HStack {
                                    Text("基于位置")
                                    Spacer()
                                    if securityDelayRequirement == "byLocation" {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            })
                            Button(action: {
                                if securityDelayRequirement != "always" {
                                    securityDelayRequirement = "always"
                                }
                            }, label: {
                                HStack {
                                    Text("总是")
                                    Spacer()
                                    if securityDelayRequirement == "always" {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            })
                        } header: {
                            Text("要求安全延时")
                        }
                        if securityDelayRequirement == "byLocation" {
                            Section {
                                if !trustedLocations.isEmpty {
                                    ForEach(0..<trustedLocations.count, id: \.self) { i in
                                        Text("(\(String(format: "%.2f", trustedLocations[i][0])), \(String(format: "%.2f", trustedLocations[i][1])))")
                                            .swipeActions {
                                                Button(role: .destructive, action: {
                                                    trustedLocations.remove(at: i)
                                                    UserDefaults.standard.set(trustedLocations, forKey: "SecurityDelayTrustedLocations")
                                                }, label: {
                                                    Image(systemName: "xmark.bin.fill")
                                                })
                                            }
                                    }
                                }
                                if addLocationCheckTimer == nil {
                                    Button(action: {
                                        if checkSecurityDelay() {
                                            LocationManager.shared.manager.startUpdatingLocation()
                                            addLocationCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                                                if let location = LocationManager.shared.location {
                                                    trustedLocations.append([location.latitude, location.longitude])
                                                    UserDefaults.standard.set(trustedLocations, forKey: "SecurityDelayTrustedLocations")
                                                    LocationManager.shared.location = nil
                                                    addLocationCheckTimer?.invalidate()
                                                    addLocationCheckTimer = nil
                                                }
                                            }
                                        } else {
                                            isAddLocationDelayPresented = true
                                        }
                                    }, label: {
                                        Text("将当前位置添加为受信任位置")
                                    })
                                } else {
                                    Text("正在获取位置...")
                                }
                            } header: {
                                Text("受信任的位置")
                            } footer: {
                                Text("在受信任的位置时，暗礁浏览器将不会要求安全延时。")
                            }
                        }
                    }
                }
                .navigationTitle("安全延时")
                .sheet(isPresented: $isTurnOffDelayPresented, content: { SecurityDelayRequiredView(reasonTitle: "需要安全延时以关闭安全延时") })
                .sheet(isPresented: $isChangeToByLocationPresented, content: { SecurityDelayRequiredView(reasonTitle: "需要安全延时以切换为“基于位置”") })
                .sheet(isPresented: $isAddLocationDelayPresented, content: { SecurityDelayRequiredView(reasonTitle: "需要安全延时以添加受信任位置") })
                .sheet(isPresented: $isLocationPermissionPresented, content: { LocationPremissionView() })
                .onAppear {
                    trustedLocations = (UserDefaults.standard.array(forKey: "SecurityDelayTrustedLocations") as? [[Double]]) ?? [[Double]]()
                }
                .onDisappear {
                    isFirstShowSecurityDelay = false
                }
            }
            
            struct LocationPremissionView: View {
                var body: some View {
                    ScrollView {
                        VStack {
                            Image(systemName: "location.square.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            Text("需要定位服务权限以使用基于位置的安全延时")
                                .font(.system(size: 22))
                                .multilineTextAlignment(.center)
                                .padding(.vertical)
                            HStack {
                                Image(systemName: "hand.raised.square.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.blue)
                                Text("所有定位信息仅保存在本地，不会与包括 Darock 在内的任何第三方共享。")
                                Spacer()
                            }
                            Button(action: {
                                CLLocationManager().requestWhenInUseAuthorization()
                            }, label: {
                                Text("使用定位服务")
                            })
                            .tint(.blue)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.roundedRectangle(radius: 14))
                        }
                    }
                    .navigationTitle("定位服务权限")
                }
            }
        }
    }
    struct PrivacySettingsView: View {
        var body: some View {
            List {
                Section {
                    SettingsSectionInfoView(title: "隐私与安全性",
                                            description: "暗礁浏览器致力于保护您的隐私，Darock 不会未经同意收集任何信息。",
                                            image: "hand.raised.fill",
                                            color: .blue)
                }
                Section {
                    NavigationLink(destination: { CookieView() },
                                   label: { SettingItemLabel(title: "Cookie", image: "doc.fill", color: .gray) })
                    NavigationLink(destination: { WebsiteSecurityView() },
                                   label: { SettingItemLabel(title: "站点安全", image: "macwindow.on.rectangle", color: .gray) })
                }
                Section {
                    NavigationLink(destination: { DeveloperModeView() }, label: {
                        SettingItemLabel(title: "开发者模式", image: "hammer.fill", color: .gray, symbolFontSize: 10)
                    })
                } header: {
                    Text("安全性")
                }
            }
            .navigationTitle("隐私与安全性")
        }
        
        struct CookieView: View {
            @AppStorage("AllowCookies") var allowCookies = true
            var body: some View {
                List {
                    Section {
                        Toggle(isOn: $allowCookies) {
                            VStack(alignment: .leading) {
                                Text("Settings.cookies.allow")
                                Text("Settings.cookies.description")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                            }
                        }
                        HStack(alignment: .center) {
                            Image(systemName: "minus.diamond")
                            Text("Settings.cookies.limitation")
                        }
                    }
                }
                .navigationTitle("Cookie")
            }
        }
        struct WebsiteSecurityView: View {
            @AppStorage("IsShowFraudulentWebsiteWarning") var isShowFraudulentWebsiteWarning = true
            @AppStorage("WKJavaScriptEnabled") var isJavaScriptEnabled = true
            var body: some View {
                List {
                    Section {
                        Toggle("显示欺诈性网站警告", isOn: $isShowFraudulentWebsiteWarning)
                        Toggle("JavaScript", isOn: $isJavaScriptEnabled)
                    }
                }
                .navigationTitle("站点安全")
            }
        }
        
        struct DeveloperModeView: View {
            @AppStorage("IsDeveloperModeEnabled") var isDeveloperModeEnabled = false
            var body: some View {
                List {
                    Section {
                        Toggle("开发者模式", isOn: $isDeveloperModeEnabled)
                    } footer: {
                        Text("如果你正在进行网页开发，开发者模式允许你使用开发所需的功能。")
                    }
                }
                .navigationTitle("开发者模式")
            }
        }
    }
    
    struct DeveloperSettingsView: View {
        @AppStorage("CustomUserAgent") var customUserAgent = ""
        @AppStorage("DTIsAllowWebInspector") var isAllowWebInspector = false
        var body: some View {
            List {
                Section {
                    Picker("User Agent", selection: $customUserAgent) {
                        Section {
                            Text("默认")
                                .tag("")
                        }
                        Section {
                            Text("Safari 18.0")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15")
                            Text("Safari - iOS 17.4 - iPhone")
                                .tag(
                                    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
                                )
                            Text("Safari - iPadOS 17.4 - iPad mini")
                                .tag(
                                    "Mozilla/5.0 (iPad; CPU OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
                                )
                            Text("Safari - iPadOS 17.4 - iPad")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15")
                        }
                        Section {
                            Text("Microsoft Edge - macOS")
                                .tag(
                                    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
                                )
                            Text("Microsoft Edge - Windows")
                                .tag(
                                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
                                )
                        }
                        Section {
                            Text("Google Chrome - macOS")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                            Text("Google Chrome - Windows")
                                .tag("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                        }
                        Section {
                            Text("Firefox - macOS")
                                .tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0")
                            Text("Firefox - Windows")
                                .tag("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0")
                        }
                    }
                } footer: {
                    Text("除非设置为默认，此处设置的值将覆盖\(Text("浏览引擎->请求桌面网站").bold().foregroundColor(.blue))设置")
                }
                Section {
                    Toggle("网页检查器", isOn: $isAllowWebInspector)
                } footer: {
                    Text("若要使用网页检查器，通过线缆将此 Apple Watch 配对的 iPhone 与 Mac 连接，在 Safari 的“开发”菜单中访问此 Apple Watch。你可以在 Safari 设置中的“高级”选项卡中打开开发菜单。")
                }
            }
            .navigationTitle("开发者")
        }
    }
    struct InternalDebuggingView: View {
        @Environment(\.openURL) private var openURL
        @AppStorage("SecurityDelayStartTime") var securityDelayStartTime = -1.0
        @AppStorage("TQCIsColorChangeButtonUnlocked") var isColorChangeButtonUnlocked = false
        @AppStorage("TQCIsColorChangeButtonEntered") var isColorChangeButtonEntered = false
        @State var isTestAppRemovalWarningPresented = false
        var body: some View {
            List {
                Section {
                    Button(action: {
                        tipWithText("\(String(isDebuggerAttached()))", symbol: "hammer.circle.fill")
                    }, label: {
                        Text("Present Debugger Attach Status")
                    })
                } header: {
                    Text("Debugger")
                }
                Section {
                    Button(action: {
                        print(NSHomeDirectory())
                    }, label: {
                        Text("Print NSHomeDirectory")
                    })
                } header: {
                    Text("LLDB")
                }
                Section {
                    Button(action: {
                        tipWithText("\(String(format: "%.2f", securityDelayStartTime))", symbol: "hammer.circle.fill")
                    }, label: {
                        Text("Present Start Time")
                    })
                    Button(action: {
                        tipWithText("\(String(checkSecurityDelay()))", symbol: "hammer.circle.fill")
                    }, label: {
                        Text("Present Check Status")
                    })
                } header: {
                    Text("Security Delay")
                }
                Section {
                    Button(action: {
                        tipWithText(String(getWebHistory().count), symbol: "hammer.circle.fill")
                    }, label: {
                        Text("Present History Count")
                    })
                } header: {
                    Text("Data & Cloud")
                }
                Section {
                    Button(action: {
                        do {
                            throw NSError(domain: "com.darock.DarockBrowser.TestError", code: 1)
                        } catch {
                            globalErrorHandler(error)
                        }
                    }, label: {
                        Text("Toggle an Internal Error")
                    })
                } header: {
                    Text("Error Handler")
                }
                Section {
                    Button(action: {
                        UserDefaults.standard.removeObject(forKey: "ShouldTipNewFeatures")
                        for i in 1...50 {
                            UserDefaults.standard.removeObject(forKey: "ShouldTipNewFeatures\(i)")
                        }
                    }, label: {
                        Text("Reset All What's New Screen State")
                    })
                    Button(action: {
                        isColorChangeButtonUnlocked = false
                        isColorChangeButtonEntered = false
                    }, label: {
                        Text("Reset TQCAccentColorHiddenButton")
                    })
                } header: {
                    Text("What's New Screen & TQC")
                }
                Section {
                    Button(role: .destructive, action: {
                        fatalError("Internal Debugging Crash")
                    }, label: {
                        Text("Crash This App through Swift fatalError")
                    })
                    Button(role: .destructive, action: {
                        let e = NSException(name: NSExceptionName.mallocException, reason: "Internal Debugging Exception", userInfo: ["Info": "Debug"])
                        e.raise()
                    }, label: {
                        Text("Crash This App through NSException")
                    })
                    Button(role: .destructive, action: {
                        isTestAppRemovalWarningPresented = true
                    }, label: {
                        HStack {
                            Text("Run App Removal Service")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .foregroundColor(.gray)
                        }
                    })
                } header: {
                    Text("Danger Zone")
                }
            }
            .navigationTitle("Debugging")
            .alert("Test Browser App Removal", isPresented: $isTestAppRemovalWarningPresented, actions: {
                Button(role: .cancel, action: {
                    
                }, label: {
                    Text("Cancel")
                        .bold()
                })
                Button(role: .destructive, action: {
                    UserDefaults.standard.removeObject(forKey: "*")
                    try! FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/*")
                    exit(0)
                }, label: {
                    Text("Continue")
                })
            }, message: {
                VStack {
                    Text("This will delete all Darock Browser app data.")
                    Text("All data will be lost!")
                }
            })
            .toolbar {
                if #available(watchOS 10.5, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            WKExtension.shared().openSystemURL(URL(string: "https://darock.top/internal/tap-to-radar/new?ProductName=Darock Browser")!)
                        }, label: {
                            Image(systemName: "ant.fill")
                        })
                    }
                }
            }
        }
        
        func isDebuggerAttached() -> Bool {
            var name = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
            var info = kinfo_proc()
            var infoSize = MemoryLayout<kinfo_proc>.stride
            
            let result = name.withUnsafeMutableBytes {
                sysctl($0.baseAddress!.assumingMemoryBound(to: Int32.self), 4, &info, &infoSize, nil, 0)
            }
            
            assert(result == 0, "sysctl failed")
            
            return (info.kp_proc.p_flag & P_TRACED) != 0
        }
    }
}

struct SecurityDelayRequiredView: View {
    var reasonTitle: LocalizedStringKey
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("SecurityDelayRequirement") var securityDelayRequirement = "always"
    @AppStorage("SecurityDelayStartTime") var securityDelayStartTime = -1.0
    @State var isCounterPresented = false
    @State var isNotificationPermissionGranted = false
    var body: some View {
        ScrollView {
            VStack {
                Image(systemName: "lock.badge.clock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                Text(reasonTitle)
                    .font(.system(size: 22))
                    .multilineTextAlignment(.center)
                Text(securityDelayRequirement == "always" ? "需要进行安全延时以执行此操作，因为安全延时已启用。" : "需要进行安全延时以执行此操作，因为安全延时已启用，且 Apple Watch 不在设定的允许位置。")
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                HStack {
                    Image(systemName: "lock.badge.clock.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                    Text("安全延时会进行一个小时。")
                    Spacer()
                }
                if isNotificationPermissionGranted {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                        Text("安全延时结束后您将收到通知。")
                        Spacer()
                    }
                }
                HStack {
                    Image(systemName: "applewatch")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                    Text("在安全延时期间您仍然可以使用暗礁浏览器。")
                    Spacer()
                }
                Button(action: {
                    securityDelayStartTime = Date.now.timeIntervalSince1970
                    isCounterPresented = true
                    let content = UNMutableNotificationContent()
                    content.title = ""
                    content.body = ""
                    content.sound = UNNotificationSound.default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
                    let request = UNNotificationRequest(identifier: "com.darock.WatchBrowser.securityDelay.notification", content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request) { _ in }
                }, label: {
                    Text("开始安全延时")
                })
                .tint(.blue)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 14))
            }
        }
        .navigationTitle("需要安全延时")
        .sheet(isPresented: $isCounterPresented, onDismiss: {
            presentationMode.wrappedValue.dismiss()
        }, content: { SecurityDelayCounterView() })
        .onAppear {
            if securityDelayStartTime > 0 {
                isCounterPresented = true
            }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                isNotificationPermissionGranted = granted
            }
        }
    }
}
struct SecurityDelayCounterView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("SecurityDelayStartTime") var securityDelayStartTime = -1.0
    @State var timeDiff = Time(minute: 0, second: 0)
    var body: some View {
        ScrollView {
            VStack {
                Image(systemName: "lock.badge.clock.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                Text("安全延时正在进行中")
                    .font(.system(size: 20))
                    .multilineTextAlignment(.center)
                Text("在安全延时结束后，您可以继续之前的操作")
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                HStack {
                    Text("剩余时间")
                    Spacer()
                    Text("\(timeDiff.minute < 10 ? "0" : "")\(timeDiff.minute):\(timeDiff.second < 10 ? "0" : "")\(timeDiff.second)")
                        .foregroundColor(.gray)
                }
                .padding()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("完成")
                })
                .tint(.blue)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 14))
            }
        }
        .onAppear {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.minute, .second], from: Date.now, to: Date(timeIntervalSince1970: securityDelayStartTime) + 1.hours)
            timeDiff = Time(minute: components.minute ?? 0, second: components.second ?? 0)
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                let components = calendar.dateComponents([.minute, .second], from: Date.now, to: Date(timeIntervalSince1970: securityDelayStartTime) + 1.hours)
                timeDiff = Time(minute: components.minute ?? 0, second: components.second ?? 0)
            }
        }
    }
    
    struct Time {
        var minute: Int
        var second: Int
    }
}

/// 检查安全延时是否已完成
/// - Returns: 是否已完成
func checkSecurityDelay() -> Bool {
    if !UserDefaults.standard.bool(forKey: "IsSecurityDelayEnabled") {
        return true
    }
    
    if let requirement = UserDefaults.standard.string(forKey: "SecurityDelayRequirement"),
       let trustedLocations = UserDefaults.standard.array(forKey: "SecurityDelayTrustedLocations") as? [[Double]],
       requirement == "byLocation" {
        LocationManager.shared.manager.startUpdatingLocation()
        if let location = LocationManager.shared.location {
            let currArg1f = Double(String(format: "%.2f", location.latitude))!
            let currArg2f = Double(String(format: "%.2f", location.longitude))!
            for trustedLocation in trustedLocations {
                let arg1f = Double(String(format: "%.2f", trustedLocation[0]))!
                let arg2f = Double(String(format: "%.2f", trustedLocation[1]))!
                if currArg1f == arg1f && currArg2f == arg2f {
                    return true
                }
            }
        }
    }
    
    let startTime = UserDefaults.standard.double(forKey: "SecurityDelayStartTime")
    let currentTime = Date.now.timeIntervalSince1970
    let targetTime = startTime + 3600
    let timeDiff = targetTime - currentTime
    if timeDiff <= 0 && timeDiff >= -1800 {
        return true
    } else if timeDiff < -1800 {
        UserDefaults.standard.set(-1.0, forKey: "SecurityDelayStartTime")
    }
    return false
}

final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    public var manager = CLLocationManager()
    public var location: CLLocationCoordinate2D?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        manager.stopUpdatingLocation()
        location = locValue
    }
}

enum HomeScreenControlType: Codable, Equatable {
    case searchField
    case searchButton
    case spacer
    case pinnedBookmarks
    case text(String)
    case navigationLink(HomeScreenNavigationType)
    
    static var defaultScreen: [Self] {
        [
            .searchField,
            .searchButton,
            .spacer,
            .navigationLink(.bookmark),
            .navigationLink(.history),
            .navigationLink(.webarchive),
            .navigationLink(.musicPlaylist),
            .navigationLink(.localMedia),
            .navigationLink(.userscript),
            .spacer,
            .pinnedBookmarks,
            .spacer,
            .navigationLink(.settings),
            .spacer,
            .navigationLink(.feedbackAssistant),
            .navigationLink(.tips),
            .spacer,
            .navigationLink(.chores)
        ]
    }
}
enum HomeScreenNavigationType: Codable, Hashable {
    case bookmark
    case history
    case webarchive
    case musicPlaylist
    case localMedia
    case userscript
    case chores
    case feedbackAssistant
    case tips
    case settings
}
enum ToolbarButtonRenderType {
    case preference // In Settings View
    case main       // In Home Screen
}
enum HomeScreenToolbarPosition: Codable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomCenter
    case bottomTrailing
}
struct HomeScreenToolbar: Codable {
    var topLeading: HomeScreenControlType
    var topTrailing: HomeScreenControlType
    var bottomLeading: HomeScreenControlType
    var bottomCenter: HomeScreenControlType
    var bottomTrailing: HomeScreenControlType
    
    static var `default`: Self {
        .init(topLeading: .navigationLink(.settings), topTrailing: .spacer, bottomLeading: .spacer, bottomCenter: .spacer, bottomTrailing: .spacer)
    }
}

@_effects(readonly)
@_effects(notEscaping control.**)
@_effects(notEscaping type.**)
@ViewBuilder
func getToolbarButton(by control: HomeScreenControlType, with type: ToolbarButtonRenderType, action: ((Any?) -> Void)? = nil) -> some View {
    switch control {
    case .searchField, .searchButton:
        if type == .main {
            TextFieldLink(label: {
                Image(systemName: "magnifyingglass")
            }, onSubmit: { str in
                action?(str)
            })
        } else {
            Button(action: {
                action?(nil)
            }, label: {
                Image(systemName: "magnifyingglass")
            })
        }
    case .spacer, .pinnedBookmarks:
        if type == .main {
            Spacer()
        } else {
            Button(action: {
                action?(nil)
            }, label: {
                Image(systemName: "circle.dashed")
            })
        }
    case .text(let string):
        Text(string)
            .onTapGesture {
                action?(string)
            }
    case .navigationLink(let navigation):
        Button(action: {
            action?(navigation)
        }, label: {
            switch navigation {
            case .bookmark:
                Image(systemName: "bookmark")
            case .history:
                Image(systemName: "clock")
            case .webarchive:
                Image(systemName: "archivebox")
            case .musicPlaylist:
                Image(systemName: "music.note.list")
            case .userscript:
                Image(systemName: "applescript")
            case .localMedia:
                Image(systemName: "play.square.stack")
            case .chores:
                Spacer()
            case .feedbackAssistant:
                Image(systemName: "exclamationmark.bubble")
            case .tips:
                Image(systemName: "lightbulb")
            case .settings:
                Image(systemName: "gear")
            }
        })
    }
}
@available(watchOS 10.0, *)
@_effects(readonly)
@_effects(escaping controls.** -> action.**)
@ToolbarContentBuilder
func getFullToolbar(
    by controls: HomeScreenToolbar,
    with type: ToolbarButtonRenderType,
    action: @escaping (HomeScreenControlType, HomeScreenToolbarPosition, Any?) -> Void
) -> some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
        getToolbarButton(by: controls.topLeading, with: type) { object in
            action(controls.topLeading, .topLeading, object)
        }
    }
    if UserDefaults.standard.bool(forKey: "LabTabBrowsingEnabled") {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                action(controls.topTrailing, .topTrailing, nil)
            }, label: {
                Image(systemName: "square.on.square.dashed")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.white)
            })
            .disabled(type == .preference)
        }
    } else {
        ToolbarItem(placement: .topBarTrailing) {
            if controls.topTrailing != .spacer {
                getToolbarButton(by: controls.topTrailing, with: type) { object in
                    action(controls.topTrailing, .topTrailing, object)
                }
            }
        }
    }
    ToolbarItemGroup(placement: .bottomBar) {
        getToolbarButton(by: controls.bottomLeading, with: type) { object in
            action(controls.bottomLeading, .bottomLeading, object)
        }
//        getToolbarButton(by: controls.bottomCenter, with: type) { object in
//            action(controls.bottomCenter, .bottomCenter, object)
//        }
        Spacer()
        getToolbarButton(by: controls.bottomTrailing, with: type) { object in
            action(controls.bottomTrailing, .bottomTrailing, object)
        }
    }
}

enum EngineNames: String, CaseIterable {
    case bing = "必应"
    case baidu = "百度"
    case google = "谷歌"
    case sougou = "搜狗"
}
