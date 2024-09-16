//
//  Bookmark.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/9/16.
//

import SwiftUI
import WidgetKit

struct BookmarkWidgets: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "BookmarkWidgets", intent: BookmarkWidgetIntent.self, provider: BookmarkProvider()) { entry in
            BookmarkWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("书签")
        .description("快速打开书签")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

private struct BookmarkProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BookmarkEntry {
        BookmarkEntry(displayName: String(localized: "书签"), displaySymbol: "bookmark.fill", url: "https://darock.top")
    }
    
    func recommendations() -> [AppIntentRecommendation<BookmarkWidgetIntent>] {
        guard UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.bool(forKey: "IsProWidgetsAvailable") else {
            return []
        }
        
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.darock.WatchBrowser.Widgets")!.path
        
        var result = [AppIntentRecommendation<BookmarkWidgetIntent>]()
        
        if let _bookmarksStr = try? String(contentsOfFile: containerPath + "/WidgetBookmarks.drkdataw", encoding: .utf8),
           let bookmarks = getJsonData([SingleWidgetBookmark].self, from: _bookmarksStr) {
            for bookmark in bookmarks {
                let intent = BookmarkWidgetIntent()
                intent.displayName = bookmark.displayName
                intent.displaySymbol = bookmark.displaySymbol
                intent.url = bookmark.link
                result.append(AppIntentRecommendation(intent: intent, description: bookmark.displayName))
            }
        }
        
        return result
    }
    
    func snapshot(for configuration: Intent, in context: Context) async -> BookmarkEntry {
        return BookmarkEntry(
            displayName: configuration.displayName ?? "",
            displaySymbol: configuration.displaySymbol ?? "bookmark.fill",
            url: configuration.url ?? ""
        )
    }
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let timeline = Timeline(entries: [BookmarkEntry(
            displayName: configuration.displayName ?? "",
            displaySymbol: configuration.displaySymbol ?? "bookmark.fill",
            url: configuration.url ?? ""
        )], policy: .never)
        return timeline
    }
}

private struct BookmarkEntry: TimelineEntry {
    var date: Date = Date.now
    
    let displayName: String
    let displaySymbol: String
    let url: String
}

private struct BookmarkWidgetsEntryView: View {
    var entry: BookmarkProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    var body: some View {
        VStack {
            switch widgetFamily {
            case .accessoryInline:
                HStack {
                    Image(systemName: entry.displaySymbol)
                    Text(entry.displayName)
                        .lineLimit(1)
                }
            case .accessoryCircular:
                Image(systemName: entry.displaySymbol)
                    .font(.system(.title))
            case .accessoryRectangular:
                HStack {
                    Image(systemName: entry.displaySymbol)
                    Text(entry.displayName)
                        .bold()
                }
                Text(entry.url)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(.horizontal)
            default: EmptyView()
            }
        }
    }
}
