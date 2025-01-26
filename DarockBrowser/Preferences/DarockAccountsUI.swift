//
//  DarockAccountsUI.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 6/18/24.
//

import SwiftUI
import DarockUI

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
