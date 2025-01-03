//
//  ProPurchaseView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/9/16.
//

import SwiftUI
import WidgetKit
import SwiftyStoreKit
import DarockFoundation

struct ProPurchaseView: View {
    @AppStorage("IsProPurchased") var isProPurchased = false
    @State var priceString = ""
    @State var isErrorLoadingPriceString = false
    @State var errorText = ""
    @State var isPurchasing = false
    @State var isRestoring = false
    @State var restoreErrorText = ""
    var body: some View {
        List {
            if !isProPurchased {
                Section {
                    Text("升级到暗礁浏览器 Pro 以解锁更多高级功能")
                        .centerAligned()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            Section {
                Label(title: {
                    Text("Darock 智能")
                }, icon: {
                    Image("DarockIntelligenceIcon")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .clipShape(Circle())
                })
                if #available(watchOS 10.0, *) {
                    Label("书签小组件", systemImage: "bookmark")
                    Label("快速搜索小组件", systemImage: "magnifyingglass")
                }
                NavigationLink(destination: { WebLayoutDescriptionView() }, label: {
                    HStack {
                        Label("更改网页视图与浏览菜单布局", systemImage: {
                            if #available(watchOS 11.0, *) {
                                "square.grid.3x3.square.badge.ellipsis"
                            } else {
                                "square.fill.text.grid.1x2"
                            }
                        }())
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .opacity(0.6)
                    }
                })
            } header: {
                Text("Pro 功能")
            }
            .listRowBackground(Color.clear)
            if #unavailable(watchOS 10.0) {
                Section {
                    Label("书签小组件", systemImage: "bookmark")
                    Label("快速搜索小组件", systemImage: "magnifyingglass")
                } header: {
                    Text("更新 watchOS 以解锁更多功能")
                }
                .listRowBackground(Color.clear)
            }
            if !isProPurchased {
                Section {
                    if !priceString.isEmpty {
                        Button(action: {
                            #if !targetEnvironment(simulator)
                            isPurchasing = true
                            SwiftyStoreKit.purchaseProduct("BrowserPro", quantity: 1, atomically: true) { result in
                                switch result {
                                case .success:
                                    isProPurchased = true
                                    UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.set(true, forKey: "IsProWidgetsAvailable")
                                    WidgetCenter.shared.reloadAllTimelines()
                                    WidgetCenter.shared.invalidateConfigurationRecommendations()
                                case .error(let error):
                                    errorText = error.localizedDescription
                                case .deferred:
                                    break
                                }
                                isPurchasing = false
                            }
                            #else
                            isProPurchased = true
                            UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.set(true, forKey: "IsProWidgetsAvailable")
                            WidgetCenter.shared.reloadAllTimelines()
                            WidgetCenter.shared.invalidateConfigurationRecommendations()
                            #endif
                        }, label: {
                            if !isAppBetaBuild {
                                if !isPurchasing {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("以 \(priceString) 购买")
                                        #if targetEnvironment(simulator)
                                        Text(verbatim: "Simulator Mode")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.gray)
                                        #endif
                                    }
                                } else {
                                    ProgressView()
                                        .centerAligned()
                                }
                            } else {
                                Text("无法使用 Beta 版本购买暗礁浏览器 Pro")
                            }
                        })
                        .disabled(isPurchasing || isAppBetaBuild)
                    } else {
                        if !isErrorLoadingPriceString {
                            HStack {
                                ProgressView()
                                    .frame(width: 20)
                                Text("正在载入购买信息...")
                            }
                        } else {
                            Text("载入购买信息时出错")
                        }
                    }
                } footer: {
                    Text(errorText)
                        .foregroundStyle(.red)
                }
                Section {
                    Button(action: {
                        isRestoring = true
                        SwiftyStoreKit.restorePurchases(atomically: true) { results in
                            if results.restoredPurchases.count > 0, results.restoredPurchases.first?.productId == "BrowserPro" {
                                isProPurchased = true
                                UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.set(true, forKey: "IsProWidgetsAvailable")
                                WidgetCenter.shared.reloadAllTimelines()
                                WidgetCenter.shared.invalidateConfigurationRecommendations()
                            } else {
                                restoreErrorText = "没有可恢复的项目"
                            }
                            isRestoring = false
                        }
                    }, label: {
                        HStack {
                            Text("恢复购买")
                            Spacer()
                            if isRestoring {
                                ProgressView()
                            }
                        }
                    })
                    .disabled(isRestoring)
                } footer: {
                    Text(restoreErrorText)
                        .foregroundStyle(.red)
                }
            } else {
                Section {
                    Text("暗礁浏览器 Pro 已激活")
                }
            }
        }
        .navigationTitle("暗礁浏览器 Pro")
        .navigationBarTitleDisplayMode(isProPurchased ? .inline : .large)
        .onAppear {
            if !isProPurchased {
                isErrorLoadingPriceString = false
                SwiftyStoreKit.retrieveProductsInfo(["BrowserPro"]) { result in
                    if let product = result.retrievedProducts.first {
                        priceString = product.localizedPrice!
                    } else {
                        isErrorLoadingPriceString = true
                    }
                }
            }
        }
    }
}

private struct WebLayoutDescriptionView: View {
    var body: some View {
        Form {
            Section {
                Text("激活暗礁浏览器 Pro 后，在\(Text("设置→浏览引擎").bold().foregroundColor(.blue))中更改布局设置")
            }
            Section {
                Text("此布局在网页视图顶部添加模糊效果，轻触模糊区域可返回网页顶部。")
            } header: {
                Text("网页视图布局 - 模糊顶部")
            }
            Section {
                Text("此布局在网页视图顶部工具栏添加返回按钮，轻触可返回上一页直至退出网页。")
            } header: {
                Text("网页视图布局 - 快速返回")
            }
            Section {
                Text("此布局紧凑排列浏览菜单中的各项目，网页浏览效率更高。")
            } header: {
                Text("浏览菜单布局 - 紧凑")
            }
        }
        .navigationTitle("网页视图与浏览菜单布局介绍")
    }
}
