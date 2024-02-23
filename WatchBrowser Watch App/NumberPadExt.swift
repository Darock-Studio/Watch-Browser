//
//  NumberPadExt.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/2/19.
//

// From GitHub repo: https://github.com/ApplebaumIan/SwiftUI-Apple-Watch-Decimal-Pad

import SwiftUI

public struct DigiTextView: View {
    private var locale: Locale
    var style: KeyboardStyle
    var placeholder: String
    @Binding public var text: String
    @State public var presentingModal: Bool
    
    var align: TextViewAlignment
    public init( placeholder: String, text: Binding<String>, presentingModal:Bool, alignment: TextViewAlignment = .center,style: KeyboardStyle = .numbers, locale: Locale = .current){
        _text = text
        _presentingModal = State(initialValue: presentingModal)
        self.align = alignment
        self.placeholder = placeholder
        self.style = style
        self.locale = locale
    }
    
    public var body: some View {
        Button(action: {
            presentingModal.toggle()
        }) {
            if text != ""{
                Text(text)
            }
            else{
                Text(placeholder)
                    .lineLimit(1)
                    .opacity(0.5)
            }
        }.buttonStyle(TextViewStyle(alignment: align))
        .sheet(isPresented: $presentingModal, content: {
            EnteredText(text: $text, presentedAsModal: $presentingModal, style: self.style, locale: locale)
        })
    }
}

public struct EnteredText: View {
    @Binding var text:String
    @Binding var presentedAsModal: Bool
    var style: KeyboardStyle
    var watchOSDimensions: CGRect?
    private var locale: Locale
    
    public init(text: Binding<String>, presentedAsModal:
                Binding<Bool>, style: KeyboardStyle, locale: Locale = .current){
        _text = text
        _presentedAsModal = presentedAsModal
        self.style = style
        self.locale = locale
        let device = WKInterfaceDevice.current()
        watchOSDimensions = device.screenBounds
    }
    public var body: some View{
        VStack(alignment: .trailing) {
                Button(action:{
                    presentedAsModal.toggle()
                }){
                    ZStack(content: {
                        Text("1")
                            .font(.title2)
                            .foregroundColor(.clear
                            )
                    })
                    Text(text)
                        .font(.title2)
                        .frame(height: watchOSDimensions!.height * 0.15, alignment: .trailing)
                }
                .buttonStyle(PlainButtonStyle())
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                
                DigetPadView(text: $text, style: style, locale: locale)
                    .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        }
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction){
                Button {
                    presentedAsModal.toggle()
                } label: {
                    Label("Done", systemImage: "xmark")
                }
            }
        })
        
    }
}

 public struct DigetPadView: View {
    public var widthSpace: CGFloat = 1.0
    @Binding var text:String
    var style: KeyboardStyle
    private var decimalSeparator: String
    public init(text: Binding<String>, style: KeyboardStyle, locale: Locale = .current) {
        _text = text
        self.style = style

        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        decimalSeparator = numberFormatter.decimalSeparator
    }
     public var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: widthSpace){
                Button(action: {
                    text.append("1")
                }) {
                    Text("1")
                        .padding(0)
                }
                .digitKeyFrame()
                Button(action: {
                    text.append("2")
                }) {
                    Text("2")
                }.digitKeyFrame()
                
                Button(action: {
                    text.append("3")
                }) {
                            Text("3")
                        }.digitKeyFrame()
            }
            HStack(spacing:widthSpace){
                Button(action: {
                    text.append("4")
                }) {
                    Text("4")
                }.digitKeyFrame()
                Button(action: {
                    text.append("5")
                }) {
                    Text("5")
                }.digitKeyFrame()
                
                Button(action: {
                    text.append("6")
                }) {
                    Text("6")
                }.digitKeyFrame()
            }
            
            HStack(spacing:widthSpace){
                Button(action: {
                    text.append("7")
                }) {
                    Text("7")
                }.digitKeyFrame()
                Button(action: {
                    text.append("8")
                }) {
                    Text("8")
                }.digitKeyFrame()
                
                Button(action: {
                    text.append("9")
                }) {
                    Text("9")
                }
                .digitKeyFrame()
            }
            HStack(spacing:widthSpace) {
                if style == .decimal {
                    Button(action: {
                        if !(text.contains(decimalSeparator)){
                            if text == ""{
                                text.append("0\(decimalSeparator)")
                            }else{
                                text.append(decimalSeparator)
                            }
                        }
                    }) {
                        Text(decimalSeparator)
                    }
                    .digitKeyFrame()
                } else {
                    Spacer()
                        .padding(1)
                }
                Button(action: {
                    text.append("0")
                }) {
                    Text("0")
                }
                .digitKeyFrame()
                
                Button(action: {
                    if let last = text.indices.last{
                        text.remove(at: last)
                    }
                }) {
                    Image(systemName: "delete.left")
                }
                .digitKeyFrame()
            }
        }
        .font(.title2)
    }
}

struct TextViewStyle: ButtonStyle {
    init(alignment: TextViewAlignment = .center) {
        self.align = alignment
    }
    
    
    var align: TextViewAlignment
    func makeBody(configuration: Configuration) -> some View {
            HStack {
                if align == .center || align == .trailing{
                Spacer()
                }
                configuration.label
                    .font(/*@START_MENU_TOKEN@*/.body/*@END_MENU_TOKEN@*/)
                    .padding(.vertical, 11.0)
                    .padding(.horizontal)
                if align == .center || align == .leading{
                Spacer()
                }
            }
            .background(
                GeometryReader { geometry in
                    ZStack{
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(configuration.isPressed ? Color.gray.opacity(0.1): Color.gray.opacity(0.2))
                    }
            })
            
    }
}

public struct DigitButtonModifier: ViewModifier {
    public func body(content: Content) -> some View {
        return content
            .buttonStyle(DigitPadStyle())

    }
}

public extension Button {
    func digitKeyFrame() -> some View {
        self.modifier(DigitButtonModifier())
    }
}

public struct DigitPadStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        GeometryReader(content: { geometry in
            configuration.isPressed ?
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.gray.opacity(0.7))
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(1.5)
                :
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.gray.opacity(0.5))
                .frame(width:  geometry.size.width, height:  geometry.size.height)
                .scaleEffect(1)
            
            configuration.label
                .background(
                    ZStack {
                        GeometryReader(content: { geometry in
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.clear)
                                .frame(width: configuration.isPressed ? geometry.size.width/0.75 : geometry.size.width, height: configuration.isPressed ? geometry.size.height/0.8 : geometry.size.height)
                                
                        })
                        
                        
                    }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(configuration.isPressed ? 1.2 : 1)
        })
            .onChange(of: configuration.isPressed, perform: { value in
                if configuration.isPressed{
                    DispatchQueue.main.async {
                        #if os(watchOS)
                        WKInterfaceDevice().play(.click)
                        #endif
                        
                    }
                }
            })
        
    }
}

public enum TextViewAlignment {
    case trailing
    case leading
    case center
}

public enum KeyboardStyle {
    case decimal
    case numbers
}
