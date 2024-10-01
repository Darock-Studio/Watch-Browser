//
//  BookmarkView.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//

import SwiftUI
import DarockKit
import AuthenticationServices

struct BookmarkView: View {
    var selectionHandler: ((String, String) -> Void)?
    public static var editingBookmarkIndex = 0
    @AppStorage("IsAllowCookie") var isAllowCookie = false
    @AppStorage("WebSearch") var webSearch = "必应"
    @AppStorage("UserPasscodeEncrypted") var userPasscodeEncrypted = ""
    @AppStorage("UsePasscodeForLockBookmarks") var usePasscodeForLockBookmarks = false
    @State var isLocked = true
    @State var passcodeInputCache = ""
    @State var bookmarks = [BookmarkStackManager.BookmarkData]()
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
                if selectionHandler == nil {
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
                        .sheet(isPresented: $isNewMarkPresented, onDismiss: {
                            bookmarks = BookmarkStackManager.shared.getAll()
                        }, content: { AddBookmarkView() })
                        NavigationLink(destination: { StaredBookmarksView() }, label: {
                            HStack {
                                Spacer()
                                Label("快捷书签", systemImage: "star")
                                Spacer()
                            }
                        })
                    }
                }
                if !bookmarks.isEmpty {
                    Section {
                        ForEach(1...bookmarks.count, id: \.self) { i in
                            Button(action: {
                                if let handler = selectionHandler {
                                    handler(bookmarks[i - 1].name, bookmarks[i - 1].link)
                                } else {
                                    AdvancedWebViewController.shared.present(bookmarks[i - 1].link)
                                }
                            }, label: {
                                Text(bookmarks[i - 1].name)
                            })
                            .privacySensitive()
                            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                Button(role: .destructive, action: {
                                    BookmarkStackManager.shared.remove(at: i)
                                    bookmarks = BookmarkStackManager.shared.getAll()
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
                        .onMove { source, destination in
                            BookmarkStackManager.shared.move(fromOffsets: source, toOffset: destination)
                            bookmarks = BookmarkStackManager.shared.getAll()
                        }
                    }
                }
            }
            .navigationTitle("书签")
            .sheet(isPresented: $isShareSheetPresented, content: { ShareView(linkToShare: $shareLink) })
            .sheet(isPresented: $isBookmarkEditPresented, onDismiss: {
                bookmarks = BookmarkStackManager.shared.getAll()
            }, content: { EditBookmarkView() })
            .onAppear {
                bookmarks = BookmarkStackManager.shared.getAll()
                pinnedBookmarkIndexs = (UserDefaults.standard.array(forKey: "PinnedBookmarkIndex") as! [Int]?) ?? [Int]()
            }
        }
    }
    
    struct StaredBookmarksView: View {
        @State var staredBookmarks = [String: String]()
        var body: some View {
            List {
                Section {
                    if !staredBookmarks.isEmpty {
                        ForEach(Array<String>(staredBookmarks.keys).sorted(), id: \.self) { key in
                            Button(action: {
                                AdvancedWebViewController.shared.present(staredBookmarks[key]!)
                            }, label: {
                                Text(key)
                            })
                        }
                    } else {
                        Text("无法载入快捷书签，请提交错误报告。")
                    }
                } footer: {
                    Text("网站内容由网页提供商提供，Darock 不对其内容负责。\n请自行辨别其中内容真实性，特别是广告内容。")
                }
            }
            .navigationTitle("快捷书签")
            .onAppear {
                // Updating values dynamicly to resolve rdar://FB268002073203
                staredBookmarks.updateValue("http://yhdm.one", forKey: String(localized: "樱花动漫"))
                staredBookmarks.updateValue("https://math.microsoft.com", forKey: String(localized: "微软数学"))
                staredBookmarks.updateValue("https://tieba.baidu.com", forKey: String(localized: "百度贴吧"))
                staredBookmarks.updateValue("https://music.163.com", forKey: String(localized: "网易云音乐"))
                staredBookmarks.updateValue("https://bilibili.com", forKey: String(localized: "哔哩哔哩"))
                staredBookmarks.updateValue("https://qidian.com", forKey: String(localized: "起点小说"))
                staredBookmarks.updateValue("https://www.pixiv.pics", forKey: "Pixiv Viewer")
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
                    BookmarkStackManager.shared.push(
                        (markName, markLink.hasPrefix("https://") || markLink.hasPrefix("http://") ? markLink : "http://" + markLink)
                    )
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
    @Environment(\.presentationMode) var presentationMode
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
                    BookmarkStackManager.shared[BookmarkView.editingBookmarkIndex]
                    = (markName, markLink.hasPrefix("https://") || markLink.hasPrefix("http://") ? markLink : "http://" + markLink)
                    presentationMode.wrappedValue.dismiss()
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

class BookmarkStackManager {
    static let shared = BookmarkStackManager()
    
    typealias BookmarkData = (name: String, link: String)
    
    var endIndex: Int {
        UserDefaults.standard.integer(forKey: "BookmarkTotal")
    }
    
    func push(_ data: BookmarkData) {
        let total = endIndex &+ 1
        UserDefaults.standard.set(data.name, forKey: "BookmarkName\(total)")
        UserDefaults.standard.set(data.link, forKey: "BookmarkLink\(total)")
        UserDefaults.standard.set(total, forKey: "BookmarkTotal")
    }
    @discardableResult
    func pop() -> BookmarkData {
        let popedData = (UserDefaults.standard.string(forKey: "BookmarkName\(endIndex)")!,
                         UserDefaults.standard.string(forKey: "BookmarkLink\(endIndex)")!)
        UserDefaults.standard.removeObject(forKey: "BookmarkName\(endIndex)")
        UserDefaults.standard.removeObject(forKey: "BookmarkLink\(endIndex)")
        UserDefaults.standard.set(endIndex - 1, forKey: "BookmarkTotal")
        return popedData
    }
    
    @inline(__always)
    func _checkIndex(_ index: Int) {
        precondition(index <= endIndex, "Array index is out of range")
        precondition(index >= 0, "Negative Array index is out of range")
    }
    @inline(__always)
    func _checkSubscript(_ index: Int) {
        precondition(
            (index >= 0) && (index <= endIndex),
            "Index out of range"
        )
    }
    
    @inline(__always)
    func get(at index: Int) -> BookmarkData {
        _checkIndex(index)
        return (UserDefaults.standard.string(forKey: "BookmarkName\(index)")!, UserDefaults.standard.string(forKey: "BookmarkLink\(index)")!)
    }
    func getAll() -> [BookmarkData] {
        var result = [BookmarkData]()
        
        guard endIndex > 0 else { return result }
        
        for i in 1...endIndex {
            result.append((UserDefaults.standard.string(forKey: "BookmarkName\(i)")!, UserDefaults.standard.string(forKey: "BookmarkLink\(i)")!))
        }
        return result
    }
    func replaceAll(to newData: [BookmarkData]) {
        for i in 0..<newData.count {
            UserDefaults.standard.set(newData[i].name, forKey: "BookmarkName\(i + 1)")
            UserDefaults.standard.set(newData[i].link, forKey: "BookmarkLink\(i + 1)")
        }
        UserDefaults.standard.set(newData.count, forKey: "BookmarkTotal")
    }
    
    @discardableResult
    func remove(at index: Int) -> BookmarkData {
        var total = endIndex
        let removedData = self[index]
        var popedStack = [BookmarkData]()
        while total >= index {
            popedStack.append(pop())
            total--
        }
        popedStack.removeLast()
        for data in popedStack.reversed() {
            push(data)
            total++
        }
        UserDefaults.standard.set(total, forKey: "BookmarkTotal")
        return removedData
    }
    func insert(_ newElement: BookmarkData, at index: Int) {
        var total = endIndex
        var popedStack = [BookmarkData]()
        while total >= index {
            popedStack.append(pop())
            total--
        }
        push(newElement)
        total++
        popedStack.removeLast()
        for data in popedStack.reversed() {
            push(data)
            total++
        }
        UserDefaults.standard.set(total, forKey: "BookmarkTotal")
    }
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        var arrayData = getAll()
        arrayData.move(fromOffsets: source, toOffset: destination)
        replaceAll(to: arrayData)
    }
    
    @inlinable
    subscript(index: Int) -> BookmarkData {
        get {
            _checkSubscript(index)
            return get(at: index)
        }
        set {
            UserDefaults.standard.set(newValue.name, forKey: "BookmarkName\(index)")
            UserDefaults.standard.set(newValue.link, forKey: "BookmarkLink\(index)")
        }
    }
}
