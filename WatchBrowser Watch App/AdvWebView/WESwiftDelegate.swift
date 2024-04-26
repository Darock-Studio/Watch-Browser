//
//  WESwiftDelegate.swift
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/26.
//

import Dynamic
import Foundation

fileprivate var errorLabel = { () -> Dynamic in
    let errorLabel = Dynamic.UILabel()
    errorLabel.setFrame(getMiddleRect(y: 30, height: 60))
    errorLabel.setFont(UIFont(name: "Helvetica", size: 13))
    errorLabel.setNumberOfLines(4)
    errorLabel.setTextColor(UIColor.black)
    errorLabel.setTextAlignment(NSTextAlignment.center)
    return errorLabel
}()

@objcMembers
public class WESwiftDelegate: NSObject {
    public func webView(_ view: Any, didStartProvisionalNavigation navigation: Any) {
        debugPrint("Start Navigation")
        errorLabel.removeFromSuperview()
    }
    
    public func webView(_ view: Any, didFinishNavigation navigation: Any) {
        debugPrint("Finish Navigation")
    }
    
    public func webView(_ view: Any, didFailNavigation navigation: Any, withError error: NSError) {
        debugPrint("Failed Navigation")
        debugPrint(error)
    }
    
    public func webView(_ view: Any, didFailProvisionalNavigation navigation: Any, withError error: NSError) {
        debugPrint("Failed Early Navigation")
        debugPrint(error)
        errorLabel.text = "载入页面时出错\n\(error.localizedDescription)"
        AdvancedWebViewController.shared.webViewHolder.addSubview(errorLabel)
    }
}
