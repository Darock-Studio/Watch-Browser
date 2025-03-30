//
//  ProPurchaseView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/9/16.
//

import Vortex
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
    @State var tabSelection = 0
    @State var isWidgetTimeAnimating = false
    @State var isWidgetSearchAnimating = false
    @State var isWidgetBookmarkAnimating = false
    @State var isWidgetTextAnimating = false
    @State var quickButtonAnimationProperty = 0
    var body: some View {
        ifContainer({ if #available(watchOS 10, *) { true } else { false } }()) { content in
            if #available(watchOS 10, *) {
                ZStack {
                    TabView(selection: $tabSelection) {
                        content
                            .scrollIndicators(.never)
                    }
                    .tabViewStyle(.verticalPage)
                    .scrollIndicators(.never)
                    VStack {
                        Spacer()
                        if tabSelection == 1 && !isProPurchased {
                            Button(action: {
                                withAnimation {
                                    tabSelection = 2
                                }
                            }, label: {
                                Text("激活 Pro")
                            })
                            .background(Capsule().fill(Material.thin))
                            .padding(.bottom, 5)
                            .transition(.offset(y: 50))
                        }
                    }
                    .ignoresSafeArea()
                    .animation(.easeOut, value: tabSelection)
                }
                .navigationTitle({
                    return switch tabSelection {
                    case 1: Text("先刷重点")
                    default: Text("暗礁浏览器 Pro")
                    }
                }())
                .navigationBarTitleDisplayMode(.inline)
            }
        } false: { content in
            Form {
                content
            }
            .navigationTitle("暗礁浏览器 Pro")
            .navigationBarTitleDisplayMode(isProPurchased ? .inline : .large)
        } containing: {
            VStack {
                HStack(spacing: 0) {
                    VortexView(.init(
                        tags: ["star"],
                        shape: .ellipse(radius: 0.5),
                        birthRate: 15,
                        lifespan: 1,
                        speed: 0.15,
                        speedVariation: 0.2,
                        angle: .degrees(-90),
                        colors: .single(.init(red: 0, green: 0.667, blue: 0.843)),
                        size: 0.5,
                        sizeVariation: 0.5,
                        sizeMultiplierAtDeath: 0.01
                    )) {
                        Image(systemName: "star.fill")
                            .tag("star")
                    }
                    Image(systemName: "star.fill")
                        .font(.title)
                        .padding(.horizontal, -20)
                    VortexView(.init(
                        tags: ["star"],
                        shape: .ellipse(radius: 0.5),
                        birthRate: 15,
                        lifespan: 1,
                        speed: 0.15,
                        speedVariation: 0.2,
                        angle: .degrees(90),
                        colors: .single(.init(red: 0, green: 0.667, blue: 0.843)),
                        size: 0.5,
                        sizeVariation: 0.5,
                        sizeMultiplierAtDeath: 0.01
                    )) {
                        Image(systemName: "star.fill")
                            .tag("star")
                    }
                }
                .foregroundStyle(.accent)
                .frame(height: 80)
                .padding(.bottom, -20)
                Text("此刻的 Pro，不仅在此刻")
                    .multilineTextAlignment(.center)
                    .centerAligned()
                if #available(watchOS 10, *) {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            tabSelection = 2
                        }
                    }, label: {
                        Text("激活 Pro")
                    })
                    .background(Capsule().fill(Material.thin))
                    .padding(.bottom, 5)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .tag(0)
            List {
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
                    NavigationLink(destination: { ShortcutButtonDescriptionView() }, label: {
                        HStack {
                            Label("网页快捷按钮", systemImage: "button.programmable")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .opacity(0.6)
                        }
                    })
                    if #available(watchOS 10.0, *) {
                        Spacer()
                    }
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
            }
            .tag(1)
            if #available(watchOS 10, *) {
                ScrollView {
                    VStack {
                        VStack {
                            Text("Darock 智能")
                                .font(.system(size: 20, weight: .bold))
                            Image("DarockIntelligenceIcon")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            if NSLocale.current.language.languageCode!.identifier != "en" {
                                Text("Darock 智能可\(Text(verbatim: "总结网页摘要").foregroundColor(.white))，小屏幕浏览网页也能\(Text(verbatim: "简单轻松").foregroundColor(.white))")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.gray)
                            } else {
                                Text("Darock Intelligence can \(Text(verbatim: "summerize webpages").foregroundColor(.white)).")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                .tag(3)
                ZStack {
                    VStack {
                        Spacer()
                            .frame(height: 20)
                        HStack {
                            Spacer()
                            Text({
                                let calendar = Calendar.autoupdatingCurrent
                                var minute = String(calendar.component(.minute, from: .now))
                                if minute.count == 1 {
                                    minute = "0" + minute
                                }
                                return String("\(calendar.component(.hour, from: .now)):\(minute)")
                            }())
                            .font(.system(size: 50, weight: .semibold, design: .rounded))
                            Spacer()
                                .frame(width: 5)
                        }
                        .opacity(isWidgetTimeAnimating ? 1 : 0)
                        .offset(y: isWidgetTimeAnimating ? -20 : 0)
                        Spacer()
                        ZStack {
                            Label("使用暗礁浏览器搜索", systemImage: "magnifyingglass")
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.8))
                                .frame(width: 170, height: 60)
                        }
                        .opacity(isWidgetSearchAnimating ? 1 : 0)
                        .offset(y: isWidgetSearchAnimating ? -20 : 0)
                        Spacer()
                        ZStack {
                            VStack {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                    Text(verbatim: "Darock")
                                }
                                Text(verbatim: "https://darock.top")
                            }
                            .fontDesign(.rounded)
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.8))
                                .frame(width: 170, height: 60)
                        }
                        .opacity(isWidgetBookmarkAnimating ? 1 : 0)
                        .offset(y: isWidgetBookmarkAnimating ? -20 : 0)
                        Spacer()
                            .frame(height: 30)
                    }
                    .blur(radius: isWidgetTextAnimating ? 10 : 0)
                    if isWidgetTextAnimating {
                        Text("小组件，\n高效直达")
                            .font(.system(size: 30, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                .animation(.smooth, value: isWidgetTextAnimating)
                .ignoresSafeArea(edges: .vertical)
                .toolbar(.hidden)
                .onAppear {
                    setMainSceneHideStatusBarSubject.send(true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isWidgetTimeAnimating = true
                        } completion: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isWidgetSearchAnimating = true
                            } completion: {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isWidgetBookmarkAnimating = true
                                } completion: {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        isWidgetTextAnimating = true
                                    }
                                }
                            }
                        }
                    }
                }
                .onDisappear {
                    setMainSceneHideStatusBarSubject.send(false)
                    isWidgetTimeAnimating = false
                    isWidgetSearchAnimating = false
                    isWidgetBookmarkAnimating = false
                    isWidgetTextAnimating = false
                }
                .tag(4)
                ScrollView {
                    VStack {
                        Text("网页快捷按钮")
                            .font(.system(size: 20, weight: .bold))
                            .multilineTextAlignment(.center)
                        Spacer(minLength: 20)
                        HStack {
                            Image(systemName: "ellipsis.circle")
                                .opacity(quickButtonAnimationProperty > 0 ? 1 : 0)
                                .offset(y: quickButtonAnimationProperty > 0 ? 0 : 20)
                            Spacer()
                            Image(systemName: "chevron.backward")
                                .opacity(quickButtonAnimationProperty > 1 ? 1 : 0)
                                .offset(y: quickButtonAnimationProperty > 1 ? 0 : 20)
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .opacity(quickButtonAnimationProperty > 2 ? 1 : 0)
                                .offset(y: quickButtonAnimationProperty > 2 ? 0 : 20)
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .opacity(quickButtonAnimationProperty > 3 ? 1 : 0)
                                .offset(y: quickButtonAnimationProperty > 3 ? 0 : 20)
                            Spacer()
                            Image(systemName: "film.stack")
                                .opacity(quickButtonAnimationProperty > 4 ? 1 : 0)
                                .offset(y: quickButtonAnimationProperty > 4 ? 0 : 20)
                        }
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                        Spacer(minLength: 20)
                        Group {
                            if NSLocale.current.language.languageCode!.identifier != "en" {
                                Text("每个按钮的功能均可\(Text(verbatim: "自定义").foregroundColor(.white))，支持\(Text(verbatim: "快速返回").foregroundColor(.white))、\(Text(verbatim: "重新载入").foregroundColor(.white))以及\(Text(verbatim: "查看媒体").foregroundColor(.white))等多项功能。")
                            } else {
                                Text("Each button can be \(Text(verbatim: "customized").foregroundColor(.white)). Support \(Text(verbatim: "go back").foregroundColor(.white)), \(Text(verbatim: "reload").foregroundColor(.white)), \(Text(verbatim: "view media").foregroundColor(.white)) and so on.")
                            }
                        }
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.gray)
                        .opacity(quickButtonAnimationProperty > 4 ? 1 : 0)
                        .offset(y: quickButtonAnimationProperty > 4 ? 0 : 20)
                    }
                }
                .onAppear {
                    withAnimation(.easeOut) {
                        quickButtonAnimationProperty = 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut) {
                                quickButtonAnimationProperty = 2
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeOut) {
                                quickButtonAnimationProperty = 3
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            withAnimation(.easeOut) {
                                quickButtonAnimationProperty = 4
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation(.easeOut) {
                                quickButtonAnimationProperty = 5
                            }
                        }
                    }
                }
                .tag(5)
            }
            List {
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
            .tag(2)
        }
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

private struct ShortcutButtonDescriptionView: View {
    var body: some View {
        Form {
            Section {
                Text("激活暗礁浏览器 Pro 后，在\(Text("设置→浏览引擎→快捷按钮").bold().foregroundColor(.blue))中设置快捷按钮")
            }
            Section {
                Text("最多添加四个快捷按钮，按钮将显示在网页顶部，效果如下")
                HStack {
                    Image(systemName: "ellipsis.circle")
                    Spacer()
                    Image(systemName: "chevron.backward")
                    Spacer()
                    Image(systemName: "chevron.forward")
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                    Spacer()
                    Image(systemName: "film.stack")
                }
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            Section {
                Text("每个按钮的功能均可自定义，支持快速返回、重新载入以及查看媒体等多项功能。")
            }
        }
        .navigationTitle("网页快捷按钮介绍")
    }
}
