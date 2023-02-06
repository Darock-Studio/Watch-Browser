////
////  ExtKeyboardView.swift
////  WatchBrowser Watch App
////
////  Created by Windows MEMZ on 2023/2/6.
////
//
//import SwiftUI
//
//struct ExtKeyboardView: View {
//    @State var inputText = ""
//    var body: some View {
//        VStack {
//            HStack {
//                Button(action: {
//
//                }, label: {
//                    Text("取消")
//                })
//                .background(Color.black)
//                Spacer()
//                Button(action: {
//
//                }, label: {
//                    Text("完成")
//                        .foregroundColor(Color(hex: 0x2093f9))
//                })
//                .background(Color.black)
//            }
//            Text(inputText)
//            HStack {
//                Button(action: {
//
//                }, label: {
//                    Text("q")
//                })
//                Button(action: {
//
//                }, label: {
//                    Text("w")
//                })
//                Button(action: {
//
//                }, label: {
//                    Text("e")
//                })
//                Button(action: {
//
//                }, label: {
//                    Text("r")
//                })
//                Button(action: {
//
//                }, label: {
//                    Text("t")
//                })
//                Button(action: {
//
//                }, label: {
//                    Text("y")
//                })
//                Button(action: {
//
//                }, label: {
//                    Text("u")
//                })
//                Button(action: {
//
//                }, label: {
//                    Text("i")
//                })
//                Button(action: {
//
//                }, label: {
//                    Text("o")
//                })
//                Button(action: {
//
//                }, label: {
//                    Text("p")
//                })
//            }
//        }
//    }
//}
//
//extension Color {
//    init(hex: Int, alpha: Double = 1) {
//        let components = (
//            R: Double((hex >> 16) & 0xff) / 255,
//            G: Double((hex >> 08) & 0xff) / 255,
//            B: Double((hex >> 00) & 0xff) / 255
//        )
//        self.init(
//            .sRGB,
//            red: components.R,
//            green: components.G,
//            blue: components.B,
//            opacity: alpha
//        )
//    }
//}
//
//struct ExtKeyboardView_Previews: PreviewProvider {
//    static var previews: some View {
//        ExtKeyboardView()
//    }
//}
