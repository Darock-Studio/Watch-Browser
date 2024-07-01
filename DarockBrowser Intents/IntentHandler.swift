//
//  IntentHandler.swift
//  DarockBrowser Intents
//
//  Created by memz233 on 6/30/24.
//

import Intents

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        guard intent is SearchIntent else {
            return self
        }
        return SearchIntentHandler()
    }
}

public class SearchIntentHandler: NSObject, SearchIntentHandling {
    public func handle(intent: SearchIntent, completion: @escaping (SearchIntentResponse) -> Void) {
        let userActivity = NSUserActivity(activityType: NSStringFromClass(SearchIntent.self))
        userActivity.userInfo = ["Intent": intent, "Type": "SiriSearch"]
        let response = SearchIntentResponse(code: .continueInApp, userActivity: userActivity)
        completion(response)
    }
    
    public func resolveContent(for intent: SearchIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let content = intent.content, !content.isEmpty {
            completion(.success(with: content))
        } else {
            completion(.needsValue())
        }
    }
}
