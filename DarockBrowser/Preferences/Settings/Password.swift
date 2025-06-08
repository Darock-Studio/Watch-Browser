//
//  Password.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import DarockUI

extension SettingsView {
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
                            isClosePasswordPresented = true
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
                            isChangePasswordPresented = true
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
            }
            .navigationTitle("密码")
        }
    }
}
