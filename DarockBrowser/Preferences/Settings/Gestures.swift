//
//  Gestures.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI

#if compiler(>=6)
extension SettingsView {
    struct GesturesSettingsView: View {
        @AppStorage("GSIsDoubleTapEnabled") var isDoubleTapEnabled = false
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: { DoubleTapSettingsView() }, label: {
                        VStack(alignment: .leading) {
                            Text("互点两下")
                            Text(isDoubleTapEnabled ? "开启" : "关闭")
                                .foregroundStyle(.gray)
                        }
                    })
                }
            }
            .navigationTitle("手势")
        }
        
        struct DoubleTapSettingsView: View {
            @AppStorage("GSIsDoubleTapEnabled") var isDoubleTapEnabled = false
            @AppStorage("GSGlobalAction") var globalAction = "None"
            @AppStorage("GSInWebAction") var inWebAction = "None"
            @AppStorage("GSOpenWebLink") var openWebLink = ""
            @AppStorage("GSQuickAvoidanceAction") var quickAvoidanceAction = "ShowEmpty"
            @State var isHistorySelectorPresented = false
            var body: some View {
                Form {
                    List {
                        Section {
                            Toggle("互点两下", isOn: $isDoubleTapEnabled)
                        } footer: {
                            if #available(watchOS 11.0, *), WKInterfaceDevice.supportsDoubleTapGesture {
                                Text("食指和拇指互点两下以执行指定的操作。互点两下必须已在系统“手势”设置中打开。")
                            } else {
                                Text("食指和拇指互点两下以执行指定的操作。需要先在系统设置→辅助功能中启用“快速操作”。")
                            }
                        }
                    }
                    if isDoubleTapEnabled {
                        Picker("全局操作", selection: $globalAction) {
                            Text("无").tag("None")
                            Text("打开网页").tag("OpenWeb")
                            Text("紧急回避").tag("QuickAvoidance")
                        }
                        .pickerStyle(.inline)
                        Picker("网页内操作", selection: $inWebAction) {
                            Text("无").tag("None")
                            Text("退出网页").tag("ExitWeb")
                            Text("重新载入网页").tag("ReloadWeb")
                            Text("紧急回避").tag("QuickAvoidance")
                        }
                        .pickerStyle(.inline)
                        List {
                            if globalAction == "OpenWeb" {
                                Section {
                                    TextField("链接", text: $openWebLink) {
                                        if !openWebLink.isURL() {
                                            openWebLink = ""
                                            tipWithText("网页链接无效", symbol: "xmark.circle.fill")
                                            return
                                        }
                                        if !openWebLink.hasPrefix("http://") && !openWebLink.hasPrefix("https://") {
                                            openWebLink = "http://" + openWebLink
                                        }
                                    }
                                    Button(action: {
                                        isHistorySelectorPresented = true
                                    }, label: {
                                        Label("从历史记录选择", systemImage: "clock.badge.checkmark")
                                    })
                                } header: {
                                    Text("打开网页行为")
                                }
                            }
                            if globalAction == "QuickAvoidance" || inWebAction == "QuickAvoidance" {
                                Section {
                                    Picker(selection: $quickAvoidanceAction, content: {
                                        Text("显示空屏幕").tag("ShowEmpty")
                                        Text("退出暗礁浏览器").tag("ExitApp")
                                    }, label: {})
                                    .pickerStyle(.inline)
                                    if quickAvoidanceAction == "ShowEmpty" {
                                        NavigationLink(destination: { ShowEmptyPreview(isActionGlobal: globalAction == "QuickAvoidance") }, label: {
                                            Text("预览...")
                                        })
                                    }
                                } header: {
                                    Text("紧急回避行为")
                                } footer: {
                                    if quickAvoidanceAction == "ExitApp" {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.yellow)
                                            Text("如果误触发手势，所有未保存的更改也将丢失！")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("互点两下")
                .sheet(isPresented: $isHistorySelectorPresented) {
                    NavigationStack {
                        HistoryView { sel in
                            openWebLink = sel
                            isHistorySelectorPresented = false
                        }
                        .navigationTitle("选取历史记录")
                    }
                }
            }
            
            struct ShowEmptyPreview: View {
                var isActionGlobal: Bool
                @State var isScreenCleared = false
                var body: some View {
                    ZStack {
                        if !isActionGlobal {
                            Button("") {
                                isScreenCleared = true
                            }
                            .compatibleDoubleTapGesture()
                            .minimumRenderableOpacity()
                            .allowsHitTesting(false)
                        }
                        ScrollView {
                            VStack {
                                ZStack {
                                    Color.blue
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                    Image(_internalSystemName: "hand.side.pinch.fill")
                                        .font(.system(size: 22))
                                }
                                Text("使用“互点两下”手势以显示空屏幕")
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical)
                                Text("轻触三下屏幕以恢复，或按下数码表冠以返回表盘。")
                                    .multilineTextAlignment(.center)
                            }
                        }
                        if isScreenCleared {
                            Color.black
                                .ignoresSafeArea()
                                .onTapGesture(count: 3) {
                                    isScreenCleared = false
                                }
                        }
                    }
                    .navigationBarBackButtonHidden(isScreenCleared)
                    ._statusBarHidden(isScreenCleared)
                }
            }
        }
    }
}
#endif
