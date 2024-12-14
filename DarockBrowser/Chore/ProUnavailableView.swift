//
//  ProUnavailableView.swift
//  DarockBrowser
//
//  Created by memz233 on 12/14/24.
//

import SwiftUI

struct ProUnavailableView: View {
    var body: some View {
        VStack {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(Color.secondary)
            VStack {
                Text("需要激活暗礁浏览器 Pro")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                NavigationLink(destination: { ProPurchaseView() }, label: {
                    Text("前往激活")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .multilineTextAlignment(.center)
                })
                .buttonStyle(.plain)
            }
            .padding(.vertical)
        }
    }
}
