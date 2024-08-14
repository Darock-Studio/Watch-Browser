//
//  General.swift
//  WatchBrowser
//
//  Created by memz233 on 7/1/24.
//

import SwiftUI
import Cepheus

var globalMediaUserActivity: NSUserActivity?

// Ext Keyboard
struct TextField: View {
    var titleKey: LocalizedStringResource?
    var titleKeyString: String?
    var text: Binding<String>
    var style: String
    var _onSubmit: () -> Void
    @AppStorage("ModifyKeyboard") private var _modifyKeyboard = false
    @State private var _isOldModifyKeyboardPresented = false
    
    init(_ titleKey: LocalizedStringResource, text: Binding<String>, style: String = "field", onSubmit: @escaping () -> Void = {}) {
        self.titleKey = titleKey
        self.text = text
        self.style = style
        self._onSubmit = onSubmit
    }
    @_disfavoredOverload
    init(_ titleKey: String, text: Binding<String>, style: String = "field", onSubmit: @escaping () -> Void = {}) {
        self.titleKeyString = titleKey
        self.text = text
        self.style = style
        self._onSubmit = onSubmit
    }
    
    var body: some View {
        if _modifyKeyboard {
            if #available(watchOS 10, *) {
                if let titleKey {
                    CepheusKeyboard(input: text, prompt: titleKey, CepheusIsEnabled: true, style: style, onSubmit: _onSubmit)
                } else if let titleKeyString {
                    CepheusKeyboard(input: text,
                                    prompt: LocalizedStringResource(stringLiteral: titleKeyString),
                                    CepheusIsEnabled: true,
                                    style: style,
                                    onSubmit: _onSubmit)
                }
            } else {
                Button(action: {
                    _isOldModifyKeyboardPresented = true
                }, label: {
                    HStack {
                        if let titleKey {
                            Text(!text.wrappedValue.isEmpty ? text.wrappedValue : String(localized: titleKey))
                                .foregroundColor(text.wrappedValue.isEmpty ? Color.gray : Color.white)
                        } else if let titleKeyString {
                            Text(!text.wrappedValue.isEmpty ? text.wrappedValue : titleKeyString)
                                .foregroundColor(text.wrappedValue.isEmpty ? Color.gray : Color.white)
                        }
                        Spacer()
                    }
                })
                .sheet(isPresented: $_isOldModifyKeyboardPresented, content: {
                    ExtKeyboardView(startText: text.wrappedValue) { ott in
                        text.wrappedValue = ott
                    }
                })
            }
        } else {
            if let titleKey {
                SwiftUI.TextField(String(localized: titleKey), text: text)
                    .onSubmit(_onSubmit)
            } else if let titleKeyString {
                SwiftUI.TextField(titleKeyString, text: text)
                    .onSubmit(_onSubmit)
            }
        }
    }
}

extension Int: Identifiable {
    public var id: Self { self }
}
