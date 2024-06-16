//
//  BookmarkView.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//

import SwiftUI
import AuthenticationServices

struct BookmarkView: View {
    @State var markTotal = 0
    public static var editingBookmarkIndex = 0
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @AppStorage("IsRecordHistory") var isRecordHistory = true
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLockBookmarks") var usePasscodeForLockBookmarks = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var isNewMarkPresented = false
    @State var isBookmarkEditPresented = false
    @State var pinnedBookmarkIndexs = [Int]()
    @State var isShareSheetPresented = false
    @State var shareLink = ""
    var body: some View {
        if isLocked && !userPasscodeEncrypted.isEmpty && usePasscodeForLockBookmarks {
            PasswordInputView(text: $passcodeInputCache, placeholder: "输入密码", dismissAfterComplete: false) { pwd in
                if pwd.md5 == userPasscodeEncrypted {
                    isLocked = false
                } else {
                    tipWithText("密码错误", symbol: "xmark.circle.fill")
                }
                passcodeInputCache = ""
            }
            .navigationBarBackButtonHidden()
        } else {
            let userdefault = UserDefaults.standard
            List {
                Button(action: {
                    isNewMarkPresented = true
                }, label: {
                    HStack {
                        Spacer()
                        Label("Bookmark.add", systemImage: "plus")
                        Spacer()
                    }
                })
                .accessibilityIdentifier("AddBookmarkButton")
                .sheet(isPresented: $isNewMarkPresented, onDismiss: {
                    markTotal = UserDefaults.standard.integer(forKey: "BookmarkTotal")
                }, content: {
                    AddBookmarkView()
                })
                if markTotal != 0 {
                    Section {
                        ForEach(1...markTotal, id: \.self) { i in
                            Button(action: {
                                AdvancedWebViewController.shared.present(userdefault.string(forKey: "BookmarkLink\(i)")!)
                                if isRecordHistory {
                                    RecordHistory(userdefault.string(forKey: "BookmarkLink\(i)")!, webSearch: webSearch)
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
                                Button(action: {
                                    BookmarkView.editingBookmarkIndex = i
                                    isBookmarkEditPresented = true
                                }, label: {
                                    Image(systemName: "pencil.line")
                                })
                            })
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(action: {
                                    if pinnedBookmarkIndexs.contains(i) {
                                        for j in 0..<pinnedBookmarkIndexs.count {
                                            if pinnedBookmarkIndexs[j] == i {
                                                pinnedBookmarkIndexs.remove(at: j)
                                                break
                                            }
                                        }
                                    } else {
                                        pinnedBookmarkIndexs.append(i)
                                    }
                                    UserDefaults.standard.set(pinnedBookmarkIndexs, forKey: "PinnedBookmarkIndex")
                                }, label: {
                                    if pinnedBookmarkIndexs.contains(i) {
                                        Image(systemName: "pin.slash.fill")
                                    } else {
                                        Image(systemName: "pin.fill")
                                    }
                                })
                            }
                            .swipeActions(edge: .leading) {
                                Button(action: {
                                    shareLink = userdefault.string(forKey: "BookmarkLink\(i)")!
                                    isShareSheetPresented = true
                                }, label: {
                                    Image(systemName: "square.and.arrow.up.fill")
                                })
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isShareSheetPresented, content: {ShareView(linkToShare: $shareLink)})
            .sheet(isPresented: $isBookmarkEditPresented, onDismiss: {
                markTotal = 0
                markTotal = UserDefaults.standard.integer(forKey: "BookmarkTotal")
            }, content: {EditBookmarkView()})
            .onAppear {
                markTotal = UserDefaults.standard.integer(forKey: "BookmarkTotal")
                pinnedBookmarkIndexs = (UserDefaults.standard.array(forKey: "PinnedBookmarkIndex") as! [Int]?) ?? [Int]()
            }
        }
    }
}

struct AddBookmarkView: View {
    var initMarkName: Binding<String>?
    var initMarkLink: Binding<String>?
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var markName = ""
    @State var markLink = ""
    var body: some View {
        ScrollView {
            VStack {
                TextField("Bookmark.name", text: $markName)
                TextField("Bookmark.link", text: $markLink)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button(action: {
                    let userdefault = UserDefaults.standard
                    let total = userdefault.integer(forKey: "BookmarkTotal") + 1
                    userdefault.set(markName, forKey: "BookmarkName\(total)")
                    userdefault.set(
                        markLink.hasPrefix("https://") || markLink.hasPrefix("http://") ? markLink.urlEncoded() : "http://" + markLink.urlEncoded(),
                        forKey: "BookmarkLink\(total)"
                    )
                    userdefault.set(total, forKey: "BookmarkTotal")
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Label("Bookmark.add", systemImage: "plus")
                })
            }
        }
        .onAppear {
            // rdar://FB268002071827
            if let initMarkName, let initMarkLink {
                markName = initMarkName.wrappedValue
                markLink = initMarkLink.wrappedValue
            }
        }
    }
}

struct EditBookmarkView: View {
    @Environment(\.dismiss) var dismiss
    @State var markName = ""
    @State var markLink = ""
    var body: some View {
        ScrollView {
            VStack {
                Text("Bookmark.edit")
                    .font(.system(size: 18, weight: .bold))
                TextField("Bookmark.name", text: $markName)
                TextField("Bookmark.link", text: $markLink)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button(action: {
                    let userdefault = UserDefaults.standard
                    userdefault.set(markName, forKey: "BookmarkName\(BookmarkView.editingBookmarkIndex)")
                    userdefault.set(
                        markLink.hasPrefix("https://") || markLink.hasPrefix("http://") ? markLink.urlEncoded() : "http://" + markLink.urlEncoded(),
                        forKey: "BookmarkLink\(BookmarkView.editingBookmarkIndex)"
                    )
                    dismiss()
                }, label: {
                    Label("Bookmark.finish", systemImage: "checkmark")
                })
            }
        }
        .onAppear {
            markName = UserDefaults.standard.string(forKey: "BookmarkName\(BookmarkView.editingBookmarkIndex)") ?? ""
            markLink = UserDefaults.standard.string(forKey: "BookmarkLink\(BookmarkView.editingBookmarkIndex)") ?? ""
        }
    }
}

struct BookmarkView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkView()
    }
}
