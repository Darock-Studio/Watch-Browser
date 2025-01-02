//
//  CelebrationFireworksView.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/1/3.
//

import Vortex
import SwiftUI

struct CelebrationFireworksView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var dismissTimer: Timer?
    var body: some View {
        VortexView(.fireworks) {
            Circle()
                .fill(.white)
                .frame(width: 32)
                .blur(radius: 5)
                .blendMode(.plusLighter)
                .tag("circle")
        }
        .ignoresSafeArea()
        .onTapGesture {
            dismissTimer?.invalidate()
            presentationMode.wrappedValue.dismiss()
        }
        .onAppear {
            dismissTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                presentationMode.wrappedValue.dismiss()
            }
        }
        .digitalCrownAccessory(.hidden)
        .toolbar(.hidden)
        ._statusBarHidden(true)
    }
}
