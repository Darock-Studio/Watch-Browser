//
//  BrowsingPreference.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/3/8.
//

import SwiftUI
import DarockUI

extension SettingsView {
    @available(watchOS 10.0, *)
    struct BrowsingPreferenceSettingsView: View {
        var isShowingInStartup = false
        @AppStorage("IsUseTabBasedBrowsing") var isUseTabBasedBrowsing = true
        var body: some View {
            Form {
                if isShowingInStartup {
                    Text("您可以随时在设置中更改浏览偏好")
                        .multilineTextAlignment(.center)
                        .centerAligned()
                        .listRowBackground(Color.clear)
                }
                Button(action: {
                    isUseTabBasedBrowsing = true
                }, label: {
                    VStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 150, height: 60)
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 150, height: 60)
                                .mask {
                                    VStack {
                                        Rectangle()
                                            .frame(height: 30)
                                        Spacer()
                                    }
                                }
                            HStack {
                                if isUseTabBasedBrowsing {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                                Text("标签页浏览")
                            }
                        }
                    }
                    .centerAligned()
                })
                Button(action: {
                    isUseTabBasedBrowsing = false
                }, label: {
                    VStack {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 150, height: 40)
                            Text(verbatim: "Placeholder")
                                .lineLimit(1)
                                .redacted(reason: .placeholder)
                                .padding(.horizontal)
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 150, height: 40)
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.gray)
                                Image(systemName: "globe")
                                    .foregroundStyle(.gray)
                            }
                        }
                        HStack {
                            if !isUseTabBasedBrowsing {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                            Text("单页面浏览")
                        }
                    }
                    .centerAligned()
                })
            }
            .navigationTitle(isShowingInStartup ? "选择浏览偏好" : "浏览偏好")
        }
    }
}
