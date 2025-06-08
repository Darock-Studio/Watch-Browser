//
//  ClusterTipView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 7/28/24.
//

import DarockUI

struct ClusterTipView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        List {
            Section {
                Text("已安装暗礁文件")
                    .font(.system(size: 20, weight: .bold))
                Text("现在，可将暗礁浏览器的本地文件分享到暗礁文件")
            }
            .listRowBackground(Color.clear)
            Section {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("我知道了")
                })
            }
        }
    }
}
