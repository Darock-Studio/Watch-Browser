//
//  EnginesView.swift
//  WatchBrowser Watch App
//
//  Created by Windows MEMZ on 2023/2/6.
//

import SwiftUI

struct EnginesView: View {
    @AppStorage("WebSearch") var webSearch = 0
    enum EngineNames: String, CaseIterable {
        case bing = "必应"
        case baidu = "百度"
        case google = "谷歌"
        case sougou = "搜狗"
    }
    
    var body: some View {
        NavigationView {
            Picker(selection: $webSearch, label: Label("搜索引擎", systemImage: "magnifyingglass.circle.fill")) {
                ForEach(EngineNames.allCases, id: \.self) {EngineNames in
                    Text(EngineNames.rawValue).tag(EngineNames)
                }
            }
        }
        .navigationTitle("搜索引擎")
    }
}

struct EnginesView_Previews: PreviewProvider {
    static var previews: some View {
        EnginesView()
    }
}
