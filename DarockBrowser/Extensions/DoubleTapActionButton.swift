//
//  DoubleTapActionButton.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/27.
//

import SwiftUI

struct DoubleTapActionButton: View {
    var forType: ButtonType
    var webView: WKWebView?
    var presentationModeForExitWeb: Binding<PresentationMode>?
    var quickShowEmptyAction: (() -> Void)?
    @AppStorage("GSIsDoubleTapEnabled") var isDoubleTapEnabled = false
    @AppStorage("GSGlobalAction") var globalAction = "None"
    @AppStorage("GSInWebAction") var inWebAction = "None"
    @AppStorage("GSOpenWebLink") var openWebLink = ""
    @AppStorage("GSQuickAvoidanceAction") var quickAvoidanceAction = "ShowEmpty"
    var body: some View {
        #if compiler(>=6)
        if isDoubleTapEnabled {
            Button("") {
                switch forType {
                case .global:
                    switch globalAction {
                    case "OpenWeb":
                        AdvancedWebViewController.shared.present(openWebLink)
                    case "QuickAvoidance":
                        doQuickAvoidance()
                    default: break
                    }
                case .inWeb:
                    switch inWebAction {
                    case "ExitWeb":
                        presentationModeForExitWeb?.wrappedValue.dismiss()
                    case "ReloadWeb":
                        webView?.reload()
                    case "QuickAvoidance":
                        doQuickAvoidance()
                    default: break
                    }
                }
            }
            .compatibleDoubleTapGesture()
            .opacity(0.0100000002421438702673861521)
            .allowsHitTesting(false)
        }
        #else
        EmptyView()
        #endif
    }
    
    @inline(__always)
    private func doQuickAvoidance() {
        switch quickAvoidanceAction {
        case "ShowEmpty":
            quickShowEmptyAction?()
        case "ExitApp":
            _Exit(0)
        default: break
        }
    }
    
    enum ButtonType {
        case global
        case inWeb
    }
}
