//
//  ShareView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/3/23.
//

import SwiftUI
import EFQRCode

struct ShareView: View {
    @Binding var linkToShare: String
    var body: some View {
        NavigationView {
            List {
                if #available(watchOS 9, *) {
                    if let surl = URL(string: linkToShare) {
                        ShareLink("共享表单", item: surl)
                    }
                }
                NavigationLink(destination: {
                    VStack {
                        Image(decorative: EFQRCode.generate(for: linkToShare)!, scale: 1)
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text("分享到 iPhone")
                    }
                }, label: {
                    Label("二维码", systemImage: "qrcode")
                })
            }
            .navigationTitle("分享方式")
        }
    }
}
