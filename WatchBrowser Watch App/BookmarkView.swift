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
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @AppStorage("IsRecordHistory") var isRecordHistory = true
    @State var isNewMarkPresented = false
    var body: some View {
        let userdefault = UserDefaults.standard
        List {
                Button(action: {
                    isNewMarkPresented = true
                }, label: {
                    HStack {
                        Spacer()
                        Label("添加书签", systemImage: "plus")
                        Spacer()
                    }
                })
                .sheet(isPresented: $isNewMarkPresented, onDismiss: {
                    markTotal = UserDefaults.standard.integer(forKey: "BookmarkTotal")
                }, content: {
                    AddBookmarkView()
                })
                if markTotal != 0 {
                    Section {
                            ForEach(1...markTotal, id: \.self) { i in
                                Button(action: {
                                    let session = ASWebAuthenticationSession(
                                        url: URL(string: userdefault.string(forKey: "BookmarkLink\(i)")!)!,
                                        callbackURLScheme: nil
                                    ) { _, _ in
                                        
                                    }
                                    session.prefersEphemeralWebBrowserSession = !isAllowCookie
                                    session.start()
                                    if isRecordHistory {
                                        if (UserDefaults.standard.stringArray(forKey: "WebHistory") != nil) ? (UserDefaults.standard.stringArray(forKey: "WebHistory")![UserDefaults.standard.stringArray(forKey: "WebHistory")!.count - 1] != userdefault.string(forKey: "BookmarkLink\(i)")!) : true {
                                            UserDefaults.standard.set([userdefault.string(forKey: "BookmarkLink\(i)")!] + (UserDefaults.standard.stringArray(forKey: "WebHistory") ?? [String]()), forKey: "WebHistory")
                                        }
                                    }
                                }, label: {
                                    Text(userdefault.string(forKey: "BookmarkName\(i)") ?? "")
                                })
                                .privacySensitive()
                                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                    Button(role: .destructive, action: {
                                        for i2 in i...markTotal {
                                            userdefault.set(userdefault.string(forKey: "BookmarkName\(i2 + 1)"), forKey: "BookmarkName\(i2)")
                                            userdefault.set(userdefault.string(forKey: "BookmarkLink\(i2 + 1)"), forKey: "BookmarkLink\(i2)")
                                        }
                                        userdefault.set(markTotal - 1, forKey: "BookmarkTotal")
                                        markTotal -= 1
                                    }, label: {
                                        Image(systemName: "bin.xmark.fill")
                                    })
                                })
                            }
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
