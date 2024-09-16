//
//  Extensions.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/9/16.
//

import Foundation

func jsonString<T>(from value: T) -> String? where T: Encodable {
    do {
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(value)
        return String(decoding: jsonData, as: UTF8.self)
    } catch {
        print("Error encoding data to JSON: \(error)")
    }
    return nil
}
func getJsonData<T>(_ type: T.Type, from json: String) -> T? where T: Decodable {
    do {
        let jsonData = json.data(using: .utf8)!
        let jsonDecoder = JSONDecoder()
        return try jsonDecoder.decode(type, from: jsonData)
    } catch {
        print("Error decoding JSON to data: \(error)")
    }
    return nil
}
