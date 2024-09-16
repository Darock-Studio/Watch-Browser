//
//  Search.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/9/16.
//

import SwiftUI
import WidgetKit

struct SearchWidgets: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SearchWidgets", provider: SearchProvider()) { entry in
            SearchWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("搜索")
        .description("快速开始搜索")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

private struct SearchProvider: TimelineProvider {
    func placeholder(in context: Context) -> SearchEntry {
        let availability = UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.bool(forKey: "IsProWidgetsAvailable")
        return SearchEntry(availability: availability)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SearchEntry) -> Void) {
        let availability = UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.bool(forKey: "IsProWidgetsAvailable")
        completion(SearchEntry(availability: availability))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SearchEntry>) -> Void) {
        let availability = UserDefaults(suiteName: "group.darock.WatchBrowser.Widgets")!.bool(forKey: "IsProWidgetsAvailable")
        completion(.init(entries: [SearchEntry(availability: availability)], policy: .never))
    }
}

private struct SearchEntry: TimelineEntry {
    var date: Date = Date.now
    
    let availability: Bool
}

private struct SearchWidgetsEntryView: View {
    var entry: SearchProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    var body: some View {
        VStack {
            if entry.availability {
                switch widgetFamily {
                case .accessoryInline:
                    Label("使用暗礁浏览器搜索", systemImage: "magnifyingglass")
                case .accessoryCircular:
                    Image(systemName: "magnifyingglass")
                        .font(.system(.title))
                case .accessoryRectangular:
                    Label("使用暗礁浏览器搜索", systemImage: "magnifyingglass")
                default: EmptyView()
                }
            } else {
                switch widgetFamily {
                case .accessoryInline:
                    Label("快速搜索不可用", systemImage: "xmark")
                case .accessoryCircular:
                    Image(systemName: "xmark")
                        .font(.system(.title))
                case .accessoryRectangular:
                    Label("快速搜索不可用", systemImage: "xmark")
                default: EmptyView()
                }
            }
        }
    }
}
