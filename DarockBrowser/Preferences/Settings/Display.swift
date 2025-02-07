//
//  Display.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI

extension SettingsView {
    struct DisplaySettingsView: View {
        @AppStorage("DBIsAutoAppearence") var isAutoAppearence = false
        @AppStorage("DBAutoAppearenceOptionTrigger") var autoAppearenceOptionTrigger = "CustomTimeRange"
        @AppStorage("DBAutoAppearenceOptionTimeRangeLight") var autoAppearenceOptionTimeRangeLight = "7:00"
        @AppStorage("DBAutoAppearenceOptionTimeRangeDark") var autoAppearenceOptionTimeRangeDark = "22:00"
        @AppStorage("ABIsReduceBrightness") var isReduceBrightness = false
        @AppStorage("ABReduceBrightnessLevel") var reduceBrightnessLevel = 0.2
        @AppStorage("IsWebMinFontSizeStricted") var isWebMinFontSizeStricted = false
        @AppStorage("WebMinFontSize") var webMinFontSize = 10.0
        var body: some View {
            List {
                Section {
                    Toggle("自动", isOn: $isAutoAppearence)
                    if isAutoAppearence {
                        NavigationLink(destination: { AutoAppearenceOptionsView() }, label: {
                            VStack(alignment: .leading) {
                                Text("选项")
                                Text({
                                    if autoAppearenceOptionTrigger == "Sun" {
                                        AppearenceManager.shared.currentAppearence == .light ? "日落前保持浅色外观" : "日出前保持深色外观"
                                    } else {
                                        AppearenceManager.shared.currentAppearence == .light ? "\(autoAppearenceOptionTimeRangeDark)前保持浅色外观"
                                        : "\(autoAppearenceOptionTimeRangeLight)前保持深色外观"
                                    }
                                }())
                                .font(.footnote)
                                .foregroundStyle(.gray)
                                .animation(.default, value: autoAppearenceOptionTrigger)
                            }
                        })
                    }
                    Toggle("降低亮度", isOn: $isReduceBrightness)
                    VStack {
                        Slider(value: $reduceBrightnessLevel, in: 0.0...0.8, step: 0.05) {
                            Text("降低亮度")
                        }
                        Text(String(format: "%.2f", reduceBrightnessLevel))
                    }
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                } header: {
                    Text("外观")
                } footer: {
                    Text("屏幕右上方的时间不会被降低亮度")
                }
                Section {
                    Toggle("限制最小字体大小", isOn: $isWebMinFontSizeStricted)
                    VStack {
                        Slider(value: $webMinFontSize, in: 10...50, step: 1) {
                            Text("字体大小")
                        }
                        Text(String(format: "%.0f", webMinFontSize))
                    }
                    .disabled(!isWebMinFontSizeStricted)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
            .navigationTitle("显示与亮度")
        }
        
        struct AutoAppearenceOptionsView: View {
            @AppStorage("DBAutoAppearenceOptionTrigger") var autoAppearenceOptionTrigger = "CustomTimeRange"
            @AppStorage("DBAutoAppearenceOptionTimeRangeLight") var autoAppearenceOptionTimeRangeLight = "7:00"
            @AppStorage("DBAutoAppearenceOptionTimeRangeDark") var autoAppearenceOptionTimeRangeDark = "22:00"
            @AppStorage("DBAutoAppearenceOptionEnableForReduceBrightness") var autoAppearenceOptionEnableForReduceBrightness = false
            @AppStorage("DBAutoAppearenceOptionEnableForWebForceDark") var autoAppearenceOptionEnableForWebForceDark = true
            @State var isLocationPermissionRequestInfoPresented = false
            @State var isSunPrivacySplashPresented = false
            @State var lightTimeSelectionHour = "7"
            @State var lightTimeSelectionMinute = "00"
            @State var darkTimeSelectionHour = "22"
            @State var darkTimeSelectionMinute = "00"
            var body: some View {
                Form {
                    List {
                        Section {} footer: {
                            Text("设定时间让外观自动更改。暗礁浏览器可能会等到你不使用屏幕时才执行外观切换。")
                        }
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    Picker("定时切换外观", selection: $autoAppearenceOptionTrigger) {
                        Text("日落到日出").tag("Sun")
                        Text("自定义时段").tag("CustomTimeRange")
                    }
                    .pickerStyle(.inline)
                    .onChange(of: autoAppearenceOptionTrigger) { _ in
                        if autoAppearenceOptionTrigger == "Sun" {
                            if CLLocationManager().authorizationStatus != .notDetermined {
                                CachedLocationManager.shared.updateCache {
                                    AppearenceManager.shared.updateAll()
                                }
                            } else {
                                isLocationPermissionRequestInfoPresented = true
                            }
                        }
                    }
                    List {
                        if autoAppearenceOptionTrigger == "Sun" {
                            Section {} footer: {
                                VStack(alignment: .leading) {
                                    HStack(spacing: 2) {
                                        Image(systemName: "apple.logo")
                                        Text("天气")
                                    }
                                    Button(action: {
                                        isSunPrivacySplashPresented = true
                                    }, label: {
                                        Text("关于根据日落与日出切换外观与隐私…")
                                            .foregroundStyle(.blue)
                                    })
                                    .buttonStyle(.plain)
                                }
                            }
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .offset(y: -20)
                        }
                        if autoAppearenceOptionTrigger == "CustomTimeRange" {
                            Section {
                                NavigationLink(destination: {
                                    HourMinuteSelectorView(hour: $lightTimeSelectionHour, minute: $lightTimeSelectionMinute) {
                                        autoAppearenceOptionTimeRangeLight = "\(lightTimeSelectionHour):\(lightTimeSelectionMinute)"
                                    }
                                }, label: {
                                    HStack {
                                        Text("浅色")
                                        Spacer()
                                        Text(autoAppearenceOptionTimeRangeLight)
                                            .foregroundStyle(.gray)
                                    }
                                })
                                NavigationLink(destination: {
                                    HourMinuteSelectorView(hour: $darkTimeSelectionHour, minute: $darkTimeSelectionMinute) {
                                        autoAppearenceOptionTimeRangeDark = "\(darkTimeSelectionHour):\(darkTimeSelectionMinute)"
                                    }
                                }, label: {
                                    HStack {
                                        Text("深色")
                                        Spacer()
                                        Text(autoAppearenceOptionTimeRangeDark)
                                            .foregroundStyle(.gray)
                                    }
                                })
                            }
                        }
                        Section {
                            Toggle("降低屏幕亮度", isOn: $autoAppearenceOptionEnableForReduceBrightness)
                            Toggle("网页强制深色模式", isOn: $autoAppearenceOptionEnableForWebForceDark)
                        } header: {
                            Text("外观作用域")
                        }
                    }
                }
                .navigationTitle("外观选项")
                .sheet(isPresented: $isLocationPermissionRequestInfoPresented, content: { LocationPremissionView() })
                .sheet(isPresented: $isSunPrivacySplashPresented, content: { AboutSunAutoAppearenceAndPrivacy() })
                .onAppear {
                    let lightTimeSplited = autoAppearenceOptionTimeRangeLight.components(separatedBy: ":")
                    let darkTimeSplited = autoAppearenceOptionTimeRangeDark.components(separatedBy: ":")
                    lightTimeSelectionHour = lightTimeSplited[0]
                    lightTimeSelectionMinute = lightTimeSplited[1]
                    darkTimeSelectionHour = darkTimeSplited[0]
                    darkTimeSelectionMinute = darkTimeSplited[1]
                }
            }
            
            struct LocationPremissionView: View {
                @State var isPrivacySplashPresented = false
                var body: some View {
                    ScrollView {
                        VStack {
                            Image(systemName: "location.square.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            Text("需要定位服务权限以根据日落与日出切换外观")
                                .font(.system(size: 22))
                                .multilineTextAlignment(.center)
                                .padding(.vertical)
                            Button(action: {
                                isPrivacySplashPresented = true
                            }, label: {
                                HStack {
                                    Image(systemName: "hand.raised.square.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.blue)
                                    Text("关于根据日落与日出切换外观与隐私")
                                    Spacer()
                                }
                            })
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
                    .sheet(isPresented: $isPrivacySplashPresented, content: { AboutSunAutoAppearenceAndPrivacy() })
                    .onDisappear {
                        CachedLocationManager.shared.updateCache()
                    }
                }
            }
            struct AboutSunAutoAppearenceAndPrivacy: View {
                var body: some View {
                    PrivacyAboutView(
                        title: "关于根据日落与日出切换外观与隐私",
                        description: Text("你的位置信息将被发送至 Apple 天气以获取日落与日出时间。\(Text("进一步了解...").foregroundColor(.blue))"),
                        detailText: """
                        **根据日落与日出切换外观与隐私**
                        
                        暗礁浏览器和 Apple 天气旨在保护你的信息并可让你选择要共享的内容。
                        
                        在“定时切换外观”设置为“日落到日出”时，暗礁浏览器会在本地存储你当前的位置信息并向 Apple 天气发送副本以获取天气信息。位置信息仅被发送到 Apple 天气，不会与包括
                         Darock 在内的任何第三方共享。
                        
                        你可以随时在暗礁浏览器的设置中关闭“根据日落与日出切换外观”，一旦此选项关闭，暗礁浏览器将立即停止收集你的位置信息且不会发送到 Apple 天气，直到再次启用。
                        
                        访问 https://www.apple.com/privacy 了解 Apple 对数据的管理方式。
                        """
                    )
                }
            }
            struct HourMinuteSelectorView: View {
                @Binding var hour: String
                @Binding var minute: String
                var completion: () -> Void
                @Environment(\.presentationMode) private var presentationMode
                var body: some View {
                    VStack {
                        Spacer()
                        HStack(spacing: 2) {
                            Picker("小时", selection: $hour) {
                                ForEach(0..<24, id: \.self) { i in
                                    Text(String(i)).tag(String(i))
                                }
                            }
                            Text(verbatim: ":")
                            Picker("分钟", selection: $minute) {
                                ForEach(Array(0..<60).map {
                                    let str = String($0)
                                    if str.count >= 2 {
                                        return str
                                    } else {
                                        return "0" + str
                                    }
                                }, id: \.self) { i in
                                    Text(i).tag(i)
                                }
                            }
                        }
                        .font(.title2)
                        Button(action: {
                            completion()
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Text("完成")
                        })
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
}
