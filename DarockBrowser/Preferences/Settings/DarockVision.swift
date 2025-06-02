//
//  DarockVision.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/6/2.
//

import SwiftUI
import SwiftyStoreKit

extension SettingsView {
    struct DarockVisionSettingsView: View {
        @AppStorage("DVIsDarockVisionActived") var isDarockVisionActived = false
        @AppStorage("DVIsDarockVisionAutoActivedFromOldVersion") var isDarockVisionAutoActivedFromOldVersion = false
        @State var priceString = ""
        @State var isErrorLoadingPriceString = false
        @State var errorText = ""
        @State var isPurchasing = false
        @State var isRestoring = false
        var body: some View {
            List {
                Section {
                    Text("激活 Darock Vision 以播放与下载网页内的视频。")
                        .listRowBackground(Color.clear)
                }
                Section {
                    if !isDarockVisionActived {
                        if !priceString.isEmpty {
                            Button(action: {
                                #if !targetEnvironment(simulator)
                                isPurchasing = true
                                SwiftyStoreKit.purchaseProduct("DarockVision", quantity: 1, atomically: true) { result in
                                    switch result {
                                    case .success:
                                        isDarockVisionActived = true
                                    case .error(let error):
                                        errorText = error.localizedDescription
                                    case .deferred:
                                        break
                                    }
                                    isPurchasing = false
                                }
                                #else
                                isDarockVisionActived = true
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
                                    Text("无法使用 Beta 版本购买 Darock Vision")
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
                        Button(action: {
                            isRestoring = true
                            SwiftyStoreKit.restorePurchases(atomically: true) { results in
                                if results.restoredPurchases.count > 0, results.restoredPurchases.first?.productId == "DarockVision" {
                                    isDarockVisionActived = true
                                } else {
                                    errorText = "没有可恢复的项目"
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
                    } else {
                        Text("Darock Vision 已激活")
                    }
                } footer: {
                    if isDarockVisionAutoActivedFromOldVersion {
                        Text("你在 Darock Vision 推出前使用过暗礁浏览器，因此已为你免费激活 Darock Vision。")
                    }
                    Text(errorText)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Darock Vision")
            .onAppear {
                if !isDarockVisionActived {
                    isErrorLoadingPriceString = false
                    SwiftyStoreKit.retrieveProductsInfo(["DarockVision"]) { result in
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
}
