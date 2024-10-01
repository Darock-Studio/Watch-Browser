//
//  View+Introspect.swift
//  WatchBrowser
//
//  Created by memz233 on 10/1/24.
//

import SwiftUI
import Dynamic

extension View {
    @ViewBuilder
    func introspect(_ transition: @escaping (Dynamic) -> Void) -> some View {
        IntrospectRepresent<Self, Never>(sourceView: self, transition: transition)
    }
    
    @ViewBuilder
    func introspect<T>(withValueUpdating updatingValue: Binding<T>, _ transition: @escaping (Dynamic, T) -> Void) -> some View {
        IntrospectRepresent(sourceView: self, transition: { object in
            transition(object, updatingValue.wrappedValue)
        }, updater: transition, updatingValue: updatingValue)
    }
}

private struct IntrospectRepresent<T, U>: _UIViewRepresentable where T: View {
    let sourceView: T
    var transition: (Dynamic) -> Void
    var updater: ((Dynamic, U) -> Void)?
    var updatingValue: Binding<U>?
    
    func makeUIView(context: Context) -> some NSObject {
        let hostingView = _makeUIHostingView(sourceView)
        transition(Dynamic(hostingView))
        return hostingView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if let updater, let updatingValue {
            updater(Dynamic(uiView), updatingValue.wrappedValue)
        }
    }
}
