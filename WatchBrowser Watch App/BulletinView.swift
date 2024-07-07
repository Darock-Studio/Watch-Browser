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
    @AppStorage("BulletinTitle") var bulletinTitle = ""
    @AppStorage("BulletinContent") var bulletinContent = ""
    var body: some View {
        if #available(watchOS 9.0, *) {
            NavigationStack {
                List {
                    Text(bulletinContent)
                    Button(action: {
                        isNewBulletinUnread.toggle()
                    }, label: {
                        Text(isNewBulletinUnread ? String(localized: "Bulletin.read") : String(localized: "Bulletin.unread"))
                    })
                }
            }
            .navigationTitle(bulletinTitle.isEmpty ? String(localized: "Bulletin") : bulletinTitle)
            .onAppear(perform: {
                isNewBulletinUnread = false
            })
        } else {
            NavigationView {
                ScrollView {
                    Text(bulletinContent)
                }
            }
            .navigationTitle(bulletinTitle.isEmpty ? String(localized: "Bulletin") : bulletinTitle)
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
