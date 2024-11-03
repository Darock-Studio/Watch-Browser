//
//  BookListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 6/27/24.
//

import SwiftUI

struct BookListView: View {
    var body: some View {
        if !bookLinkLists.isEmpty {
            List {
                Section {
                    ForEach(0..<bookLinkLists.count, id: \.self) { i in
                        NavigationLink(destination: { BookViewerView(bookLink: bookLinkLists[i]) }, label: {
                            Text(bookLinkLists[i])
                        })
                    }
                }
                Section {
                    HStack {
                        Image(systemName: "lightbulb.max")
                            .foregroundColor(.orange)
                        Text("图书会在访问后保存在磁盘上，您可以稍后进行管理。")
                    }
                }
            }
            .navigationTitle("图书列表")
        } else {
            Text("空图书列表")
        }
    }
}
