//
//  Keyboard.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import Cepheus
import DarockUI

extension SettingsView.GeneralSettingsView {
    struct KeyboardView: View {
        @AppStorage("ModifyKeyboard") var modifyKeyboard = false
        @State var isKeyboardPresented = false
        var body: some View {
            List {
                Section {
                    Toggle(isOn: $modifyKeyboard) {
                        Text("Settings.keyboard.third-party")
                    }
                    if #available(watchOS 10, *) {
                        CepheusKeyboard(input: .constant(""), prompt: "Settings.keyboard.preview", CepheusIsEnabled: true)
                    } else {
                        Button(action: {
                            isKeyboardPresented = true
                        }, label: {
                            Label("Settings.keyboard.preview", systemImage: "keyboard.badge.eye")
                        })
                        .sheet(isPresented: $isKeyboardPresented, content: {
                            ExtKeyboardView(startText: "") { _ in }
                        })
                    }
                } footer: {
                    VStack(alignment: .leading) {
                        Text("Settings.keyboard.discription")
                        if #available(watchOS 10, *) {
                            Text(verbatim: "Powered by Cepheus Keyboard")
                        }
                    }
                }
                if #available(watchOS 10, *), modifyKeyboard {
                    NavigationLink(destination: { CepheusSettingsView() }, label: {
                        Text("键盘设置...")
                    })
                }
            }
            .navigationTitle("Settings.keyboard")
        }
    }
}
