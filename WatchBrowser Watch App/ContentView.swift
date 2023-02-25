//
//  ContentView.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @AppStorage("WebSearch") var webSearch = 0
    @AppStorage("IsUseModifyKeyboard") var isUseModifyKeyboard = true
    @State var textOrURL = ""
    @State var goToButtonLabelText = "搜索"
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("抬腕浏览器")
                        .font(.system(size: 20))
                    if !isUseModifyKeyboard {
                        TextField("搜索或输入网址", text: $textOrURL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit({
                                if textOrURL.contains(".com") || textOrURL.contains(".top") || textOrURL.contains(".cn") || textOrURL.contains(".net") || textOrURL.contains(".xyz") || textOrURL.contains(".vip") || textOrURL.contains(".org") {
                                    goToButtonLabelText = "前往"
                                } else {
                                    goToButtonLabelText = "搜索"
                                }
                         })
                    } else {
                        Button(action: {
                            
                        }, label: {
                            Text(textOrURL != "" ? textOrURL : "搜索或输入网址")
                                .foregroundColor(textOrURL == "" ? Color.gray : Color.white)
                        })
                    }
                    Button(action: {
                        if textOrURL.contains(".com") || textOrURL.contains(".top") || textOrURL.contains(".cn") || textOrURL.contains(".net") || textOrURL.contains(".xyz") || textOrURL.contains(".vip") || textOrURL.contains(".org") {
                            if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
                                textOrURL = "http://" + textOrURL
                            }
                            let session = ASWebAuthenticationSession(
                                url: URL(string: textOrURL.urlEncoded())!,
                                callbackURLScheme: nil
                            ) { _, _ in
                                
                            }
                            // Makes the "Watch App Wants To Use example.com to Sign In" popup not show up
                            session.prefersEphemeralWebBrowserSession = true
                            session.start()
                        } else {
                            var wisu = ""
                            switch webSearch {
                            case 0:
                                wisu = "https://www.bing.com/search?q=\(textOrURL.urlEncoded())"
                                break
                            case 1:
                                wisu = "https://www.baidu.com/s?wd=\(textOrURL.urlEncoded())"
                                break
                            case 2:
                                wisu = "https://www.google.com/search?q=\(textOrURL.urlEncoded())"
                                break
                            case 3:
                                wisu = "https://www.sogou.com/web?query=\(textOrURL.urlEncoded())"
                                break
                            default:
                                break
                            }
                            let session = ASWebAuthenticationSession(
                                url: URL(string: wisu)!,
                                callbackURLScheme: nil
                            ) { _, _ in
                                
                            }
                            // Makes the "Watch App Wants To Use example.com to Sign In" popup not show up
                            session.prefersEphemeralWebBrowserSession = true
                            session.start()
                        }
                    }, label: {
                        Label(goToButtonLabelText, systemImage: goToButtonLabelText == "搜索" ? "magnifyingglass" : "globe")
                            .font(.system(size: 18))
                    })
                    Spacer()
                        .frame(height: 14)
                    NavigationLink(destination: {
                        BookmarkView()
                    }, label: {
                        Label("书签", systemImage: "bookmark")
                    })
                    NavigationLink(destination: {
                        EnginesView()
                    }, label: {
                        Label("更改搜索引擎", systemImage: "magnifyingglass.circle")
                    })
                    Toggle(isOn: $isUseModifyKeyboard) {
                        Text("使用自定义键盘")
                    }
                }
            }
        }
    }
}

extension String {
     
    //将原始的url编码为合法的url
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }
     
    //将编码后的url转换回原始的url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
