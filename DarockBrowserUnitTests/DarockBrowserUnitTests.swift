//
//  DarockBrowserUnitTests.swift
//  DarockBrowserUnitTests
//
//  Created by memz233 on 7/1/24.
//

import Testing
@testable import DarockBrowser

struct HistoryTests {
    @Test(arguments: [
        HistoryMergeTestItem(primary: [.init(url: "1", time: 5), .init(url: "2", time: 3), .init(url: "3", time: 1)],
                             secondary: [.init(url: "4", time: 4), .init(url: "5", time: 2)],
                             expectedResult: ["1", "4", "2", "5", "3"]),
        HistoryMergeTestItem(primary: [.init(url: "1", time: 1000), .init(url: "2", time: 500), .init(url: "3", time: 100)],
                             secondary: [.init(url: "4", time: 1500), .init(url: "5", time: 99)],
                             expectedResult: ["4", "1", "2", "3", "5"]),
        HistoryMergeTestItem(primary: [],
                             secondary: [.init(url: "1", time: 1500), .init(url: "2", time: 1000)],
                             expectedResult: ["1", "2"]),
        HistoryMergeTestItem(primary: [],
                             secondary: [.init(url: "1", time: 1000), .init(url: "2", time: 1500)],
                             expectedResult: ["2", "1"]),
        HistoryMergeTestItem(primary: [.init(url: "1", time: 1000), .init(url: "2", time: 1500)],
                             secondary: [],
                             expectedResult: ["1", "2"]),
        HistoryMergeTestItem(primary: [.init(url: "1", time: 1500), .init(url: "2", time: 1000)],
                             secondary: [],
                             expectedResult: ["1", "2"]),
        HistoryMergeTestItem(primary: [.init(url: "1", time: 1000), .init(url: "2", time: 500), .init(url: "3", time: 100)],
                             secondary: [.init(url: "4", time: 1000), .init(url: "5", time: 100)],
                             expectedResult: ["1", "2", "3"]),
        HistoryMergeTestItem(primary: [.init(url: "1", time: 1000), .init(url: "2", time: 500), .init(url: "3", time: 100)],
                             secondary: [.init(url: "4", time: 1000), .init(url: "5", time: 150)],
                             expectedResult: ["1", "2", "5", "3"])
    ]) func testHistoryMerge(by item: HistoryMergeTestItem) async throws {
        let result = MergeWebHistoriesBetween(primary: item.primary, secondary: item.secondary)
        let zippedResults = zip(result, item.expectedResult)
        #expect(zippedResults.allSatisfy { lhs, rhs in lhs.url == rhs }, .init(stringLiteral: result.description))
    }
    
    struct HistoryMergeTestItem {
        var primary: [SingleHistoryItem]
        var secondary: [SingleHistoryItem]
        var expectedResult: [String]
    }
}
