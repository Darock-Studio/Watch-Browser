//
//  LaboratoryView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/6/6.
//

import SwiftUI

struct LaboratoryView: View {
    @AppStorage("IsFirstEnterLab") var isFirstEnterLab = true
    @AppStorage("LabHideDistractingItemsEnabled") var labHideDistractingItemsEnabled = false
    @AppStorage("LabTabBrowsingEnabled") var labTabBrowsingEnabled = false
    @State var isLabTipPresented = false
    var body: some View {
        List {
            Section {
                Toggle(isOn: $labHideDistractingItemsEnabled, label: {
                    VStack {
                        HStack {
                            Text("隐藏干扰项目")
                            Spacer()
                        }
                        HStack {
                            Text("BETA")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue)
                                }
                            Spacer()
                        }
                    }
                })
                Toggle(isOn: $labTabBrowsingEnabled, label: {
                    VStack {
                        HStack {
                            Text("标签页浏览")
                            Spacer()
                        }
                        HStack {
                            Text("BETA")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue)
                                }
                            Spacer()
                        }
                    }
                })
            }
        }
        .navigationTitle("实验室")
        .sheet(isPresented: $isLabTipPresented) {
            NavigationStack {
                List {
                    Section {
                        VStack {
                            Text("实验室")
                                .font(.title2)
                            Text("使用前提示")
                        }
                    }
                    .listRowBackground(Color.clear)
                    Section {
                        VStack {
                            HStack {
                                Text("每个实验项目会带有以下标签中的一个：")
                                Spacer()
                            }
                            HStack {
                                Text("ALPHA")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 5)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.yellow)
                                    }
                                Text("BETA")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue)
                                    }
                                Spacer()
                            }
                        }
                        Text("“ALPHA”代表目前不成熟的功能，我们不接受与此相关的反馈")
                        Text("“BETA”代表目前较为完整，但仍需验证的功能，欢迎为此类项目提交反馈")
                    }
                }
            }
        }
        .onAppear {
            if isFirstEnterLab {
                isLabTipPresented = true
                isFirstEnterLab = false
            }
        }
    }
}
