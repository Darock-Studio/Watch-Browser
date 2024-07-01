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
import SDWebImage
import SDWebImageSVGCoder
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
    @AppStorage("ShouldTipNewFeatures2") var shouldTipNewFeatures = true
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLockDarockBrowser") var usePasscodeForLockDarockBrowser = false
    @State var showTipText: LocalizedStringKey = ""
    @State var showTipSymbol = ""
    @State var isShowingTip = false
    @State var isBrowserLocked = true
    @State var passcodeInputCache = ""
    @State var tapToRadarAlertContent = ""
    @State var isTapToRadarAlertPresented = false
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .blur(radius: isBrowserLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLockDarockBrowser ? 12 : 0)
                    .allowsHitTesting(!(isBrowserLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLockDarockBrowser))
                    .sheet(isPresented: $shouldTipNewFeatures, content: { NewFeaturesView() })
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
            }
            .alert("Runtime Error", isPresented: $isTapToRadarAlertPresented, actions: {
                Button(role: .cancel, action: {
                    
                }, label: {
                    Text("Cancel")
                })
                Button(action: {
                    UserDefaults(suiteName: "group.darockst")!.set(pTapToRadarAttachText, forKey: "InternalTapToRadarAttachText")
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
                    if pIsTapToRadarAlertPresented {
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
            @unknown default:
                break
            }
        }
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
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
public func globalErrorHandler(_ error: Error, at: String = "Not Provided") {
    print(error)
    if UserDefaults(suiteName: "group.darockst")!.bool(forKey: "IsDarockInternalTap-to-RadarAvailable") {
        pTapToRadarAlertContent = "Swift has catched an internal error.\nPlease help us make Darock Browser better by logging a bug. Thanks. (\(at))"
        pTapToRadarAttachText = "Auto-attachd DarockBrowser(\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)). At \(at). LocdStr: \(error.localizedDescription). Add more infomation here: "
            .replacingOccurrences(of: "\n", with: "{LineBreak}")
            .replacingOccurrences(of: "/", with: "{slash}")
        pIsTapToRadarAlertPresented = true
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
