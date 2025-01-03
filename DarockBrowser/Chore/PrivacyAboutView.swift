//
//  PrivacyAboutView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/9/17.
//

import SwiftUI
import MarkdownUI
import DarockFoundation

struct PrivacyAboutView: View {
    var title: LocalizedStringKey
    var description: Text
    var detailText: LocalizedStringResource
    @Environment(\.presentationMode) private var presentationMode
    @State private var isDetailPresented = false
    var body: some View {
        ScrollView {
            VStack {
                Image(_internalSystemName: "privacy.handshake")
                    .symbolRenderingMode(.palette)
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: 0x0A84FF), Color(hex: 0x115AA5))
                Text(title)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                Button(action: {
                    isDetailPresented = true
                }, label: {
                    description
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                })
                .buttonStyle(.plain)
                .padding(.vertical)
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("完成")
                        .fontWeight(.medium)
                        .foregroundStyle(.black)
                })
                .buttonStyle(.borderedProminent)
                .padding(.vertical)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $isDetailPresented) {
            ScrollView {
                Spacer()
                    .frame(height: 50)
                Markdown(String(localized: detailText))
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .environment(\.openURL, OpenURLAction { url in
                        AdvancedWebViewController.shared.present(url.absoluteString)
                        return .handled
                    })
                    .padding(.vertical)
            }
        }
    }
}
