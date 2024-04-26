//
//  PrivateBrowsingView.swift
//  WatchBrowser Watch App
//
//  Created by WindowsMEMZ on 2024/3/17.
//

import SwiftUI
import DarockKit
import Alamofire
import SwiftyJSON
import AuthenticationServices

struct PrivateBrowsingView: View {
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("ModifyKeyboard") var ModifyKeyboard = false
    @AppStorage("IsSearchEngineShortcutEnabled") var isSearchEngineShortcutEnabled = true
    @State var textOrURL = ""
    @State var goToButtonLabelText: LocalizedStringKey = "Home.search"
    @State var isKeyboardPresented = false
    var body: some View {
        List {
            Section {
                Group {
                    if !ModifyKeyboard {
                        TextField("Home.search-or-URL", text: $textOrURL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .privacySensitive()
                            .onSubmit({
                                if textOrURL.isURL() {
                                    goToButtonLabelText = "Home.go"
                                } else {
                                    if isSearchEngineShortcutEnabled {
                                        if textOrURL.hasPrefix("bing") {
                                            goToButtonLabelText = "Home.search.bing"
                                        } else if textOrURL.hasPrefix("baidu") {
                                            goToButtonLabelText = "Home.search.baidu"
                                        } else if textOrURL.hasPrefix("google") {
                                            goToButtonLabelText = "Home.search.google"
                                        } else if textOrURL.hasPrefix("sogou") {
                                            goToButtonLabelText = "Home.search.sogou"
                                        } else {
                                            goToButtonLabelText = "Home.search"
                                        }
                                    } else {
                                        goToButtonLabelText = "Home.search"
                                    }
                                }
                            })
                    } else {
                        Button(action: {
                            isKeyboardPresented = true
                        }, label: {
                            HStack {
                                Text(!textOrURL.isEmpty ? textOrURL : String(localized: "Home.search-or-URL"))
                                    .foregroundColor(textOrURL.isEmpty ? Color.gray : Color.white)
                                    .privacySensitive()
                                Spacer()
                            }
                        })
                        .sheet(isPresented: $isKeyboardPresented, content: {
                            ExtKeyboardView(startText: textOrURL) { ott in
                                textOrURL = ott
                            }
                        })
                        .onChange(of: textOrURL, perform: { value in
                            if value.isURL() {
                                goToButtonLabelText = "Home.go"
                            } else {
                                if isSearchEngineShortcutEnabled {
                                    if value.hasPrefix("bing") {
                                        goToButtonLabelText = "Home.search.bing"
                                    } else if value.hasPrefix("baidu") {
                                        goToButtonLabelText = "Home.search.baidu"
                                    } else if value.hasPrefix("google") {
                                        goToButtonLabelText = "Home.search.google"
                                    } else if value.hasPrefix("sogou") {
                                        goToButtonLabelText = "Home.search.sogou"
                                    } else {
                                        goToButtonLabelText = "Home.search"
                                    }
                                } else {
                                    goToButtonLabelText = "Home.search"
                                }
                            }
                        })
                    }
                }
                .swipeActions {
                    if textOrURL != "" {
                        Button(role: .destructive, action: {
                            textOrURL = ""
                        }, label: {
                            Image(systemName: "xmark.bin.fill")
                        })
                    }
                }
                Button(action: {
                    if textOrURL.isURL() {
                        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
                            textOrURL = "http://" + textOrURL
                        }
                        AdvancedWebViewController.sharedPrivacy.present(textOrURL.urlEncoded())
                    } else {
                        AdvancedWebViewController.sharedPrivacy.present(GetWebSearchedURL(textOrURL, webSearch: webSearch, isSearchEngineShortcutEnabled: isSearchEngineShortcutEnabled))
                    }
                    textOrURL = ""
                }, label: {
                    HStack {
                        Spacer()
                        Label(goToButtonLabelText, systemImage: goToButtonLabelText == "Home.search" ? "magnifyingglass" : "globe")
                            .font(.system(size: 18))
                        Spacer()
                    }
                })
            }
        }
        .navigationTitle("无痕浏览")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivateBrowsingView_Previews: PreviewProvider {
    static var previews: some View {
        PrivateBrowsingView()
    }
}
