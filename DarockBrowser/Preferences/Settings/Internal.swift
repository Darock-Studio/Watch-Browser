//
//  Internal.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import DarockUI
import WidgetKit

extension SettingsView {
    struct InternalDebuggingView: View {
        @AppStorage("SecurityDelayStartTime") var securityDelayStartTime = -1.0
        @AppStorage("TQCIsColorChangeButtonUnlocked") var isColorChangeButtonUnlocked = false
        @AppStorage("TQCIsColorChangeButtonEntered") var isColorChangeButtonEntered = false
        @AppStorage("IsProPurchased") var isProPurchased = false
        @AppStorage("PRSubscriptionExpirationDate") var subscriptionExpirationDate = 0.0
        @AppStorage("DVIsDarockVisionActived") var isDarockVisionActived = false
        var body: some View {
            List {
                Section {
                    Button(action: {
                        tipWithText("\(String(isDebuggerAttached()))", symbol: "hammer.circle.fill")
                    }, label: {
                        Text(verbatim: "Present Debugger Attach Status")
                    })
                    Button(action: {
                        print(NSHomeDirectory())
                    }, label: {
                        Text(verbatim: "Print NSHomeDirectory")
                    })
                } header: {
                    Text(verbatim: "Debugger")
                }
                Section {
                    Button(action: {
                        tipWithText("\(ProcessInfo.processInfo.thermalState)", symbol: "hammer.circle.fill")
                    }, label: {
                        Text(verbatim: "Present Thermal State")
                    })
                } header: {
                    Text(verbatim: "Energy & Performance")
                }
                Section {
                    Button(action: {
                        tipWithText(String(getWebHistory().count), symbol: "hammer.circle.fill")
                    }, label: {
                        Text(verbatim: "Present History Count")
                    })
                } header: {
                    Text(verbatim: "Data & Cloud")
                }
                Section {
                    Button(action: {
                        isProPurchased = false
                        UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.set(false, forKey: "IsProWidgetsAvailable")
                        WidgetCenter.shared.reloadAllTimelines()
                        WidgetCenter.shared.invalidateConfigurationRecommendations()
                    }, label: {
                        Text(verbatim: "Reset Pro State")
                    })
                    Button(action: {
                        isProPurchased = true
                        UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.set(true, forKey: "IsProWidgetsAvailable")
                        WidgetCenter.shared.reloadAllTimelines()
                        WidgetCenter.shared.invalidateConfigurationRecommendations()
                    }, label: {
                        Text(verbatim: "Active Pro")
                    })
                    Button(action: {
                        isDarockVisionActived = false
                    }, label: {
                        Text(verbatim: "Reset Darock Vision")
                    })
                    Button(action: {
                        isDarockVisionActived = true
                    }, label: {
                        Text(verbatim: "Active Darock Vision")
                    })
                    Button(action: {
                        subscriptionExpirationDate = 0
                    }, label: {
                        Text(verbatim: "Reset Private Relay")
                    })
                    Button(action: {
                        subscriptionExpirationDate = Date.now.timeIntervalSince1970 + 3600 * 24 * 30
                    }, label: {
                        Text(verbatim: "Active Private Relay")
                    })
                } header: {
                    Text(verbatim: "Purchasing")
                }
                Section {
                    Button(action: {
                        do {
                            throw NSError(domain: "com.darock.DarockBrowser.TestError", code: 1)
                        } catch {
                            globalErrorHandler(error)
                        }
                    }, label: {
                        Text(verbatim: "Toggle an Internal Error")
                    })
                } header: {
                    Text(verbatim: "Error Handler")
                }
                Section {
                    Button(action: {
                        UserDefaults.standard.removeObject(forKey: "ShouldTipNewFeatures")
                        for i in 1...50 {
                            UserDefaults.standard.removeObject(forKey: "ShouldTipNewFeatures\(i)")
                        }
                    }, label: {
                        Text(verbatim: "Reset All What‘s New Screen State")
                    })
                    Button(action: {
                        isColorChangeButtonUnlocked = false
                        isColorChangeButtonEntered = false
                    }, label: {
                        Text(verbatim: "Reset TQCAccentColorHiddenButton")
                    })
                } header: {
                    Text(verbatim: "What’s New Screen & TQC")
                }
                Section {
                    Button(role: .destructive, action: {
                        fatalError("Internal Debugging Crash")
                    }, label: {
                        Text(verbatim: "Crash This App through Swift fatalError")
                    })
                    Button(role: .destructive, action: {
                        let e = NSException(name: NSExceptionName.mallocException, reason: "Internal Debugging Exception", userInfo: ["Info": "Debug"])
                        e.raise()
                    }, label: {
                        Text(verbatim: "Crash This App through NSException")
                    })
                } header: {
                    Text(verbatim: "Danger Zone")
                }
                Section {
                    NavigationLink(destination: { FeatureFlagsView() }, label: {
                        Label("Feature Flags", systemImage: "flag")
                    })
                }
            }
            .navigationTitle("Debugging")
            .toolbar {
                if #available(watchOS 10.5, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            WKExtension.shared().openSystemURL(URL(string: "https://darock.top/internal/radar/new?ProductName=Darock Browser")!)
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
        
        struct FeatureFlagsView: View {
            var body: some View {
                List {
                    
                }
                .navigationTitle("Feature Flags")
            }
        }
    }
}
