//
//  LocalImageView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI

struct LocalImageView: View {
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLocalImages") var usePasscodeForLocalImages = false
    @AppStorage("IVUseDigitalCrownFor") var useDigitalCrownFor = "zoom"
    @AppStorage("IsThisClusterInstalled") var isThisClusterInstalled = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var images = [String]()
    @State var isImageViewerPresented = false
    @State var tabSelection = 0
    @State var isMenuPresented = false
    @State var indexForMenu = 0
    var body: some View {
        if isLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLocalImages {
            PasswordInputView(text: $passcodeInputCache, placeholder: "输入密码", dismissAfterComplete: false) { pwd in
                if pwd.md5 == userPasscodeEncrypted {
                    isLocked = false
                } else {
                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                }
                passcodeInputCache = ""
            }
            .navigationBarBackButtonHidden()
        } else {
            ScrollViewReader { scrollProxy in
                List {
                    Section {
                        if !images.isEmpty {
                            LazyVGrid(columns: [
                                .init(.fixed(WKInterfaceDevice.current().screenBounds.width / 3), spacing: 0),
                                .init(.fixed(WKInterfaceDevice.current().screenBounds.width / 3), spacing: 0),
                                .init(.fixed(WKInterfaceDevice.current().screenBounds.width / 3), spacing: 0)
                            ], spacing: 0) {
                                ForEach(0..<images.count, id: \.self) { i in
                                    if let image = UIImage(contentsOfFile: NSHomeDirectory() + "/Documents/LocalImages/\(images[i])") {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: WKInterfaceDevice.current().screenBounds.width / 3, height: 80)
                                            .clipped()
                                            .onTapGesture {
                                                tabSelection = i
                                                isImageViewerPresented = true
                                            }
                                            .onLongPressGesture(minimumDuration: 0.4) {
                                                indexForMenu = i
                                                isMenuPresented = true
                                            }
                                            .id(i)
                                    }
                                }
                            }
                            .onAppear {
                                scrollProxy.scrollTo(images.count - 1)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .scrollIndicators(.never)
            }
            .navigationTitle("本地图片")
            .sheet(isPresented: $isImageViewerPresented) {
                if useDigitalCrownFor == "zoom" {
                    TabView(selection: $tabSelection) {
                        ForEach(0..<images.count, id: \.self) { i in
                            ImageViewerView(url: URL(filePath: NSHomeDirectory() + "/Documents/LocalImages/\(images[i])").absoluteString)
                                .tag(i)
                        }
                    }
                } else {
                    TabView(selection: $tabSelection) {
                        ForEach(0..<images.count, id: \.self) { i in
                            ImageViewerView(url: URL(filePath: NSHomeDirectory() + "/Documents/LocalImages/\(images[i])").absoluteString)
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.carousel)
                }
            }
            .sheet(isPresented: $isMenuPresented) {
                NavigationStack {
                    List {
                        Section {
                            ShareLink(item: URL(filePath: NSHomeDirectory() + "/Documents/LocalImages/" + images[indexForMenu])) {
                                Label("分享", systemImage: "square.and.arrow.up")
                            }
                            if isThisClusterInstalled {
                                Button(action: {
                                    do {
                                        let containerFilePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.darockst")!.path + "/TransferFile.drkdatat"
                                        if FileManager.default.fileExists(atPath: containerFilePath) {
                                            try FileManager.default.removeItem(atPath: containerFilePath)
                                        }
                                        try FileManager.default.copyItem(
                                            atPath: NSHomeDirectory() + "/Documents/LocalImages/" + images[indexForMenu],
                                            toPath: containerFilePath
                                        )
                                        WKExtension.shared().openSystemURL(URL(string: "https://darock.top/cluster/add/\(images[indexForMenu])")!)
                                        isMenuPresented = false
                                        images = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/LocalImages")
                                        images.sort { lhs, rhs in
                                            let lt = lhs.dropLast(4) // Drop ".png"
                                            let rt = rhs.dropLast(4)
                                            if let dl = Double(lt), let dr = Double(rt) {
                                                return dl < dr
                                            }
                                            return false
                                        }
                                    } catch {
                                        globalErrorHandler(error)
                                    }
                                }, label: {
                                    Label("分享到暗礁文件", systemImage: "square.grid.3x1.folder.badge.plus")
                                })
                            }
                        }
                        Section {
                            Button(role: .destructive, action: {
                                do {
                                    try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/LocalImages/" + images[indexForMenu])
                                    isMenuPresented = false
                                } catch {
                                    globalErrorHandler(error)
                                }
                            }, label: {
                                Label("删除", systemImage: "trash")
                                    .foregroundStyle(.red)
                            })
                        }
                    }
                }
            }
            .onAppear {
                do {
                    images = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/LocalImages")
                    images.sort { lhs, rhs in
                        let lt = lhs.dropLast(4) // Drop ".png"
                        let rt = rhs.dropLast(4)
                        if let dl = Double(lt), let dr = Double(rt) {
                            return dl < dr
                        }
                        return false
                    }
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
    }
}
