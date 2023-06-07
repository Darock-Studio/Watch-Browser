//
//  ContentView.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//
import SwiftUI
import AuthenticationServices

struct ContentView: View {
    
    var body: some View {
        if #available(watchOS 10.0, *) {
            NavigationStack {
                #if FOR_NEW_OS
                MainView()
                    .containerBackground(Color(hex: 0x13A4FF).gradient, for: .navigation)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            NavigationLink(destination: {SettingsView()}, label: {
                                Image(systemName: "gear")
                            })
                        }
                    }
                #else
                MainView(withSetting: true)
                #endif
            }
        } else {
            NavigationView {
                MainView(withSetting: true)
            }
            .navigationViewStyle(.stack)
        }
    }
}

struct MainView: View {
    var withSetting: Bool = false
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("IsUseModifyKeyboard") var isUseModifyKeyboard = true
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @AppStorage("IsRecordHistory") var isRecordHistory = true
    @State var textOrURL = ""
    @State var goToButtonLabelText = "搜索"
    @State var isKeyboardPresented = false
    @State var isCookieTipPresented = false
    var body: some View {
        List {
            Section {
                if !isUseModifyKeyboard {
                    TextField("搜索或输入网址", text: $textOrURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .privacySensitive()
                        .onSubmit({
                            if textOrURL.isURL() {
                                goToButtonLabelText = "前往"
                            } else {
                                goToButtonLabelText = "搜索"
                            }
                        })
                } else {
                    Button(action: {
                        isKeyboardPresented = true
                    }, label: {
                        HStack {
                            Text(textOrURL != "" ? textOrURL : "搜索或输入网址")
                                .foregroundColor(textOrURL == "" ? Color.gray : Color.white)
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
                            goToButtonLabelText = "前往"
                        } else {
                            goToButtonLabelText = "搜索"
                        }
                    })
                }
                Button(action: {
                    if textOrURL.isURL() {
                        if !textOrURL.hasPrefix("http://") && !textOrURL.hasPrefix("https://") {
                            textOrURL = "http://" + textOrURL
                        }
                        let session = ASWebAuthenticationSession(
                            url: URL(string: textOrURL.urlEncoded())!,
                            callbackURLScheme: nil
                        ) { _, _ in
                            
                        }
                        session.prefersEphemeralWebBrowserSession = !isAllowCookie
                        session.start()
                    } else {
                        let session = ASWebAuthenticationSession(
                            url: URL(string: GetWebSearchedURL(textOrURL))!,
                            callbackURLScheme: nil
                        ) { _, _ in
                            
                        }
                        session.prefersEphemeralWebBrowserSession = !isAllowCookie
                        session.start()
                    }
                    if isRecordHistory {
                        if (UserDefaults.standard.stringArray(forKey: "WebHistory") != nil) ? (UserDefaults.standard.stringArray(forKey: "WebHistory")![UserDefaults.standard.stringArray(forKey: "WebHistory")!.count - 1] != (textOrURL.isURL() ? textOrURL : GetWebSearchedURL(textOrURL))) : true {
                            UserDefaults.standard.set((textOrURL.isURL() ? [textOrURL] : [GetWebSearchedURL(textOrURL)]) + (UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()), forKey: "WebHistory")
                        }
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Label(goToButtonLabelText, systemImage: goToButtonLabelText == "搜索" ? "magnifyingglass" : "globe")
                            .font(.system(size: 18))
                        Spacer()
                    }
                })
            }
            Section {
                NavigationLink(destination: {
                    BookmarkView()
                }, label: {
                    HStack {
                        Spacer()
                        Label("书签", systemImage: "bookmark")
                        Spacer()
                    }
                })
                NavigationLink(destination: {
                    HistoryView()
                }, label: {
                    HStack {
                        Spacer()
                        Label("历史记录", systemImage: "clock")
                        Spacer()
                    }
                })
                if withSetting {
                    NavigationLink(destination: {
                        SettingsView()
                    }, label: {
                        HStack {
                            Spacer()
                            Label("设置", systemImage: "gear")
                            Spacer()
                        }
                    })
                }
            }
        }
        .navigationTitle("暗礁浏览器")
        .navigationBarTitleDisplayMode(.large)
    }
    
    func GetWebSearchedURL(_ iUrl: String) -> String {
        var wisu = ""
        switch webSearch {
        case "必应":
            wisu = "https://www.bing.com/search?q=\(iUrl.urlEncoded())"
            break
        case "百度":
            wisu = "https://www.baidu.com/s?wd=\(iUrl.urlEncoded())"
            break
        case "谷歌":
            wisu = "https://www.google.com/search?q=\(iUrl.urlEncoded())"
            break
        case "搜狗":
            wisu = "https://www.sogou.com/web?query=\(iUrl.urlEncoded())"
            break
        default:
            wisu = "https://www.bing.com/search?q=\(iUrl.urlEncoded())"
            break
        }
        return wisu
    }
}

struct CookieTip: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    var body: some View {
        ScrollView {
            VStack {
                Text("开启Cookie后，每次访问网页前会出现如下页面，是否开启？")
                Group {
                    Spacer()
                        .frame(height: 26)
                    Text("“暗礁浏览器”想要使用“example.com”登录")
                        .fontWeight(.bold)
                    Text("这将允许App和网站共享你的信息。")
                    Button(action: {}, label: {
                        Text("取消")
                    })
                    .disabled(true)
                    Button(action: {}, label: {
                        Text("继续")
                    })
                    .disabled(true)
                    Spacer()
                        .frame(height: 26)
                }
                Button(action: {
                    isAllowCookie = true
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("开启")
                })
                Button(action: {
                    isAllowCookie = false
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("不开启")
                })
                Text("Darock 以及暗礁浏览器不会收集您的 Cookie 信息，所有信息均由 watchOS 处理。")
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
    
    //是否为URL
    func isURL() -> Bool {
        if self.contains(".com") || self.contains(".org") || self.contains(".net") || self.contains(".int") || self.contains(".edu") || self.contains(".gov") || self.contains(".mil") || self.contains(".arpa") || self.contains(".ac") || self.contains(".ae") || self.contains(".af") || self.contains(".ag") || self.contains(".ai") || self.contains(".al") || self.contains(".am") || self.contains(".ao") || self.contains(".aq") || self.contains(".ar") || self.contains(".as") || self.contains(".at") || self.contains(".au") || self.contains(".aw") || self.contains(".ax") || self.contains(".az") || self.contains(".ba") || self.contains(".bb") || self.contains(".bd") || self.contains(".be") || self.contains(".bf") || self.contains(".bg") || self.contains(".bh") || self.contains(".bi") || self.contains(".bj") || self.contains(".bm") || self.contains(".bn") || self.contains(".bo") || self.contains(".br") || self.contains(".bs") || self.contains(".bt") || self.contains(".bw") || self.contains(".by") || self.contains(".bz") || self.contains(".ca") || self.contains(".cc") || self.contains(".cd") || self.contains(".cf") || self.contains(".cg") || self.contains(".ch") || self.contains(".ci") || self.contains(".ck") || self.contains(".cl") || self.contains(".cm") || self.contains(".cn") || self.contains(".co") || self.contains(".cr") || self.contains(".cu") || self.contains(".cv") || self.contains(".cw") || self.contains(".cx") || self.contains(".cy") || self.contains(".cz") || self.contains(".de") || self.contains(".dj") || self.contains(".dk") || self.contains(".dm") || self.contains(".do") || self.contains(".dz") || self.contains(".ec") || self.contains(".ee") || self.contains(".eg") || self.contains(".er") || self.contains(".es") || self.contains(".et") || self.contains(".eu") || self.contains(".fi") || self.contains(".fk") || self.contains(".fm") || self.contains(".fo") || self.contains(".fr") || self.contains(".ga") || self.contains(".gd") || self.contains(".ge") || self.contains(".gf") || self.contains(".gg") || self.contains(".gh") || self.contains(".gi") || self.contains(".gl") || self.contains(".gm") || self.contains(".gn") || self.contains(".gp") || self.contains(".gq") || self.contains(".gr") || self.contains(".gs") || self.contains(".gt") || self.contains(".gu") || self.contains(".gw") || self.contains(".gy") || self.contains(".hk") || self.contains(".hm") || self.contains(".hn") || self.contains(".hr") || self.contains(".ht") || self.contains(".hu") || self.contains(".id") || self.contains(".ie") || self.contains(".il") || self.contains(".im") || self.contains(".in") || self.contains(".io") || self.contains(".iq") || self.contains(".ir") || self.contains(".is") || self.contains(".it") || self.contains(".je") || self.contains(".jm") || self.contains(".jo") || self.contains(".jp") || self.contains(".ke") || self.contains(".kg") || self.contains(".kh") || self.contains(".ki") || self.contains(".km") || self.contains(".kn") || self.contains(".kp") || self.contains(".kr") || self.contains(".kw") || self.contains(".ky") || self.contains(".kz") || self.contains(".la") || self.contains(".lb") || self.contains(".lc") || self.contains(".li") || self.contains(".lk") || self.contains(".lr") || self.contains(".ls") || self.contains(".lt") || self.contains(".lu") || self.contains(".lv") || self.contains(".ly") || self.contains(".ma") || self.contains(".mc") || self.contains(".md") || self.contains(".me") || self.contains(".mg") || self.contains(".mh") || self.contains(".mk") || self.contains(".ml") || self.contains(".mm") || self.contains(".mn") || self.contains(".mo") || self.contains(".mp") || self.contains(".mq") || self.contains(".mr") || self.contains(".ms") || self.contains(".mt") || self.contains(".mu") || self.contains(".mv") || self.contains(".mw") || self.contains(".mx") || self.contains(".my") || self.contains(".mz") || self.contains(".na") || self.contains(".mil") || self.contains(".gov") || self.contains(".mil") || self.contains(".gov") || self.contains(".mil") || self.contains(".gov") || self.contains(".nc") || self.contains(".ne") || self.contains(".nf") || self.contains(".ng") || self.contains(".ni") || self.contains(".nl") || self.contains(".no") || self.contains(".np") || self.contains(".nr") || self.contains(".nu") || self.contains(".nz") || self.contains(".om") || self.contains(".pa") || self.contains(".pe") || self.contains(".pf") || self.contains(".pg") || self.contains(".ph") || self.contains(".pk") || self.contains(".pl") || self.contains(".pm") || self.contains(".pn") || self.contains(".pr") || self.contains(".ps") || self.contains(".pt") || self.contains(".pw") || self.contains(".py") || self.contains(".qa") || self.contains(".re") || self.contains(".ro") || self.contains(".rs") || self.contains(".ru") || self.contains(".rw") || self.contains(".sa") || self.contains(".sb") || self.contains(".sc") || self.contains(".sd") || self.contains(".se") || self.contains(".sg") || self.contains(".sh") || self.contains(".si") || self.contains(".sk") || self.contains(".sl") || self.contains(".sm") || self.contains(".sn") || self.contains(".so") || self.contains(".sr") || self.contains(".ss") || self.contains(".st") || self.contains(".su") || self.contains(".sv") || self.contains(".sx") || self.contains(".sy") || self.contains(".sz") || self.contains(".tc") || self.contains(".td") || self.contains(".tf") || self.contains(".tg") || self.contains(".th") || self.contains(".tj") || self.contains(".tk") || self.contains(".tl") || self.contains(".tm") || self.contains(".tn") || self.contains(".to") || self.contains(".tr") || self.contains(".tt") || self.contains(".tv") || self.contains(".tw") || self.contains(".tz") || self.contains(".ua") || self.contains(".ug") || self.contains(".uk") || self.contains(".us") || self.contains(".uy") || self.contains(".uz") || self.contains(".va") || self.contains(".vc") || self.contains(".ve") || self.contains(".vg") || self.contains(".vi") || self.contains(".vn") || self.contains(".vu") || self.contains(".wf") || self.contains(".ws") || self.contains(".ye") || self.contains(".yt") || self.contains(".za") || self.contains(".zm") || self.contains(".zw") || self.contains(".xyz") || self.contains(".ltd") || self.contains(".top") || self.contains(".cc") || self.contains(".group") || self.contains(".shop") || self.contains(".vip") || self.contains(".site") || self.contains(".art") || self.contains(".club") || self.contains(".wiki") || self.contains(".online") || self.contains(".cloud") || self.contains(".fun") || self.contains(".store") || self.contains(".wang") || self.contains(".tech") || self.contains(".pro") || self.contains(".biz") || self.contains(".space") || self.contains(".link") || self.contains(".info") || self.contains(".team") || self.contains(".mobi") || self.contains(".city") || self.contains(".life") || self.contains(".life") || self.contains(".zone") || self.contains(".asia") || self.contains(".host") || self.contains(".website") || self.contains(".world") || self.contains(".center") || self.contains(".cool") || self.contains(".ren") || self.contains(".company") || self.contains(".plus") || self.contains(".video") || self.contains(".pub") || self.contains(".email") || self.contains(".live") || self.contains(".run") || self.contains(".love") || self.contains(".show") || self.contains(".work") || self.contains(".ink") || self.contains(".fund") || self.contains(".red") || self.contains(".chat") || self.contains(".today") || self.contains(".press") || self.contains(".social") || self.contains(".gold") || self.contains(".design") || self.contains(".auto") || self.contains(".guru") || self.contains(".black") || self.contains(".blue") || self.contains(".green") || self.contains(".pink") || self.contains(".poker") || self.contains(".news") {
            return true
        } else if self.hasPrefix("http://") || self.hasPrefix("https://") {
            return true
        } else {
            return false
        }
    }
}

extension Color {
    init(hex: Int, alpha: Double = 1) {
        let components = (
            R: Double((hex >> 16) & 0xff) / 255,
            G: Double((hex >> 08) & 0xff) / 255,
            B: Double((hex >> 00) & 0xff) / 255
        )
        self.init(
            .sRGB,
            red: components.R,
            green: components.G,
            blue: components.B,
            opacity: alpha
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
