//
//  Reset.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI

extension SettingsView.GeneralSettingsView {
    struct ResetView: View {
        @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
        @State var isResetSettingsWarningPresented = false
        @State var isResetAllWarningPresented = false
        @State var isResetSettingsPasscodePresented = false
        @State var passcodeInputTmp = ""
        var body: some View {
            List {
                Section {
                    Button(action: {
                        if userPasscodeEncrypted.isEmpty {
                            isResetSettingsWarningPresented = true
                        } else {
                            isResetSettingsPasscodePresented = true
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
