//
//  WEBackSwift.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//

import Dynamic
import Foundation

@objcMembers
public class WEBackSwift: NSObject {
    public static func createWebArchive() {
        Dynamic(webViewObject).createWebArchiveDataWithCompletionHandler({ data, error in
            if error == nil {
                if let url = Dynamic(webViewObject).URL.asObject {
                    let curl = (url as! NSURL).absoluteString!
                    do {
                        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/WebArchives") {
                            try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/WebArchives", withIntermediateDirectories: false)
                        }
                        try data.write(toFile: NSHomeDirectory() + "/Documents/WebArchives/\(curl.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")).drkdataw")
                        UserDefaults.standard.set([curl] + (UserDefaults.standard.stringArray(forKey: "WebArchiveList") ?? [String]()), forKey: "WebArchiveList")
                    } catch {
                        print(error)
                    }
                }
            } else {
                debugPrint("\(error!.localizedDescription)")
            }
            pMenuShouldDismiss = true
        } as @convention(block) (NSData, NSError?) -> Void)
    }
}
