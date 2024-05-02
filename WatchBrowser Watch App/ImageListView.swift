//
//  ImageListView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/5/2.
//

import SwiftUI
import Dynamic
import DarockKit
import SDWebImageSwiftUI

struct ImageListView: View {
    @State var willPresentImageLink = ""
    @State var isImageViewerPresented = false
    var body: some View {
        if !imageLinkLists.isEmpty {
            List {
                ForEach(0..<imageLinkLists.count, id: \.self) { i in
                    Button(action: {
                        willPresentImageLink = imageLinkLists[i]
                        debugPrint(willPresentImageLink)
                        isImageViewerPresented = true
                    }, label: {
                        Text(imageLinkLists[i])
                    })
                }
            }
            .navigationTitle("图片列表")
            .sheet(isPresented: $isImageViewerPresented, content: { ImageViewerView(url: willPresentImageLink) })
            .onDisappear {
                Dynamic.UIApplication.sharedApplication.keyWindow.rootViewController.presentViewController(AdvancedWebViewController.shared.vc, animated: true, completion: nil)
                AdvancedWebViewController.shared.registerVideoCheckTimer()
            }
        } else {
            Text("空图片列表")
        }
    }
}

struct ImageViewerView: View {
    var url: String
    var body: some View {
        WebImage(url: URL(string: url), options: [.progressiveLoad], isAnimating: .constant(true))
            .resizable()
            .indicator(.activity)
            .transition(.fade(duration: 0.5))
            .scaledToFit()
            .frame(width: CGFloat(100), height: CGFloat(100), alignment: .center)
            .modifier(Zoomable())
    }
}
