//
//  IntelligenceModels.swift
//  WatchBrowser
//
//  Created by memz233 on 10/3/24.
//

import OSLog
import Alamofire
import SwiftyJSON

private let serviceAPIBaseURL = "https://api.chatanywhere.tech"
private let serviceAPIKey = "sk-9qkHHIzQGIBDMohlF4cBM30gK13qvvBUH3Kwy8Q51dxRtGoq"

struct IntelligenceMessagePostData: Encodable {
    var messages: [[String: String]]
    var model: String = "gpt-3.5-turbo"
}
struct SingleIntelligenceMessage: Identifiable, Equatable, Codable, Hashable {
    var id = UUID()
    var role: IntelligenceRole
    var content: String
    
    init(role: IntelligenceRole, content: String) {
        self.role = role
        self.content = content
    }
    
    public func toDictionary() -> [String: String] {
        return ["role": role.rawValue, "content": content]
    }
}
enum IntelligenceRole: String, Codable {
    case system
    case user
    case assistant
    case error
}

func getRawIntelligenceCompletionData(from messages: [SingleIntelligenceMessage]) async -> String? {
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(serviceAPIKey)"
    ]
    let messageDictionaries = messages.map { $0.toDictionary() }
    return await withCheckedContinuation { continuation in
        AF.request(
            serviceAPIBaseURL + "/v1/chat/completions",
            method: .post,
            parameters: IntelligenceMessagePostData(
                messages: messageDictionaries
            ),
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).response { response in
            if let rpd = response.data {
                do {
                    let json = try JSON(data: rpd)
                    if let content = json["choices"][0]["message"]["content"].string {
                        continuation.resume(returning: content)
                    } else {
                        os_log(.error, "\(json)")
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}
