//
//  MLTestsView.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2023/10/21.
//

import SwiftUI
import EFQRCode

struct MLTestsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("IsShowBetaTest1") var isShowBetaTest = true
    var body: some View {
        List {
            Section {
                Text("Home.invatation")
                Text("Invataion.app-name")
                Text("Invataion.app-discription")
            }
            Section {
                NavigationLink(destination: {
                    VStack {
                        Image(decorative: EFQRCode.generate(for: "https://cd.darock.top:32767/meowbili/")!, scale: 1)
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text("Invatation.continue-on-iphone")
                    }
                }, label: {
                    Text("Invatation.learn-more")
                })
                NavigationLink(destination: {
                    VStack {
                        Image(decorative: EFQRCode.generate(for: "https://testflight.apple.com/join/TbuBT6ig")!, scale: 1)
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text("Invatation.continue-on-iphone")
                    }
                }, label: {
                    Text("Invatation.download")
                })
            }
            Section {
                Button(action: {
                    isShowBetaTest = false
                    dismiss()
                }, label: {
                    Text("Invatation.leave-and-hide")
                })
            }
        }
        .navigationTitle("Invatation")
    }
}

#Preview {
    MLTestsView()
}
