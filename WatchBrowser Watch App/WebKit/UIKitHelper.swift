//
//  UIKitHelper.swift
//  WatchBrowser
//
//  Created by memz233 on 8/5/24.
//

import OSLog
import Dynamic

/// 安全推出 ViewController
/// - Parameters:
///   - controller: 要推出的 ViewController
///   - parentController: 父 ViewController
///   - completion: 完成回调，参数指示是否成功推出
@_optimize(speed)
@usableFromInline
func safePresent(_ controller: Dynamic,
                 on parentController: Dynamic = Dynamic.UIApplication.sharedApplication.keyWindow.rootViewController,
                 completion: (Bool) -> Void = { _ in }) {
    if _fastPath(controller.presentingViewController.asObject == nil) {
        DispatchQueue.main.async {
            parentController.presentViewController(controller, animated: true, completion: nil)
        }
        completion(true)
        return
    }
    Logger().warning("Trying to present a ViewController which is already presented, rejecting.")
    completion(false)
}
