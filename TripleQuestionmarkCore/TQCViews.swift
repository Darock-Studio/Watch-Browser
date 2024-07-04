//
//  TQCViews.swift
//  TripleQuestionmarkCore
//
//  Created by memz233 on 6/21/24.
//

import SwiftUI
internal import Vela

/// Get a view which can convert any natural number to 0, 7, 2 and 1. 😋
public struct TQCOnaniiView: View {
    @State var numInput = ""
    @State var result = ""
    @State var navigationTitle = "???"
    
    public init() { }
    
    public var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(text: $numInput) {
                        Text("输入一个自然数")
                    }
                    .onSubmit {
                        result = to0721(from: numInput)
                        navigationTitle = "Ciallo~"
                    }
                }
                Section {
                    Text(result)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func to0721(from num: String) -> String {
        let onanii: [Int: String] = [
            0: "0×7×2×1",
            1: "0×7+2-1",
            2: "(0×7+2)×1",
            3: "0×7+2+1",
            4: "0+7-2-1",
            5: "(0+7-2)×1",
            6: "0+7-2+1",
            7: "(0+7)×(2-1)",
            8: "0+7+2-1",
            9: "(0+7+2)×1",
            10: "0+7+2+1",
            13: "(0+7)×2-1",
            14: "(0+7)×2×1",
            15: "(0+7)×2+1",
            21: "(0+7)×(2+1)",
            48: "(0-7)^2-1",
            49: "(0-7)^2×1",
            50: "(0-7)^2+1",
            11: "((0+7)×2-1+0-7)×2-1",
            12: "((0+7)×2-1+0-7)×2×1",
            16: "((0+7)×2+1+0-7)×2×1",
            17: "((0+7)×2+1+0-7)×2+1",
            18: "0+7+2-1+0+7+2+1",
            19: "(0+7)×2-1+0+7-2+1",
            20: "((0+7)×2+1+0+7-2)×1",
            22: "((0+7)×2-1+0+7+2)×1",
            23: "(0+7)×2-1+0+7+2+1",
            24: "0+7+2×(1+0+7)+2-1",
            25: "(0+7-2-1+0)×7-2-1",
            26: "((0+7-2-1+0)×7-2)×1",
            27: "(0+7-2-1+0)×7-2+1",
            28: "(0+7)×2+1+0+7×2-1",
            29: "(0+7+2-1+0+7)×2-1",
            30: "(0+7+2-1+0+7)×2×1",
            31: "(0+7+2-1+0+7)×2+1",
            32: "((0-7+2)×(1+0-7)+2)×1",
            33: "(0-7+2)×(1+0-7)+2+1",
            34: "(0+7+2+1+0+7)×2×1",
            35: "((0-7)×2+1+0+7)^2-1",
            36: "((0-7)×2+1+0+7)^2×1",
            37: "(0+7-2)×(1+0+7)-2-1",
            38: "((0+7-2)×(1+0+7)-2)×1",
            39: "(0+7-2)×(1+0+7)-2+1",
            40: "(0-7)^2-1+0-7-2+1",
            41: "(0+7-2)×(1+0+7)+2-1",
            42: "((0+7-2)×(1+0+7)+2)×1",
            43: "(0+7-2)×(1+0+7)+2+1",
            44: "(0-7)^2-1+0-7+2+1",
            45: "(0-7)^2-1+0×7-2-1",
            46: "((0-7)^2-1+0×7-2)×1",
            47: "(0-7)^2-1+0×7-2+1"
        ]
        
        func printOnanii(_ s: Int, dic: [Int: String]) -> String {
            var s = s
            var result = ""
            if s == 721 {
                result = "0721"
            } else {
                while s > 50 {
                    let digi = Int(floor(log10(Double(s)) / 1.6989700043360188047862611052755))
                    let tmp = s % Int(pow(50.0, Double(digi)))
                    if digi == 1 {
                        result += "(\(dic[Int((s - tmp) / Int(pow(50.0, Double(digi))))]!))×((0-7)^2+1)+"
                    } else {
                        result += "(\(dic[Int((s - tmp) / Int(pow(50.0, Double(digi))))]!))×((0-7)^2+1)^(\(dic[digi]!))+"
                    }
                    s = tmp
                }
                result += dic[s] ?? ""
            }
            return result
        }
        
        func calculateOnanii(userInput: String) -> String {
            guard let userInput = Int(userInput) else {
                return "Invalid input"
            }
            let result = printOnanii(userInput, dic: onanii)
            return "\(userInput) = \(result)"
        }
        
        return calculateOnanii(userInput: num)
    }
}

/// Get a button that can change the accent color of Darock Browser. 😇
/// This button should be put in List.
public struct TQCAccentColorHiddenButton: View {
    var unlockHandler: () -> Void
    @AppStorage("TQCIsColorChangeButtonUnlocked") private var isColorChangeButtonUnlocked = false
    @AppStorage("TQCIsColorChangeButtonEntered") private var isColorChangeButtonEntered = false
    @State private var buttonOpacity = 0.0100000002421438702673861521
    
    public init(unlockHandler: @escaping () -> Void = { }) {
        self.unlockHandler = unlockHandler
    }
    
    public var body: some View {
        NavigationLink(destination: { AccentColorChangeView() }, label: {
            HStack {
                if isColorChangeButtonEntered {
                    Text("更改主题色")
                } else {
                    Text("???")
                }
                Spacer()
            }
        })
        .disabled(!isColorChangeButtonUnlocked && buttonOpacity < 1.0)
        .opacity(isColorChangeButtonUnlocked ? 1.0 : buttonOpacity)
        .listRowBackground(Color(red: 31 / 255, green: 31 / 255, blue: 32 / 255, opacity: isColorChangeButtonUnlocked ? 1.0 : buttonOpacity).cornerRadius(10))
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    buttonOpacity += abs(value.translation.width) / 5000.0
                }
        )
        .onChange(of: buttonOpacity) { value in
            if value >= 1.0 {
                if !isColorChangeButtonUnlocked {
                    unlockHandler()
                    isColorChangeButtonUnlocked = true
                }
            }
        }
    }
    
    struct AccentColorChangeView: View {
        @AppStorage("TQCIsColorChangeButtonEntered") var isColorChangeButtonEntered = false
        @AppStorage("TQCIsOverrideAccentColor") var isOverrideAccentColor = false
        @AppStorage("TQCOverrideAccentColorRed") var overrideAccentColorRed = 0.0
        @AppStorage("TQCOverrideAccentColorGreen") var overrideAccentColorGreen = 0.0
        @AppStorage("TQCOverrideAccentColorBlue") var overrideAccentColorBlue = 0.0
        @State var inputColor = Color(red: 0, green: 0, blue: 0)
        var body: some View {
            List {
                Section {
                    VelaPicker(color: $inputColor, defaultColor: .accentColor, allowOpacity: false, label: {
                        HStack {
                            Text("选择颜色...")
                            Spacer()
                        }
                        .frame(width: WKInterfaceDevice.current().screenBounds.width)
                    }, onSubmit: {
                        var red = CGFloat.zero
                        var green = CGFloat.zero
                        var blue = CGFloat.zero
                        UIColor(inputColor).getRed(&red, green: &green, blue: &blue, alpha: nil)
                        overrideAccentColorRed = red
                        overrideAccentColorGreen = green
                        overrideAccentColorBlue = blue
                        isOverrideAccentColor = true
                    })
                    HStack {
                        Text("当前：")
                        (isOverrideAccentColor ? inputColor : Color.accentColor)
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                        Spacer()
                    }
                }
                Section {
                    Button(action: {
                        isOverrideAccentColor = false
                    }, label: {
                        Text("还原为默认值...")
                    })
                }
            }
            .navigationTitle("更改主题色")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                inputColor = Color(red: overrideAccentColorRed, green: overrideAccentColorGreen, blue: overrideAccentColorBlue)
                isColorChangeButtonEntered = true
            }
        }
    }
}

@ViewBuilder
internal func Text(_ key: LocalizedStringKey) -> some View {
    Text(key, bundle: Bundle(url: Bundle.main.privateFrameworksURL!.appending(path: "TripleQuestionmarkCore.framework")))
}
