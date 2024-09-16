//
//  Intents.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/9/16.
//

import AppIntents

@available(watchOS 10.0, *)
struct BookmarkWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "书签"
    static var description = IntentDescription("快速打开网页")
    
    @Parameter(title: "名称") var displayName: String?
    @Parameter(title: "符号") var displaySymbol: String?
    @Parameter(title: "链接") var url: String?
}
