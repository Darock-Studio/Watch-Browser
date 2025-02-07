//
//  Legal.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI
import DarockFoundation
import TripleQuestionmarkCore
import AuthenticationServices

extension SettingsView.GeneralSettingsView {
    struct LegalView: View {
        var body: some View {
            List {
                Section {
                    NavigationLink(destination: {
                        ScrollView {
                            Text(try! String(contentsOf: Bundle.main.url(forResource: "LICENSE", withExtension: nil)!))
                        }
                        .navigationTitle("许可证")
                    }, label: {
                        Text("许可证")
                    })
                    NavigationLink(destination: { OpenSourceView() }, label: {
                        Text("开源协议许可")
                    })
                } header: {
                    Text("暗礁浏览器")
                }
                if NSLocale.current.language.languageCode!.identifier == "zh" {
                    Section {
                        Button(action: {
                            let session = ASWebAuthenticationSession(
                                url: URL(string: "https://beian.miit.gov.cn")!,
                                callbackURLScheme: nil
                            ) { _, _ in }
                            session.prefersEphemeralWebBrowserSession = true
                            session.start()
                        }, label: {
                            Text(verbatim: "蜀ICP备2024100233号-1A")
                        })
                    } header: {
                        Text("中国大陆ICP备案号")
                    }
                }
            }
            .navigationTitle("法律与监管")
        }
        
        struct OpenSourceView: View {
            @State var isTQCView1Presented = false
            var body: some View {
                List {
                    SinglePackageBlock(name: "AEXML", license: "MIT license")
                    SinglePackageBlock(name: "Alamofire", license: "MIT license")
                    SinglePackageBlock(name: "Cache", license: "MIT license")
                    SinglePackageBlock(name: "Cepheus", license: "Apache License 2.0")
                    SinglePackageBlock(name: "EFQRCode", license: "MIT license")
                    SinglePackageBlock(name: "EPUBKit", license: "MIT license")
                    SinglePackageBlock(name: "libwebp", license: "BSD-3-Clause license")
                    SinglePackageBlock(name: "MarqueeText", license: "MIT license")
                    SinglePackageBlock(name: "NetworkImage", license: "MIT license")
                    SinglePackageBlock(name: "Pictor", license: "Apache License 2.0")
                    SinglePackageBlock(name: "Punycode", license: "MIT license")
                    SinglePackageBlock(name: "SDWebImage", license: "MIT license")
                    SinglePackageBlock(name: "SDWebImagePDFCoder", license: "MIT license")
                    SinglePackageBlock(name: "SDWebImageSVGCoder", license: "MIT license")
                    SinglePackageBlock(name: "SDWebImageSwiftUI", license: "MIT license")
                    SinglePackageBlock(name: "SDWebImageWebPCoder", license: "MIT license")
                    SinglePackageBlock(name: "swift_qrcodejs", license: "MIT license")
                    SinglePackageBlock(name: "swift-markdown-ui", license: "MIT license")
                    SinglePackageBlock(name: "SwiftSoup", license: "MIT license")
                    SinglePackageBlock(name: "SwiftyJSON", license: "MIT license")
                    SinglePackageBlock(name: "Vela", license: "Apache License 2.0")
                    SinglePackageBlock(name: "Vortex", license: "MIT license")
                    SinglePackageBlock(name: "Zip", license: "MIT license")
                    SinglePackageBlock(name: "???Core", license: "???")
                        .onTapGesture {
                            isTQCView1Presented = true
                        }
                }
                .navigationTitle("开源协议许可")
                .sheet(isPresented: $isTQCView1Presented, content: {
                    TQCOnaniiView()
                        .onAppear {
                            requestString("https://fapi.darock.top:65535/analyze/add/DBTQCOnanii/\(Date.now.timeIntervalSince1970)".compatibleUrlEncoded()) { _, _ in }
                        }
                })
            }
            
            struct SinglePackageBlock: View {
                var name: String
                var license: String
                var body: some View {
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(Color(hex: 0xa06f2f))
                        VStack {
                            HStack {
                                Text(name)
                                Spacer()
                            }
                            HStack {
                                Text(license)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
}
