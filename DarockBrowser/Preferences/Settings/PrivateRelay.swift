//
//  PrivateRelay.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/3/16.
//

import SwiftUI
import DarockUI
import SwiftyStoreKit

extension SettingsView {
    struct PrivateRelaySettingsView: View {
        @AppStorage("PRSelectedCountry") var selectedCountry = ""
        @AppStorage("PRSubscriptionExpirationDate") var subscriptionExpirationDate = 0.0
        @AppStorage("PRIsPrivateRelayEnabled") var isPrivateRelayEnabled = false
        @State var isCountrySelectorPresented = false
        @State var isPrivacySplashPresented = false
        @State var isPurchasing = false
        @State var subscriptionPriceText = String(localized: "订阅")
        @State var purchasingErrorText = ""
        @State var isRestoring = false
        var body: some View {
            Form {
                Section {
                    if !selectedCountry.isEmpty {
                        if selectedCountry != "中国大陆" {
                            if subscriptionExpirationDate > Date.now.timeIntervalSince1970 {
                                Toggle("专用代理", isOn: $isPrivateRelayEnabled)
                            } else if subscriptionExpirationDate == 0.0 {
                                Text("未订阅")
                            } else {
                                Text("订阅已于\({ let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .medium; return df.string(from: Date(timeIntervalSince1970: subscriptionExpirationDate)) }())过期")
                            }
                        } else {
                            Text("专用代理在你所在的国家或地区不可用")
                        }
                    }
                } footer: {
                    VStack(alignment: .leading) {
                        Text("专用代理会隐藏你的 IP 地址和暗礁浏览器中的浏览活动，从而包括 Darock 在内，任何人都无法查看你的身份和你访问的站点。")
                        Text("一些网站可能无法在专用代理下工作。")
                        Button(action: {
                            isPrivacySplashPresented = true
                        }, label: {
                            Text("关于专用代理与隐私...")
                                .foregroundStyle(.blue)
                        })
                        .buttonStyle(.plain)
                    }
                }
                if !selectedCountry.isEmpty && selectedCountry != "中国大陆" {
                    Section {
                        if subscriptionExpirationDate > Date.now.timeIntervalSince1970 {
                            Text("订阅将于\({ let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .medium; return df.string(from: Date(timeIntervalSince1970: subscriptionExpirationDate)) }())过期")
                                .listRowBackground(Color.clear)
                        } else {
                            Button(action: {
                                #if !targetEnvironment(simulator)
                                purchase(item: "private_relay")
                                #else
                                subscriptionExpirationDate = Date.now.timeIntervalSince1970 + 3600 * 24 * 30
                                #endif
                            }, label: {
                                if !isPurchasing {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(subscriptionPriceText)
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
                            })
                            .disabled(isPurchasing)
                            Button(action: {
                                isRestoring = true
                                SwiftyStoreKit.restorePurchases(atomically: true) { results in
                                    if results.restoredPurchases.count > 0 {
                                        verifyPurchase(item: "private_relay")
                                    } else {
                                        isRestoring = false
                                    }
                                }
                            }, label: {
                                if !isRestoring {
                                    Text("恢复购买")
                                } else {
                                    ProgressView()
                                }
                            })
                            .disabled(isRestoring)
                        }
                    } header: {
                        Text("订阅")
                    } footer: {
                        VStack(alignment: .leading) {
                            if !purchasingErrorText.isEmpty {
                                Text(purchasingErrorText)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                            }
                            Text("条款与条件")
                                .foregroundStyle(.blue)
                                .onTapGesture {
                                    AdvancedWebViewController.shared.present(
                                        "https://darock.top/darockbrowser/relay-license",
                                        overrideOldWebView: .alwaysLegacy
                                    )
                                }
                            Text("隐私策略")
                                .foregroundStyle(.blue)
                                .onTapGesture {
                                    AdvancedWebViewController.shared.present("https://darock.top/darockbrowser/privacy", overrideOldWebView: .alwaysLegacy)
                                }
                        }
                    }
                }
                Section {
                    Button(action: {
                        isCountrySelectorPresented = true
                    }, label: {
                        VStack(alignment: .leading) {
                            Text("选择国家或地区")
                            if !selectedCountry.isEmpty {
                                Text(String(localized: .init(selectedCountry)))
                                    .font(.system(size: 14))
                                    .foregroundStyle(.gray)
                            }
                        }
                    })
                } header: {
                    Text("你的位置")
                } footer: {
                    Text("选择你的国家或地区以供确认服务可用性。这些信息不会被发送至设备外。")
                }
            }
            .navigationTitle("专用代理")
            .sheet(isPresented: $isCountrySelectorPresented, content: { CountrySelector() })
            .sheet(isPresented: $isPrivacySplashPresented, content: {
                PrivacyAboutView(
                    title: "关于专用代理与隐私",
                    description: Text("专用代理可让你以更安全和隐私的方式连接并浏览网站。\(Text("进一步了解...").foregroundColor(.blue))"),
                    detailText: """
                    **关于专用代理与隐私**
                    
                    专用代理会将暗礁浏览器的部分网络请求转发到 Darock 的专用代理服务器，以向网站隐藏你的 IP 地址与隐私信息。
                    
                    Darock 不会通过专用代理收集你的任何数据，所有通过 Darock 专用代理服务器转发的内容不会被记录。
                    """
                )
            })
            .onInitialAppear {
                SwiftyStoreKit.retrieveProductsInfo(["private_relay"]) { result in
                    if let product = result.retrievedProducts.first {
                        subscriptionPriceText = String(localized: "免费试用3天，随后以\(product.localizedPrice!)/月订阅专用代理")
                    } else if let invalidProductId = result.invalidProductIDs.first {
                        print("Invalid product identifier: \(invalidProductId)")
                        purchasingErrorText = String(localized: "App 内购买项目当前不可用，请稍后再试")
                    } else {
                        print("Error: \(String(describing: result.error))")
                        purchasingErrorText = String(localized: "App 内购买项目当前不可用，请稍后再试")
                    }
                }
            }
            .onChange(of: selectedCountry) { _ in
                if selectedCountry == "中国大陆" {
                    isPrivateRelayEnabled = false
                }
            }
        }
        
        func purchase(item: String) {
            isPurchasing = true
            SwiftyStoreKit.purchaseProduct(item, quantity: 1, atomically: true) { result in
                switch result {
                case .success(let purchase):
                    print("Purchase Success: \(purchase.productId)")
                    purchasingErrorText = String(localized: "正在验证购买...")
                    verifyPurchase(item: item)
                case .error(let error):
                    purchasingErrorText = error.localizedDescription
                case .deferred:
                    break
                }
            }
        }
        func verifyPurchase(item: String) {
            let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: "e6f95fe6efbf467084bc17ba1113e2fa")
            SwiftyStoreKit.verifyReceipt(using: appleValidator, forceRefresh: true) { result in
                switch result {
                case .success(let receipt):
                    let productId = item
                    let purchaseResult = SwiftyStoreKit.verifySubscription(
                        ofType: .autoRenewable,
                        productId: productId,
                        inReceipt: receipt)
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd"
                    switch purchaseResult {
                    case .purchased(let expiryDate, let items):
                        subscriptionExpirationDate = expiryDate.timeIntervalSince1970
                        print("\(productId) is valid until \(expiryDate)\n\(items)\n")
                    case .expired(let expiryDate, let items):
                        purchasingErrorText = String(localized: "验证购买时出错：订阅已过期")
                        print("\(productId) is expired since \(expiryDate)\n\(items)\n")
                    case .notPurchased:
                        purchasingErrorText = String(localized: "验证购买时出错：未订阅")
                        print("The user has never purchased \(productId)")
                    }
                case .error(let error):
                    print("Receipt verification failed: \(error)")
                }
                isPurchasing = false
                isRestoring = false
            }
        }
        
        struct CountrySelector: View {
            @Environment(\.presentationMode) var presentationMode
            @AppStorage("PRSelectedCountry") var selectedCountry = ""
            @State var newSelection = ""
            var body: some View {
                NavigationStack {
                    Form {
                        Picker("美国和加拿大", selection: $newSelection) {
                            Text("加拿大").tag("加拿大")
                            Text("美国").tag("美国")
                        }
                        .pickerStyle(.inline)
                        Picker("欧洲", selection: $newSelection) {
                            Text("阿尔巴尼亚").tag("阿尔巴尼亚")
                            Text("爱尔兰").tag("爱尔兰")
                            Text("爱沙尼亚").tag("爱沙尼亚")
                            Text("奥地利").tag("奥地利")
                            Text("白俄罗斯").tag("白俄罗斯")
                            Text("保加利亚").tag("保加利亚")
                            Text("北马其顿").tag("北马其顿")
                            Text("比利时").tag("比利时")
                            Text("冰岛").tag("冰岛")
                            Text("波兰").tag("波兰")
                            Text("波斯尼亚和黑塞哥维那").tag("波斯尼亚和黑塞哥维那")
                            Text("丹麦").tag("丹麦")
                            Text("德国").tag("德国")
                            Text("俄罗斯").tag("俄罗斯")
                            Text("法国").tag("法国")
                            Text("芬兰").tag("芬兰")
                            Text("荷兰").tag("荷兰")
                            Text("黑山").tag("黑山")
                            Text("捷克共和国").tag("捷克共和国")
                            Text("科索沃").tag("科索沃")
                            Text("克罗地亚").tag("克罗地亚")
                            Text("拉脱维亚").tag("拉脱维亚")
                            Text("立陶宛").tag("立陶宛")
                            Text("卢森堡").tag("卢森堡")
                            Text("罗马尼亚").tag("罗马尼亚")
                            Text("马耳他").tag("马耳他")
                            Text("摩尔多瓦").tag("摩尔多瓦")
                            Text("挪威").tag("挪威")
                            Text("葡萄牙").tag("葡萄牙")
                            Text("瑞典").tag("瑞典")
                            Text("瑞士").tag("瑞士")
                            Text("塞尔维亚").tag("塞尔维亚")
                            Text("塞浦路斯").tag("塞浦路斯")
                            Text("斯洛伐克").tag("斯洛伐克")
                            Text("斯洛文尼亚").tag("斯洛文尼亚")
                            Text("土耳其").tag("土耳其")
                            Text("乌克兰").tag("乌克兰")
                            Text("西班牙").tag("西班牙")
                            Text("希腊").tag("希腊")
                            Text("匈牙利").tag("匈牙利")
                            Text("意大利").tag("意大利")
                            Text("英国").tag("英国")
                        }
                        .pickerStyle(.inline)
                        Picker("非洲、中东和印度", selection: $newSelection) {
                            Text("阿尔及利亚").tag("阿尔及利亚")
                            Text("阿富汗").tag("阿富汗")
                            Text("阿拉伯联合酋长国").tag("阿拉伯联合酋长国")
                            Text("阿曼").tag("阿曼")
                            Text("阿塞拜疆").tag("阿塞拜疆")
                            Text("埃及").tag("埃及")
                            Text("安哥拉").tag("安哥拉")
                            Text("巴林").tag("巴林")
                            Text("贝宁").tag("贝宁")
                            Text("博茨瓦纳").tag("博茨瓦纳")
                            Text("布基纳法索").tag("布基纳法索")
                            Text("佛得角").tag("佛得角")
                            Text("冈比亚").tag("冈比亚")
                            Text("刚果共和国").tag("刚果共和国")
                            Text("刚果民主共和国").tag("刚果民主共和国")
                            Text("格鲁吉亚").tag("格鲁吉亚")
                            Text("几内亚比绍").tag("几内亚比绍")
                            Text("加纳").tag("加纳")
                            Text("加蓬").tag("加蓬")
                            Text("津巴布韦").tag("津巴布韦")
                            Text("喀麦隆").tag("喀麦隆")
                            Text("卡塔尔").tag("卡塔尔")
                            Text("科特迪瓦").tag("科特迪瓦")
                            Text("科威特").tag("科威特")
                            Text("肯尼亚").tag("肯尼亚")
                            Text("黎巴嫩").tag("黎巴嫩")
                            Text("利比里亚").tag("利比里亚")
                            Text("利比亚").tag("利比亚")
                            Text("卢旺达").tag("卢旺达")
                            Text("马达加斯加").tag("马达加斯加")
                            Text("马拉维").tag("马拉维")
                            Text("马里").tag("马里")
                            Text("毛里求斯").tag("毛里求斯")
                            Text("毛里塔尼亚").tag("毛里塔尼亚")
                            Text("摩洛哥").tag("摩洛哥")
                            Text("莫桑比克").tag("莫桑比克")
                            Text("纳米比亚").tag("纳米比亚")
                            Text("南非").tag("南非")
                            Text("尼日尔").tag("尼日尔")
                            Text("尼日利亚").tag("尼日利亚")
                            Text("塞拉利昂").tag("塞拉利昂")
                            Text("塞内加尔").tag("塞内加尔")
                            Text("塞舌尔").tag("塞舌尔")
                            Text("沙特阿拉伯").tag("沙特阿拉伯")
                            Text("圣多美和普林西比").tag("圣多美和普林西比")
                            Text("斯威士兰").tag("斯威士兰")
                            Text("坦桑尼亚").tag("坦桑尼亚")
                            Text("突尼斯").tag("突尼斯")
                            Text("乌干达").tag("乌干达")
                            Text("亚美尼亚").tag("亚美尼亚")
                            Text("也门").tag("也门")
                            Text("伊拉克").tag("伊拉克")
                            Text("以色列").tag("以色列")
                            Text("印度").tag("印度")
                            Text("约旦").tag("约旦")
                            Text("赞比亚").tag("赞比亚")
                            Text("乍得").tag("乍得")
                        }
                        .pickerStyle(.inline)
                        Picker("拉丁美洲和加勒比海地区", selection: $newSelection) {
                            Text("阿根廷").tag("阿根廷")
                            Text("安圭拉").tag("安圭拉")
                            Text("安提瓜和巴布达").tag("安提瓜和巴布达")
                            Text("巴巴多斯").tag("巴巴多斯")
                            Text("巴哈马").tag("巴哈马")
                            Text("巴拉圭").tag("巴拉圭")
                            Text("巴拿马").tag("巴拿马")
                            Text("巴西").tag("巴西")
                            Text("百慕大").tag("百慕大")
                            Text("秘鲁").tag("秘鲁")
                            Text("玻利维亚").tag("玻利维亚")
                            Text("伯利兹").tag("伯利兹")
                            Text("多米尼加共和国").tag("多米尼加共和国")
                            Text("多米尼克").tag("多米尼克")
                            Text("厄瓜多尔").tag("厄瓜多尔")
                            Text("哥伦比亚").tag("哥伦比亚")
                            Text("哥斯达黎加").tag("哥斯达黎加")
                            Text("格林纳达").tag("格林纳达")
                            Text("圭亚那").tag("圭亚那")
                            Text("洪都拉斯").tag("洪都拉斯")
                            Text("开曼群岛").tag("开曼群岛")
                            Text("蒙特塞拉特").tag("蒙特塞拉特")
                            Text("墨西哥").tag("墨西哥")
                            Text("尼加拉瓜").tag("尼加拉瓜")
                            Text("萨尔瓦多").tag("萨尔瓦多")
                            Text("圣基茨和尼维斯").tag("圣基茨和尼维斯")
                            Text("圣卢西亚").tag("圣卢西亚")
                            Text("圣文森特和格林纳丁斯").tag("圣文森特和格林纳丁斯")
                            Text("苏里南").tag("苏里南")
                            Text("特克斯和凯科斯群岛").tag("特克斯和凯科斯群岛")
                            Text("特立尼达和多巴哥").tag("特立尼达和多巴哥")
                            Text("危地马拉").tag("危地马拉")
                            Text("委内瑞拉").tag("委内瑞拉")
                            Text("乌拉圭").tag("乌拉圭")
                            Text("牙买加").tag("牙买加")
                            Text("英属维尔京群岛").tag("英属维尔京群岛")
                            Text("智利").tag("智利")
                        }
                        .pickerStyle(.inline)
                        Picker("亚太地区", selection: $newSelection) {
                            Text("澳大利亚").tag("澳大利亚")
                            Text("澳门").tag("澳门")
                            Text("巴布亚新几内亚").tag("巴布亚新几内亚")
                            Text("巴基斯坦").tag("巴基斯坦")
                            Text("不丹").tag("不丹")
                            Text("菲律宾").tag("菲律宾")
                            Text("斐济").tag("斐济")
                            Text("哈萨克斯坦").tag("哈萨克斯坦")
                            Text("韩国").tag("韩国")
                            Text("吉尔吉斯斯坦").tag("吉尔吉斯斯坦")
                            Text("柬埔寨").tag("柬埔寨")
                            Text("老挝").tag("老挝")
                            Text("马尔代夫").tag("马尔代夫")
                            Text("马来西亚").tag("马来西亚")
                            Text("蒙古").tag("蒙古")
                            Text("密克罗尼西亚").tag("密克罗尼西亚")
                            Text("缅甸").tag("缅甸")
                            Text("瑙鲁").tag("瑙鲁")
                            Text("尼泊尔").tag("尼泊尔")
                            Text("帕劳").tag("帕劳")
                            Text("日本").tag("日本")
                            Text("斯里兰卡").tag("斯里兰卡")
                            Text("所罗门群岛").tag("所罗门群岛")
                            Text("塔吉克斯坦").tag("塔吉克斯坦")
                            Text("台湾").tag("台湾")
                            Text("泰国").tag("泰国")
                            Text("汤加").tag("汤加")
                            Text("土库曼斯坦").tag("土库曼斯坦")
                            Text("瓦努阿图").tag("瓦努阿图")
                            Text("文莱").tag("文莱")
                            Text("乌兹别克斯坦").tag("乌兹别克斯坦")
                            Text("香港").tag("香港")
                            Text("新加坡").tag("新加坡")
                            Text("新西兰").tag("新西兰")
                            Text("印度尼西亚").tag("印度尼西亚")
                            Text("越南").tag("越南")
                            Text("中国大陆").tag("中国大陆")
                        }
                        .pickerStyle(.inline)
                    }
                    .navigationTitle("选择国家或地区")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(action: {
                                selectedCountry = newSelection
                                presentationMode.wrappedValue.dismiss()
                            }, label: {
                                Image(systemName: "checkmark")
                            })
                        }
                    }
                }
                .onAppear {
                    newSelection = selectedCountry
                }
            }
        }
    }
}
