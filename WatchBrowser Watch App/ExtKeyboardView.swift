//
//  AW键盘.swift
//  WatchDic Watch App
//
//  Created by 凌嘉徽 on 2023/1/22.
//

import Foundation
import SwiftUI
import Combine

//有按钮点击的通知
let keyTap = PassthroughSubject<Void,Never>()

//用来表明输入的字符
struct charater:Identifiable,Equatable {
    var value:String
    var id = UUID()
}

struct ExtKeyboardView: View {
    var startText = ""
    let firstRow = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    let secondRow = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    let thirdRow = ["Z", "X", "C", "V", "B", "N", "M"]
    let numFirstRow = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    let numSecondRow = ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""]
    let numThirdRow = [".", ",", "?", "!", "'"]
    let symbolFirstRow = ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]
    let symbolSecondRow = ["_", "\\", "|", "~", "<", ">", "·"]
    @State var lastTimeTap = Date.distantPast
    @State var fullText = [charater]()
    @State var isShowingNumber = false
    @State var isShowingSymbol = false
    var body: some View {
        VStack(spacing:0) {
            TextDisplayView(fullText: $fullText, cursor: $cursor)
            if !isShowingNumber {
                EachRowView(allCharater: firstRow,dect: true,onTap: add)
            } else {
                if isShowingSymbol {
                    EachRowView(allCharater: symbolFirstRow,dect: true,onTap: add)
                } else {
                    EachRowView(allCharater: numFirstRow,dect: true,onTap: add)
                }
            }
            if !isShowingNumber {
                EachRowView(allCharater: secondRow,onTap: add)
            } else {
                if isShowingSymbol {
                    EachRowView(allCharater: symbolSecondRow,onTap: add, widthFix: 7)
                } else {
                    EachRowView(allCharater: numSecondRow,onTap: add)
                }
            }
            HStack {
                if !isShowingNumber {
                    Button(action: {
                        if lastTimeTap.distance(to: .now) < 0.3 {
                            if upper {
                                isCapsLock = true
                            } else {
                                //小写下双击，忽略
                                isCapsLock = false
                            }
                        } else {
                            upper.toggle()
                            isCapsLock = false
                        }
                        lastTimeTap = .now
                    }, label: {
                        Color.gray
                            .cornerRadius(3)
                            .opacity(0.0100000002421438702673861521)
                            .frame(width: 20)
                            .overlay {
                                if upper {
                                    Image(systemName: "arrow.up.square.fill")
                                } else {
                                    Image(systemName: "arrow.up.square")
                                }
                            }
                    })
                    .onReceive(keyTap, perform: { _ in
                        if !isCapsLock {
                            upper = false
                        }
                    })
                    .buttonStyle(.plain)
                } else {
                    Button(action: {
                        isShowingSymbol.toggle()
                    }, label: {
                        Color.gray
                            .cornerRadius(3)
                            .opacity(0.0100000002421438702673861521)
                            .frame(width: 25)
                            .overlay {
                                Text("#+=")
                                    .font(.system(size: 9))
                                    .padding(2)
                                    .border(Color.white, width: 1, cornerRadius: 3)
                            }
                    })
                    .buttonStyle(.plain)
                }
                if !isShowingNumber {
                    EachRowView(allCharater: thirdRow,onTap: add)
                } else {
                    EachRowView(allCharater: numThirdRow,onTap: add, widthFix: 8)
                }
                Button(action: {
                    if isShowingNumber {
                        isShowingSymbol = false
                    }
                    isShowingNumber.toggle()
                }, label: {
                    Color.gray
                        .cornerRadius(3)
                        .opacity(0.0100000002421438702673861521)
                        .frame(width: 20)
                        .overlay {
                            if !isShowingNumber {
                                Image(systemName: "textformat.123")
                                    .font(.system(size: 9))
                                    .padding(2)
                                    .padding(.vertical, 2)
                                    .border(Color.white, width: 1, cornerRadius: 3)
                            } else {
                                Image(systemName:"abc")
                                    .font(.system(size: 9))
                                    .padding(2)
                                    .padding(.vertical, 2)
                                    .border(Color.white, width: 1, cornerRadius: 3)
                            }
                        }
                })
                .buttonStyle(.plain)
            }
            //最底部三个按键
            BottomLine(cursor: $cursor, fullText: $fullText, upper: $upper, onTap: add)
        }
        //输入文字时带上动画
        .animation(.easeOut, value: fullText)
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(action: {
                    dismiss()
                    onFinished(Combine())
                }, label: {
                    if #available(watchOS 10.0, *) {
                        Image(systemName: "checkmark")
                    } else {
                        Text("完成")
                    }
                })
            })
        }
        .edgesIgnoringSafeArea([.horizontal,.bottom])
        //允许从已有内容继续编辑
        .onAppear(perform: {
            startText.forEach { e in
                fullText.append(.init(value: String(e)))
            }
        })
        .onChange(of: fullText, perform: { value in
            //自动滚动（当用户把光标滑到屏幕外后，继续编辑时跳转回光标位置）
        })
    }
    //有按钮点击
    func add(_ t:String) {
        keyTap.send()
        var t = t
        if upper {
            t = (t).uppercased()
        } else {
            if isCapsLock {
                t = (t).uppercased()
            } else {
                t = t.lowercased()
            }
        }
        //更新文本后记得移动光标
        if cursor == -1 {
            fullText.append(.init(value: t))
        } else {
            fullText.insert(.init(value: t), at: cursor)
            cursor += 1
        }
    }
    func Combine() -> String {
        var back = ""
        fullText.forEach { e in
            back += e.value
        }
        return back
    }
    @State var upper = false//是否大写
    @State var cursor = -1//光标的位置
    @Environment(\.dismiss) var dismiss
    var onFinished:(String) -> () = { _ in }
}

struct TextDisplayView: View {
    @Binding var fullText : [charater]
    @Binding var cursor:Int
    @Namespace private var MYcursor
    @GestureState var isDetectingLongPress = false
    @State var completedLongPress = false
    @State var TriggerTime = Date.now
    @State var isGestureTriggered = false
    @State var crownRatation = 0.0
    let timer = Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()
    var body: some View {
        HStack {
            ScrollViewReader(content: { p in
                ScrollView(.horizontal, showsIndicators: false, content: {
                    HStack(spacing: 0, content: {
                        ForEach(fullText, content: { c in
                            let index = fullText.firstIndex(where: { $0.id == c.id })!
                            HStack(spacing: 0) {
                                if cursor == index {
                                    Color.accentColor
                                        .frame(width: 3, height: 26)
                                        .cornerRadius(3)
                                        .matchedGeometryEffect(id: "ID", in: MYcursor)
                                        .id("光标")
                                }
                                Text(c.value)
                                    .padding(.bottom)
                                    .onTapGesture {
                                        cursor = index
                                    }
                            }
                            
                        })
                        if cursor == -1 {
                            Color.accentColor
                                .frame(width: 3, height: 26)
                                .cornerRadius(3)
                                .matchedGeometryEffect(id: "ID", in: MYcursor)
                                .id("光标")
                        }
                        Color.black
                            .opacity(0.001)
                            .frame(width: fullWidth/2)
                            .onTapGesture {
                                cursor = -1
                            }
                            
                    })
                })
                .onChange(of: fullText, perform: { f in
                    withAnimation(.easeOut) {
                        p.scrollTo("光标", anchor: .trailing)
                    }
                })
            })
            Button(action: {
                DeleteOneCha()
            }, label: {
                Image(systemName: "delete.left.fill")
            })
            .frame(width: 20)
            .buttonStyle(.plain)
            .simultaneousGesture(LongPressGesture(minimumDuration: 999)
                .updating($isDetectingLongPress) { currentState, gestureState, transaction in
                    gestureState = currentState
                    transaction.animation = Animation.easeIn(duration: 2.0)
                })
            .onChange(of: isDetectingLongPress, perform: { i in
                isGestureTriggered = i
                if i {
                    TriggerTime = .now
                }
            })
            .onReceive(timer, perform: { i in
                if isGestureTriggered {
                    if TriggerTime.distance(to: .now) > 0.3 {
                        DeleteOneCha()
                    }
                }
            })
        }
        .focusable()
        .digitalCrownRotation($crownRatation, from: 0, through: Double(fullText.count), by: 1, sensitivity: .low)
        .onChange(of: crownRatation, perform: { value in
            if Int(crownRatation) <= fullText.count - 1 {
                cursor = Int(crownRatation)
            } else {
                cursor = -1
            }
        })
    }
    fileprivate func DeleteOneCha() {
        if cursor == -1 {
            fullText = fullText.dropLast()
        } else {
            let index = cursor-1
            if index >= fullText.startIndex && index <= fullText.endIndex {
                fullText.remove(at: index)
                cursor -= 1
            } else {
                //Drop Once
            }
            
        }
    }
}
var isCapsLock = false
struct EachRowView: View {
    var allCharater:[String]
    var dect = false
    var onTap:(String) -> ()
    var widthFix: CGFloat = 10
    @State var isKeyPressed = Array<Bool>(repeating: false, count: 20)
    var body: some View {
        HStack(spacing:0) {
            ForEach(0..<allCharater.count, id: \.self) { i in
                Button(action: {
                    onTap(allCharater[i])
                }, label: {
                    Color.gray
                        .cornerRadius(3)
                        .opacity(isKeyPressed[i] ? 0.8 : 0.0100000002421438702673861521)
                        .frame(width:fullWidth/widthFix)
                        .overlay {
                            if isCapsLock {
                                Text(allCharater[i].uppercased())
                                    .font(.system(size: 20))
                            } else {
                                Text(allCharater[i].lowercased())
                                    .font(.system(size: 20))
                            }
                        }
                })
                //.buttonStyle(.plain)
                .buttonStyle(KeyboardKeyButton(isPressed: $isKeyPressed[i]))
            }
        }
    }
    
    struct KeyboardKeyButton: ButtonStyle {
        @Binding var isPressed: Bool
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .onChange(of: configuration.isPressed) { value in
                    isPressed = value
                }
        }
    }
}

struct BottomLine: View {
    @Binding var cursor:Int
    @Binding var fullText: [charater]
    @Binding var upper:Bool
    var onTap:(String) -> ()
    @GestureState var isDetectingLongPress = false
    @State var completedLongPress = false
    @State var lastTimeTap = Date.distantPast
    let timer = Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()
    fileprivate func DeleteOneCha() {
        if cursor == -1 {
            fullText = fullText.dropLast()
        } else {
            let index = cursor-1
            if index >= fullText.startIndex && index <= fullText.endIndex {
                fullText.remove(at: index)
                cursor -= 1
            } else {
                //Drop Once
            }
            
        }
    }
    
    var body: some View {
        HStack(spacing:0) {
            Button(action: {
                onTap(" ")
            }, label: {
                Text("Keyboard.space")
            })
            //支持长按
        }      .buttonStyle(.plain)
            .onReceive(timer, perform: { i in
                if isGestureTriggered {
                    if TriggerTime.distance(to: .now) > 0.3 {
                        DeleteOneCha()
                    }
                }
            })
    }
    @State var TriggerTime = Date.now
    @State var isGestureTriggered = false
}


private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
var h = 0.0
let fullWidth = WKInterfaceDevice.current().screenBounds.size.width

import Combine

let finalWidth = CurrentValueSubject<Double,Never>(999.0)
