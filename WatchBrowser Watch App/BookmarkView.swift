//
//  BookmarkView.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//

import SwiftUI
import AuthenticationServices

struct BookmarkView: View {
    @State var markTotal = UserDefaults.standard.integer(forKey: "BookmarkTotal")
    @State var isNewMarkPresented = false
    var body: some View {
        let userdefault = UserDefaults.standard
        ScrollView {
            VStack {
                Button(action: {
                    isNewMarkPresented = true
                }, label: {
                    Label("添加书签", systemImage: "plus")
                })
                .sheet(isPresented: $isNewMarkPresented, onDismiss: {
                    markTotal = UserDefaults.standard.integer(forKey: "BookmarkTotal")
                }, content: {
                    AddBookmarkView()
                })
                Spacer()
                    .frame(height: 14)
                if markTotal != 0 {
                    //List {
                        //Section {
                            ForEach(1...markTotal, id: \.self) { i in
                                Button(action: {
                                    let session = ASWebAuthenticationSession(
                                        url: URL(string: userdefault.string(forKey: "BookmarkLink\(i)")!)!,
                                        callbackURLScheme: nil
                                    ) { _, _ in
                                        
                                    }
                                    // Makes the "Watch App Wants To Use example.com to Sign In" popup not show up
                                    session.prefersEphemeralWebBrowserSession = true
                                    session.start()
                                }, label: {
                                    Text(userdefault.string(forKey: "BookmarkName\(i)") ?? "")
                                })
//                                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
//                                    Button(role: .destructive, action: {
//
//                                    }, label: {
//                                        Image(systemName: "bin.xmark.fill")
//                                    })
//                                })
                            }
                        //}
                    //}
                }
            }
        }
    }
}

struct AddBookmarkView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var markName = ""
    @State var markLink = ""
    var body: some View {
        ScrollView {
            VStack {
                TextField("书签名称", text: $markName)
                TextField("书签链接", text: $markLink)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button(action: {
                    let userdefault = UserDefaults.standard
                    let total = userdefault.integer(forKey: "BookmarkTotal") + 1
                    userdefault.set(markName, forKey: "BookmarkName\(total)")
                    userdefault.set(markLink.hasPrefix("https://") || markLink.hasPrefix("http://") ? markLink.urlEncoded() : "http://" + markLink.urlEncoded(), forKey: "BookmarkLink\(total)")
                    userdefault.set(total, forKey: "BookmarkTotal")
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Label("添加", systemImage: "plus")
                })
            }
        }
    }
}

struct BookmarkView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkView()
    }
}
