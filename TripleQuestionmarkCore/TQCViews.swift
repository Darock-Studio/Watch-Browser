//
//  TQCViews.swift
//  TripleQuestionmarkCore
//
//  Created by memz233 on 6/21/24.
//

import SwiftUI

/// Get a view which can convert any natural number to 0, 7, 2 and 1. 😋
public struct TQCOnaniiView: View {
    @State var numInput = ""
    @State var result = ""
    
    public init() { }
    
    public var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("输入一个自然数", text: $numInput)
                        .onSubmit {
                            result = to0721(from: numInput)
                        }
                }
                Section {
                    Text(result)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("???")
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
                // 打开 Snackbar 的代码需要在实际的 iOS 应用程序中实现
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
