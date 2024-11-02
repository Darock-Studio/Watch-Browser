//
//  WEBackSwift.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//

import Foundation

@objcMembers
public final class WEBackSwift: NSObject {
    public static func createWebArchive() {
        webViewObject.createWebArchiveData { data, error in
            if let url = webViewObject.url {
                let curl = url.absoluteString
                do {
                    if _slowPath(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/WebArchives")) {
                        try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/WebArchives", withIntermediateDirectories: false)
                    }
                    try data.write(
                        to: URL(
                            filePath: NSHomeDirectory()
                            + "/Documents/WebArchives/\(curl.base64Encoded().replacingOccurrences(of: "/", with: "{slash}").prefix(Int(NAME_MAX - 9))).drkdataw"
                        )
                    )
                    UserDefaults.standard.set(
                        [curl] + (UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()),
                        forKey: "WebArchiveList"
                    )
                } catch {
                    globalErrorHandler(error)
                }
            }
        }
    }
    
    public static func storeWebTab() {
//        if UserDefaults.standard.bool(forKey: "LabTabBrowsingEnabled") {
//            AdvancedWebViewController.shared.storeTab(in: UserDefaults.standard.stringArray(forKey: "CurrentTabs") ?? [String](),
//                                                      at: AdvancedWebViewController.shared.currentTabIndex)
//        }
    }
}
