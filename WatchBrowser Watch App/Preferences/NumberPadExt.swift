//
//  NumberPadExt.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/2/19.
//

// From GitHub repo: https://github.com/ApplebaumIan/SwiftUI-Apple-Watch-Decimal-Pad. Edited

import SwiftUI

struct PasswordInputView: View {
    @Binding var text: String
    var placeholder: LocalizedStringKey
    var hideCancelButton: Bool = false
    var dismissAfterComplete = true
    var completion: ((String) -> Void)?
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 26)
            Group {
                if !text.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(1...6, id: \.self) { i in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                                .opacity(text.count >= i ? 1.0 : 0.4)
                        }
                    }
                } else {
                    Text(placeholder)
                        .font(.system(size: 13))
                }
            }
            .frame(height: 12)
            DigitPadView(text: $text)
            if !hideCancelButton {
                ZStack {
                    Capsule()
                        .fill(Color.red)
                        .frame(width: WKInterfaceDevice.current().screenBounds.width - 28, height: 28)
                    Text("取消")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .onTapGesture {
                    dismiss()
                }
            }
            Spacer()
                .frame(height: 5)
        }
        .ignoresSafeArea()
        .onChange(of: text) { value in
            if value.count == 6 {
                completion?(value)
                if dismissAfterComplete {
                    dismiss()
                }
            }
        }
    }
}

struct DigitPadView: View {
    @Binding var text: String
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Button(action: {
                    text.append("1")
                }) {
                    Text("1")
                        .padding(0)
                }
                .buttonStyle(DigitPadStyle(scaleAnchor: .topLeading))
                Button(action: {
                    text.append("2")
                }) {
                    Text("2")
                }
                .buttonStyle(DigitPadStyle(scaleAnchor: .top))
                Button(action: {
                    text.append("3")
                }) {
                    Text("3")
                }
                .buttonStyle(DigitPadStyle(scaleAnchor: .topTrailing))
            }
            HStack(spacing: 2) {
                Button(action: {
                    text.append("4")
                }) {
                    Text("4")
                }
                .buttonStyle(DigitPadStyle(scaleAnchor: .leading))
                Button(action: {
                    text.append("5")
                }) {
                    Text("5")
                }
                .buttonStyle(DigitPadStyle())
                Button(action: {
                    text.append("6")
                }) {
                    Text("6")
                }
                .buttonStyle(DigitPadStyle(scaleAnchor: .trailing))
            }
            HStack(spacing: 2) {
                Button(action: {
                    text.append("7")
                }) {
                    Text("7")
                }
                .buttonStyle(DigitPadStyle(scaleAnchor: .bottomLeading))
                Button(action: {
                    text.append("8")
                }) {
                    Text("8")
                }
                .buttonStyle(DigitPadStyle())
                Button(action: {
                    text.append("9")
                }) {
                    Text("9")
                }
                .buttonStyle(DigitPadStyle(scaleAnchor: .bottomTrailing))
            }
            HStack(spacing: 2) {
                Spacer()
                    .padding(1)
                Button(action: {
                    text.append("0")
                }) {
                    Text("0")
                }
                .buttonStyle(DigitPadStyle(scaleAnchor: .bottom))
                if !text.isEmpty {
                    Button(action: {
                        if let last = text.indices.last {
                            text.remove(at: last)
                        }
                    }, label: {
                        Image(systemName: "delete.left")
                            .foregroundColor(.red)
                    })
                    .buttonStyle(DigitPadStyle(scaleAnchor: .bottomTrailing, isUnpressNoBackground: true))
                } else {
                    Spacer()
                        .padding(1)
                }
            }
        }
        .font(.title2)
    }
}

struct DigitPadStyle: ButtonStyle {
    var scaleAnchor: UnitPoint = .center
    var isUnpressNoBackground: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(!configuration.isPressed && isUnpressNoBackground ? Color.clear : Color.gray.opacity(configuration.isPressed ? 0.3 : 0.2))
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(configuration.isPressed ? 1.2 : 1, anchor: scaleAnchor)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            configuration.label
                .background(
                    ZStack {
                        GeometryReader(content: { geometry in
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.clear)
                                .frame(width: configuration.isPressed ? geometry.size.width / 0.75 : geometry.size.width,
                                       height: configuration.isPressed ? geometry.size.height / 0.8 : geometry.size.height)
                        })
                    }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(configuration.isPressed ? 1.2 : 1, anchor: scaleAnchor)
        }
        .onChange(of: configuration.isPressed) { value in
            if value {
                DispatchQueue.main.async {
                    WKInterfaceDevice().play(.click)
                }
            }
        }
    }
}
