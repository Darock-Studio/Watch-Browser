//
//  ImageGroupView.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/1/20.
//

import SwiftUI
import DarockFoundation

struct ImageGroupView: View {
    @Binding var links: [String]
    @State var selection = 0
    @AppStorage("IVUseDigitalCrownFor") var useDigitalCrownFor = "zoom"
    @State var isControlsHidden = false
    @State var controlsHiddenTimer: Timer?
    var body: some View {
        NavigationStack {
            if useDigitalCrownFor == "zoom" {
                if #available(watchOS 10.0, *) {
                    ImageViewerView(url: links[selection], useExternalControls: true)
                        .toolbar {
                            ToolbarItem(placement: .bottomBar) {
                                HStack {
                                    Button(action: {
                                        if _fastPath(selection - 1 >= 0) {
                                            selection--
                                        } else {
                                            selection = links.count - 1
                                        }
                                    }, label: {
                                        Image(systemName: "chevron.backward")
                                    })
                                    Spacer()
                                    Text(verbatim: "\(selection + 1)/\(links.count)")
                                    Spacer()
                                    Button(action: {
                                        if _fastPath(selection + 1 < links.count) {
                                            selection++
                                        } else {
                                            selection = 0
                                        }
                                    }, label: {
                                        Image(systemName: "chevron.forward")
                                    })
                                }
                                .opacity(isControlsHidden ? 0 : 1)
                                .allowsHitTesting(!isControlsHidden)
                            }
                        }
                        .toolbar(isControlsHidden ? .hidden : .visible)
                } else {
                    TabView(selection: $selection) {
                        ForEach(0..<links.count, id: \.self) { i in
                            ImageViewerView(url: links[i], useExternalControls: true)
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: isControlsHidden ? .always : .never))
                    .toolbar(isControlsHidden ? .hidden : .visible)
                }
            } else {
                TabView(selection: $selection) {
                    ForEach(0..<links.count, id: \.self) { i in
                        ImageViewerView(url: links[i], useExternalControls: true)
                            .tag(i)
                    }
                }
                .tabViewStyle(.carousel)
                .toolbar(isControlsHidden ? .hidden : .visible)
            }
        }
        .animation(.smooth, value: isControlsHidden)
        .toolbar(.hidden)
        ._statusBarHidden(isControlsHidden)
        .onTapGesture {
            resetControlsHiddenTimer()
        }
        .onAppear {
            resetControlsHiddenTimer()
        }
        .onDisappear {
            controlsHiddenTimer?.invalidate()
            controlsHiddenTimer = nil
        }
    }
    
    func resetControlsHiddenTimer() {
        isControlsHidden = false
        controlsHiddenTimer?.invalidate()
        controlsHiddenTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            isControlsHidden = true
        }
    }
}
