//
//  BingSearchView.swift
//  WatchBrowser Watch App
//
//  Created by WindowsMEMZ on 2023/6/30.
//

import SwiftUI
import DarockKit
import Alamofire
import SwiftyJSON
import AuthenticationServices

struct BingSearchView: View {
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @AppStorage("IsRecordHistory") var isRecordHistory = true
    @State var webDatas = [[String: String]]()
    var body: some View {
        List {
            if webDatas.count != 0 {
                ForEach(0...webDatas.count - 1, id: \.self) { i in
                    Button(action: {
                        let session = ASWebAuthenticationSession(
                            url: URL(string: webDatas[i]["URL"]!)!,
                            callbackURLScheme: nil
                        ) { _, _ in
                            
                        }
                        session.prefersEphemeralWebBrowserSession = !isAllowCookie
                        session.start()
                        
                        if isRecordHistory {
                            if (UserDefaults.standard.stringArray(forKey: "WebHistory") != nil) ? (UserDefaults.standard.stringArray(forKey: "WebHistory")![UserDefaults.standard.stringArray(forKey: "WebHistory")!.count - 1] != webDatas[i]["URL"]!) : true {
                                UserDefaults.standard.set([webDatas[i]["URL"]!] + (UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()), forKey: "WebHistory")
                            }
                        }
                    }, label: {
//                        VStack {
//                            Text(webDatas[i]["Title"]!)
//                                .font(.system(size: 18, weight: .bold))
//                                .foregroundColor(.blue)
//                                .lineLimit(3)
//                            Text(webDatas[i]["Snippet"]!)
//                                .font(.system(size: 15))
//                                .foregroundColor(.gray)
//                                .lineLimit(3)
//                        }
                        SearchResult(title: webDatas[i]["Title"]!, URL: webDatas[i]["URL"]!, discription: webDatas[i]["Snippet"]!)
                    })
                }
            }
        }
        .onAppear {
            let headers: HTTPHeaders = [
                "Ocp-Apim-Subscription-Key": "617f0bd1f8a840a39b486b83cc42bf22"
            ]
            DarockKit.Network.shared.requestJSON("https://api.bing.microsoft.com/v7.0/search?q=Darock", headers: headers) { respJson, isDone in
                if isDone {
                    let webs = respJson["webPages"]["value"]
                    for i in 0...webs.count - 1 {
                        webDatas.append(["Title": webs[i]["name"].string!, "URL": webs[i]["url"].string!, "Snippet": webs[i]["snippet"].string!])
                    }
                }
            }
        }
    }
}

struct SearchResult: View {
    var title: String
    var URL: String
    var discription: String
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                Text(URL)
                    .font(.footnote)
                Spacer(minLength: 5)
                Text(discription)
                    .foregroundStyle(.secondary)
                    .font(.caption2)
                    .lineLimit(4)
            }
            .padding(.vertical, 10.0)
            Spacer()
        }
    }
}

struct BingSearchView_Previews: PreviewProvider {
    static var previews: some View {
        BingSearchView()
    }
}
