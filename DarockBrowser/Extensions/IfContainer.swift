//
//  IfContainer.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/1/28.
//

import SwiftUI

@inlinable
@ViewBuilder
func ifContainer<T, U, V>(
    _ condition: Bool,
    @ViewBuilder true trueContainer: @escaping (AnyView) -> T,
    @ViewBuilder false falseContainer: @escaping (AnyView) -> U,
    @ViewBuilder containing containingView: @escaping () -> V
) -> some View where T: View, U: View, V: View {
    if condition {
        trueContainer(.init(containingView()))
    } else {
        falseContainer(.init(containingView()))
    }
}
