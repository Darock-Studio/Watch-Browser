//
//  BrowsingMenuView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/8/18.
//

import SwiftUI

struct BrowsingMenuView: View {
    var webView: WKWebView
    @Binding var webViewPresentationMode: PresentationMode
    var customDismissAction: (() -> Void)?
    @Environment(\.presentationMode) var presentationMode
    @State var isLoading = false
    @State var isBackListPresented = false
    @State var isForwardListPresented = false
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    Section {
                        Group {
                            HStack {
                                Button(action: {
                                    if !isLoading {
                                        webView.reload()
                                    } else {
                                        webView.stopLoading()
                                    }
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Image(systemName: isLoading ? "stop.fill" : "arrow.clockwise")
                                })
                                Button(action: {
                                    webView.goBack()
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Image(systemName: "chevron.backward")
                                })
                                .onTapGesture {
                                    webView.goBack()
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .onLongPressGesture(minimumDuration: 0.5) {
                                    isBackListPresented = true
                                }
                                .disabled(!webView.canGoBack)
                                Button(action: {
                                    webView.goForward()
                                    presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Image(systemName: "chevron.forward")
                                })
                                .onTapGesture {
                                    webView.goForward()
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .onLongPressGesture(minimumDuration: 0.5) {
                                    isForwardListPresented = true
                                }
                                .disabled(!webView.canGoForward)
                            }
                            Button(role: .destructive, action: {
                                if let customDismissAction {
                                    customDismissAction()
                                } else {
                                    webViewPresentationMode.dismiss()
                                }
                            }, label: {
                                HStack {
                                    Image(systemName: "escape")
                                    Text("退出")
                                }
                            })
                            if let currentUrl = webView.url?.absoluteString, !currentUrl.hasPrefix("file://") {
                                HStack {
//                                    Button(action: {
//                                        AdvancedWebViewController.shared.isOverrideDesktopWeb.toggle()
//                                        presentationMode.wrappedValue.dismiss()
//                                    }, label: {
//                                        Image(systemName: AdvancedWebViewController.shared.isOverrideDesktopWeb ? "applewatch" : "desktopcomputer")
//                                    })
                                    Button(action: {
                                        webViewPresentationMode.dismiss()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                            WWUIWebController.shared.present(currentUrl, overrideOldWebView: .alwaysLegacy)
                                        }
                                    }, label: {
                                        Image(systemName: "globe.badge.chevron.backward")
                                    })
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: 1000))
                    }
                    .listRowBackground(Color.clear)
                }
                .navigationTitle(webView.title ?? String(localized: "浏览菜单"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                        })
                    }
                }
            }
        }
        .sheet(isPresented: $isBackListPresented, content: { BackForwardListView(webView: webView, type: .back, menuPresentationMode: presentationMode) })
        .sheet(isPresented: $isForwardListPresented, content: { BackForwardListView(webView: webView, type: .forward, menuPresentationMode: presentationMode) })
        .onAppear {
            isLoading = webView.isLoading
        }
        .onReceive(webView.publisher(for: \.isLoading)) { loading in
            isLoading = loading
        }
    }
}

private struct BackForwardListView: View {
    var webView: WKWebView
    var type: `Type`
    @Binding var menuPresentationMode: PresentationMode
    @State var list = [WKBackForwardListItem]()
    var body: some View {
        NavigationStack {
            List {
                if !list.isEmpty {
                    ForEach(0..<list.count, id: \.self) { i in
                        Button(action: {
                            webView.go(to: list[i])
                            menuPresentationMode.dismiss()
                        }, label: {
                            if let title = list[i].title {
                                VStack(alignment: .leading) {
                                    Text(title)
                                    Text(list[i].url.absoluteString)
                                        .font(.system(size: 14))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .opacity(0.6)
                                }
                            } else {
                                Text(list[i].url.absoluteString)
                                    .lineLimit(3)
                                    .truncationMode(.middle)
                            }
                        })
                    }
                } else {
                    Text("空列表")
                }
            }
            .navigationTitle(type == .back ? "返回列表" : "前进列表")
        }
        .onAppear {
            if type == .back {
                list = webView.backForwardList.backList
            } else {
                list = webView.backForwardList.forwardList
            }
        }
    }
    
    enum `Type` {
        case back
        case forward
    }
}
