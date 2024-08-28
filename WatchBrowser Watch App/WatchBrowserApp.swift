//
//  WatchBrowserApp.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//

import SwiftUI
import Dynamic
import Intents
import WatchKit
import DarockKit
import SDWebImage
import AVFoundation
import SDWebImageSVGCoder
import SDWebImagePDFCoder
import SDWebImageWebPCoder
import AuthenticationServices

var pShowTipText: LocalizedStringKey = ""
var pShowTipSymbol = ""
var pIsShowingTip = false
var pTapToRadarAlertContent = ""
var pTapToRadarAttachText = ""
var pIsTapToRadarAlertPresented = false

@main
struct WatchBrowser_Watch_AppApp: App {
    let device = WKInterfaceDevice.current()
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("ShouldTipNewFeatures5") var shouldTipNewFeatures = true
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLockDarockBrowser") var usePasscodeForLockDarockBrowser = false
    @AppStorage("IsThisClusterInstalled") var isThisClusterInstalled = false
    @AppStorage("ABIsReduceBrightness") var isReduceBrightness = false
    @AppStorage("ABReduceBrightnessLevel") var reduceBrightnessLevel = 0.2
    @State var showTipText: LocalizedStringKey = ""
    @State var showTipSymbol = ""
    @State var isShowingTip = false
    @State var isBrowserLocked = true
    @State var passcodeInputCache = ""
    @State var tapToRadarAlertContent = ""
    @State var isTapToRadarAlertPresented = false
    @State var isClusterInstalledTipPresented = false
    @State var isQuickAvoidanceShowingEmpty = false
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !isBrowserLocked {
                    DoubleTapActionButton(forType: .global) {
                        isQuickAvoidanceShowingEmpty = true
                    }
                }
                ContentView()
                    .blur(radius: isBrowserLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLockDarockBrowser ? 12 : 0)
                    .allowsHitTesting(!(isBrowserLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLockDarockBrowser))
                    .sheet(isPresented: $shouldTipNewFeatures, content: { NewFeaturesView() })
                    .sheet(isPresented: $isClusterInstalledTipPresented, content: { ClusterTipView() })
                    .onAppear {
                        if userPasscodeEncrypted.isEmpty || !usePasscodeForLockDarockBrowser {
                            isBrowserLocked = false
                        }
                    }
                if isBrowserLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLockDarockBrowser {
                    PasswordInputView(text: $passcodeInputCache, placeholder: "输入密码", hideCancelButton: true, dismissAfterComplete: false) { pwd in
                        if pwd.md5 == userPasscodeEncrypted {
                            isBrowserLocked = false
                        } else {
                            tipWithText("密码错误", symbol: "xmark.circle.fill")
                        }
                        passcodeInputCache = ""
                    }
                }
                VStack {
                    Spacer()
                    if isShowingTip {
                        Group {
                            if #available(watchOS 10, *) {
                                HStack {
                                    Image(systemName: showTipSymbol)
                                    Text(showTipText)
                                }
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: WKInterfaceDevice.current().screenBounds.width - 20, height: 50)
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            } else {
                                HStack {
                                    Image(systemName: showTipSymbol)
                                    Text(showTipText)
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: WKInterfaceDevice.current().screenBounds.width - 20, height: 50)
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                                .background {
                                    Color.white
                                        .ignoresSafeArea()
                                        .frame(width: WKInterfaceDevice.current().screenBounds.width - 20, height: 40)
                                        .cornerRadius(14)
                                        .foregroundColor(Color(hex: 0xF5F5F5))
                                        .opacity(0.95)
                                }
                            }
                        }
                        .transition(
                            AnyTransition
                                .opacity
                                .combined(with: .scale)
                                .animation(.bouncy(duration: 0.35))
                        )
                    }
                    Spacer()
                        .frame(height: 15)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                if isReduceBrightness {
                    Rectangle()
                        .fill(Color.black)
                        .opacity(reduceBrightnessLevel)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                if isQuickAvoidanceShowingEmpty {
                    Color.black
                        .ignoresSafeArea()
                        .onTapGesture(count: 3) {
                            isQuickAvoidanceShowingEmpty = false
                        }
                }
            }
            ._statusBarHidden(isQuickAvoidanceShowingEmpty)
            .alert("Runtime Error", isPresented: $isTapToRadarAlertPresented, actions: {
                Button(role: .cancel, action: {
                    
                }, label: {
                    Text("Cancel")
                })
                Button(action: {
                    WKExtension.shared().openSystemURL(URL(string: "https://darock.top/internal/tap-to-radar/new?ProductName=Darock Browser&Title=Internal autoattachd Error&Description=\(pTapToRadarAttachText)")!)
                }, label: {
                    Text("Tap-to-Radar")
                })
            }, message: {
                Text(tapToRadarAlertContent)
            })
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    showTipText = pShowTipText
                    showTipSymbol = pShowTipSymbol
                    Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                        isShowingTip = pIsShowingTip
                    }
                    
                    tapToRadarAlertContent = pTapToRadarAlertContent
                    if _slowPath(pIsTapToRadarAlertPresented) {
                        isTapToRadarAlertPresented = true
                        pIsTapToRadarAlertPresented = false
                    }
                }
            }
        }
        .onChange(of: scenePhase) { value in
            switch value {
            case .background:
                if !userPasscodeEncrypted.isEmpty && usePasscodeForLockDarockBrowser {
                    isBrowserLocked = true
                }
            case .inactive:
                break
            case .active:
                SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
                SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
                SDImageCodersManager.shared.addCoder(SDImagePDFCoder.shared)
                
                if (UserDefaults(suiteName: "group.darockst")?.bool(forKey: "DCIsClusterInstalled") ?? false) && !isThisClusterInstalled {
                    isThisClusterInstalled = true
                    isClusterInstalledTipPresented = true
                }
            @unknown default:
                break
            }
        }
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        NSSetUncaughtExceptionHandler(nsErrorHandler(_:))
//        INPreferences.requestSiriAuthorization { status in
//            switch status {
//            case .notDetermined:
//                debugPrint("Siri Not Determined")
//            case .restricted:
//                debugPrint("Siri Restricted")
//            case .denied:
//                debugPrint("Siri Denied")
//            case .authorized:
//                debugPrint("Siri Authorized")
//                let intent = SearchIntent()
//                intent.content = "Test"
//                let interaction = INInteraction(intent: intent, response: nil)
//                interaction.donate()
//            @unknown default:
//                break
//            }
//        }
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.hexEncodedString()
        debugPrint(tokenString)
        UserDefaults.standard.set(tokenString, forKey: "UserNotificationToken")
    }
}

public func tipWithText(_ text: LocalizedStringKey, symbol: String = "", time: Double = 3.0) {
    pShowTipText = text
    pShowTipSymbol = symbol
    pIsShowingTip = true
    Timer.scheduledTimer(withTimeInterval: time, repeats: false) { _ in
        pIsShowingTip = false
    }
}
@_disfavoredOverload
public func tipWithText(_ text: String, symbol: String = "", time: Double = 3.0) {
    pShowTipText = "\(text)"
    pShowTipSymbol = symbol
    pIsShowingTip = true
    Timer.scheduledTimer(withTimeInterval: time, repeats: false) { _ in
        pIsShowingTip = false
    }
}
public func globalErrorHandler(_ error: Error, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
    print(error)
    do {
        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/SwiftErrorLogs") {
            try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/SwiftErrorLogs", withIntermediateDirectories: true)
        }
        try """
        Error：\(error.localizedDescription)
        Location：\(file):\(line) - \(function)
        """.write(
            toFile: NSHomeDirectory() + "/Documents/SwiftErrorLogs/\(Date().timeIntervalSince1970).txt",
            atomically: true,
            encoding: .utf8
        )
    } catch {
        print("Error in globalErrorHandler: \(error)")
    }
    if UserDefaults(suiteName: "group.darockst")!.bool(forKey: "IsDarockInternalTap-to-RadarAvailable") {
        pTapToRadarAlertContent = "Swift has catched an internal error.\nPlease help us make Darock Browser better by logging a bug. Thanks. (\(file):\(line) - \(function))"
        pTapToRadarAttachText = "Auto-attachd DarockBrowser(\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)). At \(file):\(line) - \(function). LocdStr: \(error.localizedDescription) Add more infomation here: "
            .replacingOccurrences(of: "\n", with: "{LineBreak}")
            .replacingOccurrences(of: "/", with: "{slash}")
            .replacingOccurrences(of: "?", with: "{questionmark}")
            .replacingOccurrences(of: "=", with: "{equal}")
            .replacingOccurrences(of: "&", with: "{and}")
        pIsTapToRadarAlertPresented = true
    }
}
public func nsErrorHandler(_ exception: NSException) {
    print(exception)
    do {
        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/NSExceptionLogs") {
            try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/NSExceptionLogs", withIntermediateDirectories: true)
        }
        var hierarchyStack = [(String, (String, [String]))]()
        //            View Controller    view   subviews
        if var topController = Dynamic.UIApplication.sharedApplication.keyWindow.rootViewController.asObject {
            hierarchyStack.append(
                (topController.description,
                 (Dynamic(topController).view.asObject?.description ?? "nil",
                  (Dynamic(topController).view.asArray as? [NSObject])?.map { $0.description } ?? ["nil"]))
            )
            while let presentedViewController = Dynamic(topController).presentedViewController.asObject {
                topController = presentedViewController
                hierarchyStack.append(
                    (topController.description,
                     (Dynamic(topController).view.asObject?.description ?? "nil",
                      (Dynamic(topController).view.asArray as? [NSObject])?.map { $0.description } ?? ["nil"]))
                )
            }
        }
        try """
        Name: \(exception.name)
        Reason: \(exception.reason ?? "nil")
        UserInfo: \(exception.userInfo ?? ["nil": "nil"])
        Last Exception Backtrace:
        \(exception.callStackSymbols.joined(separator: "\n"))
        
        Thread Call Stack Symbols:
        \(Thread.callStackSymbols.joined(separator: "\n"))
        
        View Hierarchy:
        \(hierarchyStack.map { "\($0.0)||\($0.1.0)||\($0.1.1)" }.joined(separator: "\n"))
        """.write(
            toFile: NSHomeDirectory() + "/Documents/NSExceptionLogs/\(Date().timeIntervalSince1970).txt",
            atomically: true,
            encoding: .utf8
        )
        UserDefaults.standard.set(true, forKey: "AppNewNSExceptionLogged")
    } catch {
        print(error)
    }
}
func resetGlobalAudioLooper() {
    if let currentLooper = globalAudioLooper {
        NotificationCenter.default.removeObserver(currentLooper)
        globalAudioLooper = nil
    }
    globalAudioLooper = NotificationCenter.default.addObserver(
        forName: AVPlayerItem.didPlayToEndTimeNotification,
        object: globalAudioPlayer.currentItem,
        queue: .main) { _ in
            let playbackBehavior = PlaybackBehavior.init(rawValue: UserDefaults.standard.string(forKey: "MPPlaybackBehavior") ?? "pause") ?? .pause
            if playbackBehavior == .singleLoop {
                globalAudioPlayer.seek(to: .zero)
                globalAudioPlayer.play()
            } else if playbackBehavior == .listLoop {
                if let currentContent = getCurrentPlaylistContents() {
                    for i in 0..<currentContent.count {
                        if let currentUrl = (globalAudioPlayer.currentItem?.asset as? AVURLAsset)?.url {
                            if currentUrl.absoluteString == currentContent[i].replacingOccurrences(
                                of: "%DownloadedContent@=", with: "file://\(NSHomeDirectory())/Documents/DownloadedAudios/"
                            ) {
                                if let nextItem = currentContent[from: i &+ 1] {
                                    playAudio(url: nextItem, presentController: false)
                                } else if let firstItem = currentContent.first {
                                    playAudio(url: firstItem, presentController: false)
                                }
                                break
                            }
                        }
                    }
                } else {
                    globalAudioPlayer.seek(to: .zero)
                    globalAudioPlayer.play()
                }
            }
    }
}

@_optimize(speed)
@inline(__always)
@_silgen_name("InternalScriptESIT__T-D_DS-B-def-T")
internal func extendScreenIdleTime(_ time: Double, disableSleep: Bool = true) {
    Dynamic.PUICApplication.sharedPUICApplication().setExtendedIdleTime(time, disablesSleepGesture: disableSleep, wantsAutorotation: false)
}
@_optimize(speed)
@inline(__always)
@_silgen_name("InternalScriptRNIT_V")
internal func recoverNormalIdleTime() {
    Dynamic.PUICApplication.sharedPUICApplication().extendedIdleTime = 0.0
    Dynamic.PUICApplication.sharedPUICApplication().disablesSleepGesture = false
}
