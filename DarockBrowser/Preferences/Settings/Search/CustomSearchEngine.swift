//
//  CustomSearchEngine.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftUI

extension SettingsView.SearchSettingsView {
    struct CustomSearchEngineSettingsView: View {
        @State var isAddCustomSEPresented = false
        @State var customSearchEngineList = [String]()
        var body: some View {
            Group {
                if #available(watchOS 10, *) {
                    MainView(isAddCustomSEPresented: $isAddCustomSEPresented, customSearchEngineList: $customSearchEngineList)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    isAddCustomSEPresented = true
                                }, label: {
                                    Image(systemName: "plus")
                                })
                            }
                        }
                } else {
                    MainView(isAddCustomSEPresented: $isAddCustomSEPresented, customSearchEngineList: $customSearchEngineList)
                }
            }
            .sheet(isPresented: $isAddCustomSEPresented, onDismiss: {
                customSearchEngineList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
            }, content: { AddCustomSearchEngineView(isAddCustomSEPresented: $isAddCustomSEPresented) })
        }
        
        struct MainView: View {
            @Binding var isAddCustomSEPresented: Bool
            @Binding var customSearchEngineList: [String]
            var body: some View {
                List {
                    if #unavailable(watchOS 10) {
                        Section {
                            Button(action: {
                                isAddCustomSEPresented = true
                            }, label: {
                                Label("Settings.search.customize.add", systemImage: "plus")
                            })
                        }
                    }
                    if customSearchEngineList.count != 0 {
                        ForEach(0..<customSearchEngineList.count, id: \.self) { i in
                            Text(
                                customSearchEngineList[i]
                                    .replacingOccurrences(of: "%lld", with: String(localized: "Settings.search.customize.search-content"))
                            )
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    customSearchEngineList.remove(at: i)
                                    UserDefaults.standard.set(customSearchEngineList, forKey: "CustomSearchEngineList")
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                            }
                        }
                    } else {
                        HStack {
                            Spacer()
                            Text("Settings.search.customize.nothing")
                            Spacer()
                        }
                    }
                }
                .onAppear {
                    customSearchEngineList = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
                }
            }
        }
        
        struct AddCustomSearchEngineView: View {
            @Binding var isAddCustomSEPresented: Bool
            @State var customUrlInput = ""
            var body: some View {
                NavigationView {
                    List {
                        Section {
                            TextField("Settings.search.customize.link", text: $customUrlInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } footer: {
                            Text("Settings.search.customize.link.discription")
                        }
                        Section {
                            NavigationLink(destination: { Step2(customUrlInput: customUrlInput, isAddCustomSEPresented: $isAddCustomSEPresented) }, label: {
                                Text("Settings.search.customize.next")
                            })
                            .disabled(customUrlInput.isEmpty)
                        }
                    }
                    .navigationTitle("Settings.search.customize.link.title")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            
            struct Step2: View {
                var customUrlInput: String
                @Binding var isAddCustomSEPresented: Bool
                @State var charas = [Character]()
                @State var cursorPosition = 0.0
                var body: some View {
                    VStack {
                        ScrollViewReader { p in
                            ScrollView(.horizontal) {
                                HStack(spacing: 0) {
                                    if charas.count != 0 {
                                        ForEach(0..<charas.count, id: \.self) { i in
                                            Text(String(charas[i]))
                                            if i == Int(cursorPosition) {
                                                Color.accentColor
                                                    .frame(width: 3, height: 26)
                                                    .cornerRadius(3)
                                                    .id("cur")
                                                    .onAppear {
                                                        p.scrollTo("cur")
                                                    }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .focusable()
                        .digitalCrownRotation(
                            $cursorPosition,
                            from: 0,
                            through: Double(charas.count - 1),
                            by: 1,
                            sensitivity: .medium,
                            isHapticFeedbackEnabled: true
                        )
                        Spacer()
                            .frame(height: 15)
                        Text("Settings.search.customize.cursor")
                            .font(.footnote)
                            .opacity(0.65)
                        Button(action: {
                            var combinedText = ""
                            for i in 0..<charas.count {
                                combinedText += String(charas[i])
                                if i == Int(cursorPosition) {
                                    combinedText += "%lld"
                                }
                            }
                            if !combinedText.hasPrefix("http://") && !combinedText.hasPrefix("https://") {
                                combinedText = "http://" + combinedText
                            }
                            var newLists = UserDefaults.standard.stringArray(forKey: "CustomSearchEngineList") ?? [String]()
                            newLists.append(combinedText)
                            UserDefaults.standard.set(newLists, forKey: "CustomSearchEngineList")
                            isAddCustomSEPresented = false
                        }, label: {
                            Label("Settings.search.customize.done", systemImage: "checkmark")
                        })
                    }
                    .navigationTitle("Settings.search.customize.cursor.title")
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        for c in customUrlInput {
                            charas.append(c)
                        }
                        cursorPosition = Double(charas.count - 1)
                    }
                }
            }
        }
    }
}
