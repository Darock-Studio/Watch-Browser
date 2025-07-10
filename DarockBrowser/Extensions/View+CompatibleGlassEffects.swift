//
//  View+GlassEffects.swift
//  DarockBrowser
//
//  Created by Mark Chan on 7/9/25.
//

import DarockUI

extension View {
    func compatibleGlassEffect(in shape: some Shape) -> some View {
        self
        #if compiler(>=6.2)
            .wrapIf({ if #available(watchOS 26.0, *) { true } else { false } }()) { content in
                if #available(watchOS 26.0, *) {
                    content
                        .glassEffect(in: shape)
                }
            }
        #endif
    }
    
    func compatibleGlassButtonStyle<S>(fallback: S? = nil) -> some View where S: PrimitiveButtonStyle {
        self
        #if compiler(>=6.2)
            .wrapIf({ if #available(watchOS 26.0, *) { true } else { false } }()) { content in
                if #available(watchOS 26.0, *) {
                    content
                        .buttonStyle(.glass)
                }
            } else: { content in
                if let fallback {
                    content
                        .buttonStyle(fallback)
                } else {
                    content
                }
            }
        #endif
    }
}
