//
//  DarockAccountsUI.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 6/18/24.
//

import SwiftUI
import DarockKit

struct DarockAccountLogin: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("DarockAccount") var darockAccount = ""
    @State var accountCache = ""
    @State var passwdCache = ""
    @State var alertTipText = ""
    @State var isAlertPresented = false
    @State var isLoading = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Image("AppIconImage")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    Text("Darock 账户")
                        .font(.system(size: 24))
                    Spacer()
                        .frame(height: 20)
                    TextField("Darock 账户", text: $accountCache)
                        .textContentType(.username)
                        .submitLabel(.continue)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("密码", text: $passwdCache)
                        .textContentType(.password)
                    Button(action: {
                        isLoading = true
                        DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/user/login/\(accountCache)/\(passwdCache)".compatibleUrlEncoded()) { respStr, isSuccess in
                            if isSuccess {
                                if respStr.apiFixed() == "Success" {
                                    darockAccount = accountCache
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    alertTipText = String(localized: "错误：账号或密码错误")
                                    isAlertPresented = true
                                    isLoading = false
                                }
                            } else {
                                isLoading = false
                            }
                        }
                    }, label: {
                        if !isLoading {
                            Text("登录")
                                .font(.system(size: 20, weight: .bold))
                        } else {
                            ProgressView()
                        }
                    })
                    .alert(alertTipText, isPresented: $isAlertPresented, actions: {})
                    if UserDefaults(suiteName: "group.darockst")!.bool(forKey: "IsDarockInternalConnectAvailable") {
                        Button(action: {
                            WKExtension.shared().openSystemURL(
                                URL(string: "https://darock.top/internal/connect/ssologin?callback=darockbrower{slash}login{slash}%account@")!
                            )
                        }, label: {
                            HStack {
                                Image("DarockConnectIcon")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .cornerRadius(6)
                                Text("DarockConnect")
                            }
                        })
                    }
                    NavigationLink(destination: { RegisterView() }, label: {
                        Text("注册")
                    })
                    .padding(.vertical)
                }
            }
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            if let url = userActivity.webpageURL, let action = url.absoluteString.split(separator: "darock.top/darockbrowser/", maxSplits: 1)[from: 1] {
                let slashSpd = action.split(separator: "/")
                if let arg1 = slashSpd[from: 0], let arg2 = slashSpd[from: 1] {
                    if arg1 == "login" {
                        darockAccount = String(arg2)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    struct RegisterView: View {
        @Environment(\.presentationMode) var presentationMode
        @State var mailInput = ""
        @State var passwordInput = ""
        @State var passwordConfirmInput = ""
        @State var usernameInput = ""
        @State var isRegistering = false
        var body: some View {
            List {
                Section {
                    Text("注册 Darock 账户")
                        .font(.system(size: 20, weight: .semibold))
                    Text("一个账户尽享 Darock 所有服务")
                        .multilineTextAlignment(.center)
                }
                .listRowBackground(Color.clear)
                Section {
                    TextField("电子邮件地址", text: $mailInput)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("密码", text: $passwordInput)
                        .textContentType(.newPassword)
                    SecureField("确认密码", text: $passwordConfirmInput)
                        .textContentType(.newPassword)
                }
                Section {
                    TextField("用户名", text: $usernameInput)
                } header: {
                    Text("信息")
                }
                Section {
                    Button(action: {
                        isRegistering = true
                        DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/user/reg/\(mailInput)/\(passwordInput)".compatibleUrlEncoded()) { _, isSuccess in
                            if isSuccess {
                                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/user/name/set/\(mailInput)/\(usernameInput)".compatibleUrlEncoded()) { _, isSuccess in
                                    if isSuccess {
                                        isRegistering = false
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }
                        }
                    }, label: {
                        if !isRegistering {
                            Text("注册")
                        } else {
                            ProgressView()
                        }
                    })
                    .disabled(
                        isRegistering
                        || (!mailInput.contains("@") || mailInput.hasPrefix("@") || mailInput.hasSuffix("@") || !mailInput.contains("."))
                        || passwordInput != passwordConfirmInput
                        || passwordInput.isEmpty
                        || passwordInput.count < 8
                        || usernameInput.isEmpty
                    )
                } footer: {
                    VStack(alignment: .leading) {
                        if !mailInput.contains("@") || mailInput.hasPrefix("@") || mailInput.hasSuffix("@") || !mailInput.contains(".") {
                            HStack {
                                Image(systemName: "xmark.octagon.fill")
                                    .foregroundColor(.red)
                                Text("电子邮件地址无效")
                            }
                        }
                        if passwordInput != passwordConfirmInput {
                            HStack {
                                Image(systemName: "xmark.octagon.fill")
                                    .foregroundColor(.red)
                                Text("两次密码不一致")
                            }
                        }
                        if passwordInput.isEmpty {
                            HStack {
                                Image(systemName: "xmark.octagon.fill")
                                    .foregroundColor(.red)
                                Text("密码不能为空")
                            }
                        }
                        if passwordInput.count < 8 {
                            HStack {
                                Image(systemName: "xmark.octagon.fill")
                                    .foregroundColor(.red)
                                Text("密码长度不能小于8位")
                            }
                        }
                        if usernameInput.isEmpty {
                            HStack {
                                Image(systemName: "xmark.octagon.fill")
                                    .foregroundColor(.red)
                                Text("用户名不能为空")
                            }
                        }
                    }
                }
            }
            .navigationTitle("注册")
        }
    }
}

struct DarockAccountManagementMain: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("DarockAccount") var darockAccount = ""
    @State var username = ""
    @State var isSignOutAlertPresented = false
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Group {
                            if !username.isEmpty {
                                Text(username)
                            } else {
                                Text(verbatim: "loading")
                                    .redacted(reason: .placeholder)
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        Text(darockAccount)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            Section {
                NavigationLink(destination: { PersonalInformationView(username: $username) }, label: {
                    HStack {
                        ZStack {
                            Color.gray
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: 12))
                        }
                        Text("个人信息")
                    }
                })
                NavigationLink(destination: { SigninAndSecurityView() }, label: {
                    HStack {
                        ZStack {
                            Color.gray
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                            ZStack {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 14))
                                Image(systemName: "key.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                            }
                        }
                        Text("登录与安全性")
                    }
                })
            }
            Section {
                NavigationLink(destination: { DarockCloudView() }, label: {
                    HStack {
                        ZStack {
                            Color.cyan
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                            Image(systemName: "cloud")
                                .font(.system(size: 12, weight: .bold))
                        }
                        Text("Darock Cloud")
                    }
                })
            }
            Section {
                NavigationLink(destination: { DeviceInfoView() }, label: {
                    HStack {
                        Image(systemName: "applewatch")
                            .font(.system(size: 30))
                        VStack(alignment: .leading) {
                            Text(WKInterfaceDevice.current().name)
                                .font(.system(size: 14))
                            Text("此 \(WKInterfaceDevice.modelName)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                })
            }
            Section {
                Button(role: .destructive, action: {
                    isSignOutAlertPresented = true
                }, label: {
                    Text("退出登录")
                })
            }
        }
        .navigationTitle("Darock 账户")
        .navigationBarTitleDisplayMode(.inline)
        .alert("退出登录？", isPresented: $isSignOutAlertPresented, actions: {
            Button(role: .cancel, action: {
                
            }, label: {
                Text("取消")
            })
            Button(role: .destructive, action: {
                darockAccount = ""
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("退出登录")
            })
        }, message: {
            Text("已同步的数据将会被保留。")
        })
    }
    
    struct PersonalInformationView: View {
        @Binding var username: String
        var body: some View {
            List {
                Section {
                    HStack {
                        Spacer()
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                Section {
                    NavigationLink(destination: { NameChangeView(username: $username) }, label: {
                        HStack {
                            Text("名称")
                            Spacer()
                            Text(username)
                                .lineLimit(1)
                                .foregroundColor(.gray)
                        }
                    })
                }
            }
            .navigationTitle("个人信息")
            .navigationBarTitleDisplayMode(.inline)
        }
        
        struct NameChangeView: View {
            @Binding var username: String
            @Environment(\.presentationMode) var presentationMode
            @AppStorage("DarockAccount") var darockAccount = ""
            @State var nameInput = ""
            @State var isApplying = false
            var body: some View {
                List {
                    Section {
                        TextField("名称", text: $nameInput)
                            .disabled(isApplying)
                    } footer: {
                        VStack {
                            if nameInput.isEmpty {
                                HStack {
                                    Image(systemName: "xmark.octagon.fill")
                                        .foregroundColor(.red)
                                    Text("名称不能为空")
                                }
                            }
                        }
                    }
                }
                .navigationTitle("名称")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            isApplying = true
                            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/user/name/set/\(darockAccount)/\(nameInput)".compatibleUrlEncoded()) { _, isSuccess in
                                if isSuccess {
                                    username = nameInput
                                    presentationMode.wrappedValue.dismiss()
                                }
                                isApplying = false
                            }
                        }, label: {
                            if !isApplying {
                                Image(systemName: "checkmark")
                            } else {
                                ProgressView()
                            }
                        })
                        .disabled(isApplying || nameInput.isEmpty)
                    }
                }
                .onAppear {
                    nameInput = username
                }
            }
        }
    }
    struct SigninAndSecurityView: View {
        @AppStorage("DarockAccount") var darockAccount = ""
        @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
        @State var isChangePasswordDelayPresented = false
        @State var isDeleteAccountDelayPresented = false
        @State var isPasscodeInputPresented = false
        @State var isAccountDeletionPasscodeInputPresented = false
        @State var devicePasscodeInputTmp = ""
        @State var isChangePasswordPresented = false
        @State var isAccountDeletionPresented = false
        var body: some View {
            List {
                Section {
                    Text(darockAccount)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                } header: {
                    Text("电子邮件")
                } footer: {
                    Text("电子邮件可用于登录。")
                }
                Section {
                    Button(action: {
                        if !userPasscodeEncrypted.isEmpty {
                            if !checkSecurityDelay() {
                                isChangePasswordDelayPresented = true
                                return
                            }
                            isPasscodeInputPresented = true
                            return
                        }
                        isChangePasswordPresented = true
                    }, label: {
                        Text("更改密码")
                            .foregroundColor(.blue)
                    })
                    .sheet(isPresented: $isPasscodeInputPresented) {
                        PasswordInputView(text: $devicePasscodeInputTmp, placeholder: "输入锁定密码") { pwd in
                            if pwd.md5 == userPasscodeEncrypted {
                                isChangePasswordPresented = true
                            } else {
                                isPasscodeInputPresented = true
                                tipWithText("密码错误", symbol: "xmark.circle.fill")
                            }
                            devicePasscodeInputTmp = ""
                        }
                        .toolbar(.hidden, for: .navigationBar)
                    }
                }
                Section {
                    Button(role: .destructive, action: {
                        if !userPasscodeEncrypted.isEmpty {
                            if !checkSecurityDelay() {
                                isDeleteAccountDelayPresented = true
                                return
                            }
                            isAccountDeletionPasscodeInputPresented = true
                            return
                        }
                        isAccountDeletionPresented = true
                    }, label: {
                        Text("删除账户")
                    })
                    .sheet(isPresented: $isAccountDeletionPasscodeInputPresented) {
                        PasswordInputView(text: $devicePasscodeInputTmp, placeholder: "输入锁定密码") { pwd in
                            if pwd.md5 == userPasscodeEncrypted {
                                isAccountDeletionPresented = true
                            } else {
                                isAccountDeletionPasscodeInputPresented = true
                                tipWithText("密码错误", symbol: "xmark.circle.fill")
                            }
                            devicePasscodeInputTmp = ""
                        }
                        .toolbar(.hidden, for: .navigationBar)
                    }
                } header: {
                    Text("危险区域")
                }
            }
            .navigationTitle("登录与安全性")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isChangePasswordDelayPresented, content: { SecurityDelayRequiredView(reasonTitle: "需要安全延时以更改 Darock 账户密码") })
            .sheet(isPresented: $isDeleteAccountDelayPresented, content: { SecurityDelayRequiredView(reasonTitle: "需要安全延时以删除 Darock 账户") })
            .sheet(isPresented: $isChangePasswordPresented, content: { ChangePasswordView() })
            .sheet(isPresented: $isAccountDeletionPresented, content: { AccountDeletionView() })
        }
        
        struct ChangePasswordView: View {
            @Environment(\.presentationMode) var presentationMode
            @AppStorage("DarockAccount") var darockAccount = ""
            @State var currentPasswordInput = ""
            @State var newPasswordInput = ""
            @State var passwordConfirmInput = ""
            @State var isApplying = false
            var body: some View {
                NavigationStack {
                    List {
                        Section {
                            SecureField("当前密码", text: $currentPasswordInput)
                            SecureField("密码", text: $newPasswordInput)
                            SecureField("确认密码", text: $passwordConfirmInput)
                        }
                        .disabled(isApplying)
                        Section {
                            Button(action: {
                                isApplying = true
                                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/user/modifypwd/\(darockAccount)/\(currentPasswordInput)/\(newPasswordInput)".compatibleUrlEncoded()) { respStr, isSuccess in
                                    if isSuccess {
                                        if respStr.apiFixed() == "Success" {
                                            tipWithText("密码已更改", symbol: "checkmark.circle.fill")
                                            presentationMode.wrappedValue.dismiss()
                                        } else {
                                            tipWithText("原密码错误", symbol: "xmark.circle.fill")
                                            currentPasswordInput = ""
                                        }
                                    }
                                    isApplying = false
                                }
                            }, label: {
                                if !isApplying {
                                    Text("更改密码")
                                } else {
                                    ProgressView()
                                }
                            })
                            .disabled(
                                isApplying
                                || newPasswordInput != passwordConfirmInput
                                || newPasswordInput.isEmpty
                                || newPasswordInput.count < 8
                            )
                        } footer: {
                            VStack(alignment: .leading) {
                                if newPasswordInput != passwordConfirmInput {
                                    HStack {
                                        Image(systemName: "xmark.octagon.fill")
                                            .foregroundColor(.red)
                                        Text("两次密码不一致")
                                    }
                                }
                                if newPasswordInput.isEmpty {
                                    HStack {
                                        Image(systemName: "xmark.octagon.fill")
                                            .foregroundColor(.red)
                                        Text("密码不能为空")
                                    }
                                }
                                if newPasswordInput.count < 8 {
                                    HStack {
                                        Image(systemName: "xmark.octagon.fill")
                                            .foregroundColor(.red)
                                        Text("密码长度不能小于8位")
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("更改密码")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        struct AccountDeletionView: View {
            @AppStorage("DarockAccount") var darockAccount = ""
            @State var mailConfirmInput = ""
            @State var passwordInput = ""
            @State var isDeleting = false
            var body: some View {
                NavigationStack {
                    List {
                        Section {
                            HStack {
                                Spacer()
                                VStack {
                                    Text("删除账户")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.red)
                                    Text("这将删除账户下的所有数据！")
                                }
                                Spacer()
                            }
                        }
                        .listRowBackground(Color.clear)
                        Section {
                            TextField("输入确认文本", text: $mailConfirmInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } header: {
                            Text("确认")
                        } footer: {
                            Text("若要确认删除，请在上方输入“\(darockAccount)”")
                        }
                        Section {
                            SecureField("账户密码", text: $passwordInput)
                        }
                        Section {
                            Button(role: .destructive, action: {
                                isDeleting = true
                                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/user/del/\(darockAccount)/\(passwordInput)".compatibleUrlEncoded()) { respStr, isSuccess in
                                    if isSuccess {
                                        if respStr.apiFixed() == "Success" {
                                            darockAccount = ""
                                            exit(0)
                                        } else {
                                            tipWithText("密码错误", symbol: "xmark.circle.fill")
                                            passwordInput = ""
                                        }
                                        isDeleting = false
                                    }
                                }
                            }, label: {
                                Text("删除账户")
                            })
                            .disabled(isDeleting || mailConfirmInput != darockAccount)
                        } footer: {
                            VStack {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.yellow)
                                    Text("删除账户后，暗礁浏览器将关闭以应用更改，您需要手动重启暗礁浏览器。")
                                }
                                if mailConfirmInput != darockAccount {
                                    HStack {
                                        Image(systemName: "xmark.octagon.fill")
                                            .foregroundColor(.red)
                                        Text("确认文本不匹配")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    struct DarockCloudView: View {
        @AppStorage("DarockAccount") var darockAccount = ""
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { SavedToDarockCloudView() }, label: {
                        HStack {
                            Text("存储至 Darock Cloud")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .foregroundColor(.gray)
                        }
                    })
                }
            }
            .navigationTitle("Darock Cloud")
            .navigationBarTitleDisplayMode(.inline)
        }
        
        struct SavedToDarockCloudView: View {
            @AppStorage("DarockAccount") var darockAccount = ""
            @AppStorage("DCSaveHistory") var isSaveHistoryToCloud = false
            @State var isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
            var body: some View {
                List {
                    if isLowPowerModeEnabled {
                        Section {
                            Text("为减少电量消耗，同步已暂停")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .centerAligned()
                        }
                        .listRowBackground(Color.clear)
                    }
                    Section {
                        Toggle(isOn: $isSaveHistoryToCloud) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.blue.gradient)
                                Text("历史记录")
                            }
                        }
                    } footer: {
                        Text("当在多设备登录账号，或是重新安装暗礁浏览器后，存储至 Darock Cloud 的数据将会自动同步。")
                    }
                }
                .navigationTitle("存储至 Darock Cloud")
                .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { processInfo in
                    if let processInfo = processInfo.object as? ProcessInfo {
                        isLowPowerModeEnabled = processInfo.isLowPowerModeEnabled
                    }
                }
            }
        }
    }
    
    struct DeviceInfoView: View {
        var deviceName: String?
        var body: some View {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "applewatch")
                                .font(.system(size: 40))
                            Text(WKInterfaceDevice.current().name)
                                .font(.system(size: 16))
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                            Text("此 \(WKInterfaceDevice.modelName)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("设备信息")
        }
    }
}

extension WKInterfaceDevice {
    static let modelIdentifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }()
    
    static let modelName: String = {
        // rdar://so?26028918
        
        let identifier = WKInterfaceDevice.modelIdentifier
        func mapToDevice(identifier: String) -> String {
            switch identifier {
            case "Watch1,1", "Watch1,2":   return "Apple Watch (1st generation)"
            case "Watch2,6", "Watch2,7":   return "Apple Watch Series 1"
            case "Watch2,3", "Watch2,4":   return "Apple Watch Series 2"
            case "Watch3,1", "Watch3,2",
                 "Watch3,3", "Watch3,4":   return "Apple Watch Series 3"
            case "Watch4,1", "Watch4,2",
                 "Watch4,3", "Watch4,4":   return "Apple Watch Series 4"
            case "Watch5,1", "Watch5,2",
                 "Watch5,3", "Watch5,4":   return "Apple Watch Series 5"
            case "Watch5,9", "Watch5,10",
                 "Watch5,11", "Watch5,12": return "Apple Watch SE"
            case "Watch6,1", "Watch6,2",
                 "Watch6,3", "Watch6,4":   return "Apple Watch Series 6"
            case "Watch6,6", "Watch6,7",
                 "Watch6,8", "Watch6,9":   return "Apple Watch Series 7"
            case "Watch6,10", "Watch6,11",
                 "Watch6,12", "Watch6,13": return "Apple Watch SE (2nd generation)"
            case "Watch6,14", "Watch6,15",
                 "Watch6,16", "Watch6,17": return "Apple Watch Series 8"
            case "Watch6,18":              return "Apple Watch Ultra"
            case "Watch7,1", "Watch7,2",
                 "Watch7,3", "Watch7,4":   return "Apple Watch Series 9"
            case "Watch7,5":               return "Apple Watch Ultra 2"
            case "Watch7,8", "Watch7,9",
                 "Watch7,10", "Watch7,11":   return "Apple Watch Series 10"
            default:                       return "Apple Watch"
            }
        }
        
        return mapToDevice(identifier: identifier)
    }()
}
