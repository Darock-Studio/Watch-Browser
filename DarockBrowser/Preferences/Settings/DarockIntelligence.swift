//
//  DarockIntelligence.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import DarockUI

extension SettingsView {
    struct DarockIntelligenceView: View {
        @AppStorage("IsProPurchased") var isProPurchased = false
        @AppStorage("DIWebAbstractLangOption") var webAbstractLangOption = "Web"
        @AppStorage("DIWebAbstractModelOption") var webAbstractModelOption = "Faster"
        @State var isPrivacySplashPresented = false
        var body: some View {
            if isProPurchased {
                List {
                    Section {
                        Picker("摘要语言", selection: $webAbstractLangOption) {
                            Text("网页语言").tag("Web")
                            Text("系统语言").tag("System")
                        }
                        Picker("摘要内容偏好", selection: $webAbstractModelOption) {
                            Text("更快生成").tag("Faster")
                            Text("更精确内容").tag("Accurater")
                        }
                    } header: {
                        Text("网页摘要")
                    }
                    Section {
                        Button(action: {
                            isPrivacySplashPresented = true
                        }, label: {
                            Text("关于 Darock 智能与隐私")
                        })
                    }
                }
                .navigationTitle("Darock 智能")
                .sheet(isPresented: $isPrivacySplashPresented) {
                    PrivacyAboutView(
                        title: "关于 Darock 智能与隐私",
                        description: Text("使用 Darock 智能时，部分数据可能会在设备外处理。\(Text("进一步了解...").foregroundColor(.blue))"),
                        detailText: """
                        **Darock 智能与隐私**
                        
                        Darock 智能旨在保护你的信息并可让你选择共享的内容。
                        
                        ### 网页摘要
                        使用网页摘要时，网页中的文本信息会被发送到设备外的 Darock 智能服务进行处理。这些信息不会被存储，且不会关联到个人。
                        """
                    )
                }
            } else {
                ProUnavailableView()
            }
        }
    }
}
