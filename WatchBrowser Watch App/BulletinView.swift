//
//  BulletinView.swift
//  WatchBrowser Watch App
//
//  Created by 雷美淳 on 2023/6/23.
//

import SwiftUI

struct BulletinView: View {
    @AppStorage("isBulletinPresenting") var isBulletinPresenting = true
    @AppStorage("isNewBulletinUnread") var isNewBulletinUnread = true
    @AppStorage("BulletinTitle") var BulletinTitle = "招新"
    @AppStorage("BulletinContent") var BulletinContent = "暗礁工作室招新啦，有代码、美术、宣传才能的小伙伴欢迎加入！ 加群或联系QQ 3245146430了解详情"
    var body: some View {
        if #available(watchOS 9.0, *) {
            NavigationStack {
                List {
                    Text(BulletinContent)
                    Button(action: {
                        isNewBulletinUnread.toggle()
                    }, label: {
                        Text("标记为\(isNewBulletinUnread ? "已阅" : "未读")")
                    })
                }
            }
            .navigationTitle(BulletinTitle.isEmpty ? "公告" : BulletinTitle)
            .onAppear(perform: {
                isNewBulletinUnread = false
            })
        } else {
            NavigationView {
                ScrollView {
                    Text(BulletinContent)
                }
            }
            .navigationTitle(BulletinTitle.isEmpty ? "公告" : BulletinTitle)
            .onAppear(perform: {
                isNewBulletinUnread = true
            })
        }
    }
}

struct BulletinView_Previews: PreviewProvider {
    static var previews: some View {
        BulletinView()
    }
}
