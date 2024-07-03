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

struct URLProcessorTests {
    @Test(arguments: [
        GeneralTestArgument(input: "darock.top", expectedOutput: "top"),
        GeneralTestArgument(input: "darock.co", expectedOutput: "co"),
        GeneralTestArgument(input: "darock.top/", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top/", expectedOutput: "top"),
        GeneralTestArgument(input: "darock.top/darockbrowser", expectedOutput: "top"),
        GeneralTestArgument(input: "darock.top/darockbrowser/", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top/darockbrowser", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top/darockbrowser/", expectedOutput: "top"),
        GeneralTestArgument(input: "abc.darock.top", expectedOutput: "top"),
        GeneralTestArgument(input: "abc.darock.top/", expectedOutput: "top"),
        GeneralTestArgument(input: "https://abc.darock.top/", expectedOutput: "top"),
        GeneralTestArgument(input: "https://abc.darock.top/darockbrowser", expectedOutput: "top"),
        GeneralTestArgument(input: "https://abc.darock.top/darockbrowser/", expectedOutput: "top"),
        GeneralTestArgument(input: "Test", expectedOutput: nil),
        GeneralTestArgument(input: "...", expectedOutput: nil),
        GeneralTestArgument(input: "哇袄", expectedOutput: nil),
        GeneralTestArgument(input: "../...//./../.", expectedOutput: nil),
        GeneralTestArgument(input: "////", expectedOutput: nil),
        GeneralTestArgument(input: ".//.", expectedOutput: nil),
        GeneralTestArgument(input: "", expectedOutput: nil),
        GeneralTestArgument(input: " ", expectedOutput: nil),
        GeneralTestArgument(input: "darock.top/.well-known", expectedOutput: "top"),
        GeneralTestArgument(input: "darock.top/.well-known/", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top/.well-known", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top/.well-known/", expectedOutput: "top"),
        GeneralTestArgument(input: "darock.top/.well-known/0721.mp4", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top/.well-known/0721.mp4", expectedOutput: "top"),
        GeneralTestArgument(input: "darock.top/0721.mp4", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top/0721.mp4", expectedOutput: "top"),
        GeneralTestArgument(input: "darock.top/.0721.mp4", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top/.0721.mp4", expectedOutput: "top"),
        GeneralTestArgument(input: "darock.top/_.0721.mp4", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top/_.0721.mp4", expectedOutput: "top"),
        GeneralTestArgument(input: "114514.com/https://aaa.1919810", expectedOutput: "com"),
        GeneralTestArgument(input: "darock.top:65535", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top:65535", expectedOutput: "top"),
        GeneralTestArgument(input: "darock.top:65535/", expectedOutput: "top"),
        GeneralTestArgument(input: "https://darock.top:65535/", expectedOutput: "top"),
        GeneralTestArgument(input: "https://fapi.darock.top:65535/", expectedOutput: "top"),
        GeneralTestArgument(input: "https://fapi.darock.top:65535", expectedOutput: "top")
    ]) func testGetUrlTopLevel(by arg: GeneralTestArgument<String, String?>) async throws {
        #expect(GetTopLevel(from: arg.input) == arg.expectedOutput, .init(stringLiteral: arg.input))
    }
    
    @Test(arguments: [
        GeneralTestArgument(input: "darock.top", expectedOutput: true),
        GeneralTestArgument(input: "darock.co", expectedOutput: true),
        GeneralTestArgument(input: "darock.top/", expectedOutput: true),
        GeneralTestArgument(input: "https://darock.top", expectedOutput: true),
        GeneralTestArgument(input: "https://darock.top/", expectedOutput: true),
        GeneralTestArgument(input: "电棍.com", expectedOutput: true),
        GeneralTestArgument(input: "🐮🍺.com", expectedOutput: true),
        GeneralTestArgument(input: "abc.wdnmd", expectedOutput: false),
        GeneralTestArgument(input: "https://abc.wdnmd", expectedOutput: true),
        GeneralTestArgument(input: "abc.wdnmd/https://", expectedOutput: false),
        GeneralTestArgument(input: "abc.wdnmd/https://aaa.0721", expectedOutput: false),
        GeneralTestArgument(input: "114514.com/aaa.114514", expectedOutput: true),
        GeneralTestArgument(input: "114514.com/https://aaa.1919810", expectedOutput: true),
        GeneralTestArgument(input: "nginx.conf.d", expectedOutput: false),
        GeneralTestArgument(input: "Test", expectedOutput: false),
        GeneralTestArgument(input: "...", expectedOutput: false),
        GeneralTestArgument(input: "哇袄", expectedOutput: false),
        GeneralTestArgument(input: "../...//./../.", expectedOutput: false),
        GeneralTestArgument(input: "////", expectedOutput: false),
        GeneralTestArgument(input: ".//.", expectedOutput: false),
        GeneralTestArgument(input: "", expectedOutput: false),
        GeneralTestArgument(input: " ", expectedOutput: false),
        GeneralTestArgument(input: "/etc/apt/sources.conf.d", expectedOutput: false),
        GeneralTestArgument(input: "/etc/apt/sources.conf.d/", expectedOutput: false),
        GeneralTestArgument(input: "darock.top/.well-known/0721.mp4", expectedOutput: true),
        GeneralTestArgument(input: "https://darock.top/.well-known/0721.mp4", expectedOutput: true),
        GeneralTestArgument(input: "darock.top:65535", expectedOutput: true),
        GeneralTestArgument(input: "darock.top:65535/", expectedOutput: true),
        GeneralTestArgument(input: "TEST", expectedOutput: false),
        GeneralTestArgument(input: "TEST.CoM", expectedOutput: true),
        GeneralTestArgument(input: "TEST.CoM/", expectedOutput: true),
        GeneralTestArgument(input: "test.逆天", expectedOutput: false),
        GeneralTestArgument(input: "test.逆天/", expectedOutput: false),
        GeneralTestArgument(input: "特朗普.中国", expectedOutput: true),
        GeneralTestArgument(input: "特朗普.中国/", expectedOutput: true)
    ]) func testStringIsUrl(by arg: GeneralTestArgument<String, Bool>) async throws {
        #expect(arg.input.isURL() == arg.expectedOutput)
    }
}

struct GeneralTestArgument<T, U> {
    var input: T
    var expectedOutput: U
}
