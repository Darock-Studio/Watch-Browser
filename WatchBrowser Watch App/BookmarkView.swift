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
            List {
                Section {
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
                    NavigationLink(destination: { StaredBookmarksView() }, label: {
                        HStack {
                            Spacer()
                            Label("快捷书签", systemImage: "star")
                            Spacer()
                        }
                    })
                }
                if markTotal != 0 {
                    Section {
                        ForEach(1...markTotal, id: \.self) { i in
                            Button(action: {
                                AdvancedWebViewController.shared.present(UserDefaults.standard.string(forKey: "BookmarkLink\(i)")!)
                            }, label: {
                                Text(UserDefaults.standard.string(forKey: "BookmarkName\(i)") ?? "")
                            })
                            .privacySensitive()
                            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                Button(role: .destructive, action: {
                                    for i2 in i...markTotal {
                                        UserDefaults.standard.set(UserDefaults.standard.string(forKey: "BookmarkName\(i2 + 1)"), forKey: "BookmarkName\(i2)")
                                        UserDefaults.standard.set(UserDefaults.standard.string(forKey: "BookmarkLink\(i2 + 1)"), forKey: "BookmarkLink\(i2)")
                                    }
                                    UserDefaults.standard.set(markTotal - 1, forKey: "BookmarkTotal")
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
                                        for j in 0..<pinnedBookmarkIndexs.count where pinnedBookmarkIndexs[j] == i {
                                            pinnedBookmarkIndexs.remove(at: j)
                                            break
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
                                    shareLink = UserDefaults.standard.string(forKey: "BookmarkLink\(i)")!
                                    isShareSheetPresented = true
                                }, label: {
                                    Image(systemName: "square.and.arrow.up.fill")
                                })
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isShareSheetPresented, content: { ShareView(linkToShare: $shareLink) })
            .sheet(isPresented: $isBookmarkEditPresented, onDismiss: {
                markTotal = 0
                markTotal = UserDefaults.standard.integer(forKey: "BookmarkTotal")
            }, content: { EditBookmarkView() })
            .onAppear {
                markTotal = UserDefaults.standard.integer(forKey: "BookmarkTotal")
                pinnedBookmarkIndexs = (UserDefaults.standard.array(forKey: "PinnedBookmarkIndex") as! [Int]?) ?? [Int]()
            }
        }
    }
    
    struct StaredBookmarksView: View {
        var body: some View {
            List {
                Section {
                    ForEach(Array<String>(staredBookmarks.keys).sorted(), id: \.self) { key in
                        Button(action: {
                            AdvancedWebViewController.shared.present(staredBookmarks[key]!)
                        }, label: {
                            Text(key)
                        })
                    }
                } footer: {
                    Text(
                        "上面的网站在 Apple Watch 上运行表现较好，尽管如此，我们仍然不接受网站内问题的反馈。\n网站内容由网页提供商提供，Darock 不对其内容负责。\n请自行辨别其中内容真实性，特别是广告内容。"
                    )
                }
            }
            .navigationTitle("快捷书签")
        }
        
        let staredBookmarks = [
            "樱花动漫": "http://yhdm.one",
            "笔趣阁": "https://www.bigee.cc",
            "微软数学": "https://math.microsoft.com",
            "百度贴吧": "https://tieba.baidu.com",
            "网易云音乐": "https://music.163.com",
            "哔哩哔哩": "https://bilibili.com",
            "Pixiv Viewer": "https://lab.getloli.com/pixiv-viewer"
        ]
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
        NavigationStack {
            List {
                HStack {
                    Spacer()
                    Text("Bookmark.edit")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                }
                .listRowBackground(Color.clear)
                TextField("Bookmark.name", text: $markName, style: "field-page")
                TextField("Bookmark.link", text: $markLink, style: "field-page")
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
                    HStack {
                        Spacer()
                        Label("Bookmark.finish", systemImage: "checkmark")
                        Spacer()
                    }
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
