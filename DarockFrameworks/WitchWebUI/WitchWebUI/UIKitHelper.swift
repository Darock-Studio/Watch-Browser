//
//  UIKitHelper.swift
//  WatchBrowser
//
//  Created by memz233 on 8/5/24.
//

import OSLog
import WatchKit

/// 安全推出 ViewController
/// - Parameters:
///   - controller: 要推出的 ViewController
///   - parentController: 父 ViewController
///   - completion: 完成回调，参数指示是否成功推出
@usableFromInline
func safePresent(_ controller: NSObject,
                 on parentController: NSObject? = nil,
                 completion: (Bool) -> Void = { _ in }) {
    let parentController = parentController ?? WKApplication.shared().rootInterfaceController?.value(forKey: "underlyingUIHostingController") as? NSObject
    if _slowPath(!(parentController?.responds(to: NSSelectorFromString("presentModalViewController:animated:")) ?? false)) {
        os_log(.fault, "Invalid parent controller.")
        completion(false)
        return
    }
    guard controller.responds(to: NSSelectorFromString("presentModalViewController:animated:")) else {
        os_log(.fault, "Invalid presenting controller.")
        completion(false)
        return
    }
    if controller.value(forKey: "presentingViewController") == nil {
        DispatchQueue.main.async {
            parentController?.perform(NSSelectorFromString("presentModalViewController:animated:"), with: controller, with: true)
        }
        completion(true)
        return
    }
    os_log(.error, "Trying to present a ViewController which is already being presented, rejecting.")
    completion(false)
}
